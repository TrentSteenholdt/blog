---

layout: post
author: trentsteenholdt
title:  "Home IoT - Part 1 - The start of the journey"
date: 2020-09-01
categories: [iot ]
tags:   arduino   esp32   iot
image: "/assets/images/from_wordpress/image-7.png"
---


Over the past few weeks, I’ve automated, and Internet of Things (IoT) enabled my garage door, swing gate and never to be finished with everything, my Bluetooth-enabled garden irrigation system which required some reverse engineering. If you’re interested to know more and the challenges I faced, keep reading!

- Part 1 – This post

- Part 2 – [Putting it together and integration](/2020/09/03/home-iot-part-2-putting-it-together-and-integration/)

- Part 3 – [What about my garden irrigation system](/2020/09/19/home-iot-part-3-what-about-my-garden-irrigation-system/)

- Part 4 – [The ‘final’ solution and the things I learned](/2020/09/20/home-iot-part-4-the-final-solution-and-the-things-i-learned/)

### Background

So to give you some context and background, custom IoT is relatively new to me. Of course, we all have smartwatches and gadgets at home these days but I've never worked with micro-controllers and integration, protocols and services like Adafruit.io, Azure IoT Hub, and MQTT, I'm a bit nervous I'll get tripped up here. _To be really honest, I had to google MQTT to know what it was for, so you could say my experience was very much a beginner._

As for automation, I’ve got some pretty good experience with pipelines, scripting, logical flows (Logic Apps, PowerAutomate, IFTTT Runbooks) and function apps. Enough knowledge and know-how that I knew I would be relying heavily on these skills to help with the IoT learning curve I’m about to embark on.

On top of some knowledge around automation, to call it out early, you’ll definitely need some coding experience to customise your solution. However, there are great examples out there that give you the full solution of controlling relays, sensors and displays with a microcontroller. At the end of my journey, I ended up doing C++, HTML, CSS, Javascript, .Net Core and PowerShell, but really, you could do a lot of this by copying coding examples from reputable sources (Arduino ESP32 example library), plugging your variables and hitting the compile button.

Lastly, full disclaimer here, when I started with this project, I jumped right into it without much of a plan. The series of blog posts is more about a journey of tinkering that tested my knowledge, my patience and my sanity! There are probably a million better ways to do this yourself, such as [Home-Assitant](https://www.home-assistant.io/) and [ESPHome](https://esphome.io/), but I wanted to get a deep understanding of the ins and outs of IoT, so when I do this the next time, for reals, I’d know 😉

### Challenges

Like any project, this one not only had technical challenges but business challenges too. Yep, a business challenge in the home! This challenge was working with the key stakeholder, my wife. While she’s a lover of tech (though she doesn’t admit that), she’s not a big fan of seeing home automation on the news and how it’s spying and mining all our conversations (data) for advertising.

So with the stakeholder uneasy already on what I’m about to set out to do, our at least the perception of what I was going to do, I had to set out some ground rules for myself.

### Rules

Knowing the challenges I would face with the key stakeholder, I gave myself some rules and boundaries for this project. They were:

1. I can’t control anything inside the house. **The stakeholder was very clear about that.**

3. I wouldn’t be able to install any third-party apps on the stakeholder’s phone to assist with the home automation.

5. No Google Homes, no Alexa’s, no anything that is listening in our home.

### Let's get started

Alright, to get started, we need some hardware to run this on. Something like an Arduino, Rasberry Pi, ESP8266 or an ESP32. I wanted something cheap and did all the things, so here is where I made my first mistake and brought something from [eBay](https://www.ebay.com.au/itm/4-Channel-Remote-Switch-Wifi-Bluetooth-Relay-Module-Built-in-ESP32S-For-Android/233586457006?ssPageName=STRK%3AMEBIDX%3AIT&var=533267026306&_trksid=p2060353.m2749.l2649).

![](/assets/images/from_wordpress/image-3.png)

<sup>The custom PCB that I fried</sup>

My recommendation if you’re starting out with IoT, buy a hardware option from a known manufacturer. Custom PCB’s, while sounding like a great idea (“Hey, this does everything, I can’t go wrong”), are very lacking in documentation. I learned my mistake by frying the eBay custom PCB by sending 5v somewhere I shouldn’t have because the PCB schematic was wrong. Turns out I has got a different iteration of the PCB from the doco.

What I ended up with is something much more manageable, buying from a local store my ESP32 development board that had integrated USB and a separate 4-ch relay controller. Not only did I have documentation of the pin layouts (trust me, knowing your pin layouts comes in handy when you start putting it all together) but the people at my local store were super helpful about how I should tackle the project.

![](/assets/images/from_wordpress/image-4.png)

<sup>Take two, using the ESP32 dev-kit board and 4ch relay</sup>

Links to the hardware:

- [ESP32 dev board](https://www.altronics.com.au/p/z6385-esp-32s-wifi-bluetooth-module-and-interface-board/)

- [The 4-ch relay control](https://www.altronics.com.au/p/z6327-4-channel-5v-relay-control-board/)

So with the hardware, I need to start putting it together. Thankfully, following the tip from the guys at my local store, there is plenty of ESP32 how-to blogs with relay controls. My need was a webserver (noting I couldn’t use third-party apps on the stakeholder’s phone), so a quick Google and I landed on Rui Santos’s end-to-end example here:

- [YouTube video](https://www.youtube.com/watch?v=giACxpN0cGc)

- [Associated blog post](https://randomnerdtutorials.com/esp32-relay-module-ac-web-server/)

The code you see in his post is C++, which you need to compile with an IDE. Arduino IDE is an excellent starting point with the ESP32 library, but you can also do this in VS Code (still requires Arduino IDE).

- [Arduino IDE](https://www.arduino.cc/en/main/software)

- [ESP32 library in Arduino IDE](https://randomnerdtutorials.com/installing-the-esp32-board-in-arduino-ide-windows-instructions/)

- [VS Code Extension](https://github.com/microsoft/vscode-arduino)

![](/assets/images/from_wordpress/image-18.png)

<sup>The ESP32 sketch in Arduino IDE</sup>

With my IDE ready, I'm now ready to get started. In the next part, I’ll talk about how I took Rui Santos tutorial and got my first iteration working! Stay tuned!
