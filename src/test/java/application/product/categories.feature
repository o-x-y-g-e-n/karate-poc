@product-category
Feature: Products Categories API

  Background:
    * url baseUrl
    * def testData = read('classpath:testdata.json')
    * def calculateMinimum =
    """
    function(minLimit, total) {
      return Math.min(minLimit, total);
    }
    """

  Scenario: Get Product Categories
    Given path '/products/categories'
    When method GET
    Then status 200
    And match response == '#array'
    And assert response.length > 0


  Scenario Outline: Get Product of a category - Valid Category - <category>
    Given path '/products/category/<category>'
    And param limit = <limit>
    And param skip = <skip>
    When method GET
    Then status 200
    And match response.products == '#array'
    And def matchedProducts = karate.filter(response.products, function(product){ return product.category == category })
    And match matchedProducts == response.products
    And assert matchedProducts.length == response.products.length
    And assert response.skip == <skip>
    And assert response.limit == calculateMinimum(<limit>, response.total-response.skip)
    Examples:
      | category     | limit | skip |
      | smartphones  | 5     | 5    |
      | mens-watches | 100   | 1    |


  Scenario Outline: Get Product of a category - Invalid Category - <category>
    Given path '/products/category/<category>'
    When method GET
    Then status 200
    And match response.products == '#array'
    And match response.total == 0
    Examples:
      | category   |
      | smar       |
      | mens       |
      | watches    |
      | smartphone |
      | alpha      |
      | 111        |
      | z-z-z-z    |

