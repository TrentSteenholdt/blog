---

layout: post
author: trentsteenholdt
title:  "Creating an Interactive Activity Board for My Daughter Using an ESP32 Dev Board"
date: 2023-03-27
categories: [iot ]
tags:   esp32   iot
image: "/assets/images/from_wordpress/Screenshot-2023-03-27-110513.png"
---


## Introduction

In this blog post, I will be sharing my experience in creating an interactive activity board for my daughter, Leila. The activity board is built using an ESP32 dev board, allowing me to wire buttons to various GPIO pins and play custom sounds like Elmo and other fun audio clips. In addition, I've created a separate Single Page Application (SPA) web app that allows me to interact with the sounds remotely via HTTP requests. Let's dive into the details!

Before diving into the technical aspects of the code, let me share a bit about the process of building the activity board itself. I wanted to create something durable and fun for my daughter Leila to interact with. To achieve this, I turned to [Bunnings](https://www.bunnings.com.au/) for materials like wood, screws, and paint to create the base and structure of the board. [Jaycar](https://www.jaycar.com.au/) proved the perfect source for electronic components, such as buttons, LEDs, and capacitors for the ESP32. With all the materials and components in hand, I embarked on a DIY journey to create an engaging and interactive activity board that would bring a smile to my daughter's face.

[![](/assets/images/from_wordpress/Screenshot-2023-03-27-110513.png)](/assets/images/from_wordpress/Screenshot-2023-03-27-110513.png)

<sup>The initial activity board</sup>

## Using an ESP32 Dev Board

The heart of this project is an [ESP32 dev board](https://www.espressif.com/en/products/devkits), which offers various features such as Wi-Fi and Bluetooth connectivity, low power consumption, and a large number of GPIO pins. The ESP32 is a powerful microcontroller that is perfect for creating interactive IoT projects like this activity board.

## Wiring Buttons to the Appropriate GPIO Pins

The activity board consists of several buttons wired to different GPIO pins on the ESP32 dev board. In the code, I defined the following pins for each button:

```
#define BUTTON_A_PIN  21
#define BUTTON_B_PIN  12
#define BUTTON_C_PIN  13
#define BUTTON_D_PIN  17
#define BUTTON_E_PIN  23
```

Each button is configured to trigger a specific set of sounds or functions. For example, button A plays sounds related to Elmo, Teletubbies, and Formula, while button B plays sounds related to my own interactions with Leila.

## Adding Custom Sounds with XT\DAC\Audio Library

To play the custom sounds, I used the [XT\DAC\Audio](https://www.youtube.com/watch?v=IthsYBmWk00) library. This library enables playing WAV files stored in the ESP32's flash memory. I converted the desired sound clips to the required format and stored them as constant unsigned char arrays in separate header files. In the code, I've assigned each sound to a corresponding name and duration (in seconds) within struct NameAndSeconds.

To get the sound files in the right format, all I did was use [Audacity](https://www.audacityteam.org/), convert all the sound files to Mono and convert them to a bitrate of about 8000. Then I simply opened the WAV files in a [HEX editor](https://mh-nexus.de/en/hxd/) and copied that to the unsigned char header files.

## Interacting with the Activity Board via a SPA Web App

[![](/assets/images/from_wordpress/aaaa.png)](/assets/images/from_wordpress/aaaa.png)

<sup>SPA with the sound selection</sup>

I wanted to have the ability to interact with the activity board remotely, so I created a Single Page Application (SPA) web app that communicates with the ESP32 through HTTP requests. The ESP32 acts as a web server and responds to HTTP GET requests sent by the web app.

The server handles requests for playing sounds. When the web app sends a request to "/sound", the server parses the sound name and duration parameters and plays the corresponding sound on the activity board.

I don't include the code to the SPA in this blog post as I use it for things like my irrigation system and gate/garage door controls. [Check out that blog series here to learn](/2020/09/01/home-iot-part-1-the-start-of-the-journey/) more about the SPA development.

## Conclusion

This project demonstrates creating a fun and interactive activity board for your child using an ESP32 dev board, buttons, and custom sounds. The addition of a SPA web app allows you to control the activity board remotely and adds another layer of interactivity. This activity board has brought joy and entertainment to my daughter Leila, and I hope it inspires you to create similar projects for your loved ones. Happy coding!

**_Code for the ESP32. You'll need to change a few lines to make it work in your network._**

```shell
#include "teletubbies.h"
#include "trentbooboo.h"
#include "formula.h"
#include "elmo.h"
#include "trentgigi.h"
#include "trentleila.h"
#include "mareegigi.h"
#include "mareeleila.h"
#include "mama.h"
#include "nanna.h"
#include "pop.h"
#include "mareebooboo.h"
#include "telephone.h"
#include "mareemobile.h"
#include "trentmobile.h"
#include "daddy.h"
#include "XT_DAC_Audio.h"
#include "Button2.h"
#include "WiFi.h"
#include "ESPAsyncWebServer.h"

struct NameAndSeconds {
    String name;
    double seconds;
};

const NameAndSeconds ArrayButtonA[] = `{`{"elmo", 28}, {"teletubbies", 15.5}, {"formula", 19}};
const NameAndSeconds ArrayButtonB[] = `{`{"trentgigi", 0.7}, {"trentleila", 1}, {"trentbooboo", 0.7}, {"daddy", 0.7}};
const NameAndSeconds ArrayButtonC[] = `{`{"mareegigi", 0.7}, {"mareeleila", 0.7}, {"mareebooboo", 1}, {"mama", 1}};
const NameAndSeconds ArrayButtonD[] = `{`{"trentmobile", 2.8}, {"mareemobile", 2.8}, {"telephone", 7}, {"nanna", 2}, {"pop", 1.7}};

#define BUTTON_A_PIN  21
#define BUTTON_B_PIN  12
#define BUTTON_C_PIN  13
#define BUTTON_D_PIN  17
#define BUTTON_E_PIN  23

Button2 buttonA, buttonB, buttonC, buttonD, buttonE;

#define LED_PIN_1 18 
#define LED_PIN_2 16
#define BLINK_INTERVAL_1 1000  // interval at which to blink LED (milliseconds)
#define BLINK_INTERVAL_2  500   // interval at which to blink LED 2 (milliseconds)

int ledState_1 = HIGH;  
int ledState_2 = HIGH;  
unsigned long previousMillis_1 = 0;   // will store last time LED 1 was updated
unsigned long previousMillis_2 = 0;   // will store last time LED 2 was updated

// Replace with your network credentials
const char* ssid = "IoT SSID";
const char* password = "Password";
unsigned long previousMillis = 0;   // Wifi checker

const char* PARAM_INPUT_1 = "sound";
const char* PARAM_INPUT_2 = "seconds";
const char* PARAM_INPUT_3 = "isOn";
unsigned long interval = 30000;

String soundWebServerName;
double soundWebServerSeconds;

boolean soundWebServer = false;
boolean flashingLed = true;

// Create AsyncWebServer object on port 80
AsyncWebServer server(80);

XT_DAC_Audio_Class DacAudio(/25,0);  

void WiFiEnable(){
  Serial.println("WIFI - Enabling.");
  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to the network");
  }

  // Print ESP32 Local IP Address
  Serial.print("NETWORK IP: ");
  Serial.println(WiFi.localIP());
}

void WiFiDisable(){
  Serial.println("WIFI - Disabling.");
  WiFi.mode(WIFI_OFF);
}

NameAndSeconds getRandomPair(const NameAndSeconds* const array, const int array_size) {
    srand(time(NULL)); // initialize random seed

    int random_index = rand() % array_size; // generate random index
    NameAndSeconds random_pair = array[random_index]; // access pair at random index

    return random_pair;
}

void playRandomAudio(const NameAndSeconds* const array, const int array_size) {
    flashingLed = false;
    digitalWrite(LED_PIN_1, HIGH);
    digitalWrite(LED_PIN_2, HIGH);

    NameAndSeconds random_pair = getRandomPair(array, array_size);
    playAudio(random_pair.seconds,(random_pair.name).c_str());
}

void click(Button2& btn) {
    Serial.println(btn.getPin());

    if (btn == buttonA) {
        Serial.println("Button A pressed");
        const int array_size = sizeof(ArrayButtonA) / sizeof(ArrayButtonA[0]);
        playRandomAudio(ArrayButtonA, array_size);
    } else if (btn == buttonB) {
        Serial.println("Button B pressed");
        const int array_size = sizeof(ArrayButtonB) / sizeof(ArrayButtonB[0]);
        playRandomAudio(ArrayButtonB, array_size);
    } else if (btn == buttonC) {
        const int array_size = sizeof(ArrayButtonC) / sizeof(ArrayButtonC[0]);
        Serial.println("Button C pressed");
        playRandomAudio(ArrayButtonC, array_size);
    } else if (btn == buttonD) {
        Serial.println("Button D pressed");
        const int array_size = sizeof(ArrayButtonD) / sizeof(ArrayButtonD[0]);
        playRandomAudio(ArrayButtonD, array_size);
    } else if (btn == buttonE) {
        if(flashingLed){
          digitalWrite(LED_PIN_1, HIGH);
          digitalWrite(LED_PIN_2, HIGH);
          flashingLed = false;
        } else{
          flashingLed = true;
        }
    }
}

void playAudio(double seconds, const char* sound) {
  double i = 0.00;
  double twentyms = 0.02;
  double timetoPlay = seconds / twentyms;

  const unsigned char* soundData;

  if (strcmp(sound, "elmo") == 0) {
      soundData = elmo;
  } 
  else if (strcmp(sound, "teletubbies") == 0) {
      soundData = teletubbies;
  }
  else if (strcmp(sound, "daddy") == 0) {
      soundData = daddy;
  }
  else if (strcmp(sound, "mareemobile") == 0) {
      soundData = mareemobile;
  } 
  else if (strcmp(sound, "trentmobile") == 0) {
      soundData = trentmobile;
  }
  else if (strcmp(sound, "formula") == 0) {
      soundData = formula;
  } 
  else if (strcmp(sound, "trentbooboo") == 0) {
      soundData = trentbooboo;
  }
  else if (strcmp(sound, "trentleila") == 0) {
      soundData = trentleila;
  }
  else if (strcmp(sound, "trentgigi") == 0) {
      soundData = trentgigi;
  }
  else if (strcmp(sound, "mareegigi") == 0) {
      soundData = mareegigi;
  }
  else if (strcmp(sound, "mareeleila") == 0) {
      soundData = mareeleila;
  }
  else if (strcmp(sound, "mama") == 0) {
      soundData = mama;
  }
  else if (strcmp(sound, "nanna") == 0) {
      soundData = nanna;
  }
  else if (strcmp(sound, "pop") == 0) {
      soundData = pop;
  }
  else if (strcmp(sound, "mareebooboo") == 0) {
      soundData = mareebooboo;
  }
  else if (strcmp(sound, "telephone") == 0) {
      soundData = telephone;
  }
  else {
    Serial.println("No file found with name: " + String(sound));
    return;
  }

  Serial.println("Playing sound: " + String(sound));
  Serial.println("Duaration in seconds: " + String(seconds));

  XT_Wav_Class Sound(soundData);

  while(i<timetoPlay) {
    DacAudio.FillBuffer();                
    if(Sound.Playing==false)    
      DacAudio.Play(&Sound);       
    delay(/20);
    i++;
   }

  Serial.println("Finished sound: " + String(sound));
  flashingLed = true;
}

void setup() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(115200);
  delay(5000);

  Serial.println("");
  Serial.println("-----");
  Serial.println(" Your IoT");
  Serial.println("-----");
  Serial.println(" Starting..."); 

  WiFiEnable();
  // set the digital pin as output:
  pinMode(LED_PIN_1, OUTPUT);
  pinMode(LED_PIN_2, OUTPUT);

  // Route for root / web page
  server.on("/", HTTP_GET, [](AsyncWebServerRequest *request){
    request->send(/200, "text/plain", "Cortana Design IoT");
  });

  server.on("/restart", HTTP_GET, [](AsyncWebServerRequest *request){
    Serial.println("ESP - Restarting");
    request->send(/200, "text/plain", "OK");
    delay(/2000);
    ESP.restart();

  });

  server.on("/reset", HTTP_GET, [](AsyncWebServerRequest *request){
    Serial.println("ESP - Resetting");
    request->send(/200, "text/plain", "OK");
    delay(/2000);
    WiFiDisable();
    ESP.restart();
  });

  server.on("/sound", HTTP_GET, [] (AsyncWebServerRequest *request) {
    String inputParam0;
    String inputParam1;
    String inputMessage0;
    String inputMessage1; 
    if (request->hasParam(PARAM_INPUT_1) & request->hasParam(PARAM_INPUT_2)) {
      inputMessage0 = request->getParam(PARAM_INPUT_1)->value();
      inputMessage1 = request->getParam(PARAM_INPUT_2)->value();
      request->send(/200, "text/plain", "OK");
      soundWebServer = true;
      soundWebServerName = inputMessage0.c_str();
      soundWebServerSeconds = std::stod(inputMessage1.c_str(), nullptr);
    }
  });

    server.on("/flashled", HTTP_GET, [] (AsyncWebServerRequest *request) {
    String inputParam3;
    String inputMessage3; 
    if (request->hasParam(PARAM_INPUT_3)) {
      inputMessage3 = request->getParam(PARAM_INPUT_3)->value();
      request->send(/200, "text/plain", "OK");
      if (strcmp(inputMessage3.c_str(), "true") == 0){
        flashingLed = true;
      }
      else{
        flashingLed = false;
      }
    }
  });

  DefaultHeaders::Instance().addHeader("Access-Control-Allow-Origin", "*");
  server.begin();

  buttonA.begin(BUTTON_A_PIN);
  buttonA.setTapHandler(click);

  buttonB.begin(BUTTON_B_PIN);
  buttonB.setTapHandler(click);
  
  buttonC.begin(BUTTON_C_PIN);
  buttonC.setTapHandler(click);

  buttonD.begin(BUTTON_D_PIN);
  buttonD.setTapHandler(click);

  buttonE.begin(BUTTON_E_PIN);
  buttonE.setTapHandler(click);
}

void loop() {
  // read the state of the switch/button:
  buttonA.loop();
  buttonB.loop();
  buttonC.loop();
  buttonD.loop();
  buttonE.loop();

  unsigned long currentMillis = millis();

  if(flashingLed)
  {
    if (currentMillis - previousMillis_1 >= BLINK_INTERVAL_1) {
      ledState_1 = (ledState_1 == LOW) ? HIGH : LOW;
      digitalWrite(LED_PIN_1, ledState_1);
      previousMillis_1 = currentMillis;
    }

    if (currentMillis - previousMillis_2 >= BLINK_INTERVAL_2) {
      ledState_2 = (ledState_2 == LOW) ? HIGH : LOW;
      digitalWrite(LED_PIN_2, ledState_2);
      previousMillis_2 = currentMillis;
    }
  }
  else{
    digitalWrite(LED_PIN_1, HIGH);
    digitalWrite(LED_PIN_2, HIGH);
  }
  
  if(soundWebServer){
    const char* soundWebServerNameConst = soundWebServerName.c_str();
    playAudio(soundWebServerSeconds,soundWebServerNameConst);
    soundWebServer = false;
  }

  if ((WiFi.status() != WL_CONNECTED) && (currentMillis - previousMillis >=interval)) {
    Serial.print(millis());
    Serial.println("Reconnecting to WiFi...");
    WiFi.disconnect();
    WiFi.reconnect();
    previousMillis = currentMillis;
  }
}
```

**_Code example of the file 'daddy.h'_**

```
const unsigned char daddy[16106] = {
 0x52, 0x49, 0x46, 0x46, 0xE2, 0x3E, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45,
 0x66, 0x6D, 0x74, 0x20, 0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
 0x80, 0x3E, 0x00, 0x00, 0x80, 0x3E, 0x00, 0x00, 0x01, 0x00, 0x08, 0x00,
 0x64, 0x61, 0x74, 0x61, 0x54, 0x3E, 0x00, 0x00, 0x81, 0x82, 0x82, 0x82,
 0x82, 0x82, 0x81, 0x82, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81,
 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F,... truncated here}
```
