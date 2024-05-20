package framework;

import org.apache.kafka.clients.consumer.*;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.PartitionInfo;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.time.Duration;

import org.apache.kafka.clients.producer.KafkaProducer;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

public class KafkaUtils {
    private final String bootstrapServers;
    private final String topic;

    public KafkaUtils(String bootstrapServers, String topic) {
        this.bootstrapServers = bootstrapServers;
        this.topic = topic;
    }

    public void produceMessages(long xSeconds) throws ExecutionException, InterruptedException {
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());

        int messagesInTopic = 100;
        KafkaProducer<String, String> producer = new KafkaProducer<>(props);
        for (int i = 0; i < messagesInTopic; i++) {
            producer.send(new ProducerRecord(topic, null, "a", String.valueOf(i))).get();
        }
    }

    public List<String> readMessages(long secondsAgo) {
        String bootstrapServers = "localhost:9093";

        Properties properties = new Properties();
        properties.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        properties.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        properties.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        properties.put(ConsumerConfig.GROUP_ID_CONFIG, "test-group");
        properties.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest");

        KafkaConsumer<String, String> consumer = new KafkaConsumer<>(properties);

        // Get all partitions for the topic
        List<PartitionInfo> partitions = consumer.partitionsFor(topic);
        List<TopicPartition> topicPartitions = partitions.stream()
                .map(partitionInfo -> new TopicPartition(topic, partitionInfo.partition()))
                .collect(Collectors.toList());

        // Assign partitions to the consumer
        consumer.assign(topicPartitions);

        // Calculate the timestamp X seconds ago
        long fetchTime = Instant.now().minusSeconds(secondsAgo).toEpochMilli();

        // Create a map with the timestamps for each partition
        Map<TopicPartition, Long> timestampsToSearch = topicPartitions.stream()
                .collect(Collectors.toMap(tp -> tp, tp -> fetchTime));

        // Find the offsets for the calculated timestamps
        Map<TopicPartition, OffsetAndTimestamp> offsetsForTimes = consumer.offsetsForTimes(timestampsToSearch);

        // Seek to the calculated offsets for each partition
        for (Map.Entry<TopicPartition, OffsetAndTimestamp> entry : offsetsForTimes.entrySet()) {
            TopicPartition partition = entry.getKey();
            OffsetAndTimestamp offsetAndTimestamp = entry.getValue();
            if (offsetAndTimestamp != null) {
                consumer.seek(partition, offsetAndTimestamp.offset());
            } else {
                // If no offset is found for the timestamp, seek to the end
                consumer.seekToEnd(Collections.singletonList(partition));
            }
        }

        List<String> messages = new ArrayList<>();
        // Fetch the records and filter by timestamp
        boolean continueFetching = true;
        while (continueFetching) {
            ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(1000));
            if (records.isEmpty()) {
                continueFetching = false;
            } else {
                for (ConsumerRecord<String, String> record : records) {
                    if (record.timestamp() >= fetchTime) {
                        System.out.printf("Consumed record from partition %d with key %s and value %s%n",
                                record.partition(), record.key(), record.value());
                        messages.add(record.value());
                    }
                }
                return messages;
            }
        }
        consumer.close();
        return messages;
    }

    public List<String> consumeMessages(int lastXMessages) {
        Properties props = new Properties();
        props.put("bootstrap.servers", bootstrapServers);
        props.put("group.id", "my-group");
        props.put("enable.auto.commit", "true");
        props.put("auto.commit.interval.ms", "1000");
        props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");


        KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);

        // Get all partitions for the topic
        List<PartitionInfo> partitions = consumer.partitionsFor(topic);
        List<TopicPartition> topicPartitions = partitions.stream()
                .map(partitionInfo -> new TopicPartition(topic, partitionInfo.partition()))
                .collect(Collectors.toList());

        // Assign partitions to the consumer
        consumer.assign(topicPartitions);

        // Seek to the appropriate offsets for each partition
        Map<TopicPartition, Long> endOffsets = consumer.endOffsets(topicPartitions);
        for (TopicPartition partition : topicPartitions) {
            long endOffset = endOffsets.get(partition);
            long startOffset = Math.max(0, endOffset - lastXMessages); // Ensure startOffset is not negative
            consumer.seek(partition, startOffset);
        }

        // Fetch the records from each partition
        List<String> messages = new ArrayList<>();
        boolean continueFetching = true;
        while (continueFetching) {
            ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
            if (records.isEmpty()) {
                continueFetching = false;
            } else {
                records.forEach(record -> {
                    System.out.printf("Consumed record from partition %d with key %s and value %s%n",
                            record.partition(), record.key(), record.value());
                    messages.add(record.value());
                });
                return messages;
            }
        }

        consumer.close();
        return messages;
    }

    public static void main(String[] args)  {
        String bootstrapServers = "localhost:9093";
        String topic = "test-topic";
        KafkaUtils kafkaUtility = new KafkaUtils(bootstrapServers, topic);
        List<String> messages = kafkaUtility.readMessages(60);
        System.out.println(messages);
        List<String> messages1 = kafkaUtility.consumeMessages(100);
        System.out.println(messages1);
    }
}