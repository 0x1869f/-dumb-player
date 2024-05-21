let rewindStep = 5000.0
let millisecondsInSecond = 1000.0

open ShortcutService

let audioContext = WebAudio.AudioContext.make()
let gain = audioContext -> WebAudio.AudioContext.createGain
let source: ref<WebAudio.AudioBufferSourceNode.t> = ref(audioContext -> WebAudio.AudioBufferSourceNode.make)
let audioBuffer: ref<option<WebAudio.AudioBuffer.t>> = ref(None)

gain -> WebAudio.Gain.connect(audioContext -> WebAudio.AudioContext.destination)
source.contents -> WebAudio.AudioBufferSourceNode.connect(gain)
let controller = ref(AbortController.make())

@react.component
let make = () => {
  Signal.track()

  let doesPlay = Signal.useSignal(false)
  let startTime = Signal.useSignal(0.0)
  let currentTime = Signal.useSignal(0.0)
  let lastPosition = Signal.useSignal(0.0)
  let imageUrl = Signal.useSignal(None)

  let decoder = Decoder.useDecoder()

  let calculatePosition = (current: float, start: float): float => {
    current -. start
  }

  let currentPosition = Signal.useComputed(
    () => calculatePosition(currentTime -> Signal.get, startTime -> Signal.get)
  )

  let handleOnStop = () => {
    doesPlay -> Signal.set(false)
    PlaylistStore.selectNext()
    lastPosition -> Signal.set(0.0)
  }

  let stop = (): float => {
    doesPlay -> Signal.set(false)
    controller.contents -> AbortController.abort
    let last = calculatePosition(currentTime -> Signal.get, startTime -> Signal.get)

    lastPosition -> Signal.set(last)
    try {
      source.contents -> WebAudio.AudioBufferSourceNode.stop
    }
    catch {
      | _ => ()
    }

    last
  }

  let play = (position: float) => {
    switch audioBuffer.contents {
      | Some(value) => {
        doesPlay -> Signal.set(true)
        controller :=  AbortController.make()
        let options: WebAudio.AudioBufferSourceNode.options = { buffer: value }
        source := WebAudio.AudioBufferSourceNode.make(audioContext, ~options=Some(options))
        source.contents -> WebAudio.AudioBufferSourceNode.connect(gain)
        source.contents -> WebAudio.AudioBufferSourceNode.start(0.0, position)
        source.contents -> WebAudio.AudioBufferSourceNode.addEventListener(
          "ended",
          (_) => handleOnStop(),
          { signal: controller.contents -> AbortController.signal }
        )
      }
      | None => ()
    }
  }

  let stopOrPlay = () => {
    if (doesPlay -> Signal.get) {
      stop() -> ignore
    } else {
      startTime -> Signal.set(currentTime -> Signal.get -. lastPosition -> Signal.get)
      currentTime -> Signal.set(Date.now())
      play(lastPosition -> Signal.get /. millisecondsInSecond)
    }
  }

  let playOrStop = () => {
    if (doesPlay -> Signal.get) {
      stop() -> ignore
    }
    else {
      startTime -> Signal.set(currentTime -> Signal.get -. lastPosition -> Signal.get)
      currentTime -> Signal.set(Date.now())
      play(lastPosition -> Signal.get /. millisecondsInSecond)
    }
  }

  let rewindForward = () => {
    switch audioBuffer.contents {
      | Some(_) => {
        let last = stop()
        let trackTime = last +. rewindStep

        startTime -> Signal.set(Date.now() -. trackTime)
        currentTime -> Signal.set(Date.now())
        play(trackTime /. millisecondsInSecond)
      }
      | None => ()
    }

  }

  let rewindToPosition = (position: float) => {
    if audioBuffer.contents -> Option.isSome {
      stop() -> ignore
      startTime -> Signal.set(Date.now() -. (position *. millisecondsInSecond))
      currentTime -> Signal.set(Date.now())
      play(position)
    }
  }

  let rewindBackward = () => {
    if audioBuffer.contents -> Option.isSome {
      let current = stop()

      if (current > rewindStep) {
        let trackTime = current -. rewindStep

        startTime -> Signal.set(Date.now() -. trackTime)
        play(Math.floor(trackTime /. millisecondsInSecond))
      }
      else {
        currentTime -> Signal.set(Date.now())
        startTime -> Signal.set(Date.now())
        play(0.0)
      }
    }
  }

  let loadBuffer = async (newFile: Audio.audioFile) => {
    let buffer = await Electron.readAudioFile(newFile.fullPath)
    let {
      channelData, samplesDecoded, sampleRate,
    } = await decoder(
      buffer,
      newFile.extention,
      ~container=newFile.metaInfo.container,
    )

    audioBuffer := audioContext -> WebAudio.AudioContext.createBuffer(
      channelData -> Array.length,
      samplesDecoded,
      sampleRate
    ) -> Some

    switch audioBuffer.contents {
      | Some(buffer) => {
        channelData -> Array.forEachWithIndex((data, index) => {
          buffer -> WebAudio.AudioBuffer.getChannelData(index) -> CoreExtended.Float32Array.setTypedArray(data)
        })
      }
      | None => ()
    }
  }

  Signal.useEffect(() => {
    if VolumeStore.isMuted -> Signal.get {
      gain -> WebAudio.Gain.gain -> WebAudio.Gain.AudioParam.setValue(0.0)
    } else {
      gain -> WebAudio.Gain.gain -> WebAudio.Gain.AudioParam.setValue(VolumeStore.volume -> Signal.get)
    }
  })

  let revokeUrl = () => {
    switch imageUrl -> Signal.peek {
      | Some(url) => {
        Webapi.Url.revokeObjectURL(url)
        imageUrl -> Signal.set(None)
      }
      | None => ()
    }
  }

  Signal.useEffect(() => {
    switch PlaylistStore.currentFile -> Signal.get {
      | Some(file) => {
        loadBuffer(file) -> Promise.then(() => {
          stop() -> ignore
          lastPosition -> Signal.set(0.0)
          startTime -> Signal.set(Date.now())
          currentTime -> Signal.set(Date.now())
          play(0.0)

          Promise.resolve()
        }) -> ignore

        revokeUrl()
        switch file.metaInfo.image {
          | Some(value) => {
            imageUrl -> Signal.set(Some(ImageUrl.createImageUrl(value)))
          }
          | None => ()
        }
      }
      | None => ()
    }
  })

  React.useEffect0(() => {
    Some(revokeUrl)
  })

  let playTime = Signal.useComputed(() => doesPlay -> Signal.get
    ? Math.floor(currentPosition -> Signal.get /. millisecondsInSecond)
    : Math.floor(lastPosition -> Signal.get /. millisecondsInSecond)
  )

  let image = Signal.useComputed(() => {
    if (imageUrl -> Signal.get -> Option.isSome) {
      <Image className="rounded w-14 h-14" url={imageUrl -> Signal.get} />
    } else {
      switch PlaylistStore.currentFile -> Signal.get {
        | Some(_) => <Lucide.Music className=Some("w-12 h-12 opacity-20 rounded bg-gray-500 p-1") />
        | None => <div className="w-14 h-14"></div>
      }
    }
  })

  let trackDuration = Signal.useComputed(() => switch PlaylistStore.currentFile -> Signal.get {
    | Some(file) => switch file.metaInfo.duration {
      | Some(value) => value
      | None => 0.0
      }
    | None => 0.0
    })

  let trackInfo = Signal.useComputed(() => {
    switch PlaylistStore.currentFile -> Signal.get {
      | Some(file) => {
        if file.metaInfo.artist -> Option.isSome && file.metaInfo.title -> Option.isSome {
          <div className="flex flex-col justify-center">
            <span className="text-sm">
              {React.string(file.metaInfo.artist -> Option.getUnsafe)}
            </span>
            <span className="text-purple-300">
              {React.string(file.metaInfo.title -> Option.getUnsafe)}
            </span>
          </div>
        } else {
          <div className="flex items-center">
            {React.string(file.name)}
          </div>
        }
      }
      | None => <div></div>
    }
  })

  let clearPositionAndPlayNext = () => {
    stop() -> ignore
    lastPosition -> Signal.set(0.0)
    PlaylistStore.selectNext()
  }

  let playPrev = () => {
    stop() -> ignore
    lastPosition -> Signal.set(0.0)
    PlaylistStore.selectPrev()
  }

  let playNext = () => {
    stop() -> ignore
    lastPosition -> Signal.set(0.0)
    PlaylistStore.selectNext()
  }

  let clearPositionAndPlayPrev = () => {
    stop() -> ignore
    lastPosition -> Signal.set(0.0)
    PlaylistStore.selectPrev()
  }

  let controls = Signal.useComputed(() => {
    let playOrPause = doesPlay -> Signal.get
      ? <Lucide.Pause />
      : <Lucide.Play />

    let buttonClass = `bg-transparent rounded border-none 
      text-white`

    <div className="flex gap-1 justify-center">
      <button className={buttonClass} onClick={(_) => playPrev()}>
        <Lucide.SkipBack />
      </button>

      <button className={buttonClass} onClick={(_) => playOrStop()}>
        {playOrPause}
      </button>

      <button className={buttonClass} onClick={(_) => playNext()}>
        <Lucide.SkipForward />
      </button>
    </div>
  })

  let volumeButton = Signal.useComputed(() => {
    let buttonClass = "bg-transparent rounded border-none text-white"
    let icon = VolumeStore.isMuted -> Signal.get
      ? <Lucide.VolumeX />
      : <Lucide.Volume />

    <button className={buttonClass} onClick={(_) => VolumeStore.switchMute()}>
      {icon}
    </button>
  })

  // React.useImperativeHandle(ref, () => ({
  //   stopOrResume: () => {
  //     stopOrPlay()
  //   },
  // }))

  let shuffle = Signal.useComputed(() => {
    let buttonClass = "bg-transparent rounded border-none text-white"
    let iconClass = PlaylistStore.isRandom -> Signal.get
      ? "text-green-500"
      : ""

    <button className={buttonClass} onClick={(_) => PlaylistStore.switchRandom()}>
      <Lucide.Shuffle className={Some(iconClass)} />
    </button>
  })

  React.useEffect0(() => {
    subscribe(Player, [
      {
        callback: (_) => clearPositionAndPlayNext(),
        conditions: [key("KeyN")],
      },
      {
        callback: (_) => stopOrPlay(),
        conditions: [key("KeyC")],
      },
      {
        callback: (_) => rewindForward(),
        conditions: [key("KeyL", ~keys=[ShiftKey])],
      },
      {
        callback: (_) => rewindBackward(),
        conditions: [key("KeyH", ~keys=[ShiftKey])],
      },
      {
        callback: (_) => VolumeStore.increaseVolume(),
        conditions: [key("Equal")],
      },
      {
        callback: (_) => VolumeStore.increaseVolumeDouble(),
        conditions: [key("Equal", ~keys=[ShiftKey])],
      },
      {
        callback: (_) => VolumeStore.decreaseVolume(),
        conditions: [key("Minus")],
      },
      {
        callback: (_) => VolumeStore.decreaseVolumeDouble(),
        conditions: [key("Minus", ~keys=[ShiftKey])],
      },
      {
        callback: (_) => VolumeStore.switchMute(),
        conditions: [key("KeyM")],
      },
      {
        callback: (_) => clearPositionAndPlayPrev(),
        conditions: [key("KeyP")],
      },
      {
        callback: (_) => PlaylistStore.switchRandom(),
        conditions: [key("KeyR")],
      },
    ])
    addActive(Player)

    Some(() => unsubscribe(App))
  })

  React.useEffect0(() => {
    let id = setInterval(() => {
      currentTime -> Signal.set(Date.now())
    }, 500)

    Some(() => {
      clearInterval(id)
      try {
        source.contents -> WebAudio.AudioBufferSourceNode.stop
      } catch {
        | _ => ()
      }
    })
  })

  (
    <div className="p-4 flex items-center justify-between gap-2 border-solid border-0 border-t-2 border-gray-500/20">
      <div className="flex gap-2 min-w-60">
        {image -> Signal.get}
        {trackInfo -> Signal.get}
      </div>

      <div>
        <div className="flex gap-1">
          <Duration seconds={playTime -> Signal.get} className="" />

          <RangeInput
            className="w-48"
            onChange={(~e) => rewindToPosition(e)}
            value={playTime -> Signal.get}
            step={1.0}
            min={0.0}
            max={trackDuration -> Signal.get}
          />
          <Duration seconds={trackDuration -> Signal.get} className="" />
        </div>

        {controls -> Signal.get}
      </div>

      <div className="flex gap-1 items-center">
        {shuffle -> Signal.get}
        {volumeButton -> Signal.get}
        <RangeInput
          className="w-20"
          onChange={(~e) => VolumeStore.setVolume(e)}
          value={VolumeStore.volume -> Signal.get}
          step={0.01}
          min={0.0}
          max={1.0}
        />
        <span>{React.string((VolumeStore.volume -> Signal.get *. 100.0) -> Float.toFixed ++ "%")}</span>
      </div>
    </div>
  )
}
