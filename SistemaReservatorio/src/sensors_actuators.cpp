#include <sensors_actuators.hpp>

static bool pumpOn = false;

static OneWire oneWire(TEMP_SENSOR_PIN);
static DallasTemperature tempSensor(&oneWire);
static float lastValidTempC = NAN;

void sensors_init() {
  tempSensor.begin();

  pinMode(PH_SENSOR_PIN, INPUT);
  pinMode(TDS_SENSOR_PIN, INPUT);
  pinMode(LEVEL0_SENSOR_PIN, INPUT);
  pinMode(LEVEL1_SENSOR_PIN, INPUT);
  pinMode(LEVEL2_SENSOR_PIN, INPUT);
  pinMode(PUMP_PIN, OUTPUT);
  digitalWrite(PUMP_PIN, HIGH); // HIGH é OFF e LOW é ON
}

int ph_buffer[PH_MEASURE_COUNT];
float read_ph(uint8_t pin, float a, float b) {

  for (int i = 0; i < PH_MEASURE_COUNT; i++) {
    ph_buffer[i] = analogRead(pin);
  }

  for (int i = 0; i < PH_MEASURE_COUNT - 1; i++) {
    for (int j = i + 1; j < PH_MEASURE_COUNT; j++) {
      if (ph_buffer[i] > ph_buffer[j]) {
        int temp = ph_buffer[i];
        ph_buffer[i] = ph_buffer[j];
        ph_buffer[j] = temp;
      }
    }
  }

  int start = PH_MEASURE_COUNT / 4;
  int end = (PH_MEASURE_COUNT * 3) / 4;
  int countUsed = end - start;
  long sum = 0;
  if (countUsed > 0) {
    for (int i = start; i < end; ++i)
      sum += ph_buffer[i];
  } else {
    countUsed = PH_MEASURE_COUNT;
    for (int i = 0; i < PH_MEASURE_COUNT; ++i)
      sum += ph_buffer[i];
  }

  float avgAdc = (float)sum / (float)countUsed;
  float m = (avgAdc * VREF) / 4095.0f;

  float ph = a * m + b; // reta do pH

  return ph;
}

int ec_buffer[EC_MEASURE_COUNT];
float read_ec(uint8_t pin, float temperature) {

  for (int i = 0; i < EC_MEASURE_COUNT; i++) {
    ec_buffer[i] = analogRead(pin);
    delay(5);
  }

  for (int j = 0; j < EC_MEASURE_COUNT - 1; j++) {
    for (int i = 0; i < EC_MEASURE_COUNT - j - 1; i++) {
      if (ec_buffer[i] > ec_buffer[i + 1]) {
        int tmp = ec_buffer[i];
        ec_buffer[i] = ec_buffer[i + 1];
        ec_buffer[i + 1] = tmp;
      }
    }
  }

  int start = EC_MEASURE_COUNT / 4;
  int end = (EC_MEASURE_COUNT * 3) / 4;
  int countUsed = end - start;
  long sum = 0;
  if (countUsed > 0) {
    for (int i = start; i < end; ++i)
      sum += ec_buffer[i];
  } else {
    countUsed = EC_MEASURE_COUNT;
    for (int i = 0; i < EC_MEASURE_COUNT; ++i)
      sum += ec_buffer[i];
  }

  float avgAdc = (float)sum / (float)countUsed;
  float voltage = avgAdc * (VREF / 4095.0f);

  if (isnan(temperature)) {
    temperature = 25.0f;
  }
  float coeff = 1.0 + 0.02 * (temperature - 25.0);
  float compVoltage = voltage / coeff;

  return (133.42 * compVoltage * compVoltage * compVoltage -
          255.86 * compVoltage * compVoltage + 857.39 * compVoltage) *
         0.5;
}

bool read_water_presence(uint8_t pin) { return digitalRead(pin) == HIGH; }

float read_temperature_c() {
  tempSensor.requestTemperatures();
  delay(50);
  float t = tempSensor.getTempCByIndex(0);
  if (t == DEVICE_DISCONNECTED_C) {
    Serial.println("Erro: Sensor de temperatura desconectado!");
    return lastValidTempC;
  }
  lastValidTempC = t;
  return t;
}

void set_pump(bool on) {
  pumpOn = on;
  Serial.print("Set pump: ");
  Serial.println(on ? "ON" : "OFF");
  digitalWrite(PUMP_PIN, on ? LOW : HIGH);
}

bool get_pump_state() { return pumpOn; }
