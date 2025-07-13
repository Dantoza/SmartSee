import grafica.*;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.Intent;
import android.provider.Settings;
import java.util.Set;
import java.util.UUID;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
color primaryColor = color(46, 125, 50);
color onPrimaryColor = color(255, 255, 255);
color secondaryColor = color(102, 187, 106);
color tertiaryColor = color(129, 199, 132);
color surfaceColor = color(2, 0, 2);
color onSurfaceColor = color(27, 94, 32);
color outlineColor = color(81, 121, 84);
color errorColor = color(211, 47, 47);
color successColor = color(67, 160, 71);
color warningColor = color(255, 167, 38);

String serialdata = "";
BluetoothAdapter BTAntenna;
BluetoothSocket bluetoothSocket;
BluetoothDevice targetDevice;
InputStream inputStream;
OutputStream outputStream;
String[] deviceList;
String[] deviceAddresses;
// Removed unused message variable
boolean isConnected = false;
int selectedDeviceIndex = -1;
float distance, temp, moist, humidity, err, speed;
UUID MY_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

// Font variable for Unicode/emoji support
PFont unicodeFont;

// Main setup function, requests necessary Bluetooth permissions and starts Bluetooth
void setup() {
  // Load a Unicode-compatible font (e.g., NotoSans-Regular.ttf placed in the data folder)
  unicodeFont = createFont("regular.ttf", 32, true);
  textFont(unicodeFont);
  requestPermission("BLUETOOTH_CONNECT");
  requestPermission("BLUETOOTH_ADMIN");
  requestPermission("BLUETOOTH");
  requestPermission("BLUETOOTH_ADVERTISE");
  requestPermission("BLUETOOTH_PRIVILIGED");
  requestPermission("BLUETOOTH_SCAN");
  startBT();
}

// Initializes Bluetooth adapter and lists paired devices if enabled
void startBT() {
  try {
    BTAntenna = BluetoothAdapter.getDefaultAdapter();
    if (!BTAntenna.isEnabled()) {
      // Bluetooth is off
    } else {
      // Bluetooth is on
      listBTDevice();
    }
  } catch (Exception e) {
    // Log Bluetooth error
    println("Bluetooth error: " + e.toString());
  }
}

// Populates deviceList and deviceAddresses arrays with paired Bluetooth devices
void listBTDevice() {
  try {
    Set<BluetoothDevice> pairedDevices = BTAntenna.getBondedDevices();
    deviceList = new String[pairedDevices.size()];
    deviceAddresses = new String[pairedDevices.size()];
    int i = 0;
    for (BluetoothDevice device : pairedDevices) {
      deviceList[i] = device.getName();
      deviceAddresses[i] = device.getAddress();
      i++;
    }
    println("Found " + pairedDevices.size() + " paired devices");
  } catch (Exception e) {
    // Error listing devices
  }
}

// Disconnects from the currently connected Bluetooth device
void disconnectDevice() {
  try {
    if (bluetoothSocket != null && bluetoothSocket.isConnected()) {
      bluetoothSocket.close();
    }
    isConnected = false;
    listBTDevice();
    println("Disconnected from Bluetooth device");
  } catch (IOException e) {
    println("Error disconnecting: " + e.getMessage());
  }
}

// Attempts to connect to a Bluetooth device by index
void ConnectBT(int deviceIndex) {
  try {
    if (isConnected) {
      disconnectDevice();
    }
    selectedDeviceIndex = deviceIndex;
    targetDevice = BTAntenna.getRemoteDevice(deviceAddresses[deviceIndex]);
    BTAntenna.cancelDiscovery();
    bluetoothSocket = null;
    try {
      bluetoothSocket = targetDevice.createRfcommSocketToServiceRecord(MY_UUID);
      bluetoothSocket.connect();
    } catch (IOException e1) {
      try {
        // Fallback connection method for some devices
        bluetoothSocket = (BluetoothSocket) targetDevice.getClass().getMethod("createRfcommSocket", new Class[] {int.class}).invoke(targetDevice, 1);
        bluetoothSocket.connect();
      } catch (Exception e2) {
        throw new IOException("Both connection methods failed");
      }
    }
    inputStream = bluetoothSocket.getInputStream();
    outputStream = bluetoothSocket.getOutputStream();
    isConnected = true;
    println("Successfully connected to " + deviceList[deviceIndex]);
    Thread.sleep(500);
  } catch (Exception e) {
    isConnected = false;
    println("Connection failed: " + e.getMessage());
    try {
      if (bluetoothSocket != null) bluetoothSocket.close();
    } catch (IOException closeException) {}
  }
}

