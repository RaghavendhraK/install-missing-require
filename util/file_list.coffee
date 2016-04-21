Q = require 'q'
fs = require 'fs'
path = require 'path'

fileList = (dirs, options={})->
  dirs = [dirs] unless dirs instanceof Array

  readdirCalls = []
  for dir in dirs
    continue if options.exludeDirs? and (path.basename(dir) in options.exludeDirs?)
    readdirCalls.push readdir(dir)

  return Q.all(readdirCalls).then((contents)->
    statCalls = []
    for idx in [0..dirs.length-1]
      for file in contents[idx]
        statCalls.push stat(path.join(dirs[idx], file))
    return Q.all(statCalls)
  ).then((stats)->
    files = []
    subDirs = []

    for fileStat in stats
      if fileStat.isDir
        subDirs.push fileStat.file

      else
        extn = path.extname(fileStat.file)
        if not(options.extensions?) or extn in options.extensions          
          files.push fileStat.file
          
    if subDirs.length > 0
      return fileList(subDirs, options).then((list)->
        for file in list
          files.push file
        return files
      )

    return files
  )

readdir = (dir)->
  defered = Q.defer()

  fs.readdir(dir, (e, files)->
    return defered.reject e if e?
    defered.resolve files
  )

  return defered.promise

stat = (file)->
  defered = Q.defer()

  fs.stat file, (e, stat)->
    return defered.reject e if e?
    defered.resolve {file: file, isDir: stat.isDirectory()}

  return defered.promise

module.exports = fileList