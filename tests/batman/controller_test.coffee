class TestController extends Batman.Controller
  show: ->

class MockView extends MockClass
  @chainedCallback 'ready'
  get: createSpy().whichReturns("view contents")
  set: ->
  inUse: -> false

QUnit.module 'Batman.Controller'

test "get('routingKey') should use the prototype level routingKey property", ->
  class ProductsController extends Batman.Controller
    routingKey: 'products'

  equal (new ProductsController).get('routingKey'), 'products'

QUnit.module 'Batman.Controller render'
  setup: ->
    Batman.Controller::renderCache = new Batman.RenderCache
    @controller = new TestController
    Batman.DOM.Yield.reset()
  teardown: ->
    delete Batman.currentApp

test 'it should render a Batman.View if `view` isn\'t given in the options to render', ->
  mockClassDuring Batman ,'View', MockView, (mockClass) =>
    @controller.dispatch 'show'
    view = mockClass.lastInstance
    equal view.constructorArguments[0].source, 'test/show'

    spyOnDuring Batman.DOM.Yield.withName('main'), 'replace', (replace) =>
      view.fireReady()
      deepEqual view.get.lastCallArguments, ['node']
      deepEqual replace.lastCallArguments, ['view contents']

test 'it should cache the rendered Batman.View if `view` isn\'t given in the options to render', ->
  mockClassDuring Batman ,'View', MockView, (mockClass) =>
    @controller.dispatch 'show'
    view = mockClass.lastInstance

    @controller.dispatch 'show'
    equal mockClass.lastInstance, view, "No new instance has been made"

test 'it should clear yields which weren\'t rendered into after dispatch', ->
  spyOnDuring Batman.DOM.Yield.withName('sidebar'), 'clear', (sidebarClearSpy) =>
    spyOnDuring Batman.DOM.Yield.withName('main'), 'clear', (mainClearSpy) =>
      mockClassDuring Batman ,'View', MockView, (mockClass) =>
        @controller.show = ->
          @render {into: 'main'}
        @controller.index = ->
          @render {into: 'sidebar'}

        equal mainClearSpy.callCount, 0
        equal sidebarClearSpy.callCount, 0
        @controller.dispatch 'show'
        equal mainClearSpy.callCount, 0
        equal sidebarClearSpy.callCount, 1
        @controller.dispatch 'index'
        equal mainClearSpy.callCount, 1
        equal sidebarClearSpy.callCount, 1

test 'it should clear yields which weren\'t rendered into after dispatch if the implicit render takes place', ->
  spyOnDuring Batman.DOM.Yield.withName('sidebar'), 'clear', (sidebarClearSpy) =>
    spyOnDuring Batman.DOM.Yield.withName('main'), 'clear', (mainClearSpy) =>
      mockClassDuring Batman ,'View', MockView, (mockClass) =>
        @controller.dispatch 'show'
        ok sidebarClearSpy.called
        equal mainClearSpy.called, false

test 'it should clear yields which weren\'t rendered into after dispatch if several named renders take place', ->
  spyOnDuring Batman.DOM.Yield.withName('slider'), 'clear', (sliderClearSpy) =>
    spyOnDuring Batman.DOM.Yield.withName('sidebar'), 'clear', (sidebarClearSpy) =>
      spyOnDuring Batman.DOM.Yield.withName('main'), 'clear', (mainClearSpy) =>
        mockClassDuring Batman ,'View', MockView, (mockClass) =>
          @controller.show = ->
            @render {source: 'list', into: 'main'}
            @render {source: 'show', into: 'slider'}

          @controller.dispatch 'show'
          equal mainClearSpy.called, false
          equal sliderClearSpy.called, false
          ok sidebarClearSpy.called

test 'it should render a Batman.View subclass with the ControllerAction name on the current app if it exists', ->
  Batman.currentApp = mockApp = Batman _renderContext: Batman.RenderContext.base
  mockApp.TestShowView = MockView

  @controller.dispatch 'show'
  view = MockView.lastInstance
  equal view.constructorArguments[0].source, 'test/show'

  spyOnDuring Batman.DOM.Yield.withName('main'), 'replace', (replace) =>
    view.fireReady()
    deepEqual view.get.lastCallArguments, ['node']
    deepEqual replace.lastCallArguments, ['view contents']

test 'it should cache the rendered Batman.Views if rendered from different action', ->
  Batman.currentApp = mockApp = Batman _renderContext: Batman.RenderContext.base
  @controller.actionA = ->
    @render viewClass: MockView, source: 'foo'
  @controller.actionB = ->
    @render viewClass: MockView, source: 'foo'

  @controller.dispatch 'actionA'
  view = MockView.lastInstance

  @controller.dispatch 'actionB'
  equal MockView.lastInstance, view, "No new instance has been made"

