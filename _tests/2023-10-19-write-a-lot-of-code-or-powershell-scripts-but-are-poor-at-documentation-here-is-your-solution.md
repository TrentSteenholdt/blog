---

layout: post
author: trentsteenholdt
title:  "Write a lot of Code or PowerShell scripts but are poor at documentation? Here is your solution"
date: 2023-10-19
categories: [azure   powershell ]
tags:   documentation   psdocs   psrule
image: "/assets/images/from_wordpress/sigmund-cdMAU_x9mxY-unsplash-scaled.jpg"
---


We've all done it. Spent hours writing the most amazing ARM Template/Bicep file(s) or PowerShell script(s), and it produces nothing but magic. You're happy; the customer you've written it for is happy as you've solved their problem. But when it comes to sharing this intellectual property with others in your team, they are now tasked with spending hours reading what you've written to even understand it at a basic level! That sounds like their problem, right? NO!

Documentation is an essential part of any project, whether you're a developer, a system administrator, or a manager. Well-documented processes, code, and configurations are not only beneficial for the project's success but also for the overall efficiency of the team. However, writing documentation can be a time-consuming and often tedious task. Thankfully, there's a solution: [PSDocs](https://github.com/microsoft/PSDocs).

## What is PSDocs?

PSDocs, short for PowerShell Documentation, is a versatile and powerful documentation framework that enables you to automate the creation of documentation for various systems, scripts, configurations, and more. It was created by [BernieWhite (Bernie White) (github.com)](https://github.com/BernieWhite) and is designed specifically for PowerShell users or users who are well-versed in Azure, making it a valuable tool for IT professionals, developers, and system administrators.

## Why use it?

PSDocs simplifies the process of creating documentation by automating many of the repetitive and error-prone tasks that typically accompany manual documentation. With automation, you can save time and ensure that your documentation is always up to date. Let's explore some of the key features that make PSDocs a game-changer.

### 1\. Extensive Plugin Support

PSDocs offers a wide range of plugins, e.g. [PSDocs.Azure](https://azure.github.io/PSDocs.Azure/overview/), which are sets of rules and templates tailored to specific types of documentation. Whether you need to document your infrastructure, PowerShell scripts, modules, or custom applications, PSDocs has a plugin to suit your needs. This extensibility ensures you can create documentation aligning with your specific requirements without much effort.

### 2\. Custom Templates

With PSDocs, you have the flexibility to create custom templates for your documentation. You can control the layout, formatting, and style to match your organisation's branding or your personal preferences. Custom templates allow you to create professional and consistent documentation that reflects your unique style.

### 3\. Real-Time Documentation

One of the most significant advantages of using PSDocs is the ability to generate documentation in real-time. By running the PSDocs commands, you can obtain the most up-to-date information about your systems, configurations, or scripts. This ensures that your documentation is always current and accurate.

### 4\. Continuous Integration and Deployment (CI/CD) Integration

PSDocs can be seamlessly integrated into your CI/CD pipeline. This allows you to automatically update your documentation as changes are made to your systems, code, or configurations, keeping your documentation in sync with your projects.

## Let's demo it

Here is a step-by-step guide to get started with PSDocs and some script snippets to get this added to your existing projects!

1. Open up VS Code and open up your repo project with your various IaC templates and PowerShell scripts.

3. Open up a Powershell terminal and run.

```
Install-Module -Name PSDocs -Scope CurrentUser
```

3. If you want to use PSDocs for your Azure ARM Templates/Bicep Modules, also install

```
Install-Module -Name PSDocs.Azure -Scope CurrentUser
```

4. Now, in the project root folder, create a 'ps-docs.yaml' file in the root. This will be used in your CI/CD pipelines and reference when running the various PowerShell cmdlets. In this file, put the contents of:

```
configuration:
  AZURE_USE_PARAMETER_FILE_SNIPPET: false
  AZURE_USE_COMMAND_LINE_SNIPPET: true

output:
  culture:
    - 'en-AU'
```

5. Next, create a top-level folder in the project root called ".ps-docs" with the quotes.

[![](/assets/images/from_wordpress/image-29.png)](/assets/images/from_wordpress/image-29.png)

6. Inside the ".ps-docs" folder, create your first .ps1 file, which will follow the [provided syntax](https://github.com/microsoft/PSDocs#define-a-document) to read any code file you have and produce documentation for you. This file can be for any of your scripts, code templates and files, and its limits are pretty much endless! In the screenshot above, I used PSDocs to read [PSRule YAML files](https://azure.github.io/PSRule.Rules.Azure/setup/configuring-options/) and produce the documentation for them. Here is a good starting template to document PSRule YAML configurations:

```
Document PSRule {

    $yamlRaw = (Get-Content -Raw $InputObject.FullName)
    $object = ConvertFrom-Yaml -Yaml $yamlRaw -AllDocuments

    $title = [regex]::Match($yamlRaw, '(?<=Name:\s)(.+)').Groups[1].Value.Trim()
    $description = [regex]::Match($yamlRaw, '(?<=Description:\s)(.+)').Groups[1].Value.Trim()

    if ($title) {
        Title $title # Use title from comment in YAML file
    }
    else {
        Title $InputObject.Name # Use file name
    }

    if ($description) {
        $description # # Use description from comment in YAML file
    }

foreach ($rule in $object) {
        # Add an introduction section
        Section $rule.metadata.name {

            if ($rule.spec.expiresOn) {
                ('This rule will expire on ' + (Get-Date $rule.spec.expiresOn -Format 'yyyy-MM-dd' ) + '. This rule must be re-evaluated, with human intervention, for suitability in this solution as the rule has likely been superseded. Refer to any Azure and PSRule.Rules.Azure documentation for any changes that may have occurred.') | Warning
            }

            $rule.metadata.description

            $properties = @(
                @{ 
                    Name       = 'Rule Name'; 
                    Expression = { $rule.metadata.name } 
                }, 
                @{ 
                    Name       = 'Kind'; 
                    Expression = { $rule.kind } 
                })
        }
}
```

7. Now, with this config saved, you're pretty much at the point where you can run the "[Invoke-PSDocument](https://github.com/microsoft/PSDocs/blob/main/docs/commands/PSDocs/en-US/Invoke-PSDocument.md)" and output some pretty nifty markdown documentation for the PSRules configuration you have created. But for the sake of completion, here is a simple hardcoded script you can make use of:

```
  $psRulesCustomRulesFolder = $PSRuleDirectoryPaths | ForEach-Object { (Join-Path $PSScriptRoot $_) }
  $psRulesCustomRules = $psRulesCustomRulesFolder | ForEach-Object { Get-ChildItem ($_) -File -Filter *.yaml }
  $psRuleCustomRulesDocsFolder = Join-Path $PSScriptRoot '.\docs\PS-Rule-Doco'

  $allDirectories = $bicepDirectoriesHash.Values.Values + $psRuleCustomRulesDocsFolder
  foreach ($directory in $allDirectories) {
    if (-not(Test-Path $directory -ErrorAction SilentlyContinue)) {
      Write-Host "Directory path not found, creating $directory"
      $pathCreated = New-Item -ItemType Directory -Force -Path $directory
    }
  }  
  foreach ($file in $psRulesCustomRules) {
    $templateName = $file.BaseName
    $out = Invoke-PSDocument -Path $psDocsCustomPSRuleFile -InputObject $file -InstanceName $templateName -OutputPath $psRuleCustomRulesDocsFolder
    if ($out) {
      Write-Host -ForegroundColor Cyan "📃 $($out.Name) - PS Rule documentation created."
    }
    else {
      Write-Host -ForegroundColor Red "❌ $($template.BaseName) - PS Rule documentation creation failed."
    }
  }
```

This script/script block above can be run manually or inside a CI/CD pipeline to produce your documentation as needed.

Example output of General.Rules.YAML files being produced into documentation

[![](/assets/images/from_wordpress/image-30-1024x989.png)](/assets/images/from_wordpress/image-30.png)

And here is the original YAML file (part of) for reference:

[![](/assets/images/from_wordpress/image-31-1024x586.png)](/assets/images/from_wordpress/image-31.png)

## Conclusion

PSDocs is super damn powerful, and I wish I had known about it years ago! It's a tool that caan save you a significant amount of time and effort when it comes to documentation. By automating the documentation process, you can ensure that your projects are well-documented, up-to-date, and consistent, freeing up more of your time to focus on the exciting and creative aspects of your work.

Happy documenting!
