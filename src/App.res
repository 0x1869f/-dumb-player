%%raw("import './App.css'")

open ShortcutService

@module("./ui/hooks/useBeforeunload") external useBeforeunload: (unit => unit) => unit = "useBeforeunload"

@react.component
let make = () => {
  Signal.track()

  useBeforeunload(() => {
    Electron.savePreferences({
      isRandom: PlaylistStore.isRandom -> Signal.get,
      isMuted: VolumeStore.isMuted -> Signal.get,
      volume: VolumeStore.volume -> Signal.get,
      playlist: PlaylistStore.files -> Signal.get,
    }) -> ignore
  })

  let initialPath = Signal.useSignal("")
  let isFileLoaderOpened = Signal.useSignal(false)

  let addToPlaylist = async (files: array<FileloaderFile.file>) => {
    let audioFiles = await Electron.extractFilesFromDirectories(files)
    PlaylistStore.setFiles(audioFiles)
    isFileLoaderOpened -> Signal.set(false)
  }

  let playlist = Signal.useComputed(() => 
    isFileLoaderOpened -> Signal.get
      ? <Fileloader
        onExit={() => isFileLoaderOpened -> Signal.set(false)}
        onFileSelect={(files) => addToPlaylist(files) -> ignore}
        initailPath={initialPath -> Signal.get}
      />
      : <Playlist />
  )

  React.useEffect0(() => {
    init()
    subscribe(App, [
      {
        callback: (_) => isFileLoaderOpened -> Signal.set(true),
        conditions: [
          key("KeyO", ~keys=[ShiftKey])
        ],
      }
    ])
    addActive(App)

    Electron.loadPreferences() -> Promise.then((prefs: FileRepository.preferences) => {
      PlaylistStore.setIsRandom(prefs.isRandom)
      PlaylistStore.setFiles(prefs.playlist)
      VolumeStore.setVolume(prefs.volume)
      VolumeStore.setIsMuted(prefs.isMuted)

       Promise.resolve()
    }) -> ignore

    Electron.getHomedir() -> Promise.then((value) => {
      initialPath -> Signal.set(value)
      Promise.resolve()
    }) -> ignore
    
    Some(() => unsubscribe(App))
  })


  <div className="p-6 w-full h-8">
    {playlist -> Signal.get}

    <div className="absolute w-full bottom-0 left-0">
      <Player />
    </div>
  </div>
}
