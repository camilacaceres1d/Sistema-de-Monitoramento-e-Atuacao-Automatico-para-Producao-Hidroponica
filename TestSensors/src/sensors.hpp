
#include <Arduino.h>
#include <cstdint>
#define PH_CALIBRATION_A -4.2537
#define PH_CALIBRATION_B 17.4943
#define PH_SENSOR_PIN 32
#define TDS_SENSOR_PIN 33
#define LEVEL0_SENSOR_PIN 21
#define LEVEL1_SENSOR_PIN 25
#define LEVEL2_SENSOR_PIN 35
#define TEMP_SENSOR_PIN 27
#define VREF 3.3
#define SCOUNT 30

float read_ph(uint8_t pin, float a, float b);
float read_ec(uint8_t pin, float temperature);
bool read_water_presence(uint8_t pin);
