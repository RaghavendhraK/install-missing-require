exec = require('child_process').exec

recursiveFileList = require './util/file_list'

fs = require 'fs'
Q = require 'q'
async = require 'async'
_ = require 'underscore'
Table = require 'cli-table2'
colors = require 'cli-color'

args = process.argv
srcDir = args[2]

acceptedExts = ['.coffee']
excludeDirs = ['node_modules']
table = new Table({
  head: ['Module', 'Results']
  style: {'padding-left': 0, 'padding-right': 0}
})

processLine = (line)->
  line = line.trim()
  #empty line
  return null if line.length is 0
  #comments
  return null if line[0] is '#'
  #no require function
  return null unless line.match(/require[ (]/)?

  matched = line.match(/["'](.*?)["']/)
  return null unless matched?

  module = matched[1]
  #non nodejs modules required in this project
  return module if module in ['q', 'underscore', 'cli-table2', 'async', 'cli-color']
  #discard the local modules
  return null if module.search('/') isnt -1

  try
    #discard node js modules
    require module
    return null
  catch e
    return module if e.code is 'MODULE_NOT_FOUND'
    console.log e
    throw e
  
getRequireModules = (file)->
  defered = Q.defer()

  fs.readFile file, 'utf-8', (e, data)->
    defered.reject(e) if e?

    lines = data.split('\n')

    modules = (processLine(line) for line in lines)

    modules = modules.filter (module)->
      return (module isnt null)
      
    defered.resolve(modules)

  return defered.promise

installModules = (modules)->
  defered = Q.defer()

  async.eachSeries modules, installModule, (e)->
    return defered.reject(e) if e?

    return defered.resolve()

  return defered.promise

installModule = (module, cb)->
  console.log "Installing #{module}"
  options = {cwd: srcDir}
  child = exec("npm install #{module} --save", options, (e, stdout, stderr)->
    if e?
      table.push [module, colors.red(e)]
    else if stderr?
      table.push [module, colors.red(stderr)]
    else
      table.push [module, stdout]
  
    return cb()
  )

return recursiveFileList(srcDir, {
  extensions: acceptedExts
  excludeDirs: excludeDirs
}).then((files)->
  Q.all(
    requireModules = (getRequireModules(file) for file in files)
  )
).then((modules)->
  modules = _.flatten modules
  modules = _.unique modules
  console.log 'These modules are found and will be installed: ' + modules.join(', ')
  installModules(modules)
).then(->
  console.log table.toString()
).fail((e)->
  console.log e
)