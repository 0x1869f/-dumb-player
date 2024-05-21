// type state = {
//   value: Signal.t<string>,
//   isShown: Signal.t<bool>,
//   history: Signal.t<array<string>>,
// }
//
// type action = (
//   clear: unit => unit,
//   show: unit => unit,
//   hide: unit => unit,
//   setValue: string => unit,
//   addToHistory: string => unit,
// )
//
// let make = () => {
//   let state = (
//     Signal.useMake(""),
//     Signal.useMake(false),
//     Signal.useMake([]),
//   )
//
//   let (value, isShown, history) = state
//
//   let action = ( 
//     () => value -> Signal.set(""), // clear
//     () => isShown -> Signal.set(true), // show
//     () => isShown -> Signal.set(false), // hide
//     (newValue) => value -> Signal.set(newValue), // setValue
//     (newValue) => history -> Signal.set([...history -> Signal.get, newValue]), // addToHistory
//   )
//
//   (state, action)
// }
module type BashInputStore = {
  let value: Signal.t<string>
  let isShown: Signal.t<bool>
  let history: Signal.t<array<string>>

  let clear: unit => unit
  let show: unit => unit
  let hide: unit => unit
  let setValue: (string) => unit
  let addToHistory: (string) => unit
}

module Make = (): BashInputStore => {
  let value: Signal.t<string> = Signal.useMake("")
  let isShown = Signal.useMake(false)
  let history = Signal.useMake([])

  let clear = () => value -> Signal.set("")
  let show = () => isShown -> Signal.set(true)
  let hide = () => isShown -> Signal.set(false)
  let setValue = (newValue) => value -> Signal.set(newValue)
  let addToHistory = (newValue) => history -> Signal.set([...history -> Signal.get, newValue])
}
