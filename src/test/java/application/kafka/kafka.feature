@ignore
Feature: Test Kafka
  Scenario: Kafka
    * def config = { bootstrapServers: 'localhost:9093', topic: 'test-topic', groupID: 'test-group', resetConfig: 'latest'
    * def KafkaUtils = Java.type('framework.KafkaUtils')
    * def messagesLastXSeconds = KafkaUtils.readMessages(12*1000)
    * def fn =
    """
    const hasId123 = messagesLastXSeconds.some(jsonString => JSON.parse(jsonString).id === "123");
    """
