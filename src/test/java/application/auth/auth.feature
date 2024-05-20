@auth
Feature: Auth API

  Background:
    * url baseUrl
    * def testData = read('classpath:testdata.json')
    * def customAssertions = Java.type('framework.Assertions')

  Scenario: Successful Login and Obtain Access Token
    * def user = testData.credentials.valid
    Given path '/auth/login'
    And request { username: '#(user.username)', password: '#(user.password)', expiresInMins: 30}
    And header Content-Type = 'application/json'
    When method POST
    Then status 200
    And match response.id == user.id
    And match response.username == user.username
    And match response.firstName == user.firstName
    And match response.lastName == user.lastName
    And match response.gender == user.gender
    And match response.email == user.email
    And match response.image == user.image
    And assert response.token != null
    And assert response.token.length > 1


  Scenario: User logs in twice and receives the same token
    * def user = testData.credentials.valid
    Given path '/auth/login'
    And request { username: '#(user.username)', password: '#(user.password)', expiresInMins: 30}
    And header Content-Type = 'application/json'
    When method POST
    Then status 200
    And def firstToken = response.token
    * print 'First token obtained: ' + firstToken
    Given path '/auth/login'
    And request { username: '#(user.username)', password: '#(user.password)', expiresInMins: 30}
    And header Content-Type = 'application/json'
    When method POST
    Then status 200
    And def secondToken = response.token
    * print 'Second token obtained: ' + secondToken
    * match firstToken == secondToken

  Scenario: Invalid username and password
    * def user = testData.credentials.invalid
    Given path '/auth/login'
    And request { username: '#(user.username)', password: '#(user.password)', expiresInMins: 30}
    And header Content-Type = 'application/json'
    When method POST
    Then status 400
    And match response.message == "Invalid credentials"

  Scenario: Case-sensitive username
    * def user = testData.credentials.valid
    * def capitalizedUsername = (user.username.substring(0, 2).toUpperCase() + user.username.substring(2))
    * print 'Sending request with username: ' + capitalizedUsername
    Given path '/auth/login'
    And request { username: '#(capitalizedUsername)', password: '#(user.password)', expiresInMins: 30}
    And header Content-Type = 'application/json'
    When method POST
    Then status 200
    And match response contains { id: '#number', username: '#string', email: '#string', firstName: '#string', lastName: '#string', gender: '#string', image: '#string', token: '#string' }
    And match response.id == user.id
    And match response.username == user.username
    And match response.firstName == user.firstName
    And match response.lastName == user.lastName
    And assert response.token != null
    And assert response.token.length > 1

  Scenario Outline: Empty fields
    * def user = testData.credentials.valid
    Given path '/auth/login'
    And request { username: '<username>', password: '<password>', expiresInMins: 30}
    And header Content-Type = 'application/json'
    When method POST
    Then status 400
    And match response.message == "Invalid credentials"

    Examples:
      | username | password |
      | atuny0   |          |
      |          | 9uQFF1Lh |
      |          |          |

  
  Scenario Outline: Get/Refresh Current user auth token - Valid token
    * def user = testData.credentials.valid
    Given path '/auth/login'
    And request { username: '#(user.username)', password: '#(user.password)', expiresInMins: 30}
    And header Content-Type = 'application/json'
    When method POST
    Then status 200
    And def token = response.token
    Given path '/auth/<endpoint>'
    And header Authorization = `Bearer ` + token
    When method <method>
    Then status 200
    And match response.username  == user.username
    And match response.email  == user.email
    And match response.id  == user.id
    Examples:
      | endpoint | method |
      | me       | GET    |
      | refresh  | POST   |

  
  Scenario Outline: Get Current user auth token - Expired token
    * def user = testData.credentials.valid
    * def ZonedDateTime = Java.type('java.time.ZonedDateTime')
    * def Duration = Java.type('java.time.Duration')
    * def Thread = Java.type('java.lang.Thread')
    Given path '/auth/login'
    And request { username: '#(user.username)', password: '#(user.password)', expiresInMins: 1}
    And header Content-Type = 'application/json'
    When method POST
    Then status 200
    And def token = response.token
    * print "Waiting for 1.5 min"
    * Thread.sleep(90000)
    Given path '/auth/<endpoint>'
    And header Authorization = `Bearer ` + token
    When method <request>
    Then status 401
    And match response.name == "TokenExpiredError"
    And match response.message == "Token Expired!"
    * def expiredonTime = ZonedDateTime.parse(response.expiredAt)
    * def currentTime = ZonedDateTime.now()
    * def difference = Duration.between(currentTime, expiredonTime).abs().toMinutes()
    And assert difference <= 2
    Examples:
      | endpoint | request |
      | me       | GET     |
      | refresh  | POST    |

  
  Scenario Outline: Get/Refresh Current user auth token - Tampered token
    * def user = testData.credentials.valid
    * def reverseCase =
  """
    function(s) { return s.length < 3 ? s : s.substring(0, 2) + (s.charAt(2) == s.charAt(2).toUpperCase() ? s.charAt(2).toLowerCase() : s.charAt(2).toUpperCase()) + s.substring(3); }
  """
    Given path '/auth/login'
    And request { username: '#(user.username)', password: '#(user.password)', expiresInMins: 30}
    And header Content-Type = 'application/json'
    When method POST
    Then status 200
    And def token = response.token
    Given path '/auth/<endpoint>'
    And def modifiedToken = reverseCase(token)
    * print token
    * print modifiedToken
    And header Authorization = `Bearer ` + modifiedToken
    And method <request>
    Then status 500
    And match response.message == "invalid token"
    Examples:
      | endpoint | request |
      | me       | GET     |
      | refresh  | POST    |


  Scenario Outline: Get/Refresh Current user auth token - Invalid Signature
    Given path '/auth/<endpoint>'
    And def token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MzYsInVzZXJuYW1lIjoiamRvZSUyMDEyMyIsImVtYWlsIjoiamRvZUBleGFtcGxlLmNvbSIsImZpcnN0TmFtZSI6IkpvaG4iLCJsYXN0TmFtZSI6IkRvZSIsImdlbmRlciI6Im1hbGUiLCJpbWFnZSI6Imh0dHBzOi8vZXhhbXBsZS5jb20vam9obi5wbmciLCJpYXQiOjE3MTEyMTI3ODUsImV4cCI6MTcxMTIxNjM4NX0.9QjUhxNP3pFzZ7Rd8Kx_bZcbWqZa5w5tbW5kQ8ilZ-Q"
    And header Authorization = `Bearer ` + token
    When method <request>
    Then status 500
    And match response.message == "invalid signature"
    Examples:
      | endpoint | request |
      | me       | GET     |
      | refresh  | POST    |


  Scenario Outline: Get/Refresh Current user auth token - No token
    Given path '/auth/<endpoint>'
    When method <request>
    Then status 403
    And match response.message == "Authentication Problem"
    Examples:
      | endpoint | request |
      | me       | GET     |
      | refresh  | POST    |


  Scenario Outline: Get/Refresh Current user auth token - Invalid token - <token> - Endpoint <endpoint>
    Given path '/auth/<endpoint>'
    And def token = "<token>"
    And header Authorization = `Bearer ` + token
    When method GET
    Then status 401
    And match response.name == "JsonWebTokenError"
    And match response.message == "Invalid/Expired Token!"
    Examples:
      | endpoint | token | request |
      | me       |       | GET     |
      | me       | 1111  | GET     |
      | refresh  |       | POST    |
      | refresh  | 1111  | POST    |

