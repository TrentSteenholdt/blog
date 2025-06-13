---
layout: post
author: trentsteenholdt
title:  "Invalid namespace - EventID 906 - AD Azure Sync Tool (WAAD)"
date: 2015-05-18
categories: [active-directory   office-365   windows-azure]
tags:  active-directory   azure-ad-sync-tool   office-365   password-synchronisation   waad   windows-azure
---

Today I came across an interesting issue where the AD Azure Sync Tool via Microsoft Online alerted me that AD Azure Sync had failed to run for some time!

[![errorADAzure](/assets/images/from_wordpress/errorADAzure.png)](/assets/images/from_wordpress/errorADAzure.png)

This was quite odd as there had been no changes to the Office 365 or AD instances that provide the identity sources for this AD Azure Sync. There were some power outages in their server room that caused a few other services to not come up clean so I thought it could be that the service failed to start etc. Monitoring by SCOM said otherwise though! Okay time for checking the event logs and within a few seconds found this.

[![errorADAzure2](/assets/images/from_wordpress/errorADAzure21-1024x574.png)](/assets/images/from_wordpress/errorADAzure21.png)

Interesting! EventID 906 "Invalid Namespace"... That's the same issues that appeared with the old DIRSYNC.exe when the WMI object had unregistered itself. Common for example if you have SCCM client installed on the server or something else goes through and manipulates the WMI classes probably where it shouldn't be. Okay, let's fix this quickly without having to reinstall anything... Something that you had to do with DIRSYNC.exe. A total pain in the backside, and if you weren't careful, you could have ended up with a boatload of disconnected objects in the metaverse!

At this point I had a choice. Do these steps manually or create a dirty batch script that will do the work for me and if needed in the future, on demand. I decided to do both, ran the steps manually and once I was happy with it, save my work into the batch file for future use!

So below is my script that I first ran the commands or enacted the same thing the script would do with the GUI. Once I actually had it all set up and AD Azure working again, I actually ran the new script again (over the top of my manual work) to confirm that the script was safe. And sure enough, it was and everything was working fine after the script ran.  
  
To break down what the script does here is a list of what each row does.

1. 'mofcomp' parses the MMS (FIM) wmi file and goes through the process of adding the classes etc. to the WMI repository.
2. 'regsvr32' then registers the WMI .dll file to the server.
3. 'net stop winmgt /y' stops the WMI management services and its dependancies.
4. The following 'net start' commands then start the services stopped when we fired off the 'net stop'. The services are also started in the correct order.
5. Finally, we run AD Azure Sync manually by calling "DirectorySyncClientCmd.exe".

```
mofcomp "D:\Program Files\Microsoft Azure AD Sync\Bin\mmswmi.mof"
regsvr32 /s "D:\Program Files\Microsoft Azure AD Sync\Bin\mmswmi.dll"

net stop winmgmt /y
net start winmgmt
net start "IP Helper"
net start "User Access Logging Service"
net start "Microsoft Azure AD Sync"

"D:\Program Files\Microsoft Azure AD Sync\Bin\DirectorySyncClientCmd.exe"

```

As you can see the directory for which AD Auzre has been installed is the D: drive. You can change this batch file with %Program Files% if you're using your system drive (C:).

That's it from me for now. I hope this helps others in the future using the AD Azure Sync Tool!
