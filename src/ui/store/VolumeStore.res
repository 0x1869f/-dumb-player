let maxVolume = 1.0
let minVolume = 0.0
let volumeStep = 0.05
let defaultVolume = 0.2

let volume = Signal.make(defaultVolume)
let isMuted = Signal.make(false)

let calculateIncreasedVolume = (volume: float, step: float): float => {
  volume +. step > maxVolume
    ? maxVolume
    : volume +. step
}

let calculateDecreasedVolume = (volume: float, step: float): float => {
  volume -. step > minVolume
    ? volume -. step
    : minVolume
}

let setVolume = (value) => {
  volume -> Signal.set(value)
}

let increaseVolume = () => { 
  let newValue = volume -> Signal.get -> calculateIncreasedVolume(volumeStep)
  volume -> Signal.set(newValue) 
}

let increaseVolumeDouble = () => {
  let newValue = volume -> Signal.get -> calculateIncreasedVolume(volumeStep *. 2.0)
  volume -> Signal.set(newValue) 
}

let decreaseVolume = () => {
  let newValue = volume -> Signal.get -> calculateDecreasedVolume(volumeStep)
  volume -> Signal.set(newValue) 
}
let decreaseVolumeDouble = () => {
  let newValue = volume -> Signal.get -> calculateDecreasedVolume(volumeStep *. 2.0)
  volume -> Signal.set(newValue) 
}

let switchMute = () => {
  isMuted -> Signal.set(!(isMuted -> Signal.get))
}

let setIsMuted = (value) => {
  isMuted -> Signal.set(value)
}
