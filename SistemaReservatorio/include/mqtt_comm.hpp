#pragma once
#include <ArduinoJson.h>
#include <PubSubClient.h>
#include <WiFi.h>

void network_mqtt_setup();

void network_mqtt_loop();

bool mqtt_publish_sensors(float ph, float ec, float tempC, bool level0,
                          bool level1, bool level2, bool pumpOn);
