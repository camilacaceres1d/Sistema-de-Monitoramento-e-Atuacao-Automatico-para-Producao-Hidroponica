#include <config.hpp>
#include <mqtt_comm.hpp>
#include <sensors_actuators.hpp>

double flow = 0;

void setup() {
  Serial.begin(115200);

  sensors_init();

  network_mqtt_setup();
  delay(500);
}

void loop() {
  network_mqtt_loop();

  static unsigned long lastRead = 0;

  read_water_flow(flow);
  if (millis() - lastRead >= 15000) {

    float airTemp, airHumidity;

    read_air_quality(airTemp, airHumidity);

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
