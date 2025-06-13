---

layout: post
author: trentsteenholdt
title:  "Home IoT - Part 3 - What about my garden irrigation system"
date: 2020-09-19
categories: [iot ]
tags:   arduino   css   esp32   html-2   iot   js
image: "/assets/images/from_wordpress/image-12.png"
---


This blog post is part of a series of posts were I’ve automated, and Internet of Things (IoT) enabled my garage door, swing gate and Bluetooth enabled garden irrigation system. Links below to each part!

- Part 1 – [The start of the IoT journey](/2020/09/01/home-iot-part-1-the-start-of-the-journey/)

- Part 2 – [Putting it together and integration](/2020/09/03/home-iot-part-2-putting-it-together-and-integration/)

- Part 3 – This part

- Part 4 – [The ‘final’ solution and the things I learned](/2020/09/20/home-iot-part-4-the-final-solution-and-the-things-i-learned/)

### I was about to fall asleep, and then it hit me

So after a late night just completing [part 2](/2020/09/03/home-iot-part-2-putting-it-together-and-integration/), I was laying in bed when my mind was wondering of all the things I could do with my ESP32. _Hrmm, could I convince my key stakeholder to wire up the lights in the house to this controller? Nah, she was pretty clear with the rule, nothing inside the house. Hrmm, what is there outside the house?_ My mind went blank as I started to drift to sleep when I forgot about watering the pots in the patio. _Crap! I’ll do it tomorrow._

