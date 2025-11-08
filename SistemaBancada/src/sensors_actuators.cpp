#include "Adafruit_Sensor.h"
#include "config.hpp"
#include <sensors_actuators.hpp>

static bool lightOn = false;

DHT_Unified dht(AIR_QUALITY_SENSOR_PIN, DHTTYPE);

volatile int counter_water_flow = 0;
double water_flow = 0.0;

void IRAM_ATTR flow_pulse_counter() { counter_water_flow++; }

void sensors_init() {
  dht.begin();
  pinMode(LIGHT_PIN, OUTPUT);
  pinMode(AIR_QUALITY_SENSOR_PIN, INPUT);
  pinMode(WATER_FLOW_SENSOR_PIN, INPUT);
  set_light(false);

  attachInterrupt(digitalPinToInterrupt(WATER_FLOW_SENSOR_PIN),
                  flow_pulse_counter, RISING);
}

void read_water_flow(double &flow) {
  static unsigned long last_time = 0;
  unsigned long current_time = millis();
  if (current_time - last_time >= 1000) {
    noInterrupts();
    int pulse_count = counter_water_flow;
    counter_water_flow = 0;
    interrupts();

    water_flow = (pulse_count / WATER_FLOW_CALIBRATION_FACTOR);
    last_time = current_time;
  }
  flow = water_flow;
}

void read_air_quality(float &temperature, float &humidity) {
  sensors_event_t event;
  dht.temperature().getEvent(&event);
  if (!isnan(event.temperature)) {
    temperature = event.temperature;
  } else {
    temperature = NAN;
  }
  dht.humidity().getEvent(&event);
  if (!isnan(event.relative_humidity)) {
    humidity = event.relative_humidity;
  } else {
    humidity = NAN;
  }
}
void set_light(bool on) {
  lightOn = on;
  digitalWrite(LIGHT_PIN, on ? LOW : HIGH);
}

bool get_light_state() { return lightOn; }
