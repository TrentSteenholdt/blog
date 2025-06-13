---

layout: post
author: trentsteenholdt
title:  "Take Azure Migrate data and visualise it in Power BI - Part 1"
date: 2021-02-25
categories: [azure ]
tags:   azure   azure-migrate   powerbi
image: "/assets/images/from_wordpress/1-1.png"
---


**_This was originally posted [here while working for Telstra Purple](https://purple.telstra.com/blog/azure-migrate-data-in-powerbi-part1)._**

In this two-part series, I’ll take you through the necessary steps to take data from Azure Migrate and visualise it in a much friendlier way in Power BI. In this first part, I’ll share how I worked through Azure Migrate’s problems and started putting together the data sources in Power BI.

## Azure Migrate

Azure Migrate is a great tool to help businesses lift-and-shift workloads into Azure pretty quickly. Unfortunately though, it’s use case kind of stops there at present. While useful features are being added all the time, there is still a bit of work to get it up to feature parity with competing products like Cloudamize that support tagging and better workload separation.

Sadly, these current limitations are most evident in how cumbersome it is to grab data out in a way that makes sense for a business. Microsoft recommends [creating groups](https://docs.microsoft.com/en-us/azure/migrate/how-to-create-a-group) to break down servers/workloads logically but then gives absolutely no way to visualise a holistic overview of the entire digital estate! This is a major pain point if you’re looking to present your Azure Migrate data to key stakeholders interested in different things. For example, a CFO may want to know the entire running cost of the digital estate or a subset of logical groupings. But at the same time, an application owner would probably only care about making sure their workloads are compatible with Azure.  

At this point, you really only have two options. One is to create just one big group and get all the workloads in one report. Or the other is to create lots of groups using a logical separation and deal with the multiple reports generated somehow.

For my use case, and most likely for yours, many Azure Migrate groups still make the most sense. Creating groups based on applications and the environment (e.g. “Intranet – Dev”) provide greater visibility if that application is suitable for Azure. After all, not every workload in your digital estate can be moved at once!

When creating the Azure Migrate groups, keep in mind that any [assessments](https://docs.microsoft.com/en-us/azure/migrate/how-to-create-assessment) you create are bounded by the group. So while you have got a nice break down of your digital estate, you now got the problem of tieing it all together. This is where Power BI can help!

### Exporting Azure Migrate Assessments with the REST API

Once you have created all your groups and assessments in Azure Migrate, you now need to get your data somewhere so Power BI can use it. Assessment exports (Excel) are possible but depending on how many assessments you’ve created, there will be multiple files to download. The problem, however, is the UI in the Azure Portal is horrible in terms of getting this data out! It’s at least five (5) clicks to get to the assessment export button, and there is no guarantee when you click on it that it downloads! Thankfully, you can get to these Excel files pretty quickly with the REST API. Here’s a simple script that does it for you.

```
<#
        .SYNOPSIS
        Downloads all Excel file assessments to a folder specified.
        .DESCRIPTION
        This script gets all current assessments in Azure Migrate and downloads them to a folder for easy viewing.
        .PARAMETER AssessmentProjectName
        Name of the Azure Migrate Assessment Project. Note this is not the name of the Azure Migrate Project itself! You need to pull this first. See https://docs.microsoft.com/en-us/rest/api/migrate/assessment/projects
        .PARAMETER SubscriptionID
        The Azure Subscription ID of where the Azure Migrate Project is.
        .PARAMETER ResourceGroupName
        The name the Resource Group of where the Azure Migrate Project is.
        .PARAMETER CustomerName
        The name of the customer this script is being run for.
        .EXAMPLE
        C:\PS> Export-AzMigrateAssessmentsExcelAllToFolder.ps1 -AssessmentProjectName "MyProject" -SubscriptionID "00000000-0000-000-0000-0000-0000" -ResourceGroupName "MyResourceGroup" -ExportFolder "D:\Downloads"
        .NOTES
        Requires:
          - Contributor rights to the Azure Migrate Project resource and resource group.
          - Latest Az Module.
          - Invoke-WebRequest is used. Make sure you’re proxy setting allows the files to be downloaded.
          - Connect-AzAccount to be run first and logged in with an account or Service Principle with the access noted above. 
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$AssessmentProjectName,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionID,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ })]
    [string]$ExportFolder
)

Write-Host "`r`nExport-AzMigrateAssessmentsExcelAllToFolder.ps1 script is starting."
Write-Host "---`r`n"

$token = (Get-AzAccessToken).Token

$authToken = @{ 'Content-Type' = 'application/json'
    'Authorization'            = 'Bearer ' + $token
}

$allGroups = (Invoke-RestMethod -Method GET -Uri "https://management.azure.com/subscriptions/$($SubscriptionID)/resourceGroups/$($ResourceGroupName)/providers/Microsoft.Migrate/assessmentprojects/$($AssessmentProjectName)/groups?api-version=2019-10-01" -Headers $authToken).value
$allGroupswithAssessment = $allGroups | Where-Object { $_.properties.assessments -ne $null }

$downloads = @{}
foreach ($group in $allGroupswithAssessment) { 
    Write-Host "Getting assessment for $($group.name)"; 
    $url = ("https://management.azure.com" + $group.properties.assessments + "/downloadUrl?api-version=2019-10-01"); 
    $downloads += @{$group.name = (Invoke-RestMethod -Method POST -Uri $url -Headers $authToken).assessmentReportUrl } 
}

foreach (
    $download in $downloads.GetEnumerator()) { 
    $file = Join-Path $ExportFolder ($download.name + ".xlsx")
    Invoke-WebRequest $download.value -OutFile $file
}

Write-Host "`r`nExport-AzMigrateAssessmentsExcelAllToFolder.ps1 script is starting."
Write-Host "---`r`n" 
```

## Source

With potentially hundreds of Excel files to manage because of the number of assessments you’ve made, the next step will be to bring these files into Power BI. There are two ways you could do this from a data source perspective. These are:

1. Use a folder path data source for files on local storage, or

3. Move the files to a SharePoint Online document library and use a SharePoint site data source.

Here are some power queries to help you get started.

#### SharePoint query

```shell
let
    Source = SharePoint.Files("https://purple.sharepoint.com/sites/example/", [ApiVersion = 15]),
    #"Filtered Rows" = Table.SelectRows(Source, each ([Folder Path] = "https://purple.sharepoint.com/sites/example/Shared Documents/AzMigrateData/")),
    Navigation1 = #"Filtered Rows"{0}[Content]
in
    Navigation1
```

### Local Folder query

```shell
let
    Source = Folder.Files("D:\Downloads")
in
    Source
```

In my experience, the OData query with the SharePoint data source is incredibly slow, so I’d recommend keeping it locally sourced. That way, you shouldn’t face any query timeout issues l initially faced building out this solution.

## Transform and Combine

Once you have the sources right and can see the excel files in Power BI, you need to transform and combine each worksheet inside each assessment workbook. For each Azure Migrate workbook, there are four worksheets we need to get data from. These are:

- Assessment\Summary

- All\Assessed\Disks

- All\Assessed\Machines

- Assessment\Properties

[![](/assets/images/from_wordpress/1-1-1024x728.png)](/assets/images/from_wordpress/1-1.png)

To make this easy, Power BI gives us a “Combine Data” process when looking at source files from the local/SharePoint folder source. To make use of this, open up the Power Query editor for the source folder and use the combine button (see the screenshot below) on the Content column.

[![](/assets/images/from_wordpress/2-1-1024x544.png)](/assets/images/from_wordpress/2-1.png)

In the transformation wizard, you are only given the option to combine just one of the four worksheets. To get all of them, there are two paths you can take.

1. Firstly, you could repeat this process four times for each worksheet. This works fine but does make a mess with sample files and parameters. Or,

3. Secondly, you could do this for just one worksheet and then make multiple copies of the first function. Then all you need to do is make some tiny edits to get the desired worksheet in the four functions.

If the second option is the path you want to take, here are the function queries for your reference.

#### All Asssed Machines

```shell
let
    Source = (Parameter1) => let
        Source = Excel.Workbook(Parameter1, null, true),
        All_Assessed_Machines_Sheet = Source{[Item="All_Assessed_Machines",Kind="Sheet"]}[Data],
        #"Promoted Headers" = Table.PromoteHeaders(All_Assessed_Machines_Sheet, [PromoteAllScalars=true])
    in
        # “Promoted Headers”
in
    Source
```

#### All Assessed Disks

```shell
let
    Source = (Parameter1) => let
        Source = Excel.Workbook(Parameter1, null, true),
        All_Assessed_Disks_Sheet = Source{[Item="All_Assessed_Disks",Kind="Sheet"]}[Data],
        #"Promoted Headers" = Table.PromoteHeaders(All_Assessed_Disks_Sheet, [PromoteAllScalars=true])
    in
```

#### Assessment Properties

```shell
let
    Source = (Parameter1) => let
        Source = Excel.Workbook(Parameter1, null, true),
        Assessment_Properties_Sheet = Source{[Item="Assessment_Properties",Kind="Sheet"]}[Data],
        #"Promoted Headers" = Table.PromoteHeaders(Assessment_Properties_Sheet, [PromoteAllScalars=true])
    in
        #"Promoted Headers"
in
    Source
```

#### Assessment Summary

```

let
    Source = (Parameter1 as binary) => let
    Source = Excel.Workbook(Parameter1, null, true),
    Assessment_Summary_Sheet = Source{[Item="Assessment_Summary",Kind="Sheet"]}[Data],
    #"Promoted Headers" = Table.PromoteHeaders(Assessment_Summary_Sheet, [PromoteAllScalars=true])
in
    #"Promoted Headers"
in
    Source
```

As you can see in these power queries, the Source is referring to a Parameter called Parameter1. Because there are potentially multiple Azure Migrate assessment workbooks in the folder, we need to filter on one of them to define the custom function query. Then, when we used this custom function in the power query for each table, all the worksheets will be merged. Here is what you need for the Parameter1 and the supporting Sample File query if you’re having trouble making these custom functions work.

#### Parameter1

```
#"Sample File" meta [IsParameterQuery=true, BinaryIdentifier=#"Sample File", Type="Binary", IsParameterQueryRequired=true]
```

#### Sample File

```shell
let
    Source = Folder.Files("D:\Downloads"),
    Navigation1 = Source{0}[Content]
in
    Navigation1
```

As you can see, Sample File will use the first file in the directory by using the Source index of 0. This does not mean we’ll only pull the worksheets from just one file. As the name implies, it’s only a sample.

## Summary

[![](/assets/images/from_wordpress/3-1-1024x547.png)](/assets/images/from_wordpress/3-1.png)

With the custom functions and sample file parameter created, you should now be able to make the necessary tables by calling the right custom function in the table query to get all the data. If you’re unsure how to do this, keep an eye out for part two, where I’ll provide the power queries needed for the tables, build out the data model and create some reports. Stay tuned!
