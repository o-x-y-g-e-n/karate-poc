## Framework Analysis 
By no mean, I am making any statements here. I am opening a forum for debate and discussion for some of the framework practices. Everything here is 100% my opinion, and I can 99% wrong.

### Things I didn't like about this framework

**Abusing BDD**

I think BDD was never invented to perform actions (GET, PUT, assert etc). The simple goal of BDD was to write the test cases/scenarios in a layman terms, adhering to acceptance criteria [Given - When - Then](https://www.agilealliance.org/glossary/given-when-then/) formula that anyone can understand and interpret (business, design, C level exec). This framework has messed up the concept of BDD and have attached it to all things possible. Again this is not wrong, but i would not call this behaviour driven development. 

For example (one of my test cases is):
```
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
```

Ideally, If I am writing true BDD, I would write something like
```
 Scenario: Attempting to add more than the maximum allowed quantity of a product
    Given I am authenticated with valid user credentials
    When I attempt to add 1000 quantities of the "XYZ" product to the cart
    Then the API should respond with an error message stating "Only a maximum of 10 products can be added to the cart"
```

The difference is clear. Now we can argue and find some hacks to hide all the details in seperate feature files, but then again it raises question of debugging and maintanence.

**Java Utils vs Javascript Utils**

For any major complex validations, you would need to write code outside BDD. That gives us with 2 choices, write JAVA classes and call them in BDD, write JS code embedded in the BDD. Again you can put each function in a seperate JS file, but imaging searching through 1000 js files. 
The framework doesn't set any guidance on the best approach to this problem. Also passing arguments from BDD to JAVA classes and functions can be a bit tricky.

**The framework isn't designed for e2e test cases**

This holds true especially for complex UI operations. Imagine doing some operations on UI, then calling API's to validate, add some DB operations, navigate to next screen and repeat this. How long will be your scenario (50 lines)? I think more. Good luck debugging if any issue comes up

**Good Plugins are paid**

Kafka is paid. It does reduce a lot of boilerplate, but if we are writing our own implementation for most of the integrations (like DB, Kafka, or even Splunk), why not just use core java (and add our implementations of Selenium, Appium, Jersey etc). It does become a bit complex this way to maintain. 


*All these topics are open for discussion!*🍻