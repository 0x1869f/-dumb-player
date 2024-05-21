module MusicMetadata = {
  type metaInfoPicture = {
    format: string,
    data: NodeJs.Buffer.t,
    description?: string,
    type_?: string,
    name?: string,
  }


  type metadataMetaFormat = {
    duration?: float,
    container?: string,
  }

  type metadataMetaCommon = {
    artist?: string,
    album?: string,
    title?: string,
    genre?: array<string>,
    year?: int,
    picture?: array<metaInfoPicture>
  }

  type metadataMetaInfo = {
    format: metadataMetaFormat,
    common: metadataMetaCommon,
  }

  type parseFileOptions = {
    duration?: bool
  }

  @module("music-metadata") external parseFile: (string, parseFileOptions) => promise<metadataMetaInfo> = "parseFile"
}


let supportedImageExtentions = Set.fromArray([".png", ".jpg", ".jpeg"])
let coverVariants = supportedImageExtentions -> Set.values -> Iterator.toArrayWithMapper((ext) => {
  `cover${ext}`
})

let nodeBufferToArrayBuffer = (buffer: NodeJs.Buffer.t): ArrayBuffer.t => {
  Uint8ArrayExtended.fromNodeBuffer(buffer) -> Uint8ArrayExtended.getBuffer
}

let getExtention = (filename: string): option<Audio.supportedExtention> => {
  switch NodeJs.Path.extname(filename) {
    | ".mp3" => Some(Audio.Mp3)
    | ".flac" => Some(Audio.Flac)
    | _ => None
  }

}

let getCover = async (path: string): option<ArrayBuffer.t> => {
  let files: array<NodeExtended.Fs.Dirent.t> = await NodeExtended.Fs.readdirWithOptions(path, {withFileTypes: true})

  let coverFile = files -> Array.find((file: NodeExtended.Fs.Dirent.t) => {
    coverVariants -> Array.includes(file.name -> String.toLowerCase)
  })

  let imageFile = switch coverFile {
    | Some(value) => Some(value)
    | None => {
        files -> Array.find((file: NodeExtended.Fs.Dirent.t) => {
        let parts = file.name -> String.toLowerCase -> String.split(".")
        let ext = parts -> Array.at(-1) -> Option.getOr("")
        
        supportedImageExtentions -> Set.has(ext)
      })
    }
  }

  switch imageFile {
    | Some(value) => Some(NodeJs.Fs.readFileSync(NodeJs.Path.join2(value.path, value.name)) -> nodeBufferToArrayBuffer)
    | None => None
  }
}

let mapToDirectory = async (dirent: NodeExtended.Fs.Dirent.t): FileloaderFile.directory => {
  let path = NodeJs.Path.join2(dirent.path, dirent.name)
  let image = await getCover(path)

  {
    id: Id.getId(),
    image: ?image,
    fullPath: `${NodeJs.Path.join2(dirent.path, dirent.name)}`,
    parentDir: dirent.path,
    name: dirent.name
  }
}

let parseFileMeta = async (path: string): Audio.metaInfo => {
  let info = ref(None)

  try {
    info := Some(await MusicMetadata.parseFile(path, { duration: true }))
  }
  catch {
    | _ => ()
  }

  switch info.contents {
    | Some(info) => {
      let image = switch info.common.picture {
        | Some(arr) => {
          switch arr -> Array.get(0) {
            | Some(picture) => Some(picture.data -> nodeBufferToArrayBuffer)
            | None => await getCover(NodeJs.Path.parse(path).dir)
          }
        }
        | None => await getCover(NodeJs.Path.parse(path).dir)
      }

      {
        duration: ?info.format.duration,
        artist: ?info.common.artist,
        title: ?info.common.title,
        genre: switch info.common.genre {
          | Some(value) => value
          | None => []
        },
        year: ?info.common.year,
        album: ?info.common.album,
        container: ?info.format.container,
        image: ?image,
      }
    }
    | None => {genre: []}
  }

}

let audioFileFromFile = async (file: Audio.file): option<Audio.audioFile> => {
  let ext = getExtention(file.fullPath)

  switch ext {
    | Some(extention) => Some({
      id: Id.getId(),
      parentDir: file.parentDir,
      fullPath: file.fullPath,
      name: file.name,
      metaInfo: await parseFileMeta(file.fullPath),
      extention,
    })
    | None => None
  }
}

let mapToFile = async (dirent: NodeExtended.Fs.Dirent.t): option<Audio.audioFile> => {
  await audioFileFromFile({
    name: dirent.name,
    fullPath: `${NodeJs.Path.join2(dirent.path, dirent.name)}`,
    parentDir: dirent.path,
  })
}

