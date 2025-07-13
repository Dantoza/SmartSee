# SmartSee
Code for the DIY smart stick for blind people

## Pin Assignments

| Name           | Pin Number | Description                |
|----------------|------------|----------------------------|
| TRIGGER_PIN    | 4          | Ultrasonic sensor trigger  |
| ECHO_PIN       | 5          | Ultrasonic sensor echo     |
| DHT_PIN        | 15         | DHT11 temperature/humidity |
| MOISTURE_PIN   | 13         | Soil/moisture sensor       |

Refer to `sensorreader.ino` for usage details.

## To-do
- [x] connect esp32 and microbit via serial pins
- [x] read from sensors connected to esp32
- [x] make a processing app that can read from esp32 via bluetooth
- [] make a graph of speed
- [] make an emergency signal in case of a fall