package framework;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DBUtils {
    public static String Driver = "org.h2.Driver";
    private static String ConnUrl = "jdbc:h2:tcp://localhost/~/test;DB_CLOSE_ON_EXIT=FALSE;AUTO_RECONNECT=TRUE";
    private static String Username = "sa";
    private static String Password = "";

    public DBUtils() {

    }

    public DBUtils(Map<String, String> config) {
        Driver = config.get("driver");
        ConnUrl = config.get("url");
        Username = config.get("username");
        Password = config.get("password");
    }

    private Connection connectDB() {
        Connection conn = null;
        try {
            Class.forName(Driver);
            conn = DriverManager.getConnection(ConnUrl, Username, Password);
            return conn;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return conn;
    }

    public boolean rowExists(String tableName, String criteriaColumn, Object criteriaValue) {
        String sql = "SELECT COUNT(*) AS row_count FROM " + tableName + " WHERE " + criteriaColumn + " = ?";
        try {
            Connection conn = connectDB();
            if (conn != null) {
                PreparedStatement pstmt = conn.prepareStatement(sql);
                pstmt.setObject(1, criteriaValue);
                ResultSet res = pstmt.executeQuery();
                if (res.next()) {
                    int rowCount = res.getInt("row_count");
                    return rowCount > 0;
                }
                conn.close();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public List<HashMap<String, Object>> queryDB(String sql) {
        Connection conn = connectDB();
        List<HashMap<String, Object>> resultList = new ArrayList<>();
        try {
            if (conn != null) {
                PreparedStatement pstmt = conn.prepareStatement(sql);
                ResultSet res = pstmt.executeQuery();
                ResultSetMetaData metaData = res.getMetaData();
                int columnCount = metaData.getColumnCount();
                while (res.next()) {
                    HashMap<String, Object> rowMap = new HashMap<>();
                    for (int i = 1; i <= columnCount; i++) {
                        String columnName = metaData.getColumnName(i);
                        Object columnValue = res.getObject(i);
                        rowMap.put(columnName, columnValue);
                    }
                    resultList.add(rowMap);
                }
                conn.close();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return resultList;
    }

    public void modifyDB(String sql) {
        Connection conn = connectDB();
        try {
            if (conn != null) {
                Statement stmt = conn.createStatement();
                stmt.execute(sql);
                stmt.close();
                conn.close();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) throws SQLException {
        // test the methods here
        DBUtils util = new DBUtils();
        System.out.println(util.rowExists("statenames", "first_name", "aaa"));
    }
}