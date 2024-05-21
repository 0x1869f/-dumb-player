let useImageUrl = () => {
  let imageUrls = Signal.useSignal(Dict.make())
  let isLoading = Signal.useSignal(false)

  let clearUrls = (urls: dict<string>) => {
    urls -> Dict.forEach((imageUrl) => {
      Webapi.Url.revokeObjectURL(imageUrl)
    })
  }

  React.useEffect0(() => Some(() => imageUrls -> Signal.get -> clearUrls))

  let generateNodeImageUrls = (nodeList: array<FileloaderFile.file>) => {
    isLoading -> Signal.set(true)
    let oldUrls = imageUrls -> Signal.peek

     imageUrls -> Signal.set(nodeList -> Array.reduce(Dict.make(), (images, node) => {
      let (image, id) = switch node {
        | FileloaderFile.AudioFile(file) => (file.metaInfo.image, file.id)
        | FileloaderFile.Directory(directory) => (directory.image, directory.id)
      }

      switch image {
        | Some(value) => images -> Dict.set(id, ImageUrl.createImageUrl(value))
        | None => ()
      }

      images
    }))
  
    isLoading -> Signal.set(false)
    clearUrls(oldUrls)
  }

  (imageUrls, generateNodeImageUrls, isLoading)

}
