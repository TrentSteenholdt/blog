---

layout: post
author: trentsteenholdt
title:  "Parallel deployment jobs with Azure DevOps pipelines"
date: 2020-12-21
categories: [azure   cloud   devops ]
tags:   azure   azure-devops   devops   pipelines   powershell
image: "/assets/images/from_wordpress/b.png"
---


**_This was originally posted [here while working for Telstra Purple](https://purple.telstra.com/blog/parallel-deployment-jobs-with-azure-devops-pipelines)._**

## Development of your linear pipeline

After a few days of development, you have successfully put together a comprehensive Azure DevOps pipeline to deploy a whole heap of infrastructure and components for a new service. It’s all working well, but there is just one annoying problem, and that’s how long it’s taking to deploy!

Because of the size of each deployment step which may include some very slow Azure virtual machine deployments that can take anywhere from 30 to 40 minutes, it’s taking way too long! Sometimes, even more than 60 minutes, which means you’re now hitting the timeout limit on a [Microsoft-hosted agent with a private project/repository](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/phases?view=azure-devops&tabs=yaml#timeouts). Oh no, what now?!

[![](/assets/images/from_wordpress/d-1024x132.png)](/assets/images/from_wordpress/d.png)

## Introducing parallel pipelines

If you’re at this point, you’re not alone. Over the past week, I’ve been tackling ways in which I could optimise and improve an Azure DevOps pipeline that is deploying quite a few components. This pipeline was very linear, but it didn’t need to be as there were a few Azure Powershell tasks that didn’t have dependencies on each other, so why not run them in parallel? Here was my thinking to get the pipeline, knowing each steps timings, under 60 minutes again.

[![](/assets/images/from_wordpress/e-1024x323.png)](/assets/images/from_wordpress/e.png)

### Layout and understand what you can run in parallel

First, to start optimising your pipeline, I recommend laying out and understanding your dependencies between each deployment step. This understanding can be quite time-consuming, especially if you’re not entirely familiar with each step in a pipeline. However, do take the time to get this right, as it will save you considerable time in the long run as I didn’t do this work upfront myself. Mapping out the pipeline could end up looking something like it did below for me.

[![](/assets/images/from_wordpress/a-1024x409.png)](/assets/images/from_wordpress/a.png)

As you can see, there were quite a few dependencies on each PowerShell script (step), but there were some things that could run at the same time. As a matter of fact, in my mapping, I actually found where I could have three jobs running at the same time, which helped reduce the pipeline from 60 minutes to about 35 minutes!

### Making the switch to parallel pipelines

To start, I needed to make sure of a couple of things. First and foremost, I made sure I had purchased some additional [Microsoft-hosted agents parallel jobs](https://docs.microsoft.com/en-us/azure/devops/pipelines/licensing/concurrent-jobs?view=azure-devops&tabs=ms-hosted) as I was running this in a private project/repository. Secondly, I made sure that all of my published variables were [output variables](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-variables-in-scripts) by setting **isOutput=true** on the **task.setvariable** logging command. Without doing this, variables cannot be passed between jobs.

At this point, I then needed to switch my deployment steps pipeline template ([a pipeline YAML file sitting under **azure-pipelines.yml**](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops)) to the higher level of a deployment jobs template. Jobs are the lowest point where you can have them running in parallel, and with the added support of [re-running failed jobs without needing to re-run the entire pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/runs?view=azure-devops), it made a lot of sense to go to this level.

| Old Pipeline | New Pipeline |
|---   |---   |
| azure-pipelines.yml   \-- deployment-steps.yml | azure-pipelines.yml   \-- deployment-jobs.yml |

What was done previously in the **deployment-steps.yml**.

```
steps:
  - task: AzurePowerShell@5
    displayName: Run Identities deployment
    inputs:
      azureSubscription: ${{ parameters.adosServiceConnectionName }}
      pwsh: true
      azurePowerShellVersion: LatestVersion
      ScriptType: FilePath
      ScriptPath: $(Pipeline.Workspace)/infrastructure/scripts/Deploy-Identities.ps1
      ScriptArguments: >-
        -EnvironmentName '${{ parameters.environmentName }}'
        -EnvironmentCode '${{ parameters.environmentCode }}'
        -Location '${{ parameters.location }}'
        -LocationCode '${{ parameters.locationCode }}'
        -TenantId '${{ parameters.tenantId }}'
        -SubscriptionId '${{ parameters.subscriptionId }}'
        -ConfigFile '${{ parameters.configFile }}'
        -Confirm:$false
  - task: AzurePowerShell@5
    displayName: Run Network deployment
    inputs:
      azureSubscription: ${{ parameters.adosServiceConnectionName }}
      pwsh: true
      azurePowerShellVersion: LatestVersion
      ScriptType: FilePath
      ScriptPath: $(Pipeline.Workspace)/infrastructure/scripts/Deploy-Network.ps1
      ScriptArguments: >-
        -EnvironmentName '${{ parameters.environmentName }}'
        -EnvironmentCode '${{ parameters.environmentCode }}'
        -Location '${{ parameters.location }}'
        -LocationCode '${{ parameters.locationCode }}'
        -TenantId '${{ parameters.tenantId }}'
        -SubscriptionId '${{ parameters.subscriptionId }}'
          -ConfigFile '${{ parameters.configFile }}'
          -azureADGroupId_resourceGroupContributor '$(azureADGroupId_resourceGroupContributor)'
          -Confirm:$false
        -ConfigFile '${{ parameters.configFile }}'
        -azureADGroupId_resourceGroupContributor '$(azureADGroupId_resourceGroupContributor)'
        -Confirm:$false
```

What is done with the new **deployment-jobs.yml**

```
jobs:
  - deployment: deployADPFoundation
    displayName: Foundation Components
    environment: ads-dev
    pool:
      vmImage: windows-latest
    strategy:
      runOnce:
        deploy:
          steps:
            - task: AzurePowerShell@5
              name: Identities
              displayName: Run Identities deployment
              inputs:
                azureSubscription: ${{ parameters.adosServiceConnectionName }}
                pwsh: true
                azurePowerShellVersion: LatestVersion
                ScriptType: FilePath
                ScriptPath: $(Pipeline.Workspace)/infrastructure/scripts/Deploy-Identities.ps1
                ScriptArguments: >-
                  -EnvironmentName '${{ parameters.environmentName }}'
                  -EnvironmentCode '${{ parameters.environmentCode }}'
                  -Location '${{ parameters.location }}'
                  -LocationCode '${{ parameters.locationCode }}'
                  -TenantId '${{ parameters.tenantId }}'
                  -SubscriptionId '${{ parameters.subscriptionId }}'
                  -ConfigFile '${{ parameters.configFile }}'
                  -Confirm:$false - task: AzurePowerShell@5
            - task: AzurePowerShell@5
              name: Core
              displayName: Run Core deployment
              inputs:
                azureSubscription: ${{ parameters.adosServiceConnectionName }}
                pwsh: true
                azurePowerShellVersion: LatestVersion
                ScriptType: FilePath
                ScriptPath: $(Pipeline.Workspace)/infrastructure/scripts/Deploy-Core.ps1
                ScriptArguments: >-
                  -EnvironmentName '${{ parameters.environmentName }}'
                  -EnvironmentCode '${{ parameters.environmentCode }}'
                  -Location '${{ parameters.location }}'
                  -LocationCode '${{ parameters.locationCode }}'
                  -TenantId '${{ parameters.tenantId }}'
                  -SubscriptionId '${{ parameters.subscriptionId }}'
                  -ConfigFile '${{ parameters.configFile }}'
                  -azureADGroupId_resourceGroupContributor '$(Identities.azureADGroupId_resourceGroupContributor)'
                  -Confirm:$false
  - deployment: deployADPNetwork
    displayName: Networking Components
    environment: ads-dev
    dependsOn:
      - deployADPFoundation
    pool:
      vmImage: windows-latest
    variables:
      diagnosticsObject: $[ dependencies.deployADPFoundation.outputs['deployADPFoundation.Core.diagnosticsObject'] ]
      azureADGroupId_resourceGroupContributor: $[ dependencies.deployADPFoundation.outputs['deployADPFoundation.Core. Identities.azureADGroupId_resourceGroupContributor’] ]
    strategy:
      runOnce:
        deploy:
          steps:
            - task: AzurePowerShell@5
              name: Network
              displayName: Run Network deployment
              inputs:
                azureSubscription: ${{ parameters.adosServiceConnectionName }}
                pwsh: true
                azurePowerShellVersion: LatestVersion
                ScriptType: FilePath
                ScriptPath: $(Pipeline.Workspace)/infrastructure/scripts/Deploy-Network.ps1
                ScriptArguments: >-
                  -EnvironmentName '${{ parameters.environmentName }}'
                  -EnvironmentCode '${{ parameters.environmentCode }}'
                  -Location '${{ parameters.location }}'
                  -LocationCode '${{ parameters.locationCode }}'
                  -TenantId '${{ parameters.tenantId }}'
                  -SubscriptionId '${{ parameters.subscriptionId }}'
                  -ConfigFile '${{ parameters.configFile }}'
                  -azureADGroupId_resourceGroupContributor '$(azureADGroupId_resourceGroupContributor)'
                  -diagnosticsObject '$(diagnosticsObject)'
                  -Confirm:$false
```

### Variable syntax

As you can tell with these YAML extracts, the main change between old and new is how variables are passed between jobs and tasks in the pipeline. In the old **deployment-steps.yml**, the default [macro syntax](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#understand-variable-syntax) can be used, but with the new **deployment-jobs.yml** pipelines, the expression needs to include [the dependency](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#set-variables-in-scripts) on the previous step/job. For example, the **Deploy-Identities.ps1** produces the variable “azureADGroupId\resourceGroupContributor”. To use this variable elsewhere, you must;

- For a step/task in the same job, you need to specify the name of the previous step/task. i.e:  

    _$(Identities.azureADGroupId\resourceGroupContributor)_  

- For another jobs step/task, you need to:
  - First, define the dependsOn to the previous job(s) that must be completed first before starting this job:  

        _dependsOn:
          - deployADPFoundation_  

  - Second, define the variable in the receiving job:

        _azureADGroupId\resourceGroupContributor: $[ dependencies.deployADPFoundation.outputs['deployADPFoundation.Core.Identities.azureADGroupId\resourceGroupContributor’] ]  
        _

  - Third, use the variable as you would normally with a macro syntax variable:

        _$(azureADGroupId\resourceGroupContributor)_  

It’s crucial to note that for deployment jobs in Azure DevOps pipelines, the matrices syntax for runOnce, canary and rolling strategies does vary for variable expression syntax. See the exact syntax you need by reviewing this [Microsoft Docs page (Support for output variables)](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/deployment-jobs?view=azure-devops#support-for-output-variables). I hope you don’t make the same mistake I did where I was not defining the job name! I was mistakenly referring to the [build job documentation,](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#use-output-variables-from-tasks) which does not need this defined.

With the variables passing through correctly, we now have a pipeline that runs in almost half the time as it did before, well below any timeout threshold!

[![](/assets/images/from_wordpress/b-1024x485.png)](/assets/images/from_wordpress/b.png)

Here is a screenshot from the Azure DevOps pipeline in action, running three jobs in parallel!

[![](/assets/images/from_wordpress/c.png)](/assets/images/from_wordpress/c.png)

## Conclusion

As you can see, saving almost half the time in a pipeline deployment provides a massive advantage, not only technically but business-impacting as well. Parallel pipelines can help organisations reduce downtime while deploying releases, while also giving peace of mind to developers and operations teams that everything is being deployed in the right order.  

I encourage you to utilise parallel pipelines jobs in the next major update of your Azure DevOps pipeline(s)!
