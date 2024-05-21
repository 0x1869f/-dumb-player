type decodedData = {
  channelData: array<Float32Array.t>,
  samplesDecoded: int,
  sampleRate: int,
}

module MpegDecoder = {
  type t

  @module("mpg123-decoder") @new external make: unit => t = "MPEGDecoder"

  @send external reset: t => unit = "reset"
  @send external free: t => unit = "free"
  @send external decode: (t, Int8Array.t) => decodedData = "decode"
}

module FlacDecoder = {
  type t

  @module("@wasm-audio-decoders/flac") @new external make: unit => t = "FLACDecoder"

  @send external reset: t => unit = "reset"
  @send external free: t => unit = "free"
  @send external decode: (t, Int8Array.t) => promise<decodedData> = "decode"
}

let useDecoder = () => {
  let mpgDecoder = MpegDecoder.make()
  let flacDecoder = FlacDecoder.make()

  React.useEffect0(() => Some(() => {
    mpgDecoder -> MpegDecoder.free
    flacDecoder -> FlacDecoder.free
  }))

  let decodeMp3 = (data: Int8Array.t): decodedData => {
    let value = mpgDecoder -> MpegDecoder.decode(data)
    mpgDecoder -> MpegDecoder.reset

    value
  }

  let decodeFlac = async (data: Int8Array.t): decodedData => {
    let value = await flacDecoder -> FlacDecoder.decode(data)
    flacDecoder -> FlacDecoder.reset

    value
  }

  async(
    file: Uint8Array.t,
    fileExtention: Audio.supportedExtention,
    ~container: option<string>=None,
  ): decodedData => {
    if (container -> Option.isSome) {
      switch container -> Option.getUnsafe {
        | "MPEG" => decodeMp3(file)
        | _ => await decodeFlac(file)
      }
    } else {
      switch fileExtention {
        | Audio.Mp3 => decodeMp3(file)
        | Audio.Flac => await decodeFlac(file)
      }
    }
  }
}
