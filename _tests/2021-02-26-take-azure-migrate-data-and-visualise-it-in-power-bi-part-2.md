---

layout: post
author: trentsteenholdt
title:  "Take Azure Migrate data and visualise it in Power BI - Part 2"
date: 2021-02-26
categories: [azure ]
tags:   azure   azure-migrate   powerbi
image: "/assets/images/from_wordpress/6.png"
---


**_This was originally posted [here while working for Telstra Purple](https://purple.telstra.com/blog/azure-migrate-data-in-powerbi-part2)._**

In the second part of this series, I’ll take you through the last few steps to visualise your Azure Migrate data using Power BI. If you haven’t read part one and would like to, click [here](https://purple.telstra.com/blog/azure-migrate-data-in-powerbi-part1).  
[](https://purple.telstra.com/blog/azure-migrate-data-in-powerbi-part1)

## Tables

In the previous blog post, I didn’t go into great detail about how the combined data sources from the Azure Migrate workbooks should be formatted as tables in Power BI. This is particularly important as the Assessment Summary and Assessment Properties worksheets are formated with information on rows rather than columns. To help with your formatting, here are the queries I used for each table.

#### All Assessed Machines

```shell
let
    Source = Folder.Files("D:\Downloads"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform All Assessed Machines", each #"Transform All Assessed Machines"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "Source.Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"Source.Name", "Transform All Assessed Machines"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform All Assessed Machines", Table.ColumnNames(#"Transform All Assessed Machines"(#"Sample File")))
in
    #"Expanded Table Column1"
```

#### All Assessed Disks

```shell
let
    Source = Folder.Files("D:\Downloads"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform All Assessed Disks", each #"Transform All Assessed Disks"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "Source.Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"Source.Name", "Transform All Assessed Disks"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform All Assessed Disks", Table.ColumnNames(#"Transform All Assessed Disks"(#"Sample File"))),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded Table Column1",`{`{"Monthly cost estimate ", type number}, {"Source disk size(GB)", Int64.Type}, {"Target disk size(GB)", Int64.Type}, {"Disk read(MBPS)", type number}, {"Disk write(MBPS)", type number}, {"Disk read(ops/sec)", Int64.Type}, {"Disk write(ops/sec)", Int64.Type}})
in
    #"Changed Type"
```

#### Assessment Properties

```shell
let
    Source = Folder.Files("D:\Downloads"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),  #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform Assessment Properties", each #"Transform Assessment Properties"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "File Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"File Name", "Transform Assessment Properties"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform Assessment Properties", Table.ColumnNames(#"Transform Assessment Properties"(#"Sample File"))),
    #"Pivoted Column" = Table.Pivot(#"Expanded Table Column1", List.Distinct(#"Expanded Table Column1"[Property]), "Property", "Selected value"),
    #"Duplicated Column" = Table.DuplicateColumn(#"Pivoted Column", "File Name", "File Name - Copy"),
    #"Renamed Columns" = Table.RenameColumns(#"Duplicated Column",`{`{"File Name - Copy", "Group Name"}}),
    #"Replaced Value" = Table.ReplaceValue(#"Renamed Columns",".xlsx","",Replacer.ReplaceText,{"Group Name"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Replaced Value",`{`{"VM uptime - Day(s) per month", Int64.Type}, {"VM uptime - Hour(s) per day", Int64.Type}})
in
    #"Changed Type"
```

#### Assessment Summary

```shell
let
    Source = Folder.Files("D:\Downloads"),
    #"Filtered Hidden Files1" = Table.SelectRows(Source, each [Attributes]?[Hidden]? <> true),
    #"Invoke Custom Function1" = Table.AddColumn(#"Filtered Hidden Files1", "Transform File", each #"Transform File"([Content])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoke Custom Function1", {"Name", "File Name"}),
    #"Removed Other Columns1" = Table.SelectColumns(#"Renamed Columns1", {"File Name", "Transform File"}),
    #"Expanded Table Column1" = Table.ExpandTableColumn(#"Removed Other Columns1", "Transform File", Table.ColumnNames(#"Transform File"(#"Sample File"))),
    #"Filtered Rows1" = Table.SelectRows(#"Expanded Table Column1", each [Azure Migrate] <> null and [Azure Migrate] <> ""),
    #"Pivoted Column" = Table.Pivot(#"Filtered Rows1", List.Distinct(#"Filtered Rows1"[#"Azure Migrate"]), "Azure Migrate", "Column2"),
    #"Changed Type" = Table.TransformColumnTypes(#"Pivoted Column",`{`{"Total machines assessed", Int64.Type}, {"Machines not ready for Azure", Int64.Type}, {"Machines ready with conditions", Int64.Type}, {"Machines ready for Azure", Int64.Type}, {"Machines readiness unknown", Int64.Type}, {"Total monthly cost estimate AUD", Currency.Type}, {"Compute monthly cost AUD", Currency.Type}, {"Storage monthly cost AUD", Currency.Type}, {"Standard disks cost AUD", Currency.Type}, {"Standard SSD disks cost AUD", Currency.Type}, {"Premium disks cost AUD", Currency.Type}})
in
    #"Changed Type"
```

As you can see in each of these queries, one of the four custom functions I created previously is used. This function makes it possible to pull data from all the worksheets and merge them into one table from the source directory folder.  

## Data Model

Power BI will automatically try to match the tables and columns to build a model that works once you have created your tables. Sometimes this can be spot on, but in some circumstances, some manual intervention is needed.

[![](/assets/images/from_wordpress/4-2-1024x604.png)](/assets/images/from_wordpress/4-2.png)

With the data tables from Azure Migrate, it’s possible that the mapping for All Assessed Disks may get confused and try to map on the Group name. You don’t want this, as assessed disks should match on the associated machine they are attached to. To correct this, change the data model by mapping the following relationships as per the table below.

| Table  | Column | Relationship | Column | Table |
|---   |---   |---   |---   |---   |
| Assessment Summary | Group name | 1 to 1 (both direction) | Group name | Assessment Properties |
| Assessment Summary  | Group name | Many to one (single direction) | Group name | All Assessed Machines |
| All Assessed Machines | Machine | Many to one (single direction) | Machine | All Assessed Disks |

## Visuals

With your data model ready, you’re now at the point of creating the visuals you need to assess the suitability for migrating workloads to Azure. This is a relatively straight forward task, dragging and dropping the visualisations you’re after in the report.

When creating your reports, consider using slicers and filters as they will help you narrow in on the assessments you created in Azure Migrate while also giving you the ability to get a holistic overview. To demonstrate this, have a look at the screenshots below.

[![](/assets/images/from_wordpress/5-1-1024x600.png)](/assets/images/from_wordpress/5-1.png)

[![](/assets/images/from_wordpress/6-1024x602.png)](/assets/images/from_wordpress/6.png)

## Expanding the data model with your own data

The great thing about using Power BI for visualising this data is that it’s now possible to map other data sources in your data model to enrich your dataset, something that isn’t possible in Azure Migrate right now. For example, suppose you can grab an extract from your CMBD or service register. In that case, you should be able to map business-related information like Server/Application Owner to the Azure Migrate data by either using the assessment group name or to the machine names.

[![](/assets/images/from_wordpress/7-1024x605.png)](/assets/images/from_wordpress/7.png)

## Conclusion

I hope you found this two-part blog series interesting on how you can take Azure Migrate data and enrich it with Power BI and potentially other data sources. If you’re interested in trying this yourself, the Power BI template (PBIT file) can be [downloaded here](https://github.com/trentsteenholdt-readify/data/blob/master/AzMigrate-Template.pbit?raw=true).
