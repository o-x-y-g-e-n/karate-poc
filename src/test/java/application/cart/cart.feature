@cart
Feature: Products API

  Background:
    * url baseUrl
    * def testData = read('classpath:testdata.json')
    * def cartUtils = Java.type('application.cart.CartUtils')
    * def cartSchema =
    """
    {
      "id": "#number",
      "products": "#array",
      "total": "#number",
      "discountedTotal": "#number",
      "userId": "#number",
      "totalProducts": "#number",
      "totalQuantity": "#number"
    }
    """

  Scenario: Get a single cart for valid userID - id - 1
    Given path '/carts/1'
    When method GET
    Then status 200
    And match response == '##(cartSchema)'


  Scenario Outline: Get a single cart for invalid userID - <id>
    Given path '/carts/<id>'
    When method GET
    Then status 404
    And match response.message == "Cart with id '<id>' not found"
    Examples:
      | id  |
      | 99  |
      | 101 |
      | 0   |

  Scenario Outline: Get carts of a user - Invalid ID - <id>
    Given path '/carts/user/<id>'
    When method GET
    Then status 404
    And match response.message == "User with id '<id>' not found"
    Examples:
      | id  |
      | 101 |
      | 0   |

  Scenario: Get carts of a user - Valid ID - 1
    Given path '/carts/user/1'
    When method GET
    Then status 200
    And match each response.carts[*].userId == 1


  Scenario: Get all carts
    Given path '/carts'
    When method GET
    Then status 200
    * match each response.carts == cartSchema
    * cartUtils.validateCarts(response.carts)

  @test
  Scenario: Add a cart - Happy path
    * def cart = testData.cart.happyPath
    Given path '/cart/add'
    And request cart
    When method POST
    Then status 200
    * def products = karate.jsonPath(response, '$.products[*]')
    * def productsfromAPIs = []
    * eval
    """
       karate.forEach(products, function(product) {
             var response = karate.http(baseUrl + '/product/' + product.id).get().body;
             var status = karate.http(baseUrl + '/product/' + product.id).get().status;
             if(status !== 200) {
                  throw 'KarateException: Something went wrong while fetching the product with id: ' + product.id
             }
             productsfromAPIs.push(response)
          }
       )
    """
    * print products
    * print productsfromAPIs
    * cartUtils.validateProductDetails(products, productsfromAPIs)

  Scenario: Add a cart - Missing Quantity
    * def cart = testData.cart.missingQuantity
    Given path '/cart/add'
    And request cart
    When method POST
    Then status 200
    * def products = karate.jsonPath(response, '$.products[*]')
    And assert products.length == 1
    And assert products[0].quantity == 1
    And assert products[0].id == cart.products[0].id
    And response.totalProducts == 1
    And response.totalQuantity == 1
    And response.userId == cart.userId


  #TODO: This can be a bug
  Scenario: Add a cart - Out of bound quantity
    * def cart = testData.cart.outOfBoundQuantity
    Given path '/cart/add'
    And request cart
    When method POST
    Then status 200
    * def products = karate.jsonPath(response, '$.products[*]')
    * def quantity = 1
    * eval
    """
        quantity = parseFloat(cart.products[0].quantity)
    """
    And assert products.length == 1
    And assert products[0].quantity == quantity
    And assert products[0].id == cart.products[0].id
    And response.totalProducts == 1
    And response.totalQuantity == 1
    And response.userId == cart.userId
    And response.total == products[0].price * quantity

  #TODO: This can be a bug - I am not sure what the expectation is here.
  # Actual: negative values for total
  Scenario: Add a cart - Missing Quantity
    * def cart = testData.cart.negativeQuantity
    Given path '/cart/add'
    And request cart
    When method POST
    Then status 200
    * def products = karate.jsonPath(response, '$.products[*]')


  Scenario: Add a cart - Invalid Product ID
    * def cart = testData.cart.invalidProductID
    Given path '/cart/add'
    And request cart
    When method POST
    Then status 200
    * def products = karate.jsonPath(response, '$.products[*]')
    And assert products.length == 0
    And response.totalProducts == 0
    And response.totalQuantity == 0
    And response.userId == cart.userId
    And response.total == 0


  Scenario: Add a cart - Duplicate Product iD
    * def cart = testData.cart.duplicateProductID
    Given path '/cart/add'
    And request cart
    When method POST
    Then status 200
    * def products = karate.jsonPath(response, '$.products[*]')
    And assert products.length == 1
    And response.totalProducts == 1
    And response.totalQuantity == 1
    And response.userId == cart.userId
    And response.total == 0

  # usually every company/product has a quantity limit - this scenario mimics testing that (here 10 items)
  Scenario: Add a cart - More than 10 items
    Given path '/cart/add'
    * def products =
    * def body = { userId : 1, products: [] };
    * def fun =
    """
    function() {
      var products = [];
      for (var i = 1; i <= 10; i++) {
        products.push({ id: i, quantity: 1 });
      }
      body.products = products
    }
    """
    * eval fun()
    And request body
    When method POST
    Then status 200
    * def products = karate.jsonPath(response, '$.products[*]')
    And assert products.length == 10
    And response.totalProducts == 10
    And response.totalQuantity == 10
    And response.userId == body.userId
    And response.total == 10


  Scenario: Add a cart - Invalid UserID
    * def invalidUserID = 101
    * def cart = testData.cart.happyPath
    * cart.userId = invalidUserID
    Given path '/cart/add'
    And request cart
    When method POST
    Then status 404
    And match response.message == "User with id '" + invalidUserID + "' not found"

  Scenario: Add a cart - Empty Data
    Given path '/cart/add'
    And request {}
    When method POST
    Then status 400
    And match response.message == "User id is required"
