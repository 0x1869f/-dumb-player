@react.component
let make = (
  ~file: Audio.audioFile,
  ~isSelected: bool,
  ~isCurrent: bool,
) => {
  Signal.track()

  let duration = switch file.metaInfo.duration {
    | Some(value) => Math.floor(value)
    | None => 0.0
  }

  let imageUrl = Signal.useSignal(None)

  React.useEffect0(() => {
    switch file.metaInfo.image {
      | Some(value) => imageUrl -> Signal.set(value -> ImageUrl.createImageUrl -> Some)
      | None => ()
    }

    Some(() => {
      switch imageUrl -> Signal.get {
        | Some(value) => ImageUrl.clearUrl(value)
        | None => ()
      }
    })
  })

  let boxStyle = ref("border-transparent p-1 content-center font-1 grid grid-cols-12 gap-1 border-1 border-solid rounded")

  if isSelected {
    boxStyle := boxStyle.contents ++ " bg-gray-700"
  }

  if isCurrent {
    boxStyle := boxStyle.contents ++ " bg-gray-500"
  }

  let imageOrIcon = Signal.useComputed(() => {
    let url = imageUrl -> Signal.get
    url -> Option.isSome 
      ? <Image url={url} className="rounded w-9 h-9" />
      : <Lucide.Music className={Some("rounded w-7 h-7 bordered opacity-20 bg-gray-500 p-1")} />
  })

  let title = file.metaInfo.artist -> Option.isSome && file.metaInfo.title -> Option.isSome
    ? <>
      <div className="w-1/2 flex flex-col">
        <span className="text-sm">{React.string(file.metaInfo.artist -> Option.getUnsafe)}</span>
        <span className="text-sm text-purple-300">{React.string(file.metaInfo.title -> Option.getUnsafe)}</span>
      </div>

      <div className="w-1/2">
        <span className="text-sm">{React.string(file.metaInfo.album -> Option.getOr(""))}</span>
      </div>
    </>
    : <span className="text-sm">{React.string(file.name)}</span>

  let render = () => {
    <div className={boxStyle.contents}>
      <div className="col-start-1 col-end-11 flex items-center gap-2">
        {imageOrIcon -> Signal.get}
        {title}
      </div>

      <div className="col-start-12 justify-self-end self-center">
        <Duration seconds={duration} className="" />
      </div>
    </div>
  }

  render()
}

