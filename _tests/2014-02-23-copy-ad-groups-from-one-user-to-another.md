---
layout: post
author: trentsteenholdt
title:  "Copy AD groups from one user to another"
date: 2014-02-23
categories: [active-directory   powershell]
tags:  active-directory   ad   powershell
---

It seems that a lot of my posts recently have been around AD group membership and I guess that makes sense as for the past few weeks I have been mostly cleaning up a lot of the mistakes by other IT professionals for my new clients. Alas it's coming a long way with PowerShell.

This script is very simple but a goody. It copies the group memberships of one user and gives it to another.

```
param(
  [parameter(Position=0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, mandatory=$true)][string]$SourceUser,
  [parameter(Position=0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, mandatory=$true)][string]$DestinationUser
)

Import-Module ActiveDirectory;

$originalErrAction = $ErrorActionPreference;
$ErrorActionPreference = "SilentlyContinue";

$groups = (Get-ADUser -Identity $SourceUser -Properties MemberOf).MemberOf;

foreach ($group in $groups) {
  Add-ADGroupMember -Identity $group -Members $DestinationUser;
}

$ErrorActionPreference = $originalErrAction;

```

Save this as **Copy-ADGroups.ps1** or something similar and call is by running **.\\****Copy-ADGroups.ps1 $SourceUser $DestinationUser** where the $value is replaced with the AD user idenity. E.g. "Trent Steenholdt".
