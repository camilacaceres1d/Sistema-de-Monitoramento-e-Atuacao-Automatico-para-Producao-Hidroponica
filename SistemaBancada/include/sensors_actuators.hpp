#pragma once
#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <DHT_U.h>
#include <config.hpp>
void sensors_init();

void read_water_flow(double &flow);
void read_air_quality(float &temperature, float &humidity);
void set_light(bool on);
bool get_light_state();
