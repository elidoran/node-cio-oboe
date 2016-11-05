assert   = require 'assert'
corepath = require 'path'
buildCio = require 'cio'
buildOboe = require 'oboe'
listener = require '../../lib'

# oboe lib
lib = corepath.resolve __dirname, '..', '..', 'lib'

describe 'test oboe', ->

  describe 'with fake socket', ->

    # pass a fake socket to the listener
    fakeSocket =
      events: {}
      emits: {}
      pipe: (stream) ->
        stream.pipedFrom = this
        return stream
      on: (event, listener) ->
        if @events[event]?
          @events[event] = [ @events[event] ]
          @events[event].push listener
        else
          @events[event] = listener
      emit: (event, args...) ->
        @emits[event] = args

    context =
      isSecure: false
      client  : fakeSocket
      oboe    : true

    # call the listener as if a new socket connection has been made
    listener.call context

    before 'wait for oboe event', (done) -> setTimeout done, 10

    it 'should call plugin to create the oboe and attach to the socket', ->
      assert fakeSocket.oboe

    it 'should emit the \'oboe\' event', ->
      assert.deepEqual fakeSocket.emits.oboe[0], fakeSocket.oboe


  describe 'with client and server', ->

    describe.only 'with defaults', ->

      cio = buildCio()

      cio.onServerClient listener

      # remember these for assertions
      client = null
      server = null
      listening = false
      connected = false
      closed = false
      oboed = {}
      roots = []
      headers = []
      nodes = []

      headerObjects = [
        { header: { key1: 'value1a', key2: 'value2a' } }
        { header: { key1: 'value1b', key2: 'value2b' } }
        # { header: { key1: 'value1c', key2: 'value2c' } }
        # { header: { key1: 'value1d', key2: 'value2d' } }
        # { header: { key1: 'value1e', key2: 'value2e' } }
        # { header: { key1: 'value1f', key2: 'value2f' } }
      ]

      before 'build server', ->

        # use `cio` to create a server with a tranform (and an arbitrary port)
        server = cio.server
          onConnect: (connection) ->
            serverConnection = connection
            serverConnection.on 'end', ->
              server.close()

          oboe:
            root: (object) ->
              roots.push object
              return
            top:
              header: (header) ->
                headers.push header
                return header
            node:
              '!.header': (header) ->
                nodes.push header
                return header

            fail: (info...) ->
              console.log 'oboe fail:',info
              return

        server.on 'error', (error) -> console.log 'Server error:',error

        # once the server is listening do the client stuffs
        server.on 'listening', ->
          listening = true

          # create a client via `cio` with its transform and the same port as the server
          client = cio.client
            port     : server.address().port
            host     : 'localhost'
            onConnect: ->
              connected = true
              console.log 'client connected'

              for el,index in headerObjects
                client.write JSON.stringify(el), 'utf8'

              client.end ->
                console.log 'client ended'

          client.on 'error', (error) -> console.log 'client error:',error

        server.on 'close', -> closed = true

      before 'wait for server to listen', (done) ->

        server.listen 1357, 'localhost', done

      before 'wait for server to close', (done) ->

        server.on 'close', done

      it 'should listen', -> assert.equal listening, true

      it 'should connect', -> assert.equal connected, true

      it 'should receive root objects', ->

        assert.equal roots.length, 2
        for object,index in headerObjects
          assert.deepEqual roots[index], object

      it 'should receive header objects', ->

        assert.equal headers.length, 2
        for object,index in headerObjects
          assert.deepEqual headers[index], object.header

      it 'should receive node objects', ->

        assert.equal nodes.length, 2
        for object,index in headerObjects
          assert.deepEqual nodes[index], object.header

      it 'should close', -> assert.equal closed, true