// Sends a string of data over Bluetooth to the connected device
void sendData(String data) {
  if (isConnected && outputStream != null) {
    try {
      outputStream.write(data.getBytes());
      outputStream.flush();
      println("Sent: " + data);
    } catch (IOException e) {
      println("Send error: " + e.getMessage());
    }
  }
}

// Reads and processes incoming Bluetooth data if available
String ProcessData() {
  if (isConnected && inputStream != null) {
    try {
      if (inputStream.available() > 0) {
        byte[] buffer = new byte[1024];
        int bytes = inputStream.read(buffer);
        String receivedData = new String(buffer, 0, bytes).trim();
        processReceivedData(receivedData);
      }
    } catch (IOException e) {
      println("Error reading data: " + e.getMessage());
    }
  }
  return "";
}

// Parses received Bluetooth data and updates sensor variables
void processReceivedData(String receivedData) {
  if (receivedData != null && receivedData.length() > 2) {
    try {
      String[] lines = receivedData.split("\n|\r");
      for (String line : lines) {
        line = line.trim();
        if (line.length() < 3) continue;
        char type = line.charAt(0);
        int colonIndex = line.indexOf(':');
        if (colonIndex > 0 && colonIndex < line.length() - 1) {
          float number = Float.parseFloat(line.substring(colonIndex + 1).trim());
          switch(type) {
            case 'D': distance = number; break; // Distance sensor
            case 'T': temp = number; break;     // Temperature sensor
            case 'M': moist = number; break;    // Moisture sensor
            case 'H': humidity = number; break; // Humidity sensor
            case 'E': err = number; break;      // Error/fall detection
            case 'S': speed = number; break;    // Speed sensor
            default: serialdata = line; break;  // Raw serial data
          }
        }
      }
      if (lines.length > 0) serialdata = lines[lines.length-1];
    } catch (NumberFormatException e) {
      println("Error parsing number: " + e.getMessage());
    }
  }
}
// Main draw loop for UI rendering and Bluetooth data polling
void draw() {
  background(surfaceColor);
  drawTopAppBar();
  textAlign(LEFT);
  // Show device selection if not connected
  if (!isConnected && deviceList != null && deviceList.length > 0) {
    drawDeviceSelection();
  } else if (isConnected) {
    ConnectedScreen();
  } else {
    NoConnected();
  }
  // Poll for Bluetooth data if connected
  if (isConnected) {
    ProcessData();
  }
}

// Draws the top app bar with connection status
void drawTopAppBar() {
  fill(primaryColor);
  noStroke();
  rect(0, 0, width, 120);
  for (int i = 0; i < 8; i++) {
    fill(0, 0, 0, 15 - i * 2);
    rect(0, 120 + i, width, 1);
  }
  fill(onPrimaryColor);
  textAlign(LEFT);
  textSize(32);
  text("SmartSee", 24, 50);
  textSize(18);
  text("Bluetooth Manager", 24, 80);
  if (isConnected) {
    fill(successColor);
    rect(width-180, 30, 150, 50, 25);
    fill(onPrimaryColor);
    textAlign(CENTER);
    textSize(16);
    text("Connected", width-105, 50);
    textSize(14);
    text(deviceList[selectedDeviceIndex], width-105, 70);
  } else {
    fill(errorColor);
    rect(width-180, 30, 150, 50, 25);
    fill(onPrimaryColor);
    textAlign(CENTER);
    textSize(16);
    text("Disconnected", width-105, 60);
  }
}

// Draws the device selection UI for available Bluetooth devices
void drawDeviceSelection() {
  fill(onSurfaceColor);
  textAlign(LEFT);
  textSize(28);
  text("Available Devices", 24, 180);
  fill(outlineColor);
  textSize(16);
  text("Tap any device to connect", 24, 210);
  for (int i = 0; i < deviceList.length; i++) {
    float cardY = 240 + i * 140;
    boolean isHovered = (mouseX >= 24 && mouseX <= width-24 && mouseY >= cardY && mouseY <= cardY + 120);
    float elevation = isHovered ? 8 : 2;
    for (int j = 0; j < elevation; j++) {
      fill(0, 0, 0, 10 - j);
      rect(24 + j, cardY + j + 4, width-48, 120, 16);
    }
    fill(surfaceColor);
    stroke(outlineColor);
    strokeWeight(1);
    rect(24, cardY, width-48, 120, 16);
    noStroke();
    fill(primaryColor);
    ellipse(64, cardY + 35, 36, 36);
    fill(onPrimaryColor);
    textAlign(CENTER);
    textSize(20);
    text("Device", 64, cardY + 42);
    textAlign(LEFT);
    fill(onSurfaceColor);
    textSize(22);
    text(deviceList[i], 100, cardY + 35);
    fill(outlineColor);
    textSize(16);
    text(deviceAddresses[i], 100, cardY + 60);
    fill(isHovered ? primaryColor : secondaryColor);
    rect(width-140, cardY + 25, 100, 48, 24);
    fill(onPrimaryColor);
    textAlign(CENTER);
    textSize(16);
    text("CONNECT", width-90, cardY + 54);
  }
}

