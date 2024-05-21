module AudioBuffer = {
  type t
  @send external getChannelData: (t, int) => Float32Array.t = "getChannelData"
  @get external numberOfChannels: t => int = "numberOfChannels"
}

module AudioDestinationNode = {
  type t
}

module Gain = {
  module AudioParam = {
    type t

    @set external setValue: (t, float) => unit = "value"
    @get external getValue: (t) => unit = "value"
  }

  type t

  @send external connect: (t, AudioDestinationNode.t) => unit = "connect"

  @get external gain: t => AudioParam.t = "gain"
}

module AudioContext = {
  type t
  @new external make: unit => t = "AudioContext"

  @send external createGain: t => Gain.t = "createGain"
  // @send external createBufferSource: t => AudioBufferSourceNode.t = "createBufferSource"
  @send external createBuffer: (t, int, int, int) => AudioBuffer.t = "createBuffer"

  @get external destination: t => AudioDestinationNode.t = "destination"
}

module AudioBufferSourceNode = {
  type t

  type options = {
    buffer: AudioBuffer.t
  } 

  type handler = Webapi.Dom.Event.t => unit

  type listenerOption = { signal: AbortSignal.t}

  @new external make: (AudioContext.t, ~options: option<options>=?) => t = "AudioBufferSourceNode"

  @send external start: (t, float, float) => unit = "start"
  @send external stop: (t) => unit = "stop"

  @send external addEventListener: (t, string, handler, listenerOption) => unit = "addEventListener"

  @send external connect: (t, Gain.t) => unit = "connect"
}
