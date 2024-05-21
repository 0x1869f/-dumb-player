module Fs = {
  module Dirent = {
    type t = {
      name: string,
      path: string,
    }
    @send external isBlockDevice: t => bool = "isBlockDevice"
    @send external isCharacterDevice: t => bool = "isCharacterDevice"
    @send external isDirectory: t => bool = "isDirectory"
    @send external isFIFO: t => bool = "isFIFO"
    @send external isFile: t => bool = "isFile"
    @send external isSocket: t => bool = "isSocket"
    @send external isSymbolicLink: t => bool = "isSymbolicLink"
  }

  type options = {
    withFileTypes: bool,
    recursive?: bool,
  }

  @module("node:fs") @scope("promises")
  external readdirWithOptions: (string, options) => promise<array<Dirent.t>> = "readdir"
}