// Draws the connected device screen and sensor data
void ConnectedScreen() {
  fill(onSurfaceColor);
  textAlign(LEFT);
  textSize(28);
  text("Connected", 24, 180);
  fill(surfaceColor);
  stroke(successColor);
  strokeWeight(2);
  rect(24, 200, width-48, 140, 16);
  noStroke();
  fill(successColor);
  ellipse(64, 245, 40, 40);
  fill(onPrimaryColor);
  textAlign(CENTER);
  textSize(24);
  text("✓", 64, 254);
  textAlign(LEFT);
  fill(onSurfaceColor);
  textSize(20);
  text("Connected to:", 100, 235);
  textSize(18);
  text(deviceList[selectedDeviceIndex], 100, 260);
  fill(outlineColor);
  textSize(14);
  text(deviceAddresses[selectedDeviceIndex], 100, 285);
  float buttonY = 360;
  fill(primaryColor);
  rect(24, buttonY, 120, 56, 28);
  fill(onPrimaryColor);
  textAlign(CENTER);
  textSize(16);
  text("SEND TEST", 84, buttonY + 35);
  fill(surfaceColor);
  stroke(errorColor);
  strokeWeight(2);
  rect(160, buttonY, 120, 56, 28);
  noStroke();
  fill(errorColor);
  textAlign(CENTER);
  textSize(16);
  text("DISCONNECT", 220, buttonY + 35);
  // Sensor data block
  textSize(45);
  float sensorBlockStartY = 490;
  textAlign(CENTER);
  float centerX = width / 2;
  fill(#00FF00);
  text("Distance: " + distance + " cm", centerX, sensorBlockStartY);
  text("Temperature: " + temp + " °C", centerX, sensorBlockStartY + 50);
  text("Moisture: " + moist + " units", centerX, sensorBlockStartY + 100);
  text("Humidity: " + humidity + " %", centerX, sensorBlockStartY + 150);
  text("Speed: " + speed + " m/s", centerX, sensorBlockStartY + 200);
  //text("Unfiletered: " + serialdata, centerX, sensorBlockStartY + 250);
  if (err > 0) {
    fill(errorColor);
    textSize(100);
    text("I fell", 36, sensorBlockStartY + 300);
    fill(onSurfaceColor);
  }
}

// Draws the screen shown when no device is connected
void NoConnected() {
  fill(outlineColor);
  textAlign(CENTER);
  textSize(48);
  text("Phone", width/2, height/2 - 80);
  fill(onSurfaceColor);
  textSize(24);
  text("No Paired Devices", width/2, height/2 - 20);
  fill(outlineColor);
  textSize(18);
  text("Pair your ESP32 in Android Settings", width/2, height/2 + 10);
  text("To get started with SmartSee", width/2, height/2 + 35);
  fill(primaryColor);
  rect(width/2 - 100, height/2 + 70, 200, 56, 28);
  fill(onPrimaryColor);
  textSize(16);
  text("OPEN SETTINGS", width/2, height/2 + 103);
}







// Handles mouse click events for UI interaction
void mousePressed() {
  // Device selection screen: connect to device on card click
  if (!isConnected && deviceList != null && deviceList.length > 0) {
    for (int i = 0; i < deviceList.length; i++) {
      float cardY = 240 + i * 140;
      if (mouseX >= 24 && mouseX <= width-24 && mouseY >= cardY && mouseY <= cardY + 120) {
        println("Connecting to device " + (i+1) + ": " + deviceList[i]);
        ConnectBT(i);
        break;
      }
    }
  } else if (isConnected) {
    float buttonY = 360;
    // SEND TEST button (add logic if needed)
    if (mouseX >= 24 && mouseX <= 144 && mouseY >= buttonY && mouseY <= buttonY + 56) {
      // SEND TEST button pressed
    }
    // DISCONNECT button
    if (mouseX >= 160 && mouseX <= 280 && mouseY >= buttonY && mouseY <= buttonY + 56) {
      disconnectDevice();
    }
    // Reserved for future use (bottom right circle)
    if (dist(mouseX, mouseY, width - 80, height - 80) <= 36) {
      // Reserved for future use
    }
  } else {
    // No device connected: open Android Bluetooth settings
    if (mouseX >= width/2 - 100 && mouseX <= width/2 + 100 && mouseY >= height/2 + 70 && mouseY <= height/2 + 126) {
      println("Open Android Settings to pair ESP32");
      Intent intent = new Intent(Settings.ACTION_BLUETOOTH_SETTINGS);
      startActivity(intent);
    }
  }
}
