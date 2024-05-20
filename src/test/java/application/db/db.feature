@ignore
Feature: Test DB

  Scenario: Fetch values from DB
    * def config = { username: 'sa', password: '', url: 'jdbc:h2:tcp://localhost/~/test;DB_CLOSE_ON_EXIT=FALSE;AUTO_RECONNECT=TRUE', driver: 'org.h2.Driver' }
    * def DBUtils = Java.type('framework.DBUtils')
    * def DBValidator = Java.type('framework.DBValidator')
    * def db = new DBUtils(config)

    * def statenames = db.queryDB('SELECT * FROM Statenames')
    * print statenames