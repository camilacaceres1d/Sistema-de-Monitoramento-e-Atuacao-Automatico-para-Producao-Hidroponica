#include <mqtt_comm.hpp>
#include <sensors_actuators.hpp>

static WiFiClient wifiClient;
static PubSubClient mqttClient(wifiClient);

static void ensureWifiConnected() {
  if (WiFi.status() == WL_CONNECTED)
    return;
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 15000) {
    delay(250);
  }
}

static void mqttCallback(char *topic, byte *payload, unsigned int length) {
  String message;
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  JsonDocument doc;
  DeserializationError err = deserializeJson(doc, message);
  if (err) {
    Serial.print("Erro ao desserializar comando MQTT: ");
    Serial.println(err.f_str());
    return;
  }

  Serial.println("Comando MQTT recebido:");
  serializeJsonPretty(doc, Serial);

  String atuador = doc["atuador"];
  if (!atuador) {
    Serial.println("Comando MQTT inválido: atuador ausente");
    return;
  }

  bool value = false;
  if (doc["valor"].is<bool>()) {
    value = doc["valor"].as<bool>();
  }

  if (atuador == "luz") {
    set_light(value);
  }
}

static void ensureMqttConnected() {
  if (mqttClient.connected())
    return;

  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  mqttClient.setServer(MQTT_HOST, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);

  String clientId = String("bench-") + WiFi.macAddress();
  for (int i = 0; i < 3 && !mqttClient.connected(); ++i) {
    mqttClient.connect(clientId.c_str(), MQTT_USER, MQTT_PASSWORD);
    if (!mqttClient.connected())
      delay(500);
  }

  if (mqttClient.connected()) {
    String topic = String("bench/") + WiFi.macAddress() + "/commands";
    mqttClient.subscribe(topic.c_str());
  }
}

void network_mqtt_setup() {
  ensureWifiConnected();
  ensureMqttConnected();
}

void network_mqtt_loop() {
  if (WiFi.status() != WL_CONNECTED) {
    ensureWifiConnected();
  }
  if (!mqttClient.connected()) {
    ensureMqttConnected();
  } else {
    mqttClient.loop();
  }
}

bool mqtt_publish_sensors(double flow, float airTemp, float airHumidity,
                          bool lightState) {
  if (!mqttClient.connected())
    return false;

  JsonDocument doc;
  doc["flow"] = flow;
  doc["air_temp"] = airTemp;
  doc["air_humidity"] = airHumidity;
  doc["light"] = lightState;
  doc["ts"] = millis();

  char out[512];
  size_t n = serializeJson(doc, out, sizeof(out));
  if (n == 0)
    return false;

  String publishTopic = String("bench/") + WiFi.macAddress() + "/sensors";
  return mqttClient.publish(publishTopic.c_str(), (const uint8_t *)out, n,
                            false);
}
