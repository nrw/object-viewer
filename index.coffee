inherits = require 'inherits'
patcher = require 'patcher'
cloneDeep = require 'lodash.clonedeep'
through = require 'through2'

{EventEmitter2} = require 'eventemitter2'

Viewer = (base = {}, patch = {}) ->
  return new Viewer base, patch unless this instanceof Viewer

  EventEmitter2.call this

  @base = base
  @patched = cloneDeep(base)
  @patch = {}

  patcher.applyPatch @patched, patch
  updatePatch this

  process.nextTick =>
    @emit 'base'
    @emit 'patch'

inherits Viewer, EventEmitter2

Viewer::read = (path...) ->
  opts = extractOpts path
  base = @[opts.view]
  stream = through.obj()

  process.nextTick ->
    for step in path
      stream.write {key, value} for key, value of base[step]
    stream.end()

  stream

Viewer::get = (args...) ->
  opts = extractOpts args

  obj = @patched
  obj = obj?[step] or undefined for step in args
  obj

Viewer::set = (path..., key, value) ->
  # make change
  base = @patched
  base = base[path.shift()] while base[path[0]]

  while step = path.shift()
    base[step] = {}
    base = base[step]
  base[key] = value

  # update cached patch
  updatePatch this

  # notify
  @emit 'change'
  this

Viewer::setBase = (base = {}) ->
  @base = base
  @patched = cloneDeep @base
  patcher.applyPatch @patched, @patch
  updatePatch this
  @emit 'base'

Viewer::applyPatch = (patch = {}) ->
  patcher.applyPatch @patched, patch
  updatePatch this
  @emit 'patch'

Viewer::readStream = Viewer::read
Viewer::createReadStream = Viewer::read

updatePatch = (obj) ->
  obj.patch = patcher.computePatch(obj.base, obj.patched) or {}

extractOpts = (args) ->
  opts = args[args.length-1] or {}

  if typeof opts is 'string'
    opts = {}
  else
    args.pop()

  # defaults
  opts.view or= 'patched'

  opts

module.exports = Viewer
