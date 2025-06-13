---

layout: post
author: trentsteenholdt
title:  "Home IoT - Part 4 - The ‘final’ solution and the things I learned"
date: 2020-09-20
categories: [iot ]
tags:   net-core   arduino   esp32   iot   powershell
image: "/assets/images/from_wordpress/image-17.png"
---


This blog post is part of a series of posts were I’ve automated, and Internet of Things (IoT) enabled my garage door, swing gate and Bluetooth enabled garden irrigation system. Links below to each part!

- Part 1 – [The start of the IoT journey](/2020/09/01/home-iot-part-1-the-start-of-the-journey/)

- Part 2 – [Putting it together and integration](/2020/09/03/home-iot-part-2-putting-it-together-and-integration/)

- Part 3 – [What about my garden irrigation system](/2020/09/19/home-iot-part-3-what-about-my-garden-irrigation-system/)

- Part 4 – This part

### Last changes from lessons learnt

So it’s been a good couple of weeks now with the home IoT setup, and everything has been pretty good. However, it hasn’t been all perfect, and some changes have been made since I last blogged.

Firstly, a weird issue where the Holman BTX-8 Bluetooth server would stop working after a couple of days kept cropping up. I suspect this is because the ESP32 is always connected with it, unlike the phone app which connects only when it writes a characteristic. To mitigate this, I’m simply calling ESP.restart() every night at 2 am via the webserver to give the Holman device some time alone which seems to do the trick.

Another significant change since the last write up is the way I handle the webserver on the ESP32 itself. While part 1’s example code gave me a great starting point, it became annoying when wanting to make small front-end tweaks to the webserver, which resulted in recompiling the C++ code every time. To mitigate this problem, I have since moved the front-end code into a standalone .Net Core web app that makes HTTP Gets to the ESP32.

![](/assets/images/from_wordpress/image-15.png)

<sup>.Net Core WebApp communicating with HTTP Get to the ESP32</sup>

This approach has made life so much better. Not only do I now essentially have the ESP32 working like an API service, but I can further improve the .Net core web app and allow external access to it backed by Azure AD authentication. Now, with AzureAD permissions, I can grant just me and the stakeholder access to the app which can be accessed anywhere in the world

For those interested to know why I deployed the .Net core app on-premises on an IIS server vs. using Azure, this was because of a cost-saving exercise and being able to use my own private DNS and PKI infrastructure.

The .Net Core app has been super valuable. Not only do I no longer need to carry around with me my garage and gate remotes, but over the past few weeks, I’ve come to find how hit and miss IFTTT can be. Sometimes there is a lengthy 2-3 minute delay making the call to the PowerShell runbook, which is not great when your sitting in your car, waiting for the gate and garage to open. The .Net core app doesn’t have any of these delays!

Below is a code snippet of the ActionResult in the .Net Core WebApp which makes the HTTP get calls. All I'm doing is providing this action with the full URL (base64 encoded) to the call from the front-end with some simple JS and jQuery. Simple, and does the job.

```
        public static string Base64Decode(string base64EncodedData)
        {
            var base64EncodedBytes = System.Convert.FromBase64String(base64EncodedData);
            return System.Text.Encoding.UTF8.GetString(base64EncodedBytes);
        }
        public async Task<ActionResult> GetFromExternal(string url)
        {
            string urlDecode = Base64Decode(url);

            var client = new HttpClient();

            Task<string> getStringTask =
                client.GetStringAsync(urlDecode);

            string contents = urlDecode;
            try
            {
                contents = await getStringTask;
            }
            catch
            {
                contents = "Something went wrong.";
            }
            return Content(contents);
        }
```

### Making the garden irrigation timing smarter using BOM data

Another improvement I’ve made is to the irrigation timings and smarts around changing the running times based on the actual weather.

Like many, every summer, I tend to forget bumping up the watering times or leave it too late, and my garden suffers because of it. To stop this happening ever again, I have put together two PowerShell scripts which also run locally to save on cost.

The first script pulls data from the Bureau of Meteorology of the last few days temperature and evaporation loss. Using that data with a few switch statements the script creates a JSON file with the timings to run the stations for that day. The range could be from not at all, right up to an extreme 40 minutes per station, which would only happen if there were maximum temperatures over 50 degrees for a whole week!

The second script reads the JSON file to water the garden based on that schedule if it’s one of the permitted watering days.

![](/assets/images/from_wordpress/image-16.png)

<sup>Two PowerShell scripts using BOM data to trigger irrigation run on the ESP32</sup>

Get BOM Data PowerShell script.

```
<#
        .SYNOPSIS
        Downloads BOM data and creates a JSON file.

        .DESCRIPTION
        This script creates a JSON file with irrigation timings to be invoked with another PowerShell script.
        The script is designed to get the best irrigation timings based on the tempature in the last X days and some other factors like how often the irrigation would run per WaterCorp regulations.

        .PARAMETER JSONFile
        Specifies the file name.

        .OUTPUTS
        JSON File used for the other PowerShell script to schedule irrigation.

        .EXAMPLE
        C:\PS> Invoke-IrrigationTimings.ps1 -JsonFile "payload.json"
        File.txt

        .NOTES
        Requires access to the internet.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$JSONFile
)

Write-Host "`r`nInvoke-IrrigationTimings.ps1 is running" -ForegroundColor Cyan 
Write-Host "---`r`n" -ForegroundColor Cyan 

$a = "http://www.bom.gov.au/climate/dwo/{0}/text/IDCJDW6111.{0}.csv"

$datelast = (Get-Date).AddMonths(-1);
$datelast = $datelast.ToString("yyyyMM");

$date = Get-Date -f "yyyyMM"

$combined = @{};

$a -f $date
$data = (Invoke-WebRequest -Uri ($a -f $date)).Content
$combined = $data

$a -f $datelast
$data = (Invoke-WebRequest -Uri ($a -f $datelast)).Content
$combined += "`r`n"
$combined += $data

$combined = $combined -replace "�", "" -split "`r`n" | Where-Object { $_ -like ",*" -and $_ -notlike ",`"*" } 

