// let createImageUrl = (image: ArrayBuffer.t) => {
//   Webapi.Url.createObjectURLFromBlob(Webapi.Blob.make([image -> Webapi.Blob.arrayBufferToBlobPart]))
// }
//
// let clearUrls = (urls: dict<string>) => {
//   urls -> Dict.forEach((imageUrl) => {
//     Webapi.Url.revokeObjectURL(imageUrl)
//   })
// }
//
// let generateNodeImageUrls = (nodeList: array<FileloaderFile.file>) => nodeList -> Array.reduce(Dict.make(), (images, node) => {
//   let (image, id) = switch node {
//     | FileloaderFile.AudioFile(file) => (file.metaInfo.image, file.id)
//     | FileloaderFile.Directory(directory) => (directory.image, directory.id)
//   }
//
//   switch image {
//     | Some(value) => images -> Dict.set(id, createImageUrl(value))
//     | None => ()
//   }
//
//     images
//   })

let createImageUrl = (image: ArrayBuffer.t) => {
  Webapi.Url.createObjectURLFromBlob(Webapi.Blob.make([image -> Webapi.Blob.arrayBufferToBlobPart]))
}

let clearUrl = (url: string) => {
    Webapi.Url.revokeObjectURL(url)
}

