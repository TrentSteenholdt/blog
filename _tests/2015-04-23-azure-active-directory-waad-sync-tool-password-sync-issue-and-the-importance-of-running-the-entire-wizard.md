---

layout: post
author: trentsteenholdt
title:  "Azure Active Directory (WAAD) Sync Tool - Password Sync issue and the importance of running the entire wizard"
date: 2015-04-23
categories: [active-directory   office-365   windows-azure ]
tags:   active-directory   azure-ad-sync-tool   dirsync   fim   office-365   password-synchronisation   pcns   waad   windows-azure
image: "/assets/images/from_wordpress/sync-ADAzurePassword.png"
---


Today I came across an interesting find with the Azure AD Sync Tool that I thought I would share. The issue was rather easy to identify but someone with an untrained eye might find it confusing or a little misleading. When I say untrained this article is really for those who may be going alone with an Office 365 migration for the first time for their business or in a test lab... Though the semi-professional administrator may find this interesting.

To give you a bit of history about my knowledge on this, I come from the Forefront Identity Management 2010 (FIM) head space in that when myself and [Lain](https://lainrobertson.wordpress.com/) rebuilt a major university's IT infrastructure back in 2010-2011 we didn't have the freedom that comes with Office 365 / Azure AD today. I.e. It was FIM, FIM or, and you've guessed it, FIM. So when we built our management agents and the subsequent metaverse, it was staggered in order so that once everything was in place and we were happy with it, we'd go back and implement Password Change Notification Services (PCNS) as the last step.

Coming back to today however there are three options out there for us to use for directory synchronisation. Those being of course:

- **DirSync**. The widely used directory sync tool out there for many clients. It has served its purpose and proven to be a suitable solution for many organisations who just need basic Office 365 attribute flow etc.
- **Azure AD Sync**. The now standard and recommended solution for those looking to directory sync with Azure and Office 365. Those who are about to begin with directory sync this is the current recommended tool by Microsoft. Deter away from using DirSync as the eventual plan for that tool is for it to be put to pasture. The great thing about Azure AD Sync is that it supports multiple AD forests and password write back. Password write back shouldn't be confused with Password Sync by the way! They are two different things with two very different outcomes, especially around security implications!
- **FIM.** Lastly FIM is for those who need the ability to customise management agent's (MA's) to the needs of their business. An example where FIM is very powerful is where you have say a HR system (based on say SQL) that flows into an on-premise AD. Meaning your HR system is in fact the definitive source for identity management within your organisation. From AD however you then establish lots of different ADLDS instances for proprietary systems that you might not want talking or bloating AD itself (E.g. Cisco CUCM and Avaya UCM are two strong canidates for ADLDS). Then of course you configure the Office 365 MA and PCNS for provisioning to the Azure cloud.

There is actually a fourth option to this list above but it's only in a Public Preview at the moment. Going by the name **AD Azure Connect**, this product makes massive inroads for making ADFS federation a hell of a lot easier for the inexperienced administrator. Essentially you only need to provide it with the right certificate and create some DNS records and it configures ADFS for you. It's evident when comparing the four **DirSync** and **Azure AD Sync** look somewhat primitive and that Microsoft with this new tool are really pushing the customer base away from Same Sign-On to Single Sign-On (SSO). Unfortunately its hard to compare it with FIM as it is much more powerful in terms of configuration but also to the fact Microsoft haven't really stated what FIM's future is at the moment... I guess we'll know more when AD Azure Connect becomes GA.

So now back to my issue (sorry, got sidetracked). When I was going through the process of installing the Azure AD Sync Tool in a test lab I thought I'd be smart about making sure my metaverse wouldn't be filled up with unnecessary and unneeded objects (User and Groups) from my on-premise AD. When I say unneeded, I don't for example need groups such as "Domain Admins" synchronised to the cloud. Why? Well Office 365 doesn't need them and realistically, neither does your organisation. They for example wouldn't be using "Domain Admins" as a email distribution group and administrative privileges at the Office 365 at least are done at the user level not by groups! Of course you're wanted Lync and Exchange RBAC controls you may have a need for "Domain Admins" but again your probably don't either.

So when it came to the final screen on the wizard I unselected the "Synchronize now" checkbox. No problem as I'll change the filter on my on-premise AD Management Agent first (to pick a subset of OU's) and then run my first Full Import sync on both MA's manually. Done that, great... Now run the first sync by calling the **DirectorySyncClientCmd.exe** in the install location 'Bin' folder. Done. Awesome! I have got only the users and groups I needed in Azure AD and there is no initial 'disconnectors' in my metaverse. Time to assign licenses and get users on Office 365!

Now at the point I thought everything was great and I was ready to go... I attempt to login to the Office 365 portal with one of my synchronised accounts but I'm getting told it's not the right username and password combination. Hrmm, turns out I'm not close.... So what's gone wrong?

Well after a quick look at Event Viewer connected to the server running the Azure AD Sync tool I knew my problem straight away....

[![eventvwr-ADAzure](/assets/images/from_wordpress/eventvwr-ADAzure.png)](/assets/images/from_wordpress/eventvwr-ADAzure.png)

Event 652! But I told the wizard back at Step 4 that I wanted Password Synchronisation. What's going on?!

Well turns out if you choose not to run that first initial sync with the wizard, you're PCNS is not registered on the sever. In a way that does make sense because for PCNS to work you really do need accounts in the cloud to password sync too. But on the other hand it should be able to wait until the first 'Delta Imports and Exports' are run to go, okay, time to grab the password hashes and sync them because there is something there that is new and synced... Much as the case with a new user you create in on-premise AD and eventually syncs to the cloud. For those who don't know PCNS is run completely independent of the the sync tool and the scheduled task I'm about to talk about so I thought that the latter thought of mine would make the most sense. However it's clear with the application event log Microsoft have built the tool in a way that is contrary to that.

So what's the lesson here? Well if you want to change your on-premise AD MA filters before you run the first 'Full Imports' manually you really need to actually kick off the wizard first with 'Password Synchronization' on step 4 (Optional Features) unchecked. Once you've done what you've need to do with the OU filters etc., you need to disable (not delete) the newly created task in Task Schedular, run the wizard again, enable 'Password Synchronization' and save. Again to just remind you, you don't need to run the sync again because PCNS is independent of this.

Once that's all done, confirm the task as enabled again and if it hasn't, enable it manually. You should find also that your event log is full of Event 657 informing you that PCNS is syncing passwords propery.

Finally and this is just a quick note, if you have gone through the wizard already with Password Synchronisation enabled but you didn't let the wizard run the first sync, then you'll need to add in an additional step prior to the steps above that goes through the wizard first disabling Password Synchronisation. This is because the wizard does not go off and run everything again if it determines there are no changes to be made as you have made any selection changes etc.​

Happy syncing!
