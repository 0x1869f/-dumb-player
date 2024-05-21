@react.component
let make = (
  ~file: FileloaderFile.file,
  ~imageUrl: option<string>,
  ~isCurrent: option<bool>=?,
  ~isSelected: option<bool>=?,
) => {
  let cover = () => {
    let style = "rounded w-9 h-9"
    let fileStyle = "rounded w-7 h-7 bordered opacity-20 bg-gray-500 p-1"

    switch imageUrl {
      | Some(value) => <Image url={Some(value)} className={style} />
      | None => switch file {
        | FileloaderFile.Directory(_) => <Lucide.Folder className={Some(fileStyle)} />
        | FileloaderFile.AudioFile(_) => <Lucide.Music className={Some(fileStyle)} />
      }
    }
  }

  let title =() => {
    switch file {
      | FileloaderFile.AudioFile(value) => {
        value.metaInfo.artist -> Option.isSome && value.metaInfo.title -> Option.isSome && value.metaInfo.title -> Option.isSome
          ? <div className="col-start-2 col-end-11 flex content-center gap-2">
            <span className="text-sm">{React.string(value.metaInfo.artist -> Option.getOr(""))}</span>
            <span className="text-sm text-purple-300">{React.string(value.metaInfo.title -> Option.getOr(""))}</span>
          </div>
          : <div className="col-start-2 col-end-11 flex content-center">
            <div></div>
            <span className="text-sm">{React.string(value.name)}</span>
          </div>
      }
      | FileloaderFile.Directory(value) => React.string(value.name)
    }
  }

  let buildTemplate = () => {
    let boxStyle = ref(`border-transparent h-10 p-1 flex gap-2 font-1
      border-1 border-solid rounded items-center`)

    switch isCurrent {
      | Some(true) => boxStyle := boxStyle.contents ++ " bg-gray-700"
      | _ => ()
    }

    switch isSelected {
      | Some(true) => boxStyle := boxStyle.contents ++ " bg-gray-500"
      | _ => ()
    }

    <div className={boxStyle.contents}>
      {cover()}
      {title()}
    </div>
  }

  buildTemplate()
}

