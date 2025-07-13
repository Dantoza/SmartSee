#include <Arduino.h>
#include <DHT_U.h>
#include <DHT.h>
#include "BluetoothSerial.h"

#define triggerpin 4
#define echoPin 2
#define dhtPin 15
#define moisturePin 13

BluetoothSerial SerialBT;
DHT dht11(dhtPin, DHT11);
float humi = dht11.readHumidity();
float tempC = dht11.readTemperature();
float moisture = analogRead(moisturePin);
int onoff = 1; // Initialize return info variable
float distance = 0; // Initialize distance variable
int Emergency = 0; // Initialize emergency variable

void setup() {
  Serial.begin(115200); // Initialize Serial communication

   // Bluetooth device name

  pinMode(triggerpin, OUTPUT);
  pinMode(echoPin, INPUT);
  
  delay(100);
}

void loop() {
  if(onoff==1){moisture = analogRead(moisturePin);
  tempC = dht11.readTemperature();
  humi = dht11.readHumidity();
  
  // Ultrasonic sensor reading
  digitalWrite(triggerpin, LOW);
  delayMicroseconds(2);
  digitalWrite(triggerpin, HIGH);
  delayMicroseconds(10);
  digitalWrite(triggerpin, LOW);

  long duration = pulseIn(echoPin, HIGH);
  distance = duration * 0.034 / 2;
  
  // Convert sensor readings to binary values
  if (distance > 20) {
    distance = 1;
  } else {
    distance = 0;
  }
  
  if (tempC > 30) {
    tempC = 1;
  } else {
    tempC = 0;
  }
  
  if (humi > 60) {
    humi = 1;
  } else {
    humi = 0;
  }
  
  if (moisture < 1600) {
    moisture = 1;
  } else {
    moisture = 0;
  }
  
  // Send data via Serial
  Serial.print("D:");
  Serial.println(distance);
  Serial.print("T:");
  Serial.println(tempC);
  Serial.print("H:");
  Serial.println(humi);
  Serial.print("M:");
  Serial.println(moisture);
  // Send data via Bluetooth
  SerialBT.begin("SmartBlindStick"); // Bluetooth device name
SerialBT.print("D:");
   SerialBT.println(distance);
    SerialBT.print("T:");
   SerialBT.println(tempC);
  SerialBT.print("H:");
  SerialBT.println(humi);
  SerialBT.print("M:");
  SerialBT.println(moisture);
  SerialBT.end();
}
  // Read onoff from serial if available
  if (Serial.available()) {
    String inputString = Serial.readStringUntil('\n');
    onoff = inputString.toInt(); 
  }
switch (onoff) {
    case 1://start the sript
        dht11.begin(); // Re-initialize DHT sensor
        pinMode(triggerpin, OUTPUT); // Enable ultrasonic trigger
        pinMode(echoPin, INPUT);     // Enable ultrasonic echo
        pinMode(moisturePin, INPUT); // Enable moisture sensor pin
      
      break;
    case 2://stop the script
      // Put sensors to sleep to save battery
      dht11.~DHT(); // Deinitialize DHT sensor (no direct sleep, but stops reading)
      pinMode(triggerpin, INPUT); // Disable ultrasonic trigger
      pinMode(echoPin, INPUT);    // Keep echo as input (no power draw)
      pinMode(moisturePin, INPUT); // Set moisture sensor pin to input (high impedance)
      
      
      break;
   
    default:
      onoff = 1;
      
  }
  if(Emergency == 1) {
    SerialBT.begin("SmartBlindStick"); // Bluetooth device name
    SerialBT.println("E:1");
    SerialBT.end();
  }else{
    SerialBT.begin("SmartBlindStick"); // Bluetooth device name
    SerialBT.println("E:0");
    SerialBT.end();
  }

  delay(500);
}