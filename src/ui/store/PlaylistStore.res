let isRandom = Signal.make(false)
let currentFile = Signal.make(None)
let files = Signal.make([])
let randomOrderPrevTracks = Signal.make([])
let randomOrderNextTracks = Signal.make([])

let getRandomInt = (minimum: int, maximum: int) => {
  Math.floor(Math.random() *. ((maximum :> float) -. (minimum:> float) +. 1.0)) -> Int.fromFloat + minimum
}

let rec chooseRandomTrack = (
  ~files: array<Audio.audioFile>,
  ~current: option<Audio.audioFile>=?,
): option<Audio.audioFile> => {
  let index = getRandomInt(0, files -> Array.length - 1)
  let newFile = files -> Array.at(index)

  switch newFile {
    | Some(newValue) => {
      switch current {
        | Some(value) => newValue.id === value.id
          ? chooseRandomTrack(~files=files, ~current=value)
          : newFile
        | None => newFile
      }
    }
    | None => None
    }
  }

let chooseNextTrack = (
  ~files: array<Audio.audioFile>,
  ~current: Audio.audioFile,
): option<Audio.audioFile>  => {
  let currentIndex = files -> Array.findIndex((file) => file.id === current.id)
  let nextIndex = currentIndex + 1

  if (currentIndex !== -1) {
    nextIndex < files -> Array.length
      ? files -> Array.at(nextIndex)
      : files -> Array.at(0)
  } else {
    files -> Array.at(0)
  }
}

let choosePrevTrack = (
  ~files: array<Audio.audioFile>,
  ~current: Audio.audioFile,
): option<Audio.audioFile> => {
  let currentIndex = files -> Array.findIndex((file) => file.id === current.id)
  let prevIndex = currentIndex - 1

  if (currentIndex !== -1) {
    prevIndex < 0
      ? files -> Array.at(-1)
      : files -> Array.at(prevIndex)
  } else {
    files -> Array.at(0)
  }
}

let setFiles = (newFiles: array<Audio.audioFile>) => {
  Signal.batch(() => {
    files -> Signal.set(newFiles)
    randomOrderNextTracks -> Signal.set([])
    randomOrderPrevTracks -> Signal.set([])
  })
}

let addFiles = (newFiles) => files -> Signal.set(
  files -> Signal.get -> Array.concat(newFiles)
)

let setCurrent = (file) => {
  Signal.batch(() => {
    currentFile -> Signal.set(Some(file))
    randomOrderNextTracks -> Signal.set([])
    randomOrderPrevTracks -> Signal.set([])
  })
}

let clearFiles = () => {
  Signal.batch(() => {
    files -> Signal.set([])
    randomOrderPrevTracks -> Signal.set([])
    randomOrderNextTracks -> Signal.set([])
  })
}

let moveUp = (index) => {
  if (index > 0 && files -> Signal.get -> Array.length > index) {
    let prevIndex = index - 1
    let file = files -> Signal.get -> Array.get(index)
    let prev = files -> Signal.get -> Array.get(prevIndex)

    let newFileList = [
      ...files -> Signal.get -> Array.slice(~start=0, ~end=prevIndex),
      file -> Option.getUnsafe,
      prev -> Option.getUnsafe,
      ...files  -> Signal.get -> Array.slice(~start=index + 1, ~end=files -> Signal.get -> Array.length),
    ]

    files -> Signal.set(newFileList)
  }
}

