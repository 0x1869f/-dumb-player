let itemsHeight = 64

@react.component
let make = (~dirFiles: Signal.t<array<FileloaderFile.file>>, ~isLoading: Signal.t<bool>) => {
  Signal.track()

  let itemsInViewPort = Math.floor(Window.VisualViewport.height / itemsHeight :> float) -> Int.fromFloat
  let (imageUrls, generateNodeImageUrls, isUrlLoading) = FileloaderImage.useImageUrl()

  let filesInViewPort = Signal.computed(() => {
    dirFiles -> Signal.get -> Array.slice(~start=0, ~end=itemsInViewPort - 1)
  })

  Signal.useEffect(() => {
    filesInViewPort
    -> Signal.get
    -> generateNodeImageUrls
  })

  let directoryPreview = Signal.useComputed(() => filesInViewPort -> Signal.get
    -> Array.map((item: FileloaderFile.file) => {
      switch item {
        | FileloaderFile.Directory(value) => {
          <LoaderListItem
            key={`list-item${value.id}`}
            file={item}
            imageUrl={imageUrls -> Signal.get -> Dict.get(value.id)}
          />
        }
        | FileloaderFile.AudioFile(value) => {
          <LoaderListItem key={`list-item${value.id}`} file={item} imageUrl={imageUrls -> Signal.get -> Dict.get(value.id)} />
        }
      }
    }))

  let component = Signal.useComputed(() => isLoading -> Signal.get || isUrlLoading -> Signal.get
    ? <Loader />
    : <div className="flex flex-col gap-1 h-full">
      {React.array(directoryPreview -> Signal.get)}
    </div>)

  component -> Signal.get
}

