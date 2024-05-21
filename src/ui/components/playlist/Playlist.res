open ShortcutService

let itemsHeight = 60

@react.component
let make = () => {
  Signal.track()
  let selectedFile = Signal.useSignal(None)
  let selectedFileIndex = Signal.useSignal(0)
  let firstScreenItemIndex = Signal.useSignal(0)

  let fileListWasEmpty = React.useRef(true)

  let itemsInViewPort = Math.floor((Window.VisualViewport.height - 100) / itemsHeight :> float) -> Int.fromFloat
  

  let filterFiles = (file: Audio.audioFile, filter: string) => {
    let lowerFilter = filter -> String.toLowerCase

    let result = ref(false)
    switch file.metaInfo.title {
      | Some(titleValue) => result := titleValue -> String.toLowerCase -> String.includes(lowerFilter)
      | None => ()
    }

    if !result.contents {
      result := switch file.metaInfo.artist {
        | Some(value) =>  value -> String.toLowerCase -> String.includes(lowerFilter)
        | None => file.name -> String.toLowerCase -> String.includes(lowerFilter)
      }
    }

    result.contents
  }

  let filteredFiles = Signal.useComputed(
    () => PlaylistFilter.Store.value -> Signal.get -> String.length > 0
      ? PlaylistStore.files -> Signal.get -> Array.filter((file) => filterFiles(file, PlaylistFilter.Store.value -> Signal.get))
      : PlaylistStore.files -> Signal.get,
  )

  let lastScreenItemIndex = Signal.useComputed(
    () => firstScreenItemIndex -> Signal.get + itemsInViewPort < filteredFiles -> Signal.get -> Array.length - 1
      ? firstScreenItemIndex -> Signal.get + itemsInViewPort
      : filteredFiles -> Signal.get -> Array.length - 1,
  )

  let moveCursorDown = () => {
    if selectedFile -> Signal.get -> Option.isSome {
      if (selectedFileIndex -> Signal.get < filteredFiles -> Signal.get -> Array.length - 1) {
        let newIndex = selectedFileIndex -> Signal.get + 1

        selectedFile -> Signal.set(filteredFiles -> Signal.get -> Array.get(newIndex))
        selectedFileIndex -> Signal.set(newIndex)

        if (newIndex > lastScreenItemIndex -> Signal.get) {
          firstScreenItemIndex -> Signal.set(firstScreenItemIndex -> Signal.get + 1)
        }
      }
    }
  }

  let deleteUnderCursor = () => {
    switch selectedFile -> Signal.get {
      | Some(value) => {
        let currentFileId = switch PlaylistStore.currentFile -> Signal.get {
          | Some(file) => file.id
          | None => ""
        }

        if value.id !== currentFileId {
          if (filteredFiles -> Signal.get -> Array.length > 1) {
            if (selectedFileIndex -> Signal.get === 0) {
              selectedFile -> Signal.set(filteredFiles -> Signal.get -> Array.get(1))
            } else {
              let newIndex = selectedFileIndex -> Signal.get - 1

              selectedFileIndex -> Signal.set(newIndex)
              selectedFile -> Signal.set(filteredFiles -> Signal.get -> Array.get(newIndex))
            }
          } else {
            selectedFile -> Signal.set( None)
            selectedFileIndex -> Signal.set(0)
          }

          PlaylistStore.deleteFile(value)
        }
      }
      | None => ()
    }
  }

  let moveSelectedUp = () => {
    switch selectedFile -> Signal.get {
      | Some(value) => {
        let index = PlaylistStore.files -> Signal.get -> Array.findIndex((f) => f.id === value.id)

        if (index > 0) {
          selectedFileIndex -> Signal.set(index - 1)
          PlaylistStore.moveUp(index)

          if (index === firstScreenItemIndex -> Signal.get) {
            firstScreenItemIndex -> Signal.set(firstScreenItemIndex -> Signal.get - 1)
          }
        }
      }
      | None => ()
    }
  }

  let moveSelectedDown = () => {
    switch selectedFile -> Signal.get {
      | Some(value) => {
        let index = PlaylistStore.files -> Signal.get -> Array.findIndex((f) => f.id === value.id)

        if (index < PlaylistStore.files -> Signal.get -> Array.length - 1) {
          selectedFileIndex -> Signal.set(index + 1)
          PlaylistStore.moveDown(index)

          if (index === lastScreenItemIndex -> Signal.get) {
            firstScreenItemIndex -> Signal.set(firstScreenItemIndex -> Signal.get + 1)
          }
        }
      }
      | None => ()
    }
  }

  let jumpScreenForward = () => {
    let newIndex = selectedFileIndex -> Signal.get + itemsInViewPort < filteredFiles -> Signal.get -> Array.length
      ? selectedFileIndex -> Signal.get + itemsInViewPort
      : filteredFiles -> Signal.get -> Array.length - 1

    selectedFileIndex -> Signal.set(newIndex)
    selectedFile -> Signal.set(filteredFiles -> Signal.get -> Array.get(newIndex))

    if (itemsInViewPort < filteredFiles -> Signal.get -> Array.length) {
      if (lastScreenItemIndex -> Signal.get + itemsInViewPort > filteredFiles -> Signal.get -> Array.length) {
        firstScreenItemIndex -> Signal.set(filteredFiles -> Signal.get -> Array.length - itemsInViewPort)
      } else {
        firstScreenItemIndex -> Signal.set(firstScreenItemIndex -> Signal.get + itemsInViewPort)
      }
    }
  }

  let jumpScreenBackward = () => {
    let newIndex = selectedFileIndex -> Signal.get - itemsInViewPort >= 0
      ? selectedFileIndex -> Signal.get - itemsInViewPort
      : 0

    let newFile = filteredFiles -> Signal.get -> Array.get(newIndex)

    if newFile -> Option.isSome {
      selectedFileIndex -> Signal.set(newIndex)
      selectedFile -> Signal.set(newFile)

      if (itemsInViewPort < filteredFiles -> Signal.get -> Array.length) {
        if (firstScreenItemIndex -> Signal.get - itemsInViewPort < 0) {
          firstScreenItemIndex -> Signal.set(0)
        } else {
          firstScreenItemIndex -> Signal.set(firstScreenItemIndex -> Signal.get - itemsInViewPort)
        }
      }
    }
  }

  let selectCurrent = () => {
    switch selectedFile -> Signal.get {
      | Some(value) => PlaylistStore.setCurrent(value)
      | None => ()
    }
  }

  let moveCursorUp = () => {
    switch selectedFile -> Signal.get {
      | Some(_) => {
        if (selectedFileIndex -> Signal.get > 0) {
          let newIndex = selectedFileIndex -> Signal.get - 1

          let newFile = filteredFiles -> Signal.get -> Array.get(newIndex)

          switch newFile {
            | Some(fileValue) => {
              selectedFile -> Signal.set(Some(fileValue))
              selectedFileIndex -> Signal.set(newIndex)

              if (firstScreenItemIndex -> Signal.get > newIndex) {
                firstScreenItemIndex -> Signal.set(newIndex)
              }
            }
            | None => ()
          }
        }
      }
      | None => ()
    }
  }

  let moveScreenToEnd = () => {
    if filteredFiles -> Signal.get -> Array.length > 0 {
      Signal.batch(() => {
      selectedFile -> Signal.set(filteredFiles -> Signal.get -> Array.at(-1))
      selectedFileIndex -> Signal.set(filteredFiles -> Signal.get -> Array.length - 1)

        if (filteredFiles -> Signal.get -> Array.length > itemsInViewPort) {
          firstScreenItemIndex -> Signal.set(filteredFiles -> Signal.get -> Array.length - itemsInViewPort)
        }
      })
    }
  }

  let moveScreenToStart = () => {
    if filteredFiles -> Signal.get -> Array.length > 0 {
      firstScreenItemIndex -> Signal.set(0)
      selectedFile -> Signal.set(filteredFiles -> Signal.get -> Array.get(0))
      selectedFileIndex -> Signal.set(0)
    }
  }

  Signal.useEffect(() => {
    let isEmpty = PlaylistStore.files -> Signal.get -> Array.length === 0

    if !isEmpty && fileListWasEmpty.current {
      selectedFile -> Signal.set(PlaylistStore.files -> Signal.get -> Array.get(0))
      selectedFileIndex -> Signal.set(0)
    }

    fileListWasEmpty.current = isEmpty
  })

  Signal.useEffect(() => {
    let files = filteredFiles -> Signal.get

    if (files -> Array.length > 0 && PlaylistStore.currentFile -> Signal.get -> Option.isNone) {
      selectedFile -> Signal.set(files -> Array.get(0))
      selectedFileIndex -> Signal.set(0)
      firstScreenItemIndex -> Signal.set(0)
    }
  })

  React.useEffect0(() => {
    subscribe(Playlist, [
      {
        conditions: [key("KeyJ")],
        callback: (_) => moveCursorDown(),
      },
      {
        conditions: [key("KeyJ", ~keys=[ShiftKey])],
        callback: (_) => moveSelectedDown(),
      },
      {
        conditions: [key("KeyK", ~keys=[ShiftKey])],
        callback: (_) => moveSelectedUp(),
      },
      {
        conditions: [key("KeyF", ~keys=[CtrlKey])],
        callback: (_) => jumpScreenForward(),
      },
      {
        conditions: [key("KeyB", ~keys=[CtrlKey])],
        callback: (_) => jumpScreenBackward(),
      },
      {
        conditions: [key("Enter")],
        callback: (_) => selectCurrent(),
      },
      {
        conditions: [key("KeyI")],
        callback: (_) => selectCurrent(),
      },
      {
        conditions: [key("KeyK")],
        callback: (_) => moveCursorUp(),
      },
      {
        conditions: [key("KeyG", ~keys=[ShiftKey])],
        callback: (_) => moveScreenToEnd(),
      },
      {
        conditions: [key("KeyG")],
        callback: (payload) => {
          if (payload.isRepeated) {
            moveScreenToStart()
          }
        },
      },
      {
        conditions: [key("Slash")],
        callback: (_) => PlaylistFilter.Store.show(),
      },
      {
        conditions: [key("KeyU")],
        callback: (_) => PlaylistFilter.Store.clear(),
      },
      {
        conditions: [key("KeyD")],
        callback: (payload) => {
          if (payload.isRepeated) {
            deleteUnderCursor()
          }
        },
      },
    ])
    ShortcutService.addActive(ShortcutService.Playlist)

    Some(() => {
      ShortcutService.deleteActive(ShortcutService.Playlist)
      ShortcutService.unsubscribe(ShortcutService.Playlist)
    })
  })

  let filter = Signal.useComputed(() => {
    if PlaylistFilter.Store.isShown -> Signal.get {
      <div className="filter-container w-full transition-[width]">
        <BashInput 
          history={PlaylistFilter.Store.history -> Signal.get}
          value={PlaylistFilter.Store.value -> Signal.get}
          onClear={() => PlaylistFilter.Store.clear() }
          setValue={(v) => PlaylistFilter.Store.setValue(v)}
          addToHistory={(v) => PlaylistFilter.Store.addToHistory(v)}
          onHide={() => PlaylistFilter.Store.hide()}
       />
      </div>
    } else {
      PlaylistFilter.Store.value -> Signal.get -> String.length > 0
        ? <div className="filter-container w-content transition-[width] ml-4">
          <Chip value={PlaylistFilter.Store.value -> Signal.get} className="bg-gray-700"/>
        </div>
        : <div className="filter-container w-1 transition-[width]"></div>
    }
  })

  let files = Signal.useComputed(() => {
    let itemList = filteredFiles -> Signal.get -> Array.slice(
      ~start=firstScreenItemIndex -> Signal.get,
      ~end=lastScreenItemIndex -> Signal.get + 1,
    )

    let selectedId = selectedFile -> Signal.get -> Option.mapOr("", (f) => f.id)
    let currentId = PlaylistStore.currentFile -> Signal.get -> Option.mapOr("", (f) => f.id)

    let items = itemList -> Array.map((file) => {
      <PlaylistItem
        key={file.id}
        file={file}
        isCurrent={currentId === file.id}
        isSelected={selectedId === file.id}
    />})

    <div className="p-2 flex flex-col gap-1">
      {React.array(items)}
    </div>
  })

  (
    <div>
      <div className="flex gap-1 flex-col w-full relative">
        {files -> Signal.get}
      </div>

      {filter -> Signal.get}
    </div>
  )
}

