# object-viewer [![build status](https://secure.travis-ci.org/nrw/object-viewer.png)](http://travis-ci.org/nrw/object-viewer)

View and listen for changes on state object that keeps track of saved vs patched state.

[![testling badge](https://ci.testling.com/nrw/object-viewer.png)](https://ci.testling.com/nrw/object-viewer)

## Example

``` js
var Viewer = require('object-viewer')
var assert = require('assert')

var base = {
  person: {
    kara: {name: 'Kara Thrace'},
    lee: {name: 'Lee Adama'}
  },
  ship: {
    galactica: {type: 'battlestar', number: 75},
    pegasus: {type: 'battlestar', number: 62}
  }
}
var viewer = Viewer(base)

viewer.on('change', function() {
  // access state via viewer.{base,patched,patch}
})

// the contents of the 'people' array
assert.deepEqual(viewer.read('person'), [
  {
    key: 'kara',
    value: {name: 'Kara Thrace'}
  },
  {
    key: 'lee',
    value: {name: 'Lee Adama'}
  }
])

// set value at key path
viewer.set('person', 'd', {name: 'Anastasia Dualla'})
// will fire a 'change' event
// see tests for more examples
```

## Concept Overview

This is an attempt to provide a general, familiar interface to large,
nested/namespaced, state objects that need to:

- be modified and know the difference between the original state and the modified state
- emit events when they've been changed
- allow changes to the `base` state without modifying the patch

An instance of `object-viewer` keeps track of 3 states:

1. `base` The original state
2. `patched` The state after changes have been made
3. `patch` The difference between the two states

The getters `get` and `read` can view any of these states by
setting `opts.view` to the desired state. The setter is necessary to trigger
events and update the `patch`.

## Methods

### var viewer = Viewer(base={}, patch={})

`base` is the state to diff against when determining what has changed. `patch`
is a patch from [patcher][patcher] that is used to
as the initial set of changes to the base state.

### viewer.read(keyPath..., opts={})

Get an array of objects at the given key path in the format
`{key: '<key>', value: '<value>'}` (the same format used by
[levelup](https://npmjs.org/package/levelup)).

- `opts.view = 'patched'` Set which view of the state to read. options are `patched`,
  `base`, and `patch`.

### viewer.get(keyPath..., opts={})

Gets the value at the given key path. `opts` behaves the same as in `read`.

### viewer.set(keyPath..., value)

Gets the value at the given key path to `value`. `set` values are always set on
the `patch`. To modify the `base` state, use `setBase`.

### viewer.setBase(base={})

Sets the `base` state. Does not influence the patch.

### viewer.applyPatch(patch={})

Applies the given [patcher][patcher] patch to the existing patch. Does not
modify the base state.

## Events

### viewer.on('base', fn())

Emitted when a new `base` is set. Also fires when an instance is created.

### viewer.on('patch', fn())

Emitted when a new `patch` is applied. Also fires when an instance is created.

### viewer.on('change', fn())

Emitted when any value is `set`.

## License

MIT

[patcher]: https://npmjs.org/package/patcher
