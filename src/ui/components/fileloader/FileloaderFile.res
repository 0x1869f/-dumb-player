type directory = {
  ...Audio.file,
  id: Id.t,
  image?: ArrayBuffer.t,
}

type file = AudioFile(Audio.audioFile) | Directory(directory)
