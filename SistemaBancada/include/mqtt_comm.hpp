#pragma once
#include <ArduinoJson.h>
#include <PubSubClient.h>
#include <WiFi.h>

void network_mqtt_setup();

void network_mqtt_loop();

bool mqtt_publish_sensors(double water_flow, float air_temp, float air_humidity,
                          bool light_state);
