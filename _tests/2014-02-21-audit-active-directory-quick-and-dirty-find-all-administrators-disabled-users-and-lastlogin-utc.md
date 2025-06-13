---

layout: post
author: trentsteenholdt
title:  "Audit Active Directory quick and dirty. Find all administrators, disabled users and lastlogin (UTC)"
date: 2014-02-21
categories: [active-directory   powershell]
tags:  active-directory   ad   audit
---

I had the need today to do a quick audit of Active Directory and see where it was at for a client. Not just the norm like **dcdiag.exe, repadmin** and checking the Event Viewer to see if there were any issues but also how many administrators there are, who is disabled (if any as I had my doubts) and the last last login for each user. PowerShell to the rescue.

```
if ((Get-Module -Name ActiveDirectory) -eq $nul) { Import-Module ActiveDirectory }

$admins = Get-ADGroupMember -Identity "Administrators" -Recursive
$admins += Get-ADGroupMember -Identity "Domain Admins" -Recursive
$admins += Get-ADGroupMember -Identity "Enterprise Admins" -Recursive

Write-Host "Administrative accounts" -ForegroundColor Green
foreach ($admin in ($admins | Sort-Object -Property sAMAccountName -Unique)) { if ($admin.objectClass -eq "user") {Write-Host $admin.sAMAccountName} }

Write-Host "Disabled users" -ForegroundColor Green
foreach ($user in (Get-ADUser -Filter {Enabled -eq $false} | Sort-Object -Property sAMAccountName)) { Write-Host $user.sAMAccountName }

# I'd STRONGLY recommend using the -SearchBase parameter to reduce query load if at all possible
Write-Host "Last logon times (UTC)" -ForegroundColor Green
foreach ($user in (Get-ADUser -Filter * -Property lastLogonTimestamp | Sort-Object -Property sAMAccountName)) { if ($user.lastLogonTimestamp -eq $null) {$dt = ''} else { $dt = [datetime]$user.lastLogonTimestamp }; Write-Output($user.sAMAccountName +","+ $dt) | Write-Host }

```
