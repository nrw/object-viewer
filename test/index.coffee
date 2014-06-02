test = require 'tape'
concat = require 'concat-stream'
extend = require 'xtend'

Viewer = require '../'

read = (obj) -> {key, value} for key, value of obj

test 'init', (t) ->
  t.plan 3

  v = Viewer()

  t.ok v, 'exists'
  t.same v.patched, {}, 'has patched'
  t.same v.patch, {}, 'has patch'

test 'simple', (t) ->
  t.plan 10

  base =
    person:
      kara: {name: 'Kara Thrace'}
      lee: {name: 'Lee Adama'}
    ship:
      galactica: {type: 'battlestar', number: 75}
      pegasus: {type: 'battlestar', number: 62}

  v = new Viewer base

  t.equal typeof v, 'object', 'exists'

  v.on 'base', -> t.ok yes, 'emits base'
  v.on 'patch', -> t.ok yes, 'emits patch'
  v.on 'change', -> t.ok yes, 'emits change' # called twice

  v.read('ship').pipe concat (people) ->
    t.same people, read(base.ship), 'reads ship'

  v.read('person').pipe concat (people) ->
    t.same people, read(base.person), 'reads people'

    v.set 'person', 'd', {name: 'Anastasia Dualla'}

    t.same v.get('person', 'kara'), base.person.kara, 'gets'

    t.same v.patch, person: d: name: 'Anastasia Dualla'

    v.set 'colony', 'caprica', {name: 'Caprica'}

    t.same v.patch,
      person: d: name: 'Anastasia Dualla'
      colony: caprica: name: 'Caprica'

test 'views', (t) ->
  t.plan 3

  base =
    person:
      kara: {name: 'Kara Thrace'}
      lee: {name: 'Lee Adama'}
    ship:
      galactica: {type: 'battlestar', number: 75}
      pegasus: {type: 'battlestar', number: 62}

  patch =
    person:
      d: 'Anastasia Dualla'

  v = new Viewer base, patch

  v.read('person', view: 'base').pipe concat (people) ->
    t.same people, read(base.person), 'reads base'

  v.read('person', view: 'patch').pipe concat (people) ->
    t.same people, read(patch.person), 'reads patch'

  v.read('person', view: 'patched').pipe concat (people) ->
    t.same people, read(extend {}, base.person, patch.person), 'reads patched'

test 'swap base', (t) ->
  t.plan 4

  base =
    person:
      kara: {name: 'Kara Thrace'}
      lee: {name: 'Lee Adama'}
    ship:
      galactica: {type: 'battlestar', number: 75}
      pegasus: {type: 'battlestar', number: 62}

  base2 =
    person:
      kara: {name: 'Kara Thrace'}
      lee: {name: 'Lee Adama'}
      d: {name: 'DD'}
    ship:
      galactica: {type: 'battlestar', number: 75}
      pegasus: {type: 'battlestar', number: 62}

  patch =
    person:
      d: 'Anastasia Dualla'

  v = new Viewer base, patch

  v.read('person').pipe concat (people) ->
    t.same people, read(extend {}, base.person, patch.person), 'reads patched'

    v.setBase base2

    v.read('person', view: 'patch').pipe concat (people) ->
      t.same people, read(patch.person), 'reads patch'
    v.read('person', view: 'base').pipe concat (people) ->
      t.same people, read(base2.person), 'reads base'
    v.read('person').pipe concat (people) ->
      t.same people, read(extend {}, base.person, patch.person), 'reads patched'

test 'swap patch', (t) ->
  t.plan 4

  base =
    person:
      kara: {name: 'Kara Thrace'}
      lee: {name: 'Lee Adama'}
    ship:
      galactica: {type: 'battlestar', number: 75}
      pegasus: {type: 'battlestar', number: 62}

  patch =
    person:
      d: 'DD'

  patch2 =
    person:
      d: 'Anastasia Dualla'
      tigh: 'Saul Tigh'

  v = new Viewer base, patch

  v.read('person').pipe concat (people) ->
    t.same people, read(extend {}, base.person, patch.person), 'reads patched'

    v.applyPatch patch2
    v.read('person', view: 'patch').pipe concat (people) ->
      t.same people, read(patch2.person), 'reads patch'
    v.read('person', view: 'base').pipe concat (people) ->
      t.same people, read(base.person), 'reads base'
    v.read('person').pipe concat (people) ->
      t.same people, read(extend {}, base.person, patch2.person), 'reads patched'

test 'allows empty opts', (t) ->
  t.plan 1

  base = person: kara: {name: 'Kara Thrace'}
  patch = person: d: 'Anastasia Dualla'

  v = new Viewer base, patch

  v.read('person', {}).pipe concat (people) ->
    t.same people, read(extend {}, base.person, patch.person), 'reads patched'
