#include "./sensors.hpp"

#include <DallasTemperature.h>
#include <OneWire.h>

OneWire oneWire(TEMP_SENSOR_PIN);
DallasTemperature tempSensor(&oneWire);

bool bombaStatus = false;

void setup() {
  Serial.begin(115200);
  pinMode(23, OUTPUT);
  digitalWrite(23, HIGH);
  pinMode(TDS_SENSOR_PIN, INPUT);
  pinMode(PH_SENSOR_PIN, INPUT);
  pinMode(LEVEL0_SENSOR_PIN, INPUT);
  pinMode(LEVEL1_SENSOR_PIN, INPUT);
  pinMode(LEVEL2_SENSOR_PIN, INPUT);
  analogReadResolution(12);
  tempSensor.begin();
  delay(1000);
}
void loop() {
  float ph = read_ph(PH_SENSOR_PIN, PH_CALIBRATION_A, PH_CALIBRATION_B);

  tempSensor.requestTemperatures();
  float tempC = tempSensor.getTempCByIndex(0);
  float ec = read_ec(TDS_SENSOR_PIN, tempC);
  bool level0 = read_water_presence(LEVEL0_SENSOR_PIN);
  bool level1 = read_water_presence(LEVEL1_SENSOR_PIN);
  bool level2 = read_water_presence(LEVEL2_SENSOR_PIN);

  Serial.print("pH: ");
  Serial.print(ph);
  Serial.print(" | EC: ");
  Serial.print(ec);
  Serial.print(" | Temp: ");
  Serial.print(tempC);
  Serial.print(" | Level0: ");
  Serial.print(level0);
  Serial.print(" | Level1: ");
  Serial.print(level1);
  Serial.print(" | Level2: ");
  Serial.println(level2);

  delay(1000);

  static unsigned long lastMillis = 0;
  if (millis() - lastMillis >= 120000) {
    digitalWrite(23, bombaStatus ? LOW : HIGH);
    bombaStatus = !bombaStatus;
    Serial.print("Bomba: ");
    Serial.println(bombaStatus ? "OFF" : "ON");
    lastMillis = millis();
  }
}
