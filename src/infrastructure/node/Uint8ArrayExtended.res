type t = Uint8Array.t
@get external getBuffer: t => ArrayBuffer.t = "buffer"

@new external fromNodeBuffer: NodeJs.Buffer.t => t = "Uint8Array"
