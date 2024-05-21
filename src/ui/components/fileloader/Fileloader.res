open ShortcutService

type lastNodeInfo = {
  lastNode: FileloaderFile.file,
  firstScreenIndex: option<int>,
}

let itemsHeight = 64

@react.component
let make = (
  ~initailPath: string,
  ~onFileSelect: array<FileloaderFile.file> => unit,
  ~onExit: () => unit,
) => {
  Signal.track()

  let nodes = Signal.useSignal([])
  let previewNodes = Signal.useSignal([])
  let isPreviewLoading = Signal.useSignal(false)
  let (currentDirImages, generateNodeImageUrls, _) = FileloaderImage.useImageUrl()
  let currentDir = Signal.useSignal(initailPath)
  let isLoading = Signal.useSignal(false)
  let parentDir = Signal.useSignal(initailPath)
  let currentNode = Signal.useSignal(None)
  let currentNodeIndex = Signal.useSignal(0)
  let firstScreenItemIndex = Signal.useSignal(0)
  let selectedNodes: Signal.t<Dict.t<FileloaderFile.file>> = Signal.useSignal(Dict.make())

  let dirLastNode: Map.t<string, lastNodeInfo> = Map.make()


  let itemsInViewPort = Math.floor(Window.VisualViewport.height / itemsHeight :> float) -> Int.fromFloat

  let filterNodes = (node: FileloaderFile.file, filter: string): bool => {
    switch node {
      | FileloaderFile.Directory(dir) => dir.name -> String.toLowerCase -> String.includes(filter -> String.toLowerCase)
      | FileloaderFile.AudioFile(file) => {
        let matched = ref(false)

        switch file.metaInfo.title {
          | Some(value) => matched := value -> String.toLowerCase -> String.includes(filter -> String.toLowerCase)
          | None => ()
        }

        if (matched.contents) {
          switch file.metaInfo.artist {
            | Some(value) => matched := value -> String.toLowerCase -> String.includes(filter -> String.toLowerCase)
            | None => ()
          }
        }

        matched.contents
      }
    }
  }

  let filteredNodes = Signal.useComputed(
    () => {
    FileLoaderFilter.Store.value -> Signal.get -> String.length > 0
      ? nodes -> Signal.get -> Array.filter((node) => filterNodes(node, FileLoaderFilter.Store.value -> Signal.get))
      : nodes -> Signal.get}
  )

  let selectFiles = () => {
    let files = selectedNodes -> Signal.get -> Dict.valuesToArray

    if (files -> Array.length > 0) {
      FileLoaderFilter.Store.clear()
      onFileSelect(files)
    }
  }

  let lastScreenItemIndex = Signal.useComputed(
    () => firstScreenItemIndex -> Signal.get + itemsInViewPort < filteredNodes -> Signal.get -> Array.length - 1
      ? firstScreenItemIndex -> Signal.get + itemsInViewPort
      : filteredNodes -> Signal.get -> Array.length - 1,
  )

  let moveDown = () => {
    switch currentNode -> Signal.get {
      | Some(_) => {
        if (currentNodeIndex -> Signal.get < filteredNodes -> Signal.get -> Array.length - 1) {
          let newIndex = currentNodeIndex -> Signal.get + 1

          currentNodeIndex -> Signal.set(newIndex)

          if (newIndex > lastScreenItemIndex -> Signal.get) {
            firstScreenItemIndex -> Signal.set(firstScreenItemIndex -> Signal.get + 1)
          }

          let next = filteredNodes -> Signal.get -> Array.get(newIndex)

          switch next {
            | Some(node) => currentNode -> Signal.set(Some(node))
            | None => ()
          }
        }
      }
      | None => ()
    }
  }

  let selectNode = () => {
    switch currentNode -> Signal.get {
      | Some(node) => {
        switch node {
          | FileloaderFile.Directory(dir) => {
            selectedNodes -> Signal.get -> Dict.keysToArray -> Array.forEach((keyValue) => {
              if keyValue -> String.includes(dir.fullPath) {
                selectedNodes -> Signal.get -> Dict.delete(keyValue)
              }
            })

            selectedNodes -> Signal.get -> Dict.set(dir.fullPath, node)
          }
          | FileloaderFile.AudioFile(file) => selectedNodes -> Signal.get -> Dict.set(file.fullPath, node)
        }
      }
      | None => ()
    } 
  }

  let loadPreviewDir = async (directory: FileloaderFile.directory) => {
    isPreviewLoading -> Signal.set(true)

    try {
      let result = await Electron.listFiles(directory.fullPath)
      previewNodes -> Signal.set(result)
    } catch {
      | err => Console.error(err)
    }
    isPreviewLoading -> Signal.set(false)
  }

  Signal.useEffect(() => {
    switch currentNode -> Signal.get {
    | Some(FileloaderFile.Directory(value)) => {
      loadPreviewDir(value) -> ignore
    }
    | None | Some(_) => ()
    }
  }) -> ignore

let loadCurrentDir = async (directory: string) => {
  isLoading -> Signal.set(true)

    let result = await Electron.listFiles(directory)
    nodes -> Signal.set(result)
    result -> generateNodeImageUrls
    isLoading -> Signal.set(false)
  }

  let openDirectory = () => {
    switch currentNode -> Signal.get {
      | Some(FileloaderFile.Directory(dir)) => {
        if selectedNodes -> Signal.get -> Dict.get(dir.fullPath) -> Option.isNone {
          dirLastNode -> Map.set(currentDir -> Signal.get, {
            lastNode: FileloaderFile.Directory(dir),
            firstScreenIndex: FileLoaderFilter.Store.value -> Signal.get -> String.length > 0
              ? None
              : Some(firstScreenItemIndex -> Signal.get)
          })

          FileLoaderFilter.Store.clear()
          nodes -> Signal.set(previewNodes -> Signal.get)
          previewNodes -> Signal.get -> generateNodeImageUrls
          currentDir -> Signal.set(dir.fullPath)
          parentDir -> Signal.set(dir.parentDir)
        }
      }
      | None | Some(_) => ()
    }
  }

  let goBack = () => {
    dirLastNode -> Map.delete(currentDir -> Signal.get) -> ignore

    currentDir -> Signal.set(parentDir -> Signal.get)
    parentDir -> Signal.set(
      parentDir
      -> Signal.get
      -> String.split("/")
      -> Array.slice(~start=0, ~end=-1)
      -> Array.join("/")
    )

    FileLoaderFilter.Store.clear()
    loadCurrentDir(parentDir -> Signal.get)
  }

  let moveUp = () => {
    switch currentNode -> Signal.get {
      | Some(_) => {
        if currentNodeIndex -> Signal.get > 0 {
          let newIndex = currentNodeIndex -> Signal.get - 1

          let next = filteredNodes -> Signal.get -> Array.get(newIndex)

          if next -> Option.isSome {
            currentNode -> Signal.set(next)
            currentNodeIndex -> Signal.set(newIndex)
          }

          if (firstScreenItemIndex -> Signal.get > newIndex) {
            firstScreenItemIndex -> Signal.set(newIndex)
          }
        }
      }
      | None => ()
    }
  }

  let moveToStart = () => {
    if (filteredNodes -> Signal.get -> Array.length > 0) {
      let lastIndex = filteredNodes -> Signal.get -> Array.length - 1

      let newNode = filteredNodes -> Signal.get -> Array.get(lastIndex)
      if newNode -> Option.isSome {
        currentNodeIndex -> Signal.set(lastIndex)
        currentNode -> Signal.set(newNode)
        firstScreenItemIndex -> Signal.set(filteredNodes -> Signal.get -> Array.length - itemsInViewPort)
      }
    }
  }

  let moveToEnd = () => {
    if (filteredNodes -> Signal.get -> Array.length > 0) {
      let newNode = filteredNodes -> Signal.get -> Array.get(0)

      if newNode -> Option.isSome {
        currentNode -> Signal.set(newNode)
        currentNodeIndex -> Signal.set(0)
        firstScreenItemIndex -> Signal.set(0)
      }
    }
  }

  let openNextScreen = () => {
    let newIndex = currentNodeIndex -> Signal.get + itemsInViewPort < filteredNodes -> Signal.get -> Array.length
      ? currentNodeIndex -> Signal.get + itemsInViewPort
      : filteredNodes -> Signal.get -> Array.length - 1

    currentNodeIndex -> Signal.set(newIndex)
    currentNode -> Signal.set(filteredNodes -> Signal.get -> Array.get(newIndex))

    if (lastScreenItemIndex -> Signal.get + itemsInViewPort > filteredNodes -> Signal.get -> Array.length) {
      firstScreenItemIndex -> Signal.set(filteredNodes -> Signal.get -> Array.length - itemsInViewPort)
    } else {
      firstScreenItemIndex -> Signal.set(firstScreenItemIndex -> Signal.get + itemsInViewPort)
    }
  }

  let openPreviousScreen = () => {
    let newIndex = currentNodeIndex -> Signal.get - itemsInViewPort >= 0
      ? currentNodeIndex -> Signal.get - itemsInViewPort
      : 0

    currentNodeIndex -> Signal.set(newIndex)
    currentNode -> Signal.set(filteredNodes -> Signal.get -> Array.get(newIndex))

    let screenIndex = firstScreenItemIndex -> Signal.get - itemsInViewPort < 0
      ? 0
      : firstScreenItemIndex -> Signal.get - itemsInViewPort

    firstScreenItemIndex -> Signal.set(screenIndex)
  }

  let clearAndExit = () => {
    FileLoaderFilter.Store.clear()
    onExit()
  }

  let screenNodes = Signal.useComputed(
    () => filteredNodes -> Signal.get
    -> Array.slice(~start=firstScreenItemIndex -> Signal.get, ~end=lastScreenItemIndex -> Signal.get + 1)
  )

  let preview = Signal.useComputed(() => {
    switch currentNode -> Signal.get {
      | Some(FileloaderFile.Directory(value)) => 
        <DirPreview
          key={value.id}
          isLoading={isPreviewLoading}
          dirFiles={previewNodes}
        />
      | Some(FileloaderFile.AudioFile(value)) => 
        <Preview
          key={value.id}
          file={value}
          imageUrl={currentDirImages -> Signal.get -> Dict.get(value.id)}
        />
      | None => <div />
    }
  })

  let nodeComponents = Signal.useComputed(() => {
    switch currentNode -> Signal.get {
      | Some(currentNodeValue) => {
        let currentNodeId = switch currentNodeValue {
          | FileloaderFile.AudioFile(value) => value.id
          | FileloaderFile.Directory(value) => value.id
        }

        screenNodes -> Signal.get -> Array.map((node) => {
          let (id, fullPath) = switch node {
            | FileloaderFile.Directory(value) => (value.id, value.fullPath)
            | FileloaderFile.AudioFile(value) => (value.id, value.fullPath)
          }

          let isSelected = selectedNodes -> Signal.get -> Dict.get(fullPath) -> Option.isSome
          let isCurrent = id === currentNodeId

          <LoaderListItem
            file={node}
            isSelected={isSelected}
            isCurrent={isCurrent}
            key={id}
            imageUrl={currentDirImages -> Signal.get -> Dict.get(id)}
          />
      })
    }
    | None => []
    }
  })

  let component = Signal.useComputed(() => isLoading -> Signal.get
    ? <Loader />
    : React.array(nodeComponents -> Signal.get)
  )

  Signal.useEffect(() => {
    let nodes = filteredNodes -> Signal.get
    if (nodes -> Array.length > 0) {
      let ( lastNode, firstScreenIndex) = switch dirLastNode -> Map.get(currentDir -> Signal.get) {
        | Some(value) => (Some(value.lastNode), value.firstScreenIndex)
        | None => (None, None)
      }

      dirLastNode -> Map.delete(currentDir -> Signal.get) -> ignore

      switch lastNode {
        | Some(node) => {
          let lastNodeIndex = nodes -> Array.findIndexOpt((item) => {
            let id = switch item {
              | FileloaderFile.AudioFile(value) => value.id
              | FileloaderFile.Directory(value) => value.id
            }

            let nodeId = switch node {
              | FileloaderFile.AudioFile(value) => value.id
              | FileloaderFile.Directory(value) => value.id
            }

            nodeId === id
          })

          // if lastNodeIndex > -1 {
          //   setCurrentNode(_ => lastNode)
          //   setCurrentNodeIndex(_ => lastNodeIndex)
          //
          //   let firstIndex = switch firstScreenIndex {
          //     | Some(value) => value
          //     | None => lastNodeIndex
          //   }
          //
          //   setFirstScreenItemIndex(_ => firstIndex)
          // }

          switch lastNodeIndex {
            | Some(index) => {
              currentNode -> Signal.set(lastNode)
              currentNodeIndex -> Signal.set(index)

              let firstIndex = switch firstScreenIndex {
                | Some(value) => value
                | None => index
              }

              firstScreenItemIndex -> Signal.set(firstIndex)
            }
            | None => ()
          }
        }
        | None => {
          currentNodeIndex -> Signal.set(0)
          currentNode -> Signal.set(nodes -> Array.get(0))
          firstScreenItemIndex -> Signal.set(0)
        }
      } 
    } else {
      currentNode -> Signal.set(None)
    }
  }) -> ignore

  React.useEffect0(() => {
    loadCurrentDir(initailPath) -> ignore

    None
  })

  React.useEffect0(() => {
    subscribe(FileLoader, [
      {
        conditions: [key("KeyK"), key("ArrowUp"),
        ],
        callback: (_) => moveUp(),
      },
      {
        conditions: [key("KeyJ"), key("ArrowDown")],
        callback: (_) => moveDown(),
      },
      {
        conditions: [key("KeyH"), key("ArrowLeft")],
        callback: (_) => goBack() -> ignore,
      },
      {
        conditions: [key("KeyL"), key("ArrowRight")],
        callback: (_) => openDirectory(),
      },
      {
        conditions: [key("KeyI"), key("Space")],
        callback: (_) => selectNode(),
      },
      {
        conditions: [key("KeyQ")],
        callback: (_) => clearAndExit(),
      },
      {
        conditions: [key("KeyU")],
        callback: (_) => FileLoaderFilter.Store.clear(),
      },
      {
        conditions: [key("Escape")],
        callback: (_) => onExit(),
      },
      {
        conditions: [key("Enter")],
        callback: (_) => selectFiles(),
      },
      {
        conditions: [key("KeyO")],
        callback: (_) => selectFiles(),
      },
      {
        conditions: [key("KeyB", ~keys=[CtrlKey])],
        callback: (_) => openPreviousScreen(),
      },
      {
        conditions: [key("KeyG", ~keys=[ShiftKey])],
        callback: (_) => moveToStart(),
      },
      {
        conditions: [key("KeyG")],
        callback: (payload) => {
          if (payload.isRepeated) {
            moveToEnd()
          }
        },
      },
      {
        conditions: [key("Slash")],
        callback: (_) => FileLoaderFilter.Store.show(),
      },
      {
        conditions: [key("KeyF", ~keys=[CtrlKey])],
        callback: (_) => openNextScreen(),
      },
    ])

    addActive(FileLoader)

    Some(() => {
      deleteActive(FileLoader)
      unsubscribe(FileLoader)
    })
  })

  let filter = Signal.useComputed(() => {
    if FileLoaderFilter.Store.isShown -> Signal.get {
      <div className="filter-container w-full transition-[width]">
        <BashInput 
          history={FileLoaderFilter.Store.history -> Signal.get}
          value={FileLoaderFilter.Store.value -> Signal.get}
          onClear={() => FileLoaderFilter.Store.clear() }
          setValue={(v) => FileLoaderFilter.Store.setValue(v)}
          addToHistory={(v) => FileLoaderFilter.Store.addToHistory(v)}
          onHide={() => FileLoaderFilter.Store.hide()}
       />
      </div>
    } else {
      FileLoaderFilter.Store.value -> Signal.get -> String.length > 0
        ? <div className="filter-container w-content transition-[width] ml-4">
          <Chip value={FileLoaderFilter.Store.value -> Signal.get} className="bg-gray-700"/>
        </div>
        : <div className="filter-container w-1 transition-[width]"></div>
    }
  })

  (
    <div className="h-screen relative">
      <div className="flex p-2 gap-2">
        <div className="flex gap-1 flex-col w-1/2">
          {component -> Signal.get}
        </div>
        <div className="w-1/2">
          {preview -> Signal.get}
        </div>
      </div>

      {filter -> Signal.get}
    </div>
  )
}