Just as I’m about to nod off, it hits me like a train. _WAIT FOR A SECOND, I hate that darn Android app for my Bluetooth garden irrigation system_. _The ESP32 has a Bluetooth radio! Maybe I can make the same calls to replace the app and water those pots? Maybe I can say to Google, hey, water my garden for 10 minutes._ I was excited about the challenge! Okay, after some long, painful nights, I have successfully got my ESP32 making Bluetooth Low Energy (BLE) calls to the Holman BTX-8 Outdoor Garden Irrigation System. For details on the Holman unit, it’s just one that you can find at your local [Bunnings store](https://www.bunnings.com.au/holman-btx8-8-station-bluetooth-controller_p0011579).

Here’s how I IoT enabled my garden irrigation system.

### Capturing BLE packets on my Android Phone

So to start with this, I first needed to capture the BLE calls the phone was sending and receiving. If I was to have any chance of replacing the app, I first needed to know what the app does. Turning on developer mode and capturing HCI logs was relatively straight forward on my Samsung S9 phone. I followed this [guide](https://www.bluetooth.com/blog/debugging-bluetooth-with-an-android-app/\)) and was able to get the logs into WireShark where I could start seeing the important parts that make up Bluetooth client to server communication like Service UUID and the Characteristic UUID.

![](/assets/images/from_wordpress/image-11.png)

<sup>WireShark view of the logs</sup>

Not long after finding the right write characteristic, I could see the hexadecimal calls being made. Thankfully this write characteristic didn’t look to be based on a read value of something else, so the challenge was simplified a bit. Being honest though, this step took a while, with lots of trial and error, calling to stop and start stations so I could pick up the patterns in the captured logs. I could see numbers changing, but I was only 90% sure I had the logic right. At this point, I felt I had a chance of not making a bad write characteristic to the Holman device which could, though unlikely, scramble its brain. To test locally on my PC first before going all-in on coding it on the ESP32, I ended up getting an app called [Bluetooth LE Lab](https://github.com/IanSavchenko/BleLab). This app was great. I recommended it to anyone trying to reverse engineer Bluetooth calls.

![](/assets/images/from_wordpress/image-12.png)

<sup>Bluetooth BLE Lab App</sup>

After some fun figuring out some of the other values, I concluded that there was a 10-byte hex value that made the Holman device do something. This value broken down looks like:

- Turns off all the solenoids.
  - 00 00 00 00 00 00 00 00 00 00 -

- To run a station (open a solenoid)
  - 01 (run)

  - 00 (station 1, starting at 0)

  - 13 (19 hrs in hex)

  - 12 (18 mins in hex)

  - 00 00 00 00 00 00 (used for scheduling a station at day/time, instead of immediately running it)

To state the obvious because it would have been silly, I did not run a station for 19 hours and 18 minutes! During the testing and validation, I also decided that I didn’t need to schedule the station to run as I had a plan to manage those smarts outside of the controller itself.

### Coding it up in the ESP32

```

// The remote service we wish to connect to.
static BLEUUID serviceUUID("C521F000-0D70-4D4F-X-X");
// The characteristic of the remote service we are interested in.
static BLEUUID charUUID("0000F006-0000-1000-X-X");

static boolean doConnect = false;
static boolean connected = false;
static boolean doScan = false;
static BLERemoteCharacteristic* pRemoteCharacteristic;
static BLEAdvertisedDevice* myDevice;

class MyClientCallback : public BLEClientCallbacks {
    void onConnect(BLEClient* pclient) {
    }

    void onDisconnect(BLEClient* pclient) {
      connected = false;
      Serial.println("onDisconnect");
    }
};

void connectToServer() {
  Serial.print("BLE - Forming a connection to ");
  Serial.println(myDevice->getAddress().toString().c_str());

  BLEClient*  pClient  = BLEDevice::createClient();
  Serial.println("BLE - Created client.");

  pClient->setClientCallbacks(new MyClientCallback());

  // Connect to the remove BLE Server.
  pClient->connect(myDevice);  // if you pass BLEAdvertisedDevice instead of address, it will be recognized type of peer device address (public or private)
  Serial.println("BLE - Client connected.");

  delay(1000);

  // Obtain a reference to the service we are after in the remote BLE server.
  BLERemoteService* pRemoteService = pClient->getService(serviceUUID);
  if (pRemoteService == nullptr) {
    Serial.print("BLE - Failed to find our service UUID: ");
    Serial.println(serviceUUID.toString().c_str());
    connected = false;
  }
  Serial.println("BLE - Found our service");

  pRemoteCharacteristic = pRemoteService->getCharacteristic(charUUID);
  if (pRemoteCharacteristic == nullptr) {
    Serial.print("BLE - Failed to find our characteristic UUID: ");
    Serial.println(charUUID.toString().c_str());
    connected = false;
  }
  Serial.println("BLE - Found our characteristic");
  connected = true;
}

class MyAdvertisedDeviceCallbacks: public BLEAdvertisedDeviceCallbacks {
    void onResult(BLEAdvertisedDevice advertisedDevice) {
      Serial.print("BLE - Advertised Device found: ");
      Serial.println(advertisedDevice.toString().c_str());

      if (advertisedDevice.haveServiceUUID() && advertisedDevice.isAdvertisingService(serviceUUID)) {
        BLEDevice::getScan()->stop();

        Serial.println("BLE - Correct device found.");
        myDevice = new BLEAdvertisedDevice(advertisedDevice);
        doConnect = true;
        doScan = true;
      }
    }
};

bool makeBLECall(uint8_t* value)
{
  char dataString[30] = {0};
  sprintf(dataString, "%02X %02X %02X %02X%", value[0], value[1], value[2], value[3]);
  String output = dataString;

  Serial.print("BLE ");
  Serial.println(output);

  if (connected) {
    Serial.println(" BLE - Call made.");
    pRemoteCharacteristic->writeValue(value, 4);
    return true;
  }
  return false;
}

void BLEEnable(){
  if (BLEDevice::getInitialized() == false){
    esp_bt_controller_mem_release(ESP_BT_MODE_CLASSIC_BT);
    BLEDevice::init("Cortana Design IoT");
    BLEDevice::setPower(ESP_PWR_LVL_P9);

    Serial.println("BLE - Enabling.");
    BLEScan* pBLEScan = BLEDevice::getScan();
    pBLEScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks());
    pBLEScan->setActiveScan(true);
    pBLEScan->start(5, false);

    Serial.println("BLE - Delaying for 3 seconds.");
    delay(3000);

    if (doConnect == true) {
      connectToServer();
      doConnect = false;
    }

    Serial.println("BLE - Delaying for 3 seconds.");
    delay(3000);
  }
}

void BLEDisable(){
  if (BLEDevice::getInitialized() == true){
    Serial.println("BLE - Disabling.");
    BLEDevice::deinit(false);
  }
}

void setup() {
      server.on("/irrigation", HTTP_GET, [] (AsyncWebServerRequest *request) {
    String inputMessage0;
    String inputParam0;
    String inputMessage1;
    String inputParam1;
    String inputMessage2;
    String inputParam2;
    String inputMessage3;
    String inputParam3;
    if (request->hasParam(PARAM_INPUT_3) & request->hasParam(PARAM_INPUT_4) & request->hasParam(PARAM_INPUT_5) & request->hasParam(PARAM_INPUT_6)) {
      inputMessage0 = request->getParam(PARAM_INPUT_3)->value();
      inputParam0 = PARAM_INPUT_3;
      inputMessage1 = request->getParam(PARAM_INPUT_4)->value();
      inputParam1 = PARAM_INPUT_4;
      inputMessage2 = request->getParam(PARAM_INPUT_5)->value();
      inputParam2 = PARAM_INPUT_5;
      inputMessage3 = request->getParam(PARAM_INPUT_6)->value();
      inputParam3 = PARAM_INPUT_6;

      uint8_t value[4] = {inputMessage0.toInt(),(inputMessage1.toInt()-1),inputMessage2.toInt(),inputMessage3.toInt()};
      if (makeBLECall(value)){
        request->send(/200, "text/plain", "OK");
      }
      else{
        request->send(400, "text/plain", "Something went wrong.");
      }
    }
    else {
      inputMessage0 = "BLE - Incorrect message sent.";
      inputParam0 = "none";
      Serial.println(inputMessage0);
      request->send(400, "text/plain", "Bad Request");
    }
  });
}
```

When it came to coding this up, I learnt a tough lesson about the importance of keeping your ESP32 codebase small, efficient and optimised as much as possible. It turns out the BLE library for ESP32 is quite big, and when trying to run that with WiFi, a WebServer and MQTT subscription and publishing to Azure IoT Hub, I was overflowing on the 4mb memory of the controller. To solve this, I had to change the memory partitions, but this meant that over the air (OTA) updates were now no longer possible.

This change made updating my C++ code and the webserver inside it only possible over USB, which made progress tedious and a lot slower. I also ran into another issue that as I kept moving the ESP32 back to where I wanted it to be, it couldn’t see or scan for the Holman device. This issue was quite problematic to troubleshoot as I wasn’t able to see the serial output as it wasn’t near my PC. But when I brought it back which subsequently meant it was nearer to the Holman device (located outside on the office PC wall), it worked fine! It took a good day to realise I needed to bump up the power gain settings on the ESP32 to reach the distance I wanted it to.

With a few changes to the webserver, I now had the irrigation controlled via this much simpler interface, which actually works. _Did I mention the Holman app is horrible?!_ Though this webserver was still only on the network, so I also created a new subscriber in Azure IoT too.

It’s now possible, through the ESP32, to control my Bluetooth irrigation system from anywhere in the world!

![](/assets/images/from_wordpress/image-13.png)

<sup>ESP32 Webserver with the irrigation controls</sup>

![](/assets/images/from_wordpress/image-14.png)

<sup>Integration of the irrigation using IFTTT, the WebHook + Runbook and Azure IoT Hub</sup>

In the last blog post, I’ll share the final solution and recap some learnings that I’ve taken away from this project. Stay tuned!
