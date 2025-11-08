#include <config.hpp>
#include <mqtt_comm.hpp>
#include <sensors_actuators.hpp>

void setup() {
  Serial.begin(115200);

  analogReadResolution(12);
  sensors_init();

  network_mqtt_setup();
  delay(500);
}

void loop() {
  network_mqtt_loop();

  static unsigned long lastRead = 0;
  if (millis() - lastRead >= 1000) {

    float tempNow = read_temperature_c();
    float ec = read_ec(TDS_SENSOR_PIN, tempNow);
    float ph =
        read_ph(PH_SENSOR_PIN, PH_CALIBRATION_A, PH_CALIBRATION_B, tempNow);

    bool level0 = read_water_presence(LEVEL0_SENSOR_PIN);
    bool level1 = read_water_presence(LEVEL1_SENSOR_PIN);
    bool level2 = read_water_presence(LEVEL2_SENSOR_PIN);

    Serial.print("pH: ");
    Serial.print(ph);
    Serial.print(" | EC: ");
    Serial.print(ec);
    Serial.print(" | Temp: ");
    Serial.print(tempNow);
    Serial.print(" | Level0: ");
    Serial.print(level0);
    Serial.print(" | Level1: ");
    Serial.print(level1);
    Serial.print(" | Level2: ");
    Serial.print(level2);
    Serial.print(" | Pump: ");
    Serial.println(get_pump_state() ? "ON" : "OFF");
    mqtt_publish_sensors(ph, ec, tempNow, level0, level1, level2,
                         get_pump_state());
    lastRead = millis();
  }
}
