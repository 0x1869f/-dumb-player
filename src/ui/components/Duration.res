type durationInfo = {
  mutable hours: int,
  mutable minutes: int,
  mutable seconds: int,
}

let secondsInMinute = 60.0
let secondsInHour = 60.0 *. 60.0

let getTimePeriods = (seconds: float): durationInfo => {
  let allSeconds = ref(seconds)
  let duration: durationInfo = {
    hours: 0,
    minutes: 0,
    seconds: 0,
  }

  let hours = allSeconds.contents /. secondsInHour

  if (hours >= 1.0) {
    duration.hours = Math.floor(hours) -> Int.fromFloat
    allSeconds := allSeconds.contents -. (duration.hours :> float) *. secondsInHour
  }

  let minutes = allSeconds.contents /. secondsInMinute

  if (minutes >= 1.0) {
    duration.minutes = Math.floor(minutes) -> Int.fromFloat
    allSeconds := allSeconds.contents -. (duration.minutes :> float) *. secondsInMinute
  }

  duration.seconds = allSeconds.contents -> Int.fromFloat

  duration
}


let getTimeString = (time: int): string => {
  time < 10
    ? `0${time -> Int.toString}`
    : time -> Int.toString
}

@react.component
let make = (~seconds: float, ~className: string) => {
  let duration = getTimePeriods(seconds)

  duration.hours > 0
    ? <span className={className}>
      {React.string(`${duration.hours -> Int.toString}:${getTimeString(duration.minutes)}:${getTimeString(duration.seconds)}`)}
    </span>
    : <span className={className}>
      {React.string(`${getTimeString(duration.minutes)}:${getTimeString(duration.seconds)}`)}
    </span>
}
