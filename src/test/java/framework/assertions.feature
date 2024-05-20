@ignore
Feature:

  Scenario:
    * def compareValues =
    """
    function(actual, expected) {
          karate.log('Comparison - Expected: ' + expected + ', Actual: ' + actual);
          if (actual !== expected) {
            karate.log('Assertion failed for ' +  ': Expected [' + expected + '] but found [' + actual + ']');
            throw 'AssertionError: Mismatch ' + ': Expected [' + expected + '] but found [' + actual + ']';
          }
    }
   """