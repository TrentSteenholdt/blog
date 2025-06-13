---
layout: post
author: trentsteenholdt
title:  "Migrating Certificate Services from Server 2012 R2 to Server 2019, the right way."
date: 2019-01-10
categories: [active-directory   powershell]
tags:  active-directory   adcs   adds   certificate-services   server   server-2019
---

So firstly, it's been about 4 years since my last blog post so I think an apology is in order. Honestly I thought the Ubuntu Server GuestVM I had this site running on was deleted years ago when I moved house. Turns out it wasn't and I just had it mis-configured with the wrong DNS settings (Reverse Proxy; yada, yada, yada). I can't believe this server has been here all this time with no one (including myself) ever seeing it, particularly when I'm always periodically looking at my Hyper-V console.

Anyways, as the title suggests I'm currently in the midst of a server refresh, because you know, you have to do that everyone once and a while. This task in-particular is for Active Directory Certificate Services and moving it to Server 2019 Core.

The server I'm moving from is Server 2012 R2 Core. So you can already get a sense the instructions that [everyone uses](https://blogs.technet.microsoft.com/canitpro/2014/11/11/step-by-step-migrating-the-active-directory-certificate-service-from-windows-server-2003-to-2012-r2/) because it works with any edition of Window Server wont work here because yep, I don't have a GUI. [I shouldn't need to tell you why in 2019, Server GUI is a bad, lazy way to so Server stuff](https://cloudblogs.microsoft.com/windowsserver/2018/07/05/server-core-and-server-with-desktop-which-one-is-best-for-you/).

Because I'm already running a SHA256 root CA the process is a bit more straight forward. If for whatever you're still running SHA1, then I'd suggest move the Certificate Services database first [then do the changes and certificate reissue for the new root.](https://blogs.technet.microsoft.com/askds/2015/10/26/sha1-key-migration-to-sha256-for-a-two-tier-pki-hierarchy/) _Tip: The GUI steps in this link are done command line below!_

So let's start with building our new Server 2019. Get the operating installed and go ahead and join it to the domain. On top of those, install the like-for-like Certificate Services role from the old server on the new server but don't configure them just yet! You can easily do a side-by-side comparison with running "Get-WindowsFeature" on the old and then just installing those roles with "Install-WindowsFeature" on the new.

![](/assets/images/from_wordpress/image.png)

<sup>When your new server has the new roles, Server Manager will show it like this. Leave it as is.  </sup>

Moving onto the Root Certificate and Certificate Service Database backup phase now. Get onto your old server and start up an administrative PowerShell window (_TIP: just type powershell.exe_). Run the following PS cmdlets:

```
cd C:\mkdir C:\CertificateServicesBackupBackup-CARoleService c:\CertificateServicesBackup  -Password (Read-Host -prompt "Password:" -AsSecureString) 
```

When prompted, provide a password that you'll remember. You'll need it later.

[https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/manage/component-updates/ca-backup-and-restore-windows-powershell-cmdlets](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/manage/component-updates/ca-backup-and-restore-windows-powershell-cmdlets)

Okay, so backup of Certificate Root and Database done, now to backup some important registry settings. In the same PS window, lets backup the important registry now.

```
reg export HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc C:\CertificateServicesBackup\backup.reg
```

Great! Now take a copy of the C:\\CertificateServicesBackup folder and keep it safe, maybe even on the new server. (_TIP: "xcopy /e /s C:\\CertificateServicesBackup \\\\newserver.fqdn.com\\c$"_)

At this point we've got what we need, everything is backed up. Now for what people would think is the scary bit and that's the removal of the old server! This is an important step because doing this later, not at all or after the migration will seriously screw up Active Directory... so don't do that. Let's remove it now and be done with it.

Safely remove the old certficate server roles with the "Remove-WindowsFeature" cmdlet. Once that's done, remove the server from domain.

Now it's onto the new. With Server Manger or Windows Admin Center lets now click that link to complete the set up we said we would never touch. Tricked you! Go through the wizard until you get to this screen...

![](/assets/images/from_wordpress/image-1.png)

<sup>Look familiar? It should, because we're following the same step as the everyone uses blog!  </sup>

As the [everyone uses](https://blogs.technet.microsoft.com/canitpro/2014/11/11/step-by-step-migrating-the-active-directory-certificate-service-from-windows-server-2003-to-2012-r2/) blog article suggests, we're going to provide an existing certificate and private key (protected by password). That certificate is the one you backed up earlier and the password you remembered.

Now, continue through the wizard with all the defaults, including the questions about the database to use as we'll restore over the new database with the backed up data. When the wizard is done, jump onto the server and launch an administrative PowerShell window again. This time we're running the restore PS cmdlet.

```
Stop-Service certsvc  Restore-CARoleService c:\CertificateServicesBackup -Password (read-host -prompt "Password:" -AsSecureString) -Force 
```

Again the password is the one we remembered. With that done, we just needed to import the registry settings in. Before you do this, I suggest you open the .reg file in notepad.exe and just check to make sure there is no FQDN's, Hostnames or IP's that need updating. If they do, so that before import the registry file by running the below.

```
reg import HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc C:\CertificateServicesBackup\backup.reg
```

At this point you're basically done! Start the service and make sure it comes up.

```
Start-Service certsvcGet-EventLog (for errors)
```

Your last task is to re-issue your certificate templates into Active Directory. Easy to just do this with the certsrv.msc management console go to "Certificate Templates (right click) > New > Certificate Template to issue"

![](/assets/images/from_wordpress/image-2.png)

<sup>The last step! Hooray!</sup>

That's it from me, have a splendid day!

Cheers,

Trent
