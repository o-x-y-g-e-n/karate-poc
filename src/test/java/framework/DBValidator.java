package framework;

import java.util.HashMap;
import java.util.List;

public class DBValidator {
    // Asserts that the response matches a single row from the database
    public static boolean assertResponseMatchesRow(HashMap<String, Object> response, HashMap<String, Object> dbRow) {
        return response.equals(dbRow);
    }

    // Asserts that the response matches a list of rows from the database
    public static boolean assertResponseMatchesRows(List<HashMap<String, Object>> response, List<HashMap<String, Object>> dbRows) {
        return response.containsAll(dbRows) && dbRows.containsAll(response);
    }
}
