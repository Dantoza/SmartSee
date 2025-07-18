#include <Arduino.h>
#include <DHT_U.h>
#include <DHT.h>
#include "BluetoothSerial.h"

// Pin definitions
#define TRIGGER_PIN 4
#define ECHO_PIN 5
#define DHT_PIN 15
#define MOISTURE_PIN 13

// Global objects
BluetoothSerial SerialBT;
DHT dht11(DHT_PIN, DHT11);

// Global variables
float humidity = 0;
float temperature = 0;
float moisture = 0;
float distance = 0;
int onoff = 1;        // System on/off state
int emergency = 0;    // Emergency state
float speed = 0.00;
void setup() {
  // Initialize DHT sensor first
  dht11.begin();
  
  // Initialize Serial communication
  Serial.begin(115200);
  
  // Initialize Bluetooth communication
  SerialBT.begin("SmartBlindStick");

  // Configure pins
  pinMode(TRIGGER_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(MOISTURE_PIN, INPUT);
  
  // Give time for Bluetooth to initialize
  delay(1000);
}

void loop() {
  if (onoff == 1) {
    // Read moisture sensor
    pinMode(MOISTURE_PIN, INPUT);
    moisture = analogRead(MOISTURE_PIN);
    
    // Read temperature and humidity
    temperature = dht11.readTemperature();
    humidity = dht11.readHumidity();
    
    // Read ultrasonic sensor
    digitalWrite(TRIGGER_PIN, LOW);
    delayMicroseconds(2);
    digitalWrite(TRIGGER_PIN, HIGH);
    delayMicroseconds(10);
    digitalWrite(TRIGGER_PIN, LOW);

    long duration = pulseIn(ECHO_PIN, HIGH);
    distance = duration * 0.034 / 2;
    
    SerialBT.println("D:" + String(distance));
    SerialBT.println("T:" + String(temperature));
    SerialBT.println("H:" + String(humidity));
    SerialBT.println("M:" + String(moisture));
    SerialBT.println("S:" + String(speed));
    SerialBT.println("E:"+String(emergency));
    
  
     
    
    
    // Convert sensor readings to binary values
    if (distance > 20) {
      distance = 1;
    } else {
      distance = 0;
    }
    
    if (temperature > 30) {
      temperature = 1;
    } else {
      temperature = 0;
    }
    
    if (humidity > 60) {
      humidity = 1;
    } else {
      humidity = 0;
    }
    
    if (moisture < 1600) {
      moisture = 1;
    } else {
      moisture = 0;
    }
    Serial.println("D:" + String(distance));
    Serial.println("T:" + String(temperature));
    Serial.println("H:" + String(humidity));
    Serial.println("M:" + String(moisture));
    Serial.println("S:" + String(speed));
  }
  // Handle serial and Bluetooth commands
  String inputString = "";
  
    // Check for commands from Serial
    if (Serial.available()) {
      inputString = Serial.readStringUntil('\n');
      inputString.trim();
      
      if (inputString.startsWith("E:")) {
        emergency = inputString.substring(2).toInt();
      } else if (inputString.startsWith("P:")) {
        onoff = inputString.substring(2).toInt();
      } else if (inputString.startsWith("S:")) {
        speed = inputString.substring(2).toFloat();
      }
    }
  
  // Handle system state
  switch (onoff) {
    case 1:
      digitalWrite(TRIGGER_PIN, HIGH);
      pinMode(ECHO_PIN, INPUT);
      pinMode(MOISTURE_PIN, INPUT);
      dht11.begin();
      break;
      
    case 2:
      digitalWrite(TRIGGER_PIN, LOW);
      pinMode(ECHO_PIN, INPUT);
      pinMode(MOISTURE_PIN, INPUT);
      dht11.~DHT();
      break;
   
    default:
      onoff = 1;
      break;
  }
  


  delay(500);
}