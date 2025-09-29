#include <Arduino.h>

const float a = -4.2537;
const float b = 17.4943;

int buf[10];

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
  delay(500);
}

void loop() {
  for (int i = 0; i < 10; i++) {
    buf[i] = analogRead(32);
    delay(10);
  }

  for (int i = 0; i < 9; i++) {
    for (int j = i + 1; j < 10; j++) {
      if (buf[i] > buf[j]) {
        int temp = buf[i];
        buf[i] = buf[j];
        buf[j] = temp;
      }
    }
  }

  int valorMedio = 0;
  for (int i = 2; i < 8; i++) {
    valorMedio += buf[i];
  }

  float m = (valorMedio * 3.3) / 4095.0 / 6;

  float ph = a * m + b; // reta do pH

  Serial.print("Tensão: ");
  Serial.print(m, 3);
  Serial.print("V");

  Serial.print(" | pH: ");
  Serial.println(ph, 2);

  delay(1000);
}
