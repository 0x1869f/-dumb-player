%%raw("import './BashInput.css'")

let space = " "

@react.component
let make = (
  ~value: string,
  ~history: array<string>,
  ~setValue: (string) => unit,
  ~onHide: () => unit,
  ~onClear: () => unit,
  ~addToHistory: (string) => unit,
  ~background: string="",
  ) => {
  let bufferRef = React.useRef("")

  let historyPosition: React.ref<Nullable.t<int>> = React.useRef(Nullable.null)
  let inputBeforeHistoryScroll: React.ref<string> = React.useRef(space)

  let inputValue = Signal.useSignal(`${value}${space}`)

  let cursorInitialValue = inputValue -> Signal.get -> String.length > 1 ? inputValue -> Signal.get -> String.length - 1 : 0

  let cursorPosition = Signal.useSignal(cursorInitialValue)

  Signal.useEffect(() => {
    setValue(inputValue -> Signal.get -> String.trim)
  }) -> ignore

  let addChar = (characters: string) => {
    let position = cursorPosition -> Signal.get
    inputValue -> Signal.set(inputValue -> Signal.get -> String.slice(~start=0, ~end=position)
     ++ characters
     ++ inputValue -> Signal.get -> String.slice(~start=position, ~end=inputValue -> Signal.get -> String.length))
  }

  let deleteCharBeforeCursor = () => {
    let position = cursorPosition -> Signal.get

    if (position > 0) {
      inputValue -> Signal.set(inputValue -> Signal.get -> String.slice(~start=0, ~end=position - 1)
        ++ inputValue -> Signal.get -> String.slice(~start=position, ~end=inputValue -> Signal.get -> String.length))
      cursorPosition -> Signal.set(position > 0 ? position - 1 : 0)
    }
  }

  let deleteCharOnCursor = () => {
    if (cursorPosition -> Signal.get < inputValue -> Signal.get -> String.length - 1) {
      let newValue = inputValue -> Signal.get -> String.slice(~start=0, ~end=cursorPosition -> Signal.get)
        ++ inputValue -> Signal.get -> String.slice(~start=cursorPosition -> Signal.get + 1, ~end=inputValue -> Signal.get -> String.length)

      inputValue -> Signal.set(newValue)
    }
  }

  let pasteToCursorPosition = (characters: string) => {
    addChar(characters)

    cursorPosition -> Signal.set(characters -> String.length + cursorPosition -> Signal.get)
  }

  let pasteFromBuffer = () => {
    pasteToCursorPosition(bufferRef.current)
  }

  let cutBeforeCursorPostion = () => {
    bufferRef.current = inputValue -> Signal.get -> String.slice(~start=0, ~end=cursorPosition -> Signal.get)
    let newValue = inputValue -> Signal.get -> String.slice(~start=cursorPosition -> Signal.get, ~end=inputValue -> Signal.get -> String.length)

    inputValue -> Signal.set(newValue)
    cursorPosition -> Signal.set(0)
  }

  let cutFromCursorPostion = () => {
    bufferRef.current = inputValue -> Signal.get -> String.slice(~start=cursorPosition -> Signal.get, ~end=inputValue -> Signal.get -> String.length -1)
    inputValue -> Signal.set(`${inputValue -> Signal.get -> String.slice(~start=0, ~end=cursorPosition -> Signal.get)} `)
  }

  let moveCursorBack = () => {
    let position = cursorPosition -> Signal.get
    cursorPosition -> Signal.set(position > 0 ? position - 1 : 0)
  }

  let jumpForward = () => {
    let cursor = cursorPosition -> Signal.get
    let input = inputValue -> Signal.get

    if input -> String.length > 1 && cursor !== input -> String.length - 1 {

      let spaceWasMet: ref<bool> = ref(false)
      let charWasMet: ref<bool> = ref(false)
      let endPostion: ref<int> = ref(cursor)

      while (!spaceWasMet.contents || !charWasMet.contents) && endPostion.contents < input -> String.length - 1 {
        let currentPositionChar = input -> String.get(endPostion.contents)

        if !charWasMet.contents {
          switch currentPositionChar {
            | Some(value) => if value !== " " {
              charWasMet := true
            }
            | None => ()
          }
        } else {
          switch currentPositionChar {
            | Some(value) => if value === " " {
              spaceWasMet := true
            }
            | None => ()
          }
        }


        if !spaceWasMet.contents {
          endPostion := endPostion.contents + 1
        }
      }

      cursorPosition -> Signal.set(endPostion.contents)
    }
  }

  let jumpBackward = () => {
    let cursor = cursorPosition -> Signal.get
    let input = inputValue -> Signal.get

    if (cursor > 0 || input -> String.length > 1) {
      let spaceWasMet: ref<bool> = ref(false)
      let charWasMet: ref<bool> = ref(false)
      let startPostion: ref<int> = ref(cursor - 1)

      while (!spaceWasMet.contents || !charWasMet.contents) && startPostion.contents > 0 {
        let currentPositionChar = input -> String.get(startPostion.contents)

        if (!charWasMet.contents) {
          switch currentPositionChar {
            | Some(value) => if value !== " " {
              charWasMet := true
            }
            | None => ()
          }
        }
        else {
          switch currentPositionChar {
            | Some(value) => if value === " " {
              spaceWasMet := true
              startPostion := startPostion.contents + 1
            }
            | None => ()
          }
        }

        if (!spaceWasMet.contents && startPostion.contents > 0) {
          startPostion := startPostion.contents -1
        }
      }

      cursorPosition -> Signal.set(startPostion.contents)
    }
  }

  let cutToWordStart = (isRepeted: bool) => {
    let cursor = cursorPosition -> Signal.get
    let input = inputValue -> Signal.get

    if (cursor > 0 || input -> String.length > 0) {
      let spaceWasMet: ref<bool> = ref(false)
      let charWasMet: ref<bool> = ref(false)
      let startPostion: ref<int> = ref(cursor - 1)

      while (!spaceWasMet.contents || !charWasMet.contents) && startPostion.contents !== 0 {
        let currentPositionChar = input -> String.get(startPostion.contents)

        if (!charWasMet.contents) {
          switch currentPositionChar {
            | Some(value) => if (value !== " ") {
              charWasMet := true
            }
            | None => ()
          }
        }
        else {
          switch currentPositionChar {
            | Some(value) => if (value === " ") {
              spaceWasMet := true
              startPostion := startPostion.contents + 1
            }
            | None => ()
          }
        }

        if (!spaceWasMet.contents && startPostion.contents > 0) {
          startPostion := startPostion.contents-1
        }
      }

      let cutValue = input -> String.slice(~start=startPostion.contents, ~end=cursor)

      bufferRef.current = isRepeted
        ? cutValue ++ bufferRef.current
        : cutValue

      let newValue = input -> String.slice(~start=0, ~end=startPostion.contents) ++ input -> String.slice(~start=cursor, ~end=input -> String.length)
      inputValue -> Signal.set(newValue)
      cursorPosition -> Signal.set(startPostion.contents)
    }
  }

  let jumpToTheEnd = () => {
    cursorPosition -> Signal.set(inputValue -> Signal.get -> String.length - 1)
  }

  let jumpToTheStart = () => {
    cursorPosition -> Signal.set(0)
  }

  let moveCursorForward = () => {
    let oldValue = cursorPosition -> Signal.get
    cursorPosition -> Signal.set(oldValue + 1 < inputValue -> Signal.get -> String.length - 1
      ? oldValue + 1
      : inputValue -> Signal.get -> String.length - 1)
  }

  let clearAndClose = () => {
    onClear()
    onHide()
  }

  let saveAndClose = () => {
    let trimedValue = inputValue -> Signal.get -> String.trim

    let historyLast = history -> Array.get(-1)

    switch historyLast {
      | Some(value) => if trimedValue -> String.trim -> String.length > 0 && trimedValue !== value {
        addToHistory(trimedValue)
      }
      | None => ()
    }

    onHide()
  }

  let historyPrev = () => {
    if (history -> Array.length > 0) {
      let newInputValue: ref<string> = ref(space)

      switch historyPosition.current -> Nullable.toOption {
        | Some(value) => if value > 0 {
            historyPosition.current = Nullable.make(value - 1)
            let historyItem = history -> Array.at(value)

            switch historyItem {
              | Some(itemValue) => newInputValue := itemValue
              | None => ()
            }
          }
        | None => {
            historyPosition.current = Nullable.make(history -> Array.length - 1)
            inputBeforeHistoryScroll.current = inputValue -> Signal.get

            let historyItem = history -> Array.at(-1)

            switch historyItem {
              | Some(itemValue) => newInputValue := itemValue ++ space
              | None => ()
            }
          }

        inputValue -> Signal.set(newInputValue.contents)
        cursorPosition -> Signal.set(newInputValue.contents -> String.length - 1)
      }
    }
  }

  let historyNext = () => {
    if (history -> Array.length > 0 || historyPosition.current !== null) {
      let newInputValue: ref<string> = ref(space)

      switch historyPosition.current -> Nullable.toOption {
        | Some(value) => if value < history -> Array.length - 1 {
          historyPosition.current = Nullable.make(value + 1)

          let historyItem = history -> Array.at(value)

          switch historyItem {
            | Some(itemValue) => newInputValue := itemValue ++ space
            | None => ()
          }
        } else {
          newInputValue := inputBeforeHistoryScroll.current
          inputBeforeHistoryScroll.current = space
          historyPosition.current = null
        }
        | None => ()
      }

      inputValue -> Signal.set(newInputValue.contents)
      cursorPosition -> Signal.set(newInputValue.contents -> String.length - 1)
    }
  }

  React.useEffect0(() => {
    ShortcutService.subscribe(ShortcutService.BashInput, [
      {
        conditions: [ShortcutService.key("Enter")],
        callback: (_) => saveAndClose(),
      },
      {
        conditions: [ShortcutService.key("KeyF", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => moveCursorForward(),
      },
      {
        conditions: [ShortcutService.key("ArrowRight")],
        callback: (_) => moveCursorForward(),
      },
      {
        conditions: [ShortcutService.key("ArrowLeft")],
        callback: (_) => moveCursorBack(),
      },
      {
        conditions: [ShortcutService.key("KeyB", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => moveCursorBack(),
      },
      {
        conditions: [ShortcutService.key("ArrowRight", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => jumpForward(),
      },
      {
        conditions: [ShortcutService.key("KeyF", ~keys=[ShortcutService.AltKey])],
        callback: (_) => jumpForward(),
      },
      {
        conditions: [ShortcutService.key("ArrowLeft", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => jumpBackward(),
      },
      {
        conditions: [ShortcutService.key("KeyB", ~keys=[ShortcutService.AltKey])],
        callback: (_) => jumpBackward(),
      },
      {
        conditions: [ShortcutService.key("KeyC", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => clearAndClose(),
      },
      {
        conditions: [ShortcutService.key("Escape")],
        callback: (_) => clearAndClose(),
      },
      {
        conditions: [ShortcutService.key("KeyW", ~keys=[ShortcutService.CtrlKey])],
        callback: (payload) => {
          cutToWordStart(payload.isRepeated)
        },
      },
      {
        conditions: [ShortcutService.key("KeyY", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => pasteFromBuffer(),
      },
      {
        conditions: [ShortcutService.key("KeyK", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => cutFromCursorPostion(),
      },
      {
        conditions: [ShortcutService.key("KeyA", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => jumpToTheStart(),
      },
      {
        conditions: [ShortcutService.key("Delete")],
        callback: (_) => deleteCharOnCursor(),
      },
      {
        conditions: [ShortcutService.key("KeyD", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => deleteCharOnCursor(),
      },
      {
        conditions: [ShortcutService.key("Backspace")],
        callback: (_) => deleteCharBeforeCursor(),
      },
      {
        conditions: [ShortcutService.key("KeyH", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => deleteCharBeforeCursor(),
      },
      {
        conditions: [ShortcutService.key("KeyE", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => jumpToTheEnd(),
      },
      {
        conditions: [ShortcutService.key("KeyU", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => cutBeforeCursorPostion(),
      },
      {
        conditions: [ShortcutService.key("KeyP", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => historyPrev(),
      },
      {
        conditions: [ShortcutService.key("KeyN", ~keys=[ShortcutService.CtrlKey])],
        callback: (_) => historyNext(),
      },
      {
        conditions: [
          ShortcutService.regex(RegExp.fromString("/Digit|Key|Space|Equal|Minus|Period|Comma/u")),
          ShortcutService.regex(RegExp.fromString("/Digit|Key|Equal|Minus/u"))
        ],
        callback: (payload) => {
          pasteToCursorPosition(payload.event.key)
        },
      },
    ])
    ShortcutService.backupActiveSubs()
    ShortcutService.addActive(ShortcutService.BashInput)

    Some(() => {
      ShortcutService.unsubscribe(ShortcutService.BashInput)
      ShortcutService.recoverActiveSubs()
    })
  }) 

  let bashInput = Signal.useComputed(() => {
    let containerStyle = `bash-input w-full flex items-center search-input
      pl-2 ma-0 h-10 max-w-full bg-gray-700 border-0 text-lg font-medium text-white`

    let result = []


    for index in 0 to inputValue -> Signal.get -> String.length - 1 {
    let elementStyle = `flex items-center justify-center h-6 w-3 ${index === cursorPosition -> Signal.get ? "bg-green-500" : "bg-transparent "}`

      let char = inputValue -> Signal.get -> String.get(index)
      switch char {
        | Some(value) => result -> Array.push(
          <div key={index -> Int.toString} className={elementStyle}>{React.string(value)}</div>
        )
        | None => ()
      }
    }

    <div className={containerStyle}>
      {React.array(result)}
    </div>
  })

  bashInput -> Signal.get
}
