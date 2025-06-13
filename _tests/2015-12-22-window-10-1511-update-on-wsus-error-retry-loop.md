---
layout: post
author: trentsteenholdt
title:  "Windows 10 1511 update on WSUS error (Retry Loop)"
date: 2015-12-22
categories: [windows-10   windows-update   wsus]
tags:  windows-10   windows-update   wsus
---

A quick post today for those who may be struggling with WSUS and Windows 10 1511 updates. It turns out there is one missing component/ step in order to get WSUS to deliver these new type of updates.

Lets assume you are the administrator, knowing enough about WSUS to have already completed the following:

1. On the WSUS server(s), running Windows Server 2012 or later, installed the required manual update. [https://support.microsoft.com/en-us/kb/3095113](https://support.microsoft.com/en-us/kb/3095113)
2. On the same WSUS server(s), made appropriate changes to see Upgrade classification patches from the Windows catalog.
3. Have approve the appropriate Windows 10 1511 Upgrade patches and have them successfully download onto the WSUS server(s).
4. Attempted a client-side Windows Update.

On step 4, non-1511 Windows 10 client are seeing this error with a simply retry button.

> There were problems installing some updates, but we'll try again later. If you keep seeing this and want to search the web or contact support for information, this may help:

The solution comes from a bit of digging in the WindowsUpdate.log/ Get-WindowsUpdateLog. It appears that the Windows update client is unable to find a file with the suffix \*.esd. For me this was 6F5CDF12827FAE0E37739F3222603EAF38808H12.esd.

Looking at the WSUS server, and in particular the IIS component of WSUS I could see this file was in fact in the directory so the client should get it... Hrmm, let's try the direct URL to the file, ah! 404! That's no good.

Let's check the MIME types to see if this file type can be downloaded from IIS. Nope! IIS is unable to dish out the file because \*.esd files are a new MIME type that is not configured in IIS.

Okay, I'll quickly add this and give it another go.

[![2](/assets/images/from_wordpress/2.png)](/assets/images/from_wordpress/2.png)

Sure enough success!

[![1](/assets/images/from_wordpress/1.png)](/assets/images/from_wordpress/1.png)
