#include <DHT_U.h>
#include <DHT.h>
#include "BluetoothSerial.h"
#define triggerpin 2
#define echoPin 3
#define DHT11_PIN 4
#include <Arduino.h>

BluetoothSerial SerialBT;
DHT dht11(DHT11_PIN, DHT11);
float humi = dht11.readHumidity();
float tempC = dht11.readTemperature();
void setup() {
  dht11.begin();
  Serial.begin(115200);
  SerialBT.begin("SmartBlindStick"); // Bluetooth device name

  pinMode(triggerpin, OUTPUT);
  pinMode(echoPin, INPUT);
  
  delay(100);
}

void loop() {
  tempC = dht11.readTemperature();
  humi = dht11.readHumidity();
  digitalWrite(triggerpin, LOW);
  delayMicroseconds(2);
  digitalWrite(triggerpin, HIGH);
  delayMicroseconds(10);
  digitalWrite(triggerpin, LOW);

  long duration = pulseIn(echoPin, HIGH);
  float distance = duration * 0.034 / 2;

  Serial.print("D:");
  Serial.println(distance);
  Serial.print("T:");
  Serial.println(tempC);
  Serial.print("H:");
  Serial.println(humi);




  delay(500);
}