$data = foreach ($point in $combined) {

    $data = $point -split ","
    New-Object psobject -Property @{
        Date                  = [datetime]::Parse($data[1])
        "Maximum temperature" = $data[3]
        "Minimum temperature" = $data[2]
        "Rainfall"            = $data[4]
        "Evaporation"         = $data[5]
    }
}
$data = $data | Sort-Object Date 

$daystocheckdata = switch ( Get-Date -f "%M") {
    { 11..12 -contains $_ -or 1..2 -contains $_ } { 5 }
    { 9..10 -contains $_ -or 3..5 -contains $_ } { 7 }
    { 6 -contains $_ -or 8 -contains $_} { 5 }
    { 7 -contains $_ } { 0 }
}
Write-Host -ForegroundColor Cyan "`r`nHow many days to check =" $daystocheckdata 

$data = ($data | Select-Object -Last ($daystocheckdata + 1)) | Select-Object -First $daystocheckdata

$data | Format-Table

$rainfall = ($data."Rainfall" | Measure-Object -Sum).sum
$evaporation = ($data."Evaporation" | Measure-Object -Sum).sum
$mintemp = ($data."Minimum temperature" | Measure-Object -Sum).sum
$maxtemp = ($data."Maximum temperature" | Measure-Object -Sum).sum

Write-Host "Rainfall =" ([math]::Round($rainfall, 2))
Write-Host "Evaporation =" ([math]::Round($evaporation, 2))
Write-Host -ForegroundColor Cyan "Sum of evaporation =" ([math]::Round($rainfall - $evaporation, 2)) "`r`n"
Write-Host "Sum Min Temp =" $mintemp
Write-Host "Sum Max Temp =" $maxtemp
Write-Host -ForegroundColor Cyan "Sum of Temps =" ($mintemp + $maxtemp) "`r`n"

$totalloss = ([math]::Round($rainfall - $evaporation, 2))
$totaltemp = ($mintemp + $maxtemp)

$calc1 = switch ($totaltemp) {
    { 401..1000 -contains $_ } { 40 }
    { 351..400 -contains $_ } { 30 }
    { 301..350 -contains $_ } { 25 }
    { 251..300 -contains $_ } { 20 }
    { 201..250 -contains $_ } { 15 }
    { 151..200 -contains $_ } { 10 }
    { 0..150 -contains $_ } { 0 }
}

$calc2 = switch ($totalloss) {
    { $_ -le -70 } { 40 }
    { $_ -le -55 } { 30 }
    { $_ -le -45 } { 25 }
    { $_ -le -35 } { 20 }
    { $_ -le -20 } { 15 }
    { $_ -gt -20 -and $_ -lt 10 } { 10 }
    { $_ -ge 10 } { 0 }
}

$calc = ([array]$calc1, $calc2 | Measure-Object -Maximum).Maximum
$calc_int = [convert]::ToInt32($calc, 10)
Write-Host -ForegroundColor Cyan "Recommended station watering =" $calc "minutes `r`n"

$startTime = "07:00 AM"

$arrayStations = @(1, 2, 3, 4)

[int]$count = 0;
$Object = @()

foreach ($station in $arrayStations) {
    $properties = @{
        station = $station
        time    = [datetime]::ParseExact($startTime, "hh:mm tt", $null).AddMinutes($calc_int * $count);
        runtime = $calc_int
    }
    $count++;

    $Object += New-Object psobject -Property $properties;
}
$json = $Object | ConvertTo-Json 

$json
$path = Join-Path $PSScriptRoot -ChildPath $JSONFile

Write-Host "`r`nWriting JSON file..." $path

$json | Set-Content $path

Write-Host "`r`nScript completed."
```

### The end solution

The below diagram gives a great overview of how the whole solution has come together over these last few weeks.

![](/assets/images/from_wordpress/image-17.png)

<sup>The entire solution</sup>

#### So what did I learn through this project?

- There are a lot of great tutorials out there that will get you started. They definitely helped me so I'd like to think anyone with IT and some coding experience should be able to pick this up. Caution though, some examples do naughty things like unencrypted MQTT!

- Arduino sketches are pretty easy to put together once you've got the IDE configured correctly. E.g. Libraries, example sketches etc. Much like anything, make sure your tooling works first, before doing anything big.

- Azure IoT Hub is probably a bit too big for this project. I'm contemplating switching MQTT over to [Adafruit.io](/2020/09/01/home-iot-part-1-the-start-of-the-journey/) as it would probably make integration with IFTTT a lot easier.

- Make sure to check out [HomeAssistant](http://homeassistant.io/) and [ESPHome](https://esphome.io/) first as it may cater to all your needs. I learnt about these services mid-way through the project so I kept on the same course of doing my own sketch on the ESP32.

- Think about your ESP32 as an API endpoint or as something that just listens to MQTT subscriptions to do an action. Having it be a front-end webserver became far too unwieldy after a while, especially with no over-the-air (OTA) updates.

- IFTTT recently announced a [paid pro model](https://ifttt.com/pro), which limits what you can do with the free version. Consider and factor in running costs of your IoT solution, especially if actions can be triggered simply using on-prem scripts and cron jobs like I did.

In final, I absolutely loved this challenge and learned so much on this journey. If you’re not sure about doing your first IoT project, I hope this series has helped you in jumping right in!
