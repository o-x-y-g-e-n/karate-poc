### Features Implemented

- [x] Functional and Integrated Tests Automation
- [x] Support for Java Custom Assertions
-[x] Support for Parallel Runs
-[x] Support for parameterized commandline execution (to integrate with Jenkins)
-[x] Support for DBUtils (Example)
-[x] Support for Kafka (Custom Built - Example)
-[x] Support for global test data
-[x] Cucumber Reports

### API's Automated

-[x] Auth
-[x] Product & Category
-[x] Cart

### Boilerplate command

```
mvn archetype:generate \
-DarchetypeGroupId=com.intuit.karate \
-DarchetypeArtifactId=karate-archetype \
-DarchetypeVersion=1.4.1 \
-DgroupId=com.mycompany \
-DartifactId=myproject
```

### Folder Structure

The idea here is to divide the framework into three major modules.

- `framework` - All the re-usable, generic utils. Here I have implemented Java Assertions, Database Utils, Kafka Utils
  that can be used in application automation.
- `application` - Here resides all the application test automation logic. You can use framework methods here as needed.
    - Every application would have modules named after the functionality, and the feature fiel and all the utils would
      lie
      in the same folder. We don't seperate util and folder. (This way it's more maintainable when things scale)
- `runners` - All the parallel runners or runners configured to run specific set of tests in any particular way.

### testData

Yes, might create seperate files for seperate test data. Never a big fan of this. Hence a single
file `src/test/java/testdata.json` will hold all testData in json format. Use proper naming convention to create test
data for specific scenario, and make sure you don't use an existing data entry. Always create a new one even if there is
repetition.

### How to run the test cases

```
 mvn clean test -Dkarate.options="--tags @cart,@product,@product-category,@auth" -Dtest=DemoTestsParallel
```

### The idea of util methods

I am an old dog. I love utils. I love maintaining them. But karate actually exposes all their assertion/actions through
BDD already. When I started, I had 3 options.

1. Java Assertion Utils - The `src/test/java/framework/Assertions.java`. If you see, I have common assertion methods.
   But I have used in minimally in the framework.
2. Javascript Utils - Karate lets you write JS which is cool. JS has simplier methods, less code then java, but it's
   hard to maintain. `src/test/java/framework/assertions.feature`.
3. The ideal way - Not that I like it (and I have said why in the framework analysis readme) - Use inbuit karate
   assertions like `assert` and `match`. For complex assertions, define functions.

### Assertion Logic

-[x] Response Code
-[x] Schema
-[x] Required Fields
-[x] Response Data
-[ ] Response Headers
*Ideally, I would also validate response headers (security, data-content and custom added headers). I didn't validate
them here because the API's kinda didn't have much solid to validate*

### Few points to note

`Authorization`
Generally I would assume that some API's of product/cart would require authorization. Right now the API’s didn’t have
that as a requirement, hence I didn’t include it in my scenarios. Though there is an endpoint with authentication

```
https://dummyjson.com/auth/cart -- with authentication
https://dummyjson.com/cart - without authentication
```

***Hence please note that in real-world I would also want to check authentication and authorization, because not all
users are in, and not all users have access to all resources. These test cases are not included here due to limitation
of the API's.***

`Scenarios not possible to mimic`

- E2e - create -> update -> delete
- Create product -> Get Product
  *Because the create and update API's (for products, and carts) are mocks (they don't actually perform the operation),
  there is no way to tell if the product was actually added through other API's. Ideally I would perform a DB operation
  to validate too.*

`Get Products`

- Usually I would first create a product, and then fetch it, to reduce flakiness. But because createProduct API is a
  mock (it doesn’t actually add the data), I am not able to follow the ideal test steps.
- Ideally, sometimes, we would also put some retry/poll mechanism, because the data might not have been created if async
  behavior is observed.

`Env`

- Yes the urls would change, maybe some functionality (assertion) or actions would change too based on env. (*I have not
  implemented that here because the API's don't support it*). But this can be done from `karate-config.js`.

### Weird Behaviour (Edge cases)

These are not official bugs (they might be). I would dicuss them with developers/QA in teams to get further
understanding.

`Limit Products API`

1. `?limit=0` - current - return all 100 records
3. `?limit=10.11` - returns 10 records
4. `?limit=10.77` - returns 10 records
5. `?limit=2e9` - returns 2 records

`Search Products API`

1. `/products/search` - This returns empty array (200 OK). Ideally this should work same as `/products/`
2. `https://dummyjson.com/products?limit=0&skip=10` -    "total": 100,    "skip": 10,    "limit": 90}
3. `https://dummyjson.com/products?limit=0&skip=91` - returns last 9 elements - I guess 0 means return the remaining.

`Create Product`

1. Send an empty body - and it still returns an ID
2. There is no field validation happening. Send an int to a string field (eg. Thumbnail = 1), and it returns it back.
3. not sure which fields are required/unique. Hence no way to tell duplicates. Id is different, but what if all the
   other fields are the same?

`Update Product`

1. No field type validations. You can update any field to any other field type
2. Pass an id field as body - this will return 404 -  "Product with id '11' not found" which is just weird.

`Add Cart`

1. Passing a big integer in quantity returns a float. Ideally it should have thrown an error because all API’s limit the
   products you can add.
2. Passing a negative value as quantity still returns negative values.
3. Add duplicate productID’s. The sum/total quantity still remains the same. Not sure what is expected here. 