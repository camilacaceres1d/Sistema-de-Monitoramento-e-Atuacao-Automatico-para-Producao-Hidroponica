#include "./sensors.hpp"
#include <cstdint>

int buf[10];

float read_ph(uint8_t pin, float a, float b) {

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

  return ph;
}

float read_ec(uint8_t pin, float temperature) {
  int buffer[SCOUNT];

  for (int i = 0; i < SCOUNT; i++) {
    buffer[i] = analogRead(pin);
    delay(5);
  }

  for (int j = 0; j < SCOUNT - 1; j++) {
    for (int i = 0; i < SCOUNT - j - 1; i++) {
      if (buffer[i] > buffer[i + 1]) {
        int tmp = buffer[i];
        buffer[i] = buffer[i + 1];
        buffer[i + 1] = tmp;
      }
    }
  }
  int median = (SCOUNT & 1) ? buffer[SCOUNT / 2]
                            : (buffer[SCOUNT / 2] + buffer[SCOUNT / 2 - 1]) / 2;

  float voltage = median * (VREF / 1024.0);

  float coeff = 1.0 + 0.02 * (temperature - 25.0);
  float compVoltage = voltage / coeff;

  return (133.42 * compVoltage * compVoltage * compVoltage -
          255.86 * compVoltage * compVoltage + 857.39 * compVoltage) *
         0.5;
}
