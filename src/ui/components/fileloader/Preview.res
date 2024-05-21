%%raw("import './Preview.css'")

@react.component
let make = (~file: Audio.audioFile, ~imageUrl: option<string>) => {
  let icon = () => {
    switch imageUrl {
      | Some(_) => <Image url={imageUrl} className="size-60 rounded" />
      | None => <Lucide.Music className={Some("track-icon rounded opacity-20 bg-gray-500")} />
    }
  }

  let buildGenre = (genres: array<string>) => {
    let style = "py-1 px-2 text-black rounded bg-green-500"

    genres -> Array.map(
      (genre) => <span key={genre} className={style}>{React.string(genre)}</span>,
    )
  }

  let buildDuration = (duration: float) => {
    <div key="duration" className="title-grid">
      <span className="text-gray-400">{React.string("duration")}</span>
      <Duration seconds={duration} className=""/>
    </div>
  }

  let buildPreviewItem = (field: string, value: string) => {
    let titleStyle = "text-gray-400"

    <div key={field} className="title-grid">
      <span className={titleStyle}>{React.string(field)}</span>
      <span>{React.string(value)}</span>
    </div>
  }

  let buildFilePreview = () => {
    let info = [switch file.metaInfo.title {
      | Some(value) => buildPreviewItem("title", value)
      | None => buildPreviewItem("name", file.name)
    }]

    switch file.metaInfo.artist {
      | Some(value) => info -> Array.push(buildPreviewItem("artist", value))
      | None => ()
    }

    switch file.metaInfo.album {
      | Some(value) => info -> Array.push(buildPreviewItem("album", value))
      | None => ()
    }

    switch file.metaInfo.year {
      | Some(value) => info -> Array.push(buildPreviewItem("year", value -> Int.toString))
      | None => ()
    }

    switch file.metaInfo.duration {
      | Some(value) => info -> Array.push(buildDuration(value))
      | None => ()
    }

    info -> Array.push(
      <div key="genre" className="pt-1 flex gap-2">{React.array(buildGenre(file.metaInfo.genre))}</div>,
    )

    <div className="flex flex-col">{React.array(info)}</div>
  }

  <div className="key pt-10 pl-10 flex flex-col content-center items-start gap-1">
    {icon()}
    {buildFilePreview()}
  </div>
}

