
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.provider.Settings;
import java.util.Set;
import java.util.UUID;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.lang.reflect.Method;
color primaryColor = color(46, 125, 50);
color onPrimaryColor = color(255, 255, 255);
color secondaryColor = color(102, 187, 106);
color tertiaryColor = color(129, 199, 132);
color surfaceColor = color(248, 255, 248);
color onSurfaceColor = color(27, 94, 32);
color outlineColor = color(81, 121, 84);
color errorColor = color(211, 47, 47);
color successColor = color(67, 160, 71);
color warningColor = color(255, 167, 38);

BluetoothAdapter BTAntenna;
BluetoothSocket bluetoothSocket;
BluetoothDevice targetDevice;
InputStream inputStream;
OutputStream outputStream;

String[] deviceList;
String[] deviceAddresses;
String message = "Initializing Bluetooth...";
boolean isConnected = false;
int selectedDeviceIndex = -1;
float cardElevation = 0;
int hoveredCard = -1;

UUID MY_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

void setup() {
  requestPermission("BLUETOOTH_CONNECT");
  requestPermission("BLUETOOTH_ADMIN");
  requestPermission("BLUETOOTH");
  requestPermission("BLUETOOTH_ADVERTISE");
  
  requestPermission("BLUETOOTH_PRIVILIGED");
  requestPermission("BLUETOOTH_SCAN");
    
  initializeBluetooth();
}

void initializeBluetooth() {
  try {
    BTAntenna = BluetoothAdapter.getDefaultAdapter();
    
    if (BTAntenna == null) {
      message = "Bluetooth not supported on this device";
    } 
    else if (!BTAntenna.isEnabled()) {
      message = "Bluetooth is disabled. Please enable it in settings.";
    } 
    else {
      message = "Bluetooth is enabled!";
      listPairedDevices();
    }
    
  } catch (Exception e) {
    message = "Error accessing Bluetooth: " + e.getMessage();
    println("Bluetooth error: " + e.toString());
  }
}

void listPairedDevices() {
  try {
    Set<BluetoothDevice> pairedDevices = BTAntenna.getBondedDevices();
    
    deviceList = new String[pairedDevices.size()];
    deviceAddresses = new String[pairedDevices.size()];
    
    message = "";
    
    int i = 0;
    for (BluetoothDevice device : pairedDevices) {
      String deviceName = device.getName();
      String deviceAddress = device.getAddress();
      
      deviceList[i] =deviceName;
      deviceAddresses[i] = deviceAddress;
      i++;
    }
    
    println("Found " + pairedDevices.size() + " paired devices");
    
  } catch (Exception e) {
    message = "Error listing devices: " + e.getMessage();
  }
}

void connectToDevice(int deviceIndex) {
  if (deviceIndex < 0 || deviceIndex >= deviceAddresses.length) return;
  
  try {
    if (isConnected) {
      disconnectDevice();
    }
    
    message = "Connecting...\n";
    selectedDeviceIndex = deviceIndex;
    
    targetDevice = BTAntenna.getRemoteDevice(deviceAddresses[deviceIndex]);
    
    BTAntenna.cancelDiscovery();
    
    bluetoothSocket = null;
    
    try {
      bluetoothSocket = targetDevice.createRfcommSocketToServiceRecord(MY_UUID);
      bluetoothSocket.connect();
    } catch (IOException e1) {
      try {
        message += "Trying fallback method...\n";
        bluetoothSocket = (BluetoothSocket) targetDevice.getClass()
            .getMethod("createRfcommSocket", new Class[] {int.class})
            .invoke(targetDevice, 1);
        bluetoothSocket.connect();
      } catch (Exception e2) {
        throw new IOException("Both connection methods failed");
      }
    }
    
    inputStream = bluetoothSocket.getInputStream();
    outputStream = bluetoothSocket.getOutputStream();
    
    isConnected = true;
    message = "Connected successfully!\n";
    message += "Ready for communication...\n";
    
    println("Successfully connected to " + deviceList[deviceIndex]);
    
    Thread.sleep(500);
    sendData("ANDROID_CONNECTED\n");
    
  } catch (Exception e) {
    message = "Connection failed!\n";
    message += "Error: " + e.getMessage() + "\n";
    message += "Check ESP32 is on and running Bluetooth...\n";
    isConnected = false;
    println("Connection failed: " + e.getMessage());
    
    try {
      if (bluetoothSocket != null) bluetoothSocket.close();
    } catch (IOException closeException) {
    }
  }
}

