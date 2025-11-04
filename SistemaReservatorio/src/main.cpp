#include <config.hpp>
#include <sensors_actuators.hpp>

void setup() {
  Serial.begin(115200);

  analogReadResolution(12);
  sensors_init();

  delay(500);
}

void loop() {

  static unsigned long lastRead = 0;
  if (millis() - lastRead >= 5000) {

    float ph = read_ph(PH_SENSOR_PIN, PH_CALIBRATION_A, PH_CALIBRATION_B);

    float tempNow = read_temperature_c();
    float tempForEC = tempNow;
    float ec = read_ec(TDS_SENSOR_PIN, tempForEC);

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
    lastRead = millis();
  }
}
