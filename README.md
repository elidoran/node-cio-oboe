# @cio/oboe
[![Build Status](https://travis-ci.org/elidoran/node-cio-oboe.svg?branch=master)](https://travis-ci.org/elidoran/node-cio-oboe)
[![Dependency Status](https://gemnasium.com/elidoran/node-cio-oboe.png)](https://gemnasium.com/elidoran/node-cio-oboe)
[![npm version](https://badge.fury.io/js/%40cio%2Foboe.svg)](http://badge.fury.io/js/%40cio%2Foboe)

Use Oboe.js to parse a stream of JSON objects.

An addon for the [cio](https://www.npmjs.com/package/cio) module which uses [Oboe](http://oboejs.com).

Although this library is capable of using all Oboe's features, it focuses on using it to read a series of root level objects and provide those objects one at a time without building up data in memory.

Other JSON communications separate JSON objects with newline characters. That prevents sending "pretty" JSON. Oboe, on the other hand, is capable of reading "pretty" JSON as well as minified JSON. This allows debugging to monitor communications and display the content in pretty mode for developers. In production, the JSON can be produced in its minified style.


## Install

```sh
npm install @cio/oboe --save
```


## Usage: Use in CIO

See [cio](https://github.com/elidoran/node-cio)

```javascript
// create `cio` instance
var buildCio = require('cio')
  , cio = buildCio();

// add this module for client connections
cio.onClient('@cio/oboe');
// OR: add for server client connections
cio.onServerClient('@cio/oboe');

// configure oboe
var cioOptions = {
  oboe: {
    // provide a function which receives each root object
    root: function(object) {
      // do something with the object
    },
    // provide functions for top level keys with these names:
    top: {
      header: function(header) { },
      thing : function(thing) { },
      footer: function(footer) { }
    }
  }
};

// use `cio` to build a client socket which will have oboe applied
var client = cio.client(cioOptions)
// or create a server, its client connections will have oboe applied
  , server = cio.server(cioOptions);

// when using only a 'root' function it can be provided simply:
cioOptions = {
  oboe: function(root) {
    // do something with a root object
  }
};
```


## Usage: Client

Receive JSON from a Server.

```javascript
var cio = require('cio')();

var options = {
  port: 12345
  , host: 'localhost'
  , oboe: function (rootObject) { /* do something with each */ }
};

var client = cio.client(options);

//  OR:
// add listener to configure Oboe directly:
client.on('oboe', function(oboe, client) {
  // configure the `oboe` instance
});
```


## Usage: Server

Receive JSON from a Client.

```javascript
var cio = require('cio')();

var options = {
  oboe: function (rootObject) { /* do something with each */ }
};

// create it with the options
var server = cio.server(options);

// if you want to configure Oboe directly:
server.on('oboe', function(oboe, serverClient) {
  // configure the `oboe` instance
});

// the usual
server.listen();
```

## Usage: Configure Oboe


```javascript
// Note: each subsequent Method overrides the previous one.
var oboeOptions = /* See Configuration Options below */ ;

// Method #1 - tell the cio builder
// these `oboe` options will be available to all new connections
var buildCio = require('cio')
  , cio = buildCio({ oboe: oboeOptions });

// add this library to either client:
cio.onClient('@cio/oboe');
// Or, server client:
cio.onServerClient('@cio/oboe');
// Or, add to both if you're using both...

// Method #2 - tell the socket builder
// Note: can do the same thing with `cio.server()`
// and its server client connections will receive them
var client = cio.client({
  port: 1357
  , host: 'localhost'
  , oboe: oboeOptions
});

// Method #3 - instead of options, configure it manually
client.on('oboe', function(oboe, client) {
  // configure the `oboe` instance
});
```


## Usage: Configuration Options

Use the below options to control how this library configures an `Oboe` instance.

These are a mix of Oboe's API and a few convenience things to help ease its use.

Property   | Oboe?     | Purpose
---------: | :-------: | :---------------------------------
root       | No        | Specify a function to call for each root object
top        | No        | Convenience for matching top level nodes with a specific property. Shorthand for `node` keys by prepending '!.' to them. See [Example Configuration](#example-configuration)
node       | [Yes](http://oboejs.com/api#node-event) | Add patterns to match keys and retrieve their values.
path       | [Yes](http://oboejs.com/api#path-event) | Listen for parsing errors. This library does that for
fail       | [Yes](http://oboejs.com/api#fail-event) | Listen for parsing errors. This library does that for you and emits it as an 'error' event. Feel free to listen to 'fail' as well...
done       | [Yes](http://oboejs.com/api#done-event) | Normally used to get the entire JS object at the end, which this library is intending to avoid.

Below are examples of objects and how to configure functions for processing them.

### Simple Objects

A simple object doesn't have a hierarchy, it doesn't "contain" another object. It's a 'root' object. It's *not* a 'top level' object.

Basically, use 'root' to process these.

```javascript
{ simple: 'object' }
```

### Labeled Objects

This object is what I'll call "labeled". It is an object with one property which contains another object. The label here is 'label'.

Or course, this is also a 'root' object with a 'label' property.

Use 'root' to process the entire object and use 'top' with label 'label' to process the object value of the label.

```javascript
{ label: { labeled: 'object' } }
```

This has a 'top level' object labeled 'person'.
Use 'root' to process the entire object with the label.
Use 'top' to process the object value of the label.

```javascript
{
  person: {
    name: 'John',
    address: {
      street: '123 Somewhere St.',
      city: 'Hometown',
      state: 'ZZ',
      zip: '12345'
    }
  }
}
```

### Multiple Labels

Process multiple top level properties.

```javascript
{
  header: { some: 'header stuff' },
  body  : { some: 'body content' },
  footer: { some: 'footer' }
}
```

### Example Configuration

Here are options to work with the above objects.

```javascript
var options = {
  oboe: {
    // each example object above is a 'root' object
    root: function(object) { console.log('root:',object); },

    // the "labeled" objects above are handled in `top`
    top: {
      // this would receive:  { labeled: 'object' }
      label: function(object) { console.log('top/label:',object); },

      // this would receive: { name: 'John', address: { /* ...*/ }}
      person: function(person) { console.log('top/person:',person); },

      // this would receive: { some: 'header stuff' }
      header: function(header) {  }

      // this would receive: { some: 'body content' }
      body  : function(header) {  }

      // this would receive: { some: 'footer' }
      footer: function(footer) {  }
    },

    // Now for some Oboe official ones:

    // apply patterns to match a 'node' and supply it to your function.
    node: {
      // specify pattern as the key and function as the value
      'pattern': function(arg) { },
      'pattern2': function(arg) { },

      // this is the same as specifying 'label' in the 'top' section above
      '!.label': function(object) { console.log('node/label',object); },

      // this is the same as specifying 'person' in the 'top' section above
      '!.person': function(object) { console.log('node/person',object); }
    },

    // apply patterns for 'path' matchers.
    path: {
      // same as for `node` except they match immediately.
    }
  }
};
```

Here's a small example without all the comments in it.

```javascript
var objects = [
  // 'top level' objects labeled 'data':
  { data: { _id:'8286781819263' time: 111, some: 'value' } }
  { data: { _id:'2067101738684' time: 222, some: 'stuff' } }
  { data: { _id:'9828223482106' time: 135, some: 'data' } }
  { data: { _id:'9907672385621' time: 246, some: 'object' } }
  { data: { _id:'8838283568863' time: 975, some: 'example' } }
  { data: { _id:'2282082825680' time: 321, some: 'test' } }
];

var client = cio.client({
  port: 12345
  , host: 'localhost'
  , oboe: {
    top: { // top means labeled
      data: function (data) { // label is 'data'
        // `data` arg has the value object, not the `data` key
        console.log('data provides some',data.some);
      }
    }
  }
});

// console output results:
/*
data provides some value
data provides some stuff
data provides some data
data provides some object
data provides some example
data provides some test
*/
```

## MIT License