asyncTest 'it should cache the rendered Batman.Views if rendered from different actions into different yields', ->
  Batman.currentApp = mockApp = Batman _renderContext: Batman.RenderContext.base
  mainContainer = $('<div>')[0]
  detailContainer = $('<div>')[0]
  Batman.DOM.Yield.withName('main').set 'containerNode', mainContainer
  Batman.DOM.Yield.withName('detail').set 'containerNode', detailContainer

  @controller.index = ->
    @render viewClass: Batman.View, html: 'foo', into: 'main', source: 'a'

  @controller.show = ->
    @index()
    @render viewClass: Batman.View, html: 'bar', into: 'detail', source: 'b'

  @controller.dispatch 'index'
  delay =>
    mainView = Batman._data mainContainer.childNodes[0], 'view'
    @controller.dispatch 'show'
    delay ->
      equal Batman._data(mainContainer.childNodes[0], 'view'), mainView, "The same view was used in the second dispatch"

test 'it should render views if given in the options', ->
  testView = new MockView
  @controller.render
    view: testView

  spyOnDuring Batman.DOM.Yield.withName('main'), 'replace', (replace) =>
    testView.fireReady()
    deepEqual testView.get.lastCallArguments, ['node']
    deepEqual replace.lastCallArguments, ['view contents']

test 'it should pull in views if not present already', ->
  mockClassDuring Batman ,'View', MockView, (mockClass) =>
    @controller.dispatch 'show'
    view = mockClass.lastInstance
    equal view.constructorArguments[0].source, 'test/show'

    spyOnDuring Batman.DOM.Yield.withName('main'), 'replace', (replace) =>
      view.fireReady()
      deepEqual view.get.lastCallArguments, ['node']
      deepEqual replace.lastCallArguments, ['view contents']

test 'dispatching routes without any actions calls render', 1, ->
  @controller.test = ->
  @controller.render = ->
    ok true, 'render called'

  @controller.dispatch 'test'

test '@render false disables implicit render', 2, ->
  @controller.test = ->
    ok true, 'action called'
    @render false

  spyOnDuring Batman.DOM, 'replace', (replace) =>
    @controller.dispatch 'test'
    ok ! replace.called

test 'event handlers can render after an action', 6, ->
  testView = new MockView
  @controller.test = ->
    ok true, 'action called'
    @render view: testView

  testView2 = new MockView
  @controller.handleEvent = ->
    ok true, 'event called'
    @render view: testView2

  testView3 = new MockView
  @controller.handleAnotherEvent = ->
    ok true, 'another event called'
    @render view: testView3

  @controller.dispatch 'test'
  spyOnDuring Batman.DOM.Yield.withName('main'), 'replace', (replace) =>
    testView.fire 'ready'
    equal replace.callCount, 1

    @controller.handleEvent()
    testView2.fire 'ready'
    equal replace.callCount, 2

    @controller.handleAnotherEvent()
    testView3.fire 'ready'
    equal replace.callCount, 3

test 'redirecting a dispatch prevents implicit render', 2, ->
  Batman.navigator = new Batman.HashbangNavigator
  Batman.navigator.redirect = ->
    ok true, 'redirecting history manager'
  @controller.render = ->
    ok true, 'redirecting controller'
  @controller.render = ->
    throw "shouldn't be called"

  @controller.test1 = ->
    @redirect 'foo'

  @controller.test2 = ->
    Batman.redirect 'foo2'

  @controller.dispatch 'test1'
  @controller.dispatch 'test2'

test '[before/after]Filter', 3, ->
  class FilterController extends Batman.Controller
    @beforeFilter only: 'withBefore', except: 'withoutBefore', ->
      ok true, 'beforeFilter called'
    @afterFilter 'testAfter'

    withBefore: ->
      @render false
    withoutBefore: ->
      @render false
    testAfter: ->
      ok true, 'afterFilter called'

  controller = new FilterController

  controller.dispatch 'withoutBefore'
  controller.dispatch 'withBefore'

test 'actions executed by other actions implicitly render', ->
  mockClassDuring Batman ,'View', MockView, (mockClass) =>
    @controller.test = ->
      @render false
      @executeAction 'show'

    @controller.dispatch 'test'

    view = mockClass.lastInstance # instantiated by the show implicit render
    equal view.constructorArguments[0].source, 'test/show', "The action is correctly different inside the inner execution"

test 'actions executed by other actions have their filters run', ->
  beforeSpy = createSpy()
  afterSpy = createSpy()
  class TestController extends @controller.constructor
    @beforeFilter 'show', beforeSpy
    @afterFilter 'show', afterSpy

    show: -> @render false
    test: ->
      @render false
      @executeAction 'show'

  @controller = new TestController
  @controller.dispatch 'test'
  ok beforeSpy.called
  ok afterSpy.called

test 'actions executed by other actions prevent yields from being cleared at the end of dispatch', ->
  spyOnDuring Batman.DOM.Yield.withName('sidebar'), 'clear', (sidebarClearSpy) =>
    spyOnDuring Batman.DOM.Yield.withName('main'), 'clear', (mainClearSpy) =>
      mockClassDuring Batman ,'View', MockView, (mockClass) =>
        @controller.show = ->
          @executeAction 'index'
          @render {into: 'main'}
        @controller.index = ->
          @render {into: 'sidebar'}

        @controller.dispatch 'show'

        equal mainClearSpy.callCount, 0
        equal sidebarClearSpy.callCount, 0
