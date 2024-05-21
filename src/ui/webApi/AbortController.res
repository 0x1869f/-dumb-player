type t

@new external make: unit => t = "AbortController"

@get external signal: t => AbortSignal.t = "signal"
@send external abort: t => unit = "abort"
