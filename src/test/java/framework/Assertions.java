package framework;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static org.junit.Assert.assertTrue;

public class Assertions {

    private static final Logger logger = LoggerFactory.getLogger(Assertions.class);

    /**
     * Asserts that two objects are equal with a custom error message.
     *
     * @param actual       the actual value
     * @param expected     the expected value
     */
    public static void assertEquals(Object actual, Object expected) {
        try {
            if (!actual.equals(expected)) {
                String errorMessage = String.format("Assertion failed: Expected [%s] but found [%s]", expected, actual);
                logger.error(errorMessage);
                throw new AssertionError(errorMessage);
            } else {
                logger.info("Assertion successful: Expected [{}] matches Actual [{}]", expected, actual);
            }
        } catch (Exception e) {
            String errorMessage = String.format("Error during assertion: %s", e.getMessage());
            logger.error(errorMessage);
            throw new AssertionError(errorMessage, e);
        }
    }

    /**
     * Asserts that a String object is not null or empty. If the object is null or empty,
     * an AssertionError is thrown. The method also logs the result of the assertion.
     *
     * @param scenarioName the current running scenario
     * @param string       the String object to check for nullity or emptiness
     */
    public static void assertNotNullOrEmpty(String scenarioName, String string) {
        scenarioName = "<<" + scenarioName + ">>";
        String className = "String";
        String successMessage = "Assertion passed - Object of type " + className + " is not null and not empty.";
        String errorMessage = "Assertion failed - Object of type " + className + " is null or empty.";

        if (string == null || string.isEmpty()) {
            logger.error(errorMessage);
        } else {
            logger.info(successMessage);
        }
        assertTrue(scenarioName + " - " + errorMessage, string != null && !string.isEmpty());
    }
}