let listFiles = async (path: string): array<FileloaderFile.file> => {
  let result = await NodeExtended.Fs.readdirWithOptions(path, { withFileTypes: true })
  let directories = []
  let files = []

  for i in 0 to result -> Array.length - 1 {
    let element = result -> Array.get(i)

    switch element {
      | Some(elementValue) => {
        if elementValue -> NodeExtended.Fs.Dirent.isDirectory {
          let dir = await mapToDirectory(elementValue)

          directories -> Array.push(FileloaderFile.Directory(dir))
        } else {
          if elementValue -> NodeExtended.Fs.Dirent.isFile {
            let file = await mapToFile(elementValue)
              switch file {
                | Some(value) => files -> Array.push(FileloaderFile.AudioFile(value))
                | None => ()
              }

          }
        }
      }
      | None => ()
    }
  }

  [
    ...directories,
    ...files,
  ]
}

let createCacheDir = async (path) => {
  try {
    await NodeJs.Fs.access(path)
  }
  catch {
    | _ => await NodeJs.Fs.mkdir(path, {})
  }
}

let rec extractFilesFromDirectories = async (
  files: array<FileloaderFile.file>,
): array<Audio.audioFile> => {
  let allFiles: ref<array<Audio.audioFile>> = ref([])

  for i in 0 to files -> Array.length - 1 {
    switch files -> Array.get(i) {
      | Some(file) => {
        switch file {
          | FileloaderFile.AudioFile(value) => allFiles.contents -> Array.push(value)
          | FileloaderFile.Directory(value) => { 
            let dirFiles = await listFiles(value.fullPath)
            let extractedFiles = await extractFilesFromDirectories(dirFiles)
            allFiles := allFiles.contents -> Array.concat(extractedFiles)
          }
        }
      }
      | None => ()
    }
  }

  allFiles.contents
}

type preferences = {
  playlist: array<Audio.audioFile>,
  volume: float,
  isRandom: bool,
  isMuted: bool,
}

type storedPreferences = {
  playlist: array<Audio.file>,
  volume: float,
  isRandom: bool,
  isMuted: bool,
}

@scope("JSON") @val external parsePreferencies: string => storedPreferences = "parse"

let loadPreferences = async (): preferences => {
  let path = NodeJs.Path.join2(
    NodeJs.Os.homedir(),
    ".local/share/dumb-player/preferences.json"
  )

  try {
    let file = NodeJs.Fs.readFileSync(path)
    let preferencesData: storedPreferences = parsePreferencies(file -> NodeJs.Buffer.toString)
    let playlist = []

    for i in 0 to preferencesData.playlist -> Array.length - 1 {
      let element = preferencesData.playlist -> Array.get(i)

      switch element {
        | Some(elementValue) => switch await audioFileFromFile(elementValue) {
          | Some(audioFile) => playlist -> Array.push(audioFile)
          | None => ()
        }
        | None => ()
      }
    }

    {
      volume: preferencesData.volume,
      isRandom: preferencesData.isRandom,
      isMuted: preferencesData.isMuted,
      playlist,
    }
  } catch {
    | _ => {
      playlist: [],
      isMuted: false,
      isRandom: false,
      volume: 0.4,
    }
  }
}

let readFile = (path: string): ArrayBuffer.t => {
  let nodeBuffer = NodeJs.Fs.readFileSync(path)

  nodeBufferToArrayBuffer(nodeBuffer)
}


let readAudioFile = (path: string): Uint8Array.t => {
  path -> readFile -> Uint8Array.fromBuffer
}

let mapAudioFileToFile = (audioFile: Audio.audioFile): Audio.file => {
    fullPath: audioFile.fullPath,
    parentDir: audioFile.parentDir,
    name: audioFile.name,
}

let savePreferences = (preferences: preferences) => {
  let playlist: array<Audio.file> = preferences.playlist -> Array.map((audioFile: Audio.audioFile) => mapAudioFileToFile(audioFile))

  let path = NodeJs.Path.join2(
    NodeJs.Os.homedir(),
    ".local/share/dumb-player/preferences.json"
  )
  let prefirencesData: storedPreferences = {
    isMuted: preferences.isMuted,
    isRandom: preferences.isRandom,
    volume: preferences.volume,
    playlist,
  }

  switch prefirencesData -> JSON.stringifyAny {
    | Some(value) => NodeJs.Fs.writeFileSync(path, value -> NodeJs.Buffer.fromString)
    | None => ()
  }
}

