import { ipcRenderer, contextBridge } from 'electron'

// --------- Expose some API to the Renderer process ---------
contextBridge.exposeInMainWorld('ipcRenderer', {
  on(...args) {
    const [channel, listener] = args
    return ipcRenderer.on(channel, (event, ...args) => listener(event, ...args))
  },
  off(...args) {
    const [channel, ...omit] = args
    return ipcRenderer.off(channel, ...omit)
  },
  send(...args) {
    const [channel, ...omit] = args
    return ipcRenderer.send(channel, ...omit)
  },
  invoke(...args) {
    const [channel, ...omit] = args
    return ipcRenderer.invoke(channel, ...omit)
  },

  // You can expose other APTs you need here.
  // ...
})

// --------- Preload scripts loading ---------
function domReady(condition = ['complete', 'interactive']) {
  return new Promise(resolve => {
    if (condition.includes(document.readyState)) {
      resolve(true)
    } else {
      document.addEventListener('readystatechange', () => {
        if (condition.includes(document.readyState)) {
          resolve(true)
        }
      })
    }
  })
}

const safeDOM = {
  append(parent, child) {
    if (!Array.from(parent.children).find(e => e === child)) {
      return parent.appendChild(child)
    }
  },
  remove(parent, child) {
    if (Array.from(parent.children).find(e => e === child)) {
      return parent.removeChild(child)
    }
  },
}

contextBridge.exposeInMainWorld('electron', {
  listFiles: async(path) => ipcRenderer.invoke('list-files', path),
  parseFileMeta: async(path) => ipcRenderer.invoke('get-file-metadata', path),
  readFile: async(path) => ipcRenderer.invoke('read-file', path),
  readAudioFile: async(path) => ipcRenderer.invoke('read-audio-file', path),
  loadPreferences: async() => ipcRenderer.invoke('load-preferences'),
  createCacheDir: async() => ipcRenderer.invoke('create-cache-dir'),
  getCover: async(path) => ipcRenderer.invoke('get-cover', path),
  getHomedir: () => ipcRenderer.invoke('get-homedir'),
  extractFilesFromDirectories: (files) => ipcRenderer.invoke('extract-files-from-directories', files),
  notifyNextTrack: (path) => ipcRenderer.invoke('notify-next-track', path),
  onPauseOrPlay: (callback) => ipcRenderer.on('pause-or-play', (_event) => {
    callback()
  }),
  onIncreaseVolume: (callback) => ipcRenderer.on('increase-volume', (_event) => {
    callback()
  }),
  onDecreaseVolume: (callback) => ipcRenderer.on('decrease-volume', (_event) => {
    callback()
  }),
  onPlayNext: (callback) => ipcRenderer.on('play-next', (_event) => {
    callback()
  }),
  onPlayPrevious: (callback) => ipcRenderer.on('play-previous', (_event) => {
    callback()
  }),
  onSwitchMute: (callback) => ipcRenderer.on('switch-mute', (_event) => {
    callback()
  }),
  savePreferences: (preferences) => ipcRenderer.invoke('save-preferences', preferences),
})

