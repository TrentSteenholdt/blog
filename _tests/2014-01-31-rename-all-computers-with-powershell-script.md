---

layout: post
author: trentsteenholdt
title:  "Rename all computers with a Powershell script"
date: 2014-01-31
categories: [active-directory   powershell ]
tags:   active-directory   powershell
image: "/assets/images/from_wordpress/powershell-renamecomputer.png"
---


It's an activity that all of us will have done numerous times in the past and will do in the future... **rename a computer**! But what happens when say the organisation you work for changes their workstation naming standard and want to have all the workstations renamed straight away?! Well, a simple powershell script is your answer!

What you need?

- RSAT Tools. In particular the Active Directory powershell module. Aka, "Import-Module ActiveDirectory"
- Rights to rename these workstations assuming AD delegation is set up. It doesn't have to be **Domain Admins**!
- Permission to run the script from the business (Refer below note).

```
$organizationalunit = "OU=Computers,OU=Staff,DC=contoso,DC=com"
$computers = Get-ADComputer -SearchBase $organizationalunit | where {$_.name -notlike "Contoso-*"}
$num = 0001
 
Foreach($computer in $computers)
{
 For($num=1;$num -lt $computers.count;$num++)
    {
        Rename-Computer -Computername $computer -NewName "Contoso-$num" -Force -Restart
    }
}

```

This powershell script will search the OU of **"OU=Computers,OU=Staff,DC=contoso,DC=com"**, get all the AD computers in this OU that doesn't have the name like "**Contoso-\***" and will rename them "**Contoso-0001**" and upwards until all the computers are renamed. It's easy to change the 'Get-ADComputer' cmdlet to get say only Windows XP machines! Just add:

```
  -Filter {OperatingSystem -Like "*XP*"}

```

**Just to note:** This script will restart the remote computers! So do this out-of-hours or when you organisation has approved the change. Removing the -restart switch will cause authenication issues until the workstation is of course, restarted.

Hope this helps renaming all thos computers!
