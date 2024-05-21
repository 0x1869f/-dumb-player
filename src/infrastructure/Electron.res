@val @scope(("window", "electron"))
external listFiles: (string) => promise<array<FileloaderFile.file>> = "listFiles"

@val @scope(("window", "electron"))
external parseFileMeta: (string) => promise<Audio.metaInfo> = "parseMeta"

@val @scope(("window", "electron"))
external readFile: (string) => promise<ArrayBuffer.t> = "parseFile"

@val @scope(("window", "electron"))
external readAudioFile: (string) => promise<Int8Array.t> = "readAudioFile"

@val @scope(("window", "electron"))
external savePreferences: (FileRepository.preferences) => promise<unit> = "savePreferences"

@val @scope(("window", "electron"))
external loadPreferences: () => promise<FileRepository.preferences> = "loadPreferences"

@val @scope(("window", "electron"))
external createCacheDir: () => promise<unit> = "createCacheDir"

@val @scope(("window", "electron"))
external getCover: (string) => promise<option<ArrayBuffer.t>> = "getCover"

@val @scope(("window", "electron"))
external extractFilesFromDirectories: (array<FileloaderFile.file>) => promise<array<Audio.audioFile>> = "extractFilesFromDirectories"

@val @scope(("window", "electron"))
external notifyNextTrack: (string) => unit = "notifyNextTrack"

@val @scope(("window", "electron"))
external onPauseOrPlay: (() => unit) => unit = "onPauseOrPlay"

@val @scope(("window", "electron"))
external onIncreaseVolume: (() => unit) => unit = "onIncreaseVolume"

@val @scope(("window", "electron"))
external onDecreaseVolume: (() => unit) => unit = "onDecreaseVolume"

@val @scope(("window", "electron"))
external onPlayNext: (() => unit) => unit = "onPlayNext"

@val @scope(("window", "electron"))
external onPlayPrevious: (() => unit) => unit = "onPlayPrevious"

@val @scope(("window", "electron"))
external onSwitchMute: (() => unit) => unit = "onSwitchMute"

@val @scope(("window", "electron"))
external savePlaylist: ( array<Audio.audioFile>) => promise<unit> = "savePlaylist"

@val @scope(("window", "electron"))
external getHomedir: () => promise<string> = "getHomedir"

