type supportedExtention = Mp3 | Flac

type metaInfo = {
  image?: ArrayBuffer.t,
  duration?: float,
  artist?: string,
  title?: string,
  album?: string,
  year?: int,
  container?: string,
  genre: array<string>,
}

type file = {
  fullPath: string,
  parentDir: string,
  name: string,
}

type audioFile = {
  ...file,
  id: Id.t,
  metaInfo: metaInfo,
  extention: supportedExtention,
}
