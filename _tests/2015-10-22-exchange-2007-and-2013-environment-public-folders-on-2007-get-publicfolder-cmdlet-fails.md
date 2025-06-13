---
layout: post
author: trentsteenholdt
title:  "Exchange 2007 and 2013 environment - Public Folders on 2007 \"Get-PublicFolder\" cmdlet fails."
date: 2015-10-22
categories: [exchange]
tags:  exchange
---

Recently I was tasked with a Public Folder migration project moving the public folders from Exchange 2007 to 2013. This particular company had been on Exchange 2013 for pretty much everything except Public Folders for well over a year which provides a good segue into this issue! When the administrators tried to manage Public Folders on Exchange 2007 they're were getting no where! Both the Exchange 2007 Public Folders Management Console would not load any of the public folders (500+ of them) and the Get-PublicFolder cmdlet would fail with:

**There is no existing PublicFolder that matches the following Identity: '\\'. Please make sure that you specified the correct PublicFolder Identity and that you have the necessary permissions to view PublicFolder.**

Yikes! Well that's no good! So how is it possible that PublicFolders are online and working for end users yet the administrators can't manage them! Let the investigation begin. Funnily enough “Get-PublicFolderStatistics” still worked!

After talking to the engineers previously tasked with the migration to Exchange 2013 work, it was when the last remaining mailbox database in Exchange 2007 was removed that Public Folders management broke. This immidiately led me to believe either one of two things:

1. It's a permission issue with the administrative accounts they're using.
2. Something isn't quite right with objects in AD referencing Public Folders in Exchange 2007.

After a quick look around I confirmed that while the permissions for managing Exchange infrastructure was a bit all over the place, it wouldn't have been the root cause. Their accounts had the right permissions to Organizational Management and/or the Public Folders Owner security group in AD.

Taking a dive in AD with ADSI/ LDP (If you're using ADSI, connect with a non-domain admin account to prevent accidental changes) I could again see things were a bit messy with two administrative groups, but everything was in order. The Folder Hierarchy CN was there and its references were correct.

Hitting TechNet with searches on "Exchange 2007" lead me to issues around the HomeMDB being nulled when the last mailbox database is removed for each Exchange 2007 server for the Microsoft System Attendant object. Sure enough this attribute was null so I immediately tested by creating a new fresh Exchange 2007 mailbox database to see if that was the issue. HomeMBD was instantly populated for the Microsoft System Attendant object when I created the databases but alas, still the above issue!

At this point I was really clutching at straws and therefore started checking the ‘interwebs’ and found all sorts of whacky recommendations and fixes! There are some shockers out there and it does scare me that someone with no background experience in Exchange/ AD could follow them and make a real mess of their environment. Sadly, you can't help those who can't help themselves!

None of them really fitted well with the issue I had and/ or made practical sense to even action. So with that in mind I made a call to Microsoft.

After a bit of coming and going as you do with Microsoft tier 1 support the suggestion was to populate the Exchange 2013 servers Microsoft System Attendant object with a HomeMDB attribute to the Exchange 2007 mailbox databases. As you can appreciate with my comments already above I found this a bit baffling and refuted it. However that didn’t stop me from looking at it a bit more…

On one of the Exchange 2007 Servers I got going the troubleshooting tool and selected trace control. From there I proceeded beyond the warning messages about running traces when only recommended by an Exchange support engineer.

[![3](/assets/images/from_wordpress/3.png)](/assets/images/from_wordpress/3.png)

Leaving all the trace file configuration pretty much default, I did want to capture only Store trace errors (similar to [https://support.microsoft.com/en-us/kb/971878](https://support.microsoft.com/en-us/kb/971878)) so I made this selection. For trace types I selected all of them.

For the trace tags, I took a stab in the dark a couple of times to see what I wanted to check against. After much trial and error I got it down to three which found me the issue…. These were:

- tagDSError
- tagInformation
- tagRpcIntfLogon

[![2](/assets/images/from_wordpress/2.png)](/assets/images/from_wordpress/2.png)

[![1](/assets/images/from_wordpress/1.png)](/assets/images/from_wordpress/1.png)

While the trace was running I then opened up an Exchange 2007 management shell and ran “Get-PublicFolder” to let it fail. Stopping the trace and running the report on the trace highlighted my issue!

\---
-

**tagDSError - Mailbox /o=Y/ou=Exchange Administrative Group (FYDIBOHF23SPDLT)/cn=Configuration/cn=Servers/cn=XXX/cn=Microsoft System Attendant, does not have either a Home MDB or a GUID**

**tagInformation - EcConnect2: User /o=Y/ou=Exchange Administrative Group (FYDIBOHF23SPDLT)/cn=Configuration/cn=Servers/cn=XXX/cn=Microsoft System Attendant, does not have a Home MDB/GUID attribute**

**tagRpcIntfLogon -Connect as /o=Y/ou=Exchange Administrative Group (FYDIBOHF23SPDLT)/cn=Configuration/cn=Servers/cn=XX/cn=Microsoft System Attendant failed; connect flags were 0x1**

**\---
-**

XXX CN was an Exchange 2013 server! Aha, Microsoft tier 1 support are onto something. Okay, well I don’t believe them about the Exchange 2007 mailbox database though! So I thought what’s stopped me putting in an Exchange 2013 mailbox database, at least that way the information would be accurate and not legacy!

So I jumped into ADSI edit this time as Domain Admin and found one of the mailbox databases in Exchange 2013. This is under ADSI -> Configuration -> Services -> Microsoft Exchange -> Administrative Groups -> Exchange Administrative Groups -> Databases. I copied out the DN attribute and then went to each of the Exchange 2013 servers and set the homeMBD as that DN. Note that if you have multiple AD sites to pick a mailbox database local to that sites server.

I gave it 15mins to replicate in AD (that’s the replication time for this client) and run the “Get-PublicFolder” cmdlet and sure enough… it worked! Now we're ready to migrate to Exchange 2013!

That's it for now, until next time.
