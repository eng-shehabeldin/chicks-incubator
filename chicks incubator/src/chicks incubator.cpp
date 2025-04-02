#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include <BH1750.h>
#include <Wire.h>
#include "esp_camera.h"

#define DHTPIN 4
#define DHTTYPE DHT22
#define MQ135_PIN 34
#define FAN_PIN 5
#define HEATER_PIN 18

// Camera Pins for ESP32-CAM (AI-Thinker model)
#define PWDN_GPIO -1
#define RESET_GPIO -1
#define XCLK_GPIO 0
#define SIOD_GPIO 26
#define SIOC_GPIO 27
#define Y9_GPIO 35
#define Y8_GPIO 34
#define Y7_GPIO 39
#define Y6_GPIO 36
#define Y5_GPIO 21
#define Y4_GPIO 19
#define Y3_GPIO 18
#define Y2_GPIO 5
#define VSYNC_GPIO 25
#define HREF_GPIO 23
#define PCLK_GPIO 22

const char* ssid = "Your_SSID";
const char* password = "Your_PASSWORD";
const char* serverUrl = "http://your-flutter-app.com/update";

DHT dht(DHTPIN, DHTTYPE);
BH1750 lightMeter;

// Function declarations
void controlTemperature(float temp);
void sendDataToServer(float temp, float hum, float light, int gas);
void startCameraServer();

void setup() {
    Serial.begin(115200);
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(1000);
        Serial.println("Connecting to WiFi...");
    }
    Serial.println("Connected to WiFi");
    
    dht.begin();
    Wire.begin();
    lightMeter.begin();
    
    pinMode(FAN_PIN, OUTPUT);
    pinMode(HEATER_PIN, OUTPUT);

    // Initialize camera
    camera_config_t config;
    config.ledc_channel = LEDC_CHANNEL_0;
    config.ledc_timer = LEDC_TIMER_0;
    config.pin_d0 = Y2_GPIO;
    config.pin_d1 = Y3_GPIO;
    config.pin_d2 = Y4_GPIO;
    config.pin_d3 = Y5_GPIO;
    config.pin_d4 = Y6_GPIO;
    config.pin_d5 = Y7_GPIO;
    config.pin_d6 = Y8_GPIO;
    config.pin_d7 = Y9_GPIO;
    config.pin_xclk = XCLK_GPIO;
    config.pin_pclk = PCLK_GPIO;
    config.pin_vsync = VSYNC_GPIO;
    config.pin_href = HREF_GPIO;
    config.pin_sscb_sda = SIOD_GPIO;
    config.pin_sscb_scl = SIOC_GPIO;
    config.pin_pwdn = PWDN_GPIO;
    config.pin_reset = RESET_GPIO;
    config.xclk_freq_hz = 20000000;
    config.pixel_format = PIXFORMAT_JPEG;
    config.frame_size = FRAMESIZE_QVGA;
    config.jpeg_quality = 10;
    config.fb_count = 2;
    
    if (esp_camera_init(&config) != ESP_OK) {
        Serial.println("Camera initialization failed");
        return;
    }
    
    startCameraServer();
    Serial.println("Camera streaming started");
}

void loop() {
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    float lightIntensity = lightMeter.readLightLevel();
    int gasLevel = analogRead(MQ135_PIN);

    if (isnan(temperature) || isnan(humidity)) {
        Serial.println("Failed to read from DHT sensor!");
        return;
    }
    
    controlTemperature(temperature);
    sendDataToServer(temperature, humidity, lightIntensity, gasLevel);
    delay(5000);
}

void controlTemperature(float temp) {
    float tempThresholdHigh = 37.5;
    float tempThresholdLow = 35.5;
    
    if (temp > tempThresholdHigh) {
        digitalWrite(FAN_PIN, HIGH);
        digitalWrite(HEATER_PIN, LOW);
    } else if (temp < tempThresholdLow) {
        digitalWrite(FAN_PIN, LOW);
        digitalWrite(HEATER_PIN, HIGH);
    } else {
        digitalWrite(FAN_PIN, LOW);
        digitalWrite(HEATER_PIN, LOW);
    }
}

void sendDataToServer(float temp, float hum, float light, int gas) {
    if (WiFi.status() == WL_CONNECTED) {
        HTTPClient http;
        http.begin(serverUrl);
        http.addHeader("Content-Type", "application/json");

        String jsonPayload = "{";
        jsonPayload += "\"temperature\":" + String(temp) + ",";
        jsonPayload += "\"humidity\":" + String(hum) + ",";
        jsonPayload += "\"lightIntensity\":" + String(light) + ",";
        jsonPayload += "\"gasLevel\":" + String(gas);
        jsonPayload += "}";

        int httpResponseCode = http.POST(jsonPayload);
        if (httpResponseCode > 0) {
            Serial.println("Data sent successfully");
        } else {
            Serial.println("Error sending data");
        }
        http.end();
    }
}
