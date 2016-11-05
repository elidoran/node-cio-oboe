buildOboe = require 'oboe'

# return `oboe.drop` by default
autoDrop = (fn) -> (args...) -> fn.apply(this, args) ? buildOboe.drop

module.exports = ->

  # if they didn't specify `oboe` in the options, then don't do anything.
  # Note, it can be boolean or an object, so, test both existence isnt `false`
  unless @oboe? and @oboe isnt false then return

  # whether client or server client...
  socket = @client ? @connection

  # create oboe and store it on the socket
  oboe = socket.oboe = buildOboe socket

  # setup default event handling
  oboe.on 'fail', (error) ->
    error = error:'oboe parse fail', reason:error.thrown ? error
    socket.destroy error

  # emit 'oboe' event to allow them to do their own initial work.
  # they don't have the socket yet, so, let's do this in the future
  process.nextTick -> socket.emit 'oboe', oboe, socket

  # alias
  options = @oboe

  # # Apply user config to oboe instance

  # if they specified a function as the options then it's a 'root' function
  # or, if they specified a `root` key
  root =
    if typeof options is 'function' then options
    else if typeof options.root is 'function' then options.root

  # if we figured out a `root` function, add it to oboe with autoDrop
  if root? then oboe.on 'node', { '!' : autoDrop root }

  # if they specify some top level properties (labels)
  if options.top?
    # build up all `node` patterns into one object to add.
    node = {}

    # prefix each 'top' `label` with '!.' for oboe
    node['!.' + label] = autoDrop fn for label,fn of options.top

    # add results to oboe
    oboe.on 'node', node

  # if any standard oboe props are specified then add them
  for name in [ 'node', 'path', 'done', 'fail' ]
    if options[name]? then oboe.on name, options[name]

  return
