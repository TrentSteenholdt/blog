---

layout: post
author: trentsteenholdt
title:  "Home IoT - Part 2 - Putting it together and integration"
date: 2020-09-02
categories: [iot ]
tags:   arduino   css   esp32   html-2   iot   js   powershell
image: "/assets/images/from_wordpress/image-10.png"
---


This blog post is part of a series of posts were I’ve automated, and Internet of Things (IoT) enabled my garage door, swing gate and Bluetooth enabled garden irrigation system. Links below to each part!

- Part 1 – [The start of the IoT journey](/2020/09/01/home-iot-part-1-the-start-of-the-journey/)

- Part 2 – This post

- Part 3 – [What about my garden irrigation system](/2020/09/19/home-iot-part-3-what-about-my-garden-irrigation-system/)

- Part 4 – [The ‘final’ solution and the things I learned](/2020/09/20/home-iot-part-4-the-final-solution-and-the-things-i-learned/)

### Okay, time to put this together

So not long after following Rui Santos’s blog post and video (see [part 1](/2020/09/01/home-iot-part-1-the-start-of-the-journey/)), I had my ESP32 controller on our home Wi-Fi network and running a webserver that would switch on/off a relay with a toggle function.

To start, I had only wired up the first relay to the appropriate GPIO, but I had compiled the C++ code to make use of all four relays. Yep, I only have the garage and gate to automate, but why not think big!

![](/assets/images/from_wordpress/image-5.png)

<sup>ESP32 dev-board wired to one relay</sup>

![](/assets/images/from_wordpress/image-6.png)

<sup>Webserver on the ESP32</sup>

The first problem with the example code is that I needed my gate and garage door buttons to be a momentary press rather than a switch. A necessary change because I planned to hook up the relay to the normally open (NO) loop of both the garage and gate and with it potentially stuck in the closed position, they were essentially locked out from any other action from the conventional remotes. It also didn’t make sense to turn on and then immediately off the switch to get the functionality I needed. So with a bit of HTML, JS and CSS changes plus giving the GPIOs nicer labels in the C++ code, I had what I was after.

At this point, I was pretty excited. I had a web server that gave me the ability to control my gate and garage when on the network. However, I faced another problem the very next day. A bit more back story, the gate I’ve installed blocks any access to the front of the house and subsequently, the meter boxes. This design decision became a sticking point when the meter reader rang my Ring doorbell on the gate, and I couldn’t let him in because no one was home or on the network. At that point, I was like huh, maybe I could connect my Ring Doorbell to this? Perhaps get it to send a push notification to my phone when it’s rung, that I can acknowledge, and make the call to trigger the momentary button press on the gate?!

![](/assets/images/from_wordpress/image-7.png)

<sup>The gate in question</sup>

In comes Azure IoT Hub and the power of MQTT. Essentially, I needed my ESP32 to be listening to Azure IoT Hub for the call to action and do the thing I needed it to do.

![](/assets/images/from_wordpress/image-8.png)

<sup>Azure IoT Hub integration with the ESP32</sup>

The best way to describe this is a boy (the ESP32) constantly nagging for the chocolate bar (the action) at the exit aisle by pestering mum (Azure IoT Hub). When Azure IoT Hub says yes after persistently saying no, as in changes from 0 to 1, little Jimmy ESP32 gets his chocolate (opens the gate).  
  
To call it out, as it’s sometimes misunderstood, there is no backdoor (inbound access) to the ESP32 from the outside world. MQTT is all about subscribing and publishing messages, so by nature of that principle; it’s always outbound traffic.

Setting up the subscribing and publishing of values was relatively straight forward. In my C++ code, all I needed to do was to connect to the Azure IoT Hub and set up a function in the loop() that checked if the value had changed, do the function to open the gate and then, have another function then publish back after write HIGH (back to LOW) 0 again.

```
void publishAzuredata(char* event, unsigned int value){
  client.publish(event, value);
}
void subscibeAzuredata(char* event){
  client.subscribe(iothub_subscribe_endpoint);
}

void reconnect() {
   while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect(iothub_deviceid, iothub_user, iothub_sas_token)) {
      Serial.println("connected");
  
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println("try again in 5 seconds");
      // Wait 5 seconds before retrying
      delay(5000);
    }
  }
}

void callback(char* topic, byte* payload, unsigned int length) {
  if (String(topic) == "device/deviceID/gate") {
    if (value == "1") {
      digitalWrite(gatePin, HIGH);
      delay(/2000);
      client.publish(topic, 0);
      digitalWrite(gatePin, LOW);
    }
    else if (value == "0") {
      //do nothing really
      //digitalWrite(gatePin, LOW);
    }
  }
}

void setup(){
  client.setServer(mqttServer, mqttPort);
  client.setCallback(callback);
  subscibeAzuredata("device/deviceID/gate");
  subscibeAzuredata("device/deviceID/garage");
  connect_mqtt();
}
void loop(){
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
}
```

To interface with Azure IoT Hub itself and change the value of 0 to 1, I had a few options like a Logic App or Function App in Azure. However, to keep it simple, I decided to stick with what I know and write a PowerShell script hosted in a Runbook that I could call with a WebHook. That way I could do an HTTP Post with a JSON body that could say open the gate or garage or even both at the same time.

Now that I have the WebHook, I could theoretically call it from anywhere in the world, but I wanted to have a nice way of doing it besides using Postman. Here is where I leveraged IFTTT applets, one for my phone (push notification with IFTTT app), and another for Google Assistant.  

![](/assets/images/from_wordpress/image-9.png)

<sup>Integration with IFTTT and the WebHook</sup>

The end result of it all coming together…

![](/assets/images/from_wordpress/image-10.png)

<sup>ESP32 dev-board and the 4ch relay in a box to be installed</sup>

<https://youtu.be/BZeTJtz9crE>

Stay tuned for the next part where I integrate my Bluetooth garden irrigation system with my ESP32 so I can smarten up my irrigation system!
