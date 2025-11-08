#pragma once
#include <DallasTemperature.h>
#include <OneWire.h>
#include <config.hpp>
#include <cstdint>
#include <math.h>
void sensors_init();

float read_ph(uint8_t pin, float a, float b, float temperature);
float read_ec(uint8_t pin, float temperature);
bool read_water_presence(uint8_t pin);
float read_temperature_c();
void set_pump(bool on);
bool get_pump_state();
void calibrate_ph(uint8_t pin);
