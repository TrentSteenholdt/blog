---
layout: post
author: trentsteenholdt
title:  "Remove disabled users from AD groups"
date: 2014-03-08
categories: [active-directory   powershell]
tags:  active-directory   ad   adac   aduc   powershell   scripting
---

I had an interesting request from a client today in so far they wanted AD to be cleaned out completely... Hrrm? Okay? So what do you mean by cleaned? \*Insert joke about dcpromo demoting the domain\*.

The response I got was -  _**"We want you to delete all the disabled AD accounts".**_

While I thought okay, that's possible I still had my questions. Why? What are these disabled accounts hurting? Why do they need to vanish off the face of the earth?

It's an interesting topic to discuss around the industry as I'm personally not one to delete users ever! Though I have worked with others who insist on deleting and even moving disabled AD users in another OU. The latter being simply administrative overhead and something that is easily averted by using an LDAP query that doesn't show them. Plus if another administrator later on enables them again and forgets to move them back to the appropriate OU then that account could be getting the right the right Group Policy settings!

Accounts that have been disabled for well beyond 10+ years I believe still have a place in your AD. Why? Well that person could still one day could return at any time. Why not give them their old account again rather than worry about provision a new one. Sure you can delete their mailbox which is consuming space and maybe delete the contents of their home share (not the actual folder thouht) but that account still belongs to someone... It still has an idenity and a face that needs to be kept for historical and future purporses.

To give you an example, I had another client have the same user leave and return three times in as many weeks! Yike right! Well no problem, I didn't have to go repeating the account provisioning process over and over.

Another reason not to go blowing your accounts away to hell is how indenity management is making massive inroads in our industry. For one example Office 365 with one way provisiong (DirSync or the coming WAAD) use your AD as the authoritive source. When you start deleting accounts you're disjoining those objects in the synchronisation metaverse. Not a problem when you delete, but when a new account with the same old UPN comes back, it can be quite a pain.

So after a bit of coming and going with the client they finally came back to me with their reasoning.... **"I don't like seeing all the disabled members in ADUC/ ADAC when I'm modifying group memberhship."**

This particular client allows their in-line managers to manage group memebership for their files shares and some distribution groups. This was possible thanks to some nifty AD delegation I set up for them a few months earlier.

So no worries I now know what they want me to do. They don't want the accounts to dissappear, but they do want them to be isolated from all their old security groups. I supported this request as it's always good practice for any business to review users group memberships and there is no better time to do that then when the new user or a user returns.... "Okay Jimmy, what access do you actually need".

So rather than go around and delete the same 100 account or so from 500 different security groups I got onto PowerShell again. Scripting is seriously good for things like this!

**WARNING:** Do not use this script if you has placed all your users and groups so to speak in the original "Users" container (not OU) in a domain. Many Microsoft services etc. can leverage disabled accounts in group membership for delgation etc. and running this script over those groups will pull them out. This script also doesn'y log very well as it justs spits the output to the console... So it will be difficult to go add all the accounts back in, especially if dealing with a lot of users or groups.

```
Import-Module ActiveDirectory
foreach ($group in (Get-ADObject -Filter { (ObjectClass -eq "group") -and (mailNickname -like "*") } -SearchBase "ou=groups,ou=staff,ou=contoso,dc=contoso,dc=com")) {
  Write-Host $group.Name -Foreground "green";
  foreach ($member in (Get-ADGroupMember -Identity $group)) {
    if ($member.objectClass -eq "user" -and ($member.distinguishedName.ToLower().Contains("ou=users,ou=staff"))) {
      $user = Get-ADUser -Identity $member.distinguishedName
      if ($user.enabled -eq $false) {
        Write-Host $user.Name
        Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false
      }
    }
  }
}

```

There are some important aspects of this groups you should take note of. These are:

1. The -**SearchBase** parameter is where your AD groups you wish to clean are.
2. The **$member.distinguishedName.ToLower().Contains** is where you store your AD users.
3. The **if ($user.enabled -eq $false)** is what makes sure the account is Disabled. You could change this if statement for example if you wanted to remove all users with a particular office location, phone number or event last name!

That's it for now, next blog post will be whenever I feel a need to put something up!