let moveDown = (index) => {
  if (index < files -> Signal.get -> Array.length - 1) {
    let nextIndex = index + 1
    let file = files -> Signal.get -> Array.get(index)
    let next = files -> Signal.get -> Array.get(nextIndex)

    let newFileList = [
      ...files -> Signal.get -> Array.slice(~start=0, ~end=index),
      next -> Option.getUnsafe,
      file -> Option.getUnsafe,
      ...files -> Signal.get -> Array.slice(~start=nextIndex + 1, ~end=files -> Signal.get -> Array.length),
    ]

    files -> Signal.set(newFileList)
  }
}
let selectNext =() => {
  if (files -> Signal.get -> Array.length > 0 && currentFile -> Signal.get -> Option.isSome) {
    if (isRandom -> Signal.get) {
      if (randomOrderNextTracks -> Signal.get -> Array.length > 0) {
        let next = randomOrderNextTracks -> Signal.get -> Array.at(-1)
        let rest = randomOrderNextTracks -> Signal.get -> Array.slice(~start=0, ~end=randomOrderNextTracks -> Signal.get -> Array.length)

        Signal.batch(() => {
          randomOrderPrevTracks -> Signal.set([
            ...randomOrderPrevTracks -> Signal.get,
            currentFile -> Signal.get -> Option.getUnsafe
          ])
          randomOrderNextTracks -> Signal.set(rest)
          currentFile -> Signal.set(next)
        })
      } else {
        let next = chooseRandomTrack(~files=files -> Signal.get, ~current=currentFile -> Signal.get -> Option.getUnsafe)

        Signal.batch(() => {
          randomOrderPrevTracks -> Signal.set([
            ...randomOrderPrevTracks -> Signal.get,
            currentFile -> Signal.get -> Option.getUnsafe
          ])
          currentFile -> Signal.set(next)
        })
      } 
    } else {
      let newFile = chooseNextTrack(~files=files -> Signal.get, ~current=currentFile -> Signal.get -> Option.getUnsafe)

      currentFile -> Signal.set(newFile)
    }
  }
}

let selectPrev = () => {
  if (files -> Signal.get -> Array.length > 0 && currentFile -> Signal.get -> Option.isSome) {
    if (isRandom -> Signal.get) {
      if (randomOrderPrevTracks -> Signal.get -> Array.length > 0) {
        let nextToPlay = randomOrderPrevTracks -> Signal.get -> Array.at(-1)
        let rest = randomOrderPrevTracks -> Signal.get -> Array.slice(~start=0, ~end=randomOrderPrevTracks -> Signal.get -> Array.length)

        Signal.batch(() => {
          randomOrderNextTracks -> Signal.set([
            ...randomOrderNextTracks -> Signal.get,
            currentFile -> Signal.get -> Option.getUnsafe
          ])
          randomOrderPrevTracks -> Signal.set(rest)
          currentFile -> Signal.set(nextToPlay)
        })
      } else {
        let next = chooseRandomTrack(~files=files -> Signal.get, ~current=currentFile -> Signal.get -> Option.getUnsafe)

        Signal.batch(() => {
          randomOrderNextTracks -> Signal.set([
          ...randomOrderNextTracks -> Signal.get,
          currentFile -> Signal.get -> Option.getUnsafe
          ])
          currentFile -> Signal.set(next)
        })
      }
    } else {
      let newFile = choosePrevTrack(~files=files -> Signal.get, ~current=currentFile -> Signal.get -> Option.getUnsafe)

     currentFile -> Signal.set(newFile)
   }
  }
}

let deleteFile = (deletedFile: Audio.audioFile) => {
  let index = files -> Signal.get -> Array.findIndex((file) => file.id === deletedFile.id)

  if (index > -1) {
    let newFilesList = [
    ...files -> Signal.get -> Array.slice(~start=0, ~end=index),
    ...files -> Signal.get -> Array.slice(~start=index + 1, ~end=files -> Signal.get -> Array.length)
    ]

    Signal.batch(() => {
      files -> Signal.set(newFilesList)
      randomOrderPrevTracks -> Signal.set(
        randomOrderPrevTracks -> Signal.get
        -> Array.filter((track) => track.id !== deletedFile.id)
      )
      randomOrderNextTracks -> Signal.set(
        randomOrderNextTracks -> Signal.get
        -> Array.filter((track) => track.id !== deletedFile.id)
      )
    })
  }
}
let switchRandom = () => {
    if (isRandom -> Signal.get) {
      Signal.batch(() => {
        randomOrderNextTracks -> Signal.set([])
        randomOrderPrevTracks -> Signal.set([])
        isRandom -> Signal.set(false)
      })
    } else {
      isRandom -> Signal.set(true)
    }
  }
let setIsRandom = (value) => isRandom -> Signal.set(value)

