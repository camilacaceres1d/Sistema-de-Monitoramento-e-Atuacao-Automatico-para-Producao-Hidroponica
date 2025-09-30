#include "./sensors.hpp"

float read_ph(uint8_t pin, float a, float b);
float read_ec(uint8_t pin, float temperature);

void setup() {
  Serial.begin(115200);
  pinMode(TdsSensorPin, INPUT);
  analogReadResolution(12);
  delay(500);
}

void loop() {

  float ph = read_ph(32, PH_CALIBRATION_A, PH_CALIBRATION_B);
  float ec = read_ec(27, 20);

  Serial.print("pH: ");
  Serial.println(ph, 2);

  Serial.print("ec: ");
  Serial.println(ec, 2);

  delay(1000);
}
