QUnit.module "Batman.Route: named route querying"
  setup: ->
    @app = Batman()
    @routeMap = new Batman.RouteMap
    @builder = new Batman.RouteMapBuilder(@app, @routeMap, undefined)

    @builder.resources 'products', ->
      @member 'duplicate'
      @collection 'filtered'
      @resources 'images', ->
        @member 'duplicate'
        @collection 'filtered'

    @builder.resources 'customers', {only: []}, ->
      @member 'duplicate'

    @builder.root 'products#index'

    @query = new Batman.NamedRouteQuery(@routeMap)

    @product = Batman
      name: 'Product'
      toParam: -> 10
    @image = Batman
      name: 'Image'
      toParam: -> 20
    @customer = Batman
      name: 'Customer'
      toParam: -> 30

test "should find root level routes", ->
  equal @query.get('path'), '/'
  equal @query.path(), '/'

test "should find root level collection routes", ->
  equal @query.get('products.path'), '/products'
  equal @query.products().path(), '/products'

test "should find root level member routes", ->
  equal @query.get('products').get(@product).get('path'), '/products/10'
  equal @query.products(@product).path(), '/products/10'

test "should find root level member routes using explicit params", ->
  equal @query.get('products').get(10).get('path'), '/products/10'
  equal @query.products(10).path(), '/products/10'

test "should find nonstandard root level member routes", ->
  equal @query.get('products').get(@product).get('duplicate.path'), '/products/10/duplicate'
  equal @query.products(@product).duplicate().path(), '/products/10/duplicate'

test "should find nonstandard root level member routes using explicit params", ->
  equal @query.get('products').get(10).get('duplicate.path'), '/products/10/duplicate'
  equal @query.products(10).duplicate().path(), '/products/10/duplicate'

test "should find nonstandard root level collection routes", ->
  equal @query.get('products.filtered.path'), '/products/filtered'
  equal @query.products().filtered().path(), '/products/filtered'

test "should find nested collection routes", ->
  equal @query.get('products').get(@product).get('images.path'), '/products/10/images'
  equal @query.products(@product).images().path(), '/products/10/images'

test "should find nested member routes", ->
  equal @query.get('products').get(@product).get('images').get(@image).get('path'), '/products/10/images/20'
  equal @query.products(@product).images(@image).path(), '/products/10/images/20'

test "should find nonstandard nested collection routes", ->
  equal @query.get('products').get(@product).get('images.filtered.path'), '/products/10/images/filtered'
  equal @query.products(@product).images(@image).filtered().path(), '/products/10/images/filtered'

test "should find nonstandard nested member routes", ->
  equal @query.get('products').get(@product).get('images').get(@image).get('duplicate.path'), '/products/10/images/20/duplicate'

test "should find nonstandard nested member routes even if the parent doesn't have a route", ->
  equal @query.get('customers').get(@customer).get('duplicate.path'), '/customers/30/duplicate'

test "should find routes when given association proxies", ->
  product = @product
  class MockAssociationProxy extends Batman.AssociationProxy
    @accessor 'target', -> product
  @proxy = new MockAssociationProxy({}, {})
  equal @query.get('products').get(@proxy).get('path'), '/products/10'
  equal @query.products(@proxy).path(), '/products/10'

test "should return undefined when given undefined parameters", ->
  equal typeof @query.get('products').get(undefined), 'undefined'

test "should return undefined when given null parameters", ->
  equal typeof @query.get('products').get(null), 'undefined'
