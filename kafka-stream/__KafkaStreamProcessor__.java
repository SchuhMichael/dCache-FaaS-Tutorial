package myapps;

import org.apache.kafka.common.serialization.Serde;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
//import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
//import org.apache.kafka.streams.Topology;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import java.util.Properties;
import org.apache.kafka.clients.producer.KafkaProducer;
//import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
//import org.apache.kafka.connect.json.JsonSerializer;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.KStreamBuilder;
import org.apache.kafka.streams.kstream.ForeachAction;
import org.apache.kafka.streams.kstream.KeyValueMapper;
import org.apache.kafka.streams.KeyValue;

import org.json.JSONException;
import org.json.JSONObject;

public class KafkaStreamProcessor {

public static void main(String[] args) throws JSONException {       
System.out.println("Welcome, you are running experimental Kafka Streaming for dCache");    
    Properties props = new Properties();
    props.put(StreamsConfig.APPLICATION_ID_CONFIG, "dcache");
    props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "__LOCAL_ADDRESS__:9099");
    props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest");

    final Serde < String > stringSerde = Serdes.String();

    
    Properties kafkaProperties = new Properties();
    kafkaProperties.put("key.serializer",
            "org.apache.kafka.common.serialization.StringSerializer");
    kafkaProperties.put("value.serializer",
            "org.apache.kafka.common.serialization.StringSerializer");
    kafkaProperties.put("bootstrap.servers", "localhost:9098");

    KafkaProducer<String, String> producer = new KafkaProducer<String, String>(kafkaProperties);

    KStreamBuilder builder = new KStreamBuilder();

    KStream<String, String> source = builder.stream(stringSerde, stringSerde, "billing");

    
    KStream<String, String> s1 = source.map(new KeyValueMapper<String, String, KeyValue<String, String>>() {
        @Override
        public KeyValue<String, String> apply(String dummy, String record) {
            JSONObject jsonObject;

            try {
                jsonObject = new JSONObject(record);
                if (!jsonObject.get("msgType").toString().equals("request") &&  jsonObject.get("isWrite").toString().equals("write")) {
                    if (jsonObject.get("transferPath").toString().endsWith(".dat")){
                    return new KeyValue<String,String>("WRITE", record);
                    }
                    else {
                        return new KeyValue<>("WRITE_OTHER", record);
                       }
                }
                else {
                   return new KeyValue<>("REQUEST_OR_ISWRITE_NEQ_WRITE", record);
                }
            } catch (JSONException e) {
                e.printStackTrace();
                return new KeyValue<>("REQUEST_OR_ISWRITE_UNDEF", record);
            }
        }
      });

    //s1.print();
      
	
    s1.foreach(new ForeachAction<String, String>() {
        @Override
        public void apply(String key, String value) {
            if (key.equals("WRITE")) {
                    ProducerRecord<String, String> data1 = new ProducerRecord<String, String>("billing-write", key, value);
                    producer.send(data1);
                }
        }
       
    });
        
    KafkaStreams streams = new KafkaStreams(builder, props);

    streams.start();

    System.out.println("Started KafkaStreams:");
    System.out.println(streams.toString());
    Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
        @Override
        public void run() {
          streams.close();
          //producer.close();
        }
      }));

}
}
