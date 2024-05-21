module Float32Array = {
  type t = Core__Float32Array.t

  @send external setTypedArray: (t, t) => unit = "set"
}
