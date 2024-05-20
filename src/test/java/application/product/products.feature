@product
Feature: Products API

  Background:
    * url baseUrl
    * def testData = read('classpath:testdata.json')
    * def calculateMinimum =
    """
    function(minLimit, total) {
      return Math.min(minLimit, total);
    }
    """
    * def productsSchema =
    """
      {
        "products": "#array",
        "total": "#number",
        "skip": "#number",
        "limit": "#number"
      }
    """
    * def productSchema =
    """
    {
      "id": "#number",
      "title": "#string",
      "description": "#string",
      "price": "#number",
      "discountPercentage": "#number",
      "rating": "#number",
      "stock": "#number",
      "brand": "#string",
      "category": "#string",
      "thumbnail": "#string",
      "images": "#array"
    }
    """
    * def validateProduct =
    """
    function(product) {
      return karate.match(product, productSchema);
    }
    """

  Scenario: Get all products - Schema Validation
    Given path '/products'
    When method GET
    Then status 200
    And match response contains productsSchema
    And match response.products == '#array'
    * eval karate.forEach(response.products, validateProduct)

  Scenario Outline: Get a single product by providing a valid ID
    Given path '/product/<id>'
    When method GET
    Then status 200
    And match response.id == <id>
    And match response contains productSchema
    Examples:
      | id |
      | 1  |
      | 2  |

  Scenario Outline: Get a single product - Invalid UserID <id>
    Given path '/product/<id>'
    When method GET
    Then status 404
    And match response.message == "Product with id '<id>' not found"
    Examples:
      | id                                   |
      | 1000                                 |
      | a                                    |
      | 1a                                   |
      | *1                                   |
      | 101                                  |
      | 0                                    |
      | 123e4567-e89b-12d3-a456-426614174000 |
      | 1&                                   |

  Scenario Outline: Search for a product - Products Present
    Given path '/products/search'
    And param q = '<id>'
    When method GET
    Then status 200
    And assert response.products.length > 0
    And assert response.total > 0
    And assert response.limit > 0
    Examples:
      | id      |
      | 0       |
      | 1       |
      | a       |
      | Samsung |
      | 2020    |
      | brand   |
      | A19211  |


  Scenario Outline: Search for a product - No Products Found
    Given path '/products/search'
    And param q = '<id>'
    When method GET
    Then status 200
    And assert response.products.length == 0
    And match response.total == 0
    And match response.skip  == 0
    And match response.limit == 0
    Examples:
      | id                                   |
      | zaa132                               |
      | sjdhrd                               |
      | a*12                                 |
      | a&12                                 |
      | Günter                               |
      | 123e4567-e89b-12d3-a456-426614174000 |
      | discountPercentage                   |
      | 10.58                                |


  Scenario Outline: Limit Products - In range Limits
    Given path '/products'
    And param limit = <limit>
    When method GET
    Then status 200
    And assert response.products.length == <limit>
    And assert response.limit == calculateMinimum(<limit>, response.total-response.skip)
    Examples:
      | limit |
      | 1     |
      | 2     |
      | 100   |
      | 31    |

  Scenario Outline: Limit Products - Out of Bounds with limit <limit>
    Given path '/products'
    And param limit = <limit>
    When method GET
    Then status 200
    And assert response.products.length == response.total
    And assert response.limit == calculateMinimum(<limit>, response.total-response.skip)
    Examples:
      | limit |
      | 100   |
      | 101   |
      | 1001  |

  #TODO: This can be a bug
  Scenario: Limit Products - Special Edge case limit and skip 0
    Given path '/products'
    And param limit = 0
    And param skip = 0
    When method GET
    Then status 200
    And assert response.products.length == response.total
    And assert response.limit == response.total


  Scenario Outline: Limit Products - Invalid limit
    Given path '/products'
    And param limit = '<limit>'
    When method GET
    Then status 400
    And assert response.message == "Invalid limit"
    Examples:
      | limit |
      | a     |
      | a1    |
      | 1z1   |


  Scenario Outline: Skip Products - Invalid limit
    Given path '/products'
    And param skip = '<limit>'
    When method GET
    Then status 400
    And assert response.message == "Invalid skip limit"
    Examples:
      | limit |
      | a     |
      | a1    |
      | 1z1   |


  Scenario Outline: Products - Invalid skip and limit
    Given path '/products'
    And param skip = '<limit>'
    And param limit = '<limit>'
    When method GET
    Then status 400
    And assert response.message == "Invalid limit"
    Examples:
      | limit |
      | a     |
      | a1    |
      | 1z1   |

  Scenario Outline: Skip Products - In range Skips
    Given path '/products'
    And param limit = 100
    And param skip = <skip>
    When method GET
    Then status 200
    And assert response.products.length == 100 - <skip>
    And match response.limit == 100 - <skip>
    And match response.skip == <skip>
    Examples:
      | skip |
      | 1    |
      | 2    |
      | 31   |
      | 0    |
      | 100  |


  Scenario: Add a new product
    Given path '/products/add'
    And request {title: 'some title'}
    When method POST
    Then status 200
    And match response.id == '#number'
    And match response.title == 'some title'


  # TODO: this can be a bug
  Scenario: Add an existing/duplicate product
    Given path '/products/add'
    And request testData.product.valid
    When method POST
    Then status 200
    And match response.id == '#number'
    And match response contains testData.product.valid

  Scenario: Update an existing product with empty data
    Given path '/products/1'
    And request {}
    When method PUT
    Then status 200
    And match response.id == '#number'
    And match response contains testData.product.valid


  Scenario: Update an existing product with correct values
    Given path '/products/1'
    And request {title: 'some other title', brand : 'a'}
    When method PUT
    Then status 200
    And match response contains productSchema
    And match response.title == 'some other title'
    And match response.brand == 'a'

  Scenario: Update an existing product - incorrect id
    Given path '/products/101'
    And request {title: 'some other title', brand : 'a'}
    When method PUT
    Then status 404
    And match response.message == "Product with id '101' not found"

  Scenario: Delete an existing record
    * def ZonedDateTime = Java.type('java.time.ZonedDateTime')
    * def Duration = Java.type('java.time.Duration')
    Given path '/products/1'
    And request {title: 'some other title', brand : 'a'}
    When method DELETE
    Then status 200
    And match response contains productSchema
    And match response.isDeleted == true
    * def deletedOnTime = ZonedDateTime.parse(response.deletedOn)
    * def currentTime = ZonedDateTime.now()
    * def difference = Duration.between(currentTime, deletedOnTime).abs().toMinutes()
    And assert difference <= 1
