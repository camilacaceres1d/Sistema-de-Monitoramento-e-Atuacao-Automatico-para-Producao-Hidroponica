#include <config.hpp>
#include <mqtt_comm.hpp>
#include <sensors_actuators.hpp>

void setup() {
  Serial.begin(115200);

  sensors_init();

  network_mqtt_setup();
  delay(500);
}

void loop() {
  network_mqtt_loop();

  static unsigned long lastRead = 0;
  if (millis() - lastRead >= 5000) {

    float airTemp, airHumidity;
    double flow;

    read_air_quality(airTemp, airHumidity);
    read_water_flow(flow);

    Serial.print("Water Flow: ");
    Serial.print(flow);
    Serial.print(" L/min, Air Temp: ");
    Serial.print(airTemp);
    Serial.print(" °C, Air Humidity: ");
    Serial.print(airHumidity);
    Serial.println(" %");
    mqtt_publish_sensors(flow, airTemp, airHumidity, get_light_state());

    lastRead = millis();
  }
}
