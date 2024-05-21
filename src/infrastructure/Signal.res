type t<'value>

@set external set: (t<'value>, 'value) => unit = "value"
@get external get: t<'value> => 'value = "value"
@send external peek: t<'value> => 'value = "peek"

@module("@preact/signals-core")
external make: 'value => t<'value> = "signal"

@module("@preact/signals-core")
external computed: (unit => 'value) => t<'value> = "computed"

@module("@preact/signals-core")
external effect: (unit => unit) => unit = "effect"

@module("@preact/signals-core")
external effectWithCleanup: (unit => unit) => (unit => unit) = "effect"

@module("@preact/signals-core")
external batch: (unit => unit) => unit = "batch"

@module("@preact/signals-react/runtime")
external track: unit => unit = "useSignals"

@module("@preact/signals-react")
external useMake: 'value => t<'value> = "signal"

@module("@preact/signals-react")
external useSignal: 'value => t<'value> = "useSignal"

@module("@preact/signals-react")
external useComputed: (unit => 'value) => t<'value> = "useComputed"

@module("@preact/signals-react")
external useEffect: (unit => unit) => unit = "useSignalEffect"