void disconnectDevice() {
  try {
    if (bluetoothSocket != null && bluetoothSocket.isConnected()) {
      bluetoothSocket.close();
    }
    
    isConnected = false;
    message = "Disconnected\n";
    
    listPairedDevices();
    
    println("Disconnected from Bluetooth device");
  } catch (IOException e) {
    println("Error disconnecting: " + e.getMessage());
  }
}

void sendData(String data) {
  if (isConnected && outputStream != null) {
    try {
      outputStream.write(data.getBytes());
      outputStream.flush();
      
      message += "Sent: " + data.trim() + "\n";
      println("Sent: " + data);
    } catch (IOException e) {
      message += "X Send error: " + e.getMessage() + "\n";
      println("Send error: " + e.getMessage());
    }
  }
}

String receiveData() {
  if (isConnected && inputStream != null) {
    try {
      if (inputStream.available() > 0) {
        byte[] buffer = new byte[1024];
        int bytes = inputStream.read(buffer);
        
        String receivedData = new String(buffer, 0, bytes);
        
        message += "Received: " + receivedData.trim() + "\n";
        println("Received: " + receivedData);
        
        return receivedData;
      }
    } catch (IOException e) {
      message += "X Receive error: " + e.getMessage() + "\n";
      println("Receive error: " + e.getMessage());
    }
  }
  return null;
}

void draw() {
  background(surfaceColor);
  
  drawTopAppBar();
  
  textAlign(LEFT);
  
  if (!isConnected && deviceList != null && deviceList.length > 0) {
    drawDeviceSelection();
  } else if (isConnected) {
    drawConnectedState();
  } else {
    drawEmptyState();
  }
  
  if (isConnected) {
    receiveData();
  }
}

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
    
    boolean isHovered = (mouseX >= 24 && mouseX <= width-24 && 
                        mouseY >= cardY && mouseY <= cardY + 120);
    
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
    text("Phone", 64, cardY + 42);
    
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

void drawConnectedState() {
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
  
  fill(onSurfaceColor);
  textAlign(LEFT);
  textSize(24);
  text("Communication Log", 24, 460);
  
  fill(color(248, 250, 252));
  stroke(outlineColor);
  strokeWeight(1);
  rect(24, 480, width-48, height-540, 12);
  noStroke();
  
  fill(onSurfaceColor);
  textSize(14);
  String[] lines = message.split("\n");
  int startLine = max(0, lines.length - 12);
  
  for (int i = startLine; i < lines.length; i++) {
    String line = lines[i];
    
    text(line, 36, 505 + (i - startLine) * 22);
  }
}

void drawEmptyState() {
  fill(outlineColor);
  textAlign(CENTER);
  textSize(48);
  text("phone", width/2, height/2 - 80);
  
  fill(onSurfaceColor);
  textSize(24);
  text("No Paired Devices", width/2, height/2 - 20);
  
  fill(outlineColor);
  textSize(18);
  text("Pair your ESP32 in Android Settings", width/2, height/2 + 10);
  text("to get started with SmartSee", width/2, height/2 + 35);
  
  fill(primaryColor);
  rect(width/2 - 100, height/2 + 70, 200, 56, 28);
  
  fill(onPrimaryColor);
  textSize(16);
  text("OPEN SETTINGS", width/2, height/2 + 103);
}







void mousePressed() {
  if (!isConnected && deviceList != null && deviceList.length > 0) {
    for (int i = 0; i < deviceList.length; i++) {
      float cardY = 240 + i * 140;
      
      if (mouseX >= 24 && mouseX <= width-24 && 
          mouseY >= cardY && mouseY <= cardY + 120) {
        println("Connecting to device " + (i+1) + ": " + deviceList[i]);
        connectToDevice(i);
        break;
      }
    }
  } 
  else if (isConnected) {
    float buttonY = 360;
    
    if (mouseX >= 24 && mouseX <= 144 && 
        mouseY >= buttonY && mouseY <= buttonY + 56) {
      sendData("Hello from SmartSee Android App!\n");
    }
    
    if (mouseX >= 160 && mouseX <= 280 && 
        mouseY >= buttonY && mouseY <= buttonY + 56) {
      disconnectDevice();
    }
    
    if (dist(mouseX, mouseY, width - 80, height - 80) <= 36) {
      sendData("QUICK_SENSOR_READ\n");
    }
  } 
  else {
    if (mouseX >= width/2 - 100 && mouseX <= width/2 + 100 && 
        mouseY >= height/2 + 70 && mouseY <= height/2 + 126) {
      println("Open Android Settings to pair ESP32");
      Intent intent = new Intent(Settings.ACTION_BLUETOOTH_SETTINGS);
      startActivity(intent);
    }
  }
}
