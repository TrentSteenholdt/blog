---

layout: post
author: trentsteenholdt
title:  "What you can and cannot do with GitHub Actions Environment secrets and variables"
date: 2023-04-06
categories: [devops   thoughts ]
tags:   environments   github   github-actions
image: "/assets/images/from_wordpress/image-22.png"
---


[Environments inside GitHub Actions](https://docs.github.com/en/actions/using-jobs/using-environments-for-jobs) are incredibly powerful for managing your deployment workflows. They provide numerous benefits, including the ability to handle approval gates similar to Azure DevOps. This means you can prevent deployments to production environments before everything has been thoroughly checked and approved.

However, the documentation around Environments doesn't delve much into properly leveraging secrets and variables, especially when your YAML workflows get a bit more complicated. In this post, we'll look at how to use Environment secrets and variables with a series of examples.

The examples will demonstrate a simple use case of logging into Azure with `azure/login@v1`.

Before diving into the examples, it's essential to clarify that using the `strategy` and `matrix` options is not suitable for managing environment variables, secrets, and controls. Matrices are better suited for handling different versions of your app or code, such as deploying the app in multiple languages (e.g., English and French). You can learn more about using matrices in the [GitHub Actions documentation](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs).

Now, let's explore the examples.

## Example 1: Two Environments in One Release YAML File

Here is a very simple YAML file with two environments: Test and Prod. We'll use the `azure/login@v1` action in a step, followed by a step to log out of Azure.

```
on: [push]

jobs:
  deploy-test:
    runs-on: ubuntu-latest
    environment:
      name: Test
    steps:
    - name: Checkout repo
      uses: actions/checkout@v2

    - name: Log into Azure
      uses: azure/login@v1
      with:
        creds: '{"clientId":"${{ secrets.AZURE_CLIENT_ID }}","clientSecret":"${{ secrets.AZURE_CLIENT_SECRET }}","subscriptionId":"${{ secrets.AZURE_SUBSCRIPTION_ID }}","tenantId":"${{ secrets.AZURE_TENANT_ID }}"}'
        enable-AzPSSession: true

    
    - name: Deploy to Azure
      run: |
         echo "Deploying your stuff to "${{ vars.AZURE_SUBSCRIPTION_ID }}" subscription Id/ environment"

    - name: Az Logout
      run: az logout

  deploy-prod:
    runs-on: ubuntu-latest
    environment:
      name: Prod
    steps:
    - name: Checkout repo
      uses: actions/checkout@v2

    - name: Log into Azure
      uses: azure/login@v1
      with:
        creds: '{"clientId":"${{ secrets.AZURE_CLIENT_ID }}","clientSecret":"${{ secrets.AZURE_CLIENT_SECRET }}","subscriptionId":"${{ secrets.AZURE_SUBSCRIPTION_ID }}","tenantId":"${{ secrets.AZURE_TENANT_ID }}"}'
        enable-AzPSSession: true
    
    - name: Deploy to Azure
      run: |
         echo "Deploying your stuff to "${{ vars.AZURE_SUBSCRIPTION_ID }}" subscription Id/ environment"

    - name: Az Logout
      run: az logout
```

In this scenario, you would simply go to the GitHub Actions Environment page (E.g <https://github.com/@youorg/@yourproject/settings/environments/>) and provide the secrets and variables for each environment. Here is a screenshot of the Test environment.

[![](/assets/images/from_wordpress/image-21-1024x1000.png)](/assets/images/from_wordpress/image-21.png)

Great, that was easy, you're probably thinking. Well, as someone that works with extensive Infrastructure as Code (IaC) deployments, having everything in one YAML file is downright messy to manage. Let's see what happens in example 2.

## Example 2: Splitting YAML into Workflow Callers and using Environments; gotcha

As mentioned above, when it comes to IaC deployments, especially in Azure, the length of a single YAML file containing all the deployment steps can become messy and simply massive. Since each environment should be almost identical (with possible subtle differences in SKUs and feature flags), duplicating the YAML for each environment can lead to a file no human should be forced to read. This is where workflow callers make sense to split `release.yml` logic into a caller `deploy.yml` for deploying infrastructure.

Here's the example:

**deploy.yml**

```
name: Deploy to Azure

on:
  workflow_call:
    inputs:
      environment:
        required: true
    secrets:
      AZURE_CLIENT_ID:
        required: true
      AZURE_CLIENT_SECRET:
        required: true
      AZURE_SUBSCRIPTION_ID:
        required: true
      AZURE_TENANT_ID:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: ${{ github.event.inputs.environment }}
    steps:
    - name: Checkout repo
      uses: actions/checkout@v2

    - name: Log into Azure
      uses: azure/login@v1
      with:
        creds: '{"clientId":"${{ secrets.AZURE_CLIENT_ID }}","clientSecret":"${{ secrets.AZURE_CLIENT_SECRET }}","subscriptionId":"${{ secrets.AZURE_SUBSCRIPTION_ID }}","tenantId":"${{ secrets.AZURE_TENANT_ID }}"}'
        enable-AzPSSession: true
    
    - name: Deploy to Azure
      run: echo "Deploying to 1${{ inputs.environment }}1 environment"

    - name: Az Logout
      run: az logout
```

**release.yml**

```
name: Release to Azure

on: [push]

jobs:
  call-deploy-test:
    name: Call Deploy Workflow for Test
    runs-on: ubuntu-latest
    uses: ./.github/workflows/deploy.yml
    with:
      environment: Test
    secrets:
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
        
  call-deploy-prod:
    name: Call Deploy Workflow for Prod
    needs: call-deploy-test
    runs-on: ubuntu-latest
    uses: ./.github/workflows/deploy.yml
    with:
      environment: Prod
    secrets:
     AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
     AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
     AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
     AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
```

Pretty straightforward, right? **Well bad news, this doesn't work**.

In this example, environments have not been explicitly called in the `release.yml` file. From the perspective of this workflow, the secrets referenced are actually at the repository level, not the environment level. This oversight means the workflow will fail as your secrets and variables are not accessible. To make example 2 here work, you're forced to use repository secrets, and variables and change your secrets passed into the `deploy.yml` file to have a suffix like `_DEV` and `_PRD` to differentiate.  
  
Here is what I mean by using a screenshot of repository secrets in GitHub Actions.

[![](/assets/images/from_wordpress/image-22-1024x888.png)](/assets/images/from_wordpress/image-22.png)

So if Example 2 is no good? What can we do?

## Example 3: Splitting YAML into Workflow Callers and using Environments in the nested workflow

In Example 3, we'll modify the previous example by moving the environment variable from `deploy.yml` to `release.yml`. This will fix the issue of accessing environment variables and secrets, but it will create another issue you may not like. I'll explain after showing the example.  
  
**deploy.yml**

```
name: Deploy to Azure

on:
  workflow_call:
    inputs:
      environment:
        required: true
      AZURE_CLIENT_ID:
        required: true
      AZURE_CLIENT_SECRET:
        required: true
      AZURE_SUBSCRIPTION_ID:
        required: true
      AZURE_TENANT_ID:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout repo
      uses: actions/checkout@v2

    - name: Log into Azure
      uses: azure/login@v1
      with:
       creds: '{"clientId":"${{ inputs.AZURE_CLIENT_ID }}","clientSecret":"${{ inputs.AZURE_CLIENT_SECRET }}","subscriptionId":"${{ sinputs.AZURE_SUBSCRIPTION_ID }}","tenantId":"${{ inputs.AZURE_TENANT_ID }}"}'
        enable-AzPSSession: true
    
    - name: Deploy to Azure
      run: echo "Deploying to ${{ inputs.environment }} environment"

    - name: Az Logout
      run: az logout
```

**release.yml**

```
name: Release to Azure

on: [push]

jobs:
  call-deploy-test:
    name: Call Deploy Workflow for Test
    uses: ./.github/workflows/deploy.yml
    with:
     environment: Test
     AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID_DEV }}
     AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET_DEV }}
     AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID_DEV }}
     AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID_DEV }}
        
  call-deploy-prod:
    needs: call-deploy-test
    name: Call Deploy Workflow for Prod
    uses: ./.github/workflows/deploy.yml
    with:
     environment: Prod
     AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID_PRD }}
     AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET_PRD }}
     AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID_PRD }}
     AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID_PRD }}
```

For those that can see it, well done. **Why are we passing secrets as inputs to the workflow caller deploy.yml**? Unfortunately, that's the only way to pass secrets to the workflow caller while still using GitHub Action Environment secrets and variables! It sounds crazy and almost dangerous to take a secret and pass it as an input variable, but the good news is that because the workflow caller is using the context of the job in **release.yml**, logs and outputs continue to conceal the value. Phew!

But this creates another issue, UI experience in GitHub Actions itself! Because our caller workflow is now in a single step, the entire `deploy.yml` file will show up as a single step and will log like it too! Yuck! These are some ways around this by placing `echos` everywhere in `deploy.yml` steps to help the readability of the logging, but honestly, I'm not a big fan of that experience. 😔

## Custom Actions vs. Workflow Callers

Before we conclude, as I'm sure people are probably questioning my choices here, it's important to discuss the trade-offs between [creating custom GitHub Actions](https://docs.github.com/en/actions/creating-actions/about-custom-actions) and using workflow callers in the context of deploying Infrastructure as Code (IaC). Each IaC deployment scenario may have subtle differences, making creating custom actions more complicated than their actual benefits.

Custom actions are reusable pieces of code that encapsulate specific functionality. They can be extremely helpful when you have repetitive tasks across multiple workflows. However, when it comes to IaC deployment, the variations between different environments and deployment scenarios may require extensive customisation of the action, making it less reusable and more complex to manage.

On the other hand, workflow callers provide a way to split your YAML files and create modular, maintainable workflows. They allow you to keep the environment-specific logic and secrets within the context of the calling workflow. This approach offers more flexibility when dealing with complex IaC deployment scenarios while maintaining the simplicity and readability of your YAML files.

In the context of this blog post, we've focused on using workflow callers to manage environment secrets and variables in IaC deployment scenarios, as they offer a more adaptable solution for these specific use cases.  
  
If someone has been able to crack the code (pardon the pun) on using custom actions for IaC deployment, please reach out to me!

## Conclusion

[![](/assets/images/from_wordpress/image-24-1024x254.png)](/assets/images/from_wordpress/image-24.png)

We have an old-fashioned stalemate! As much as I would love to use environment secrets and values to their fullest potential when splitting up YAML files, the 'logical' way of doing something becomes slightly more complicated than it ought to be. For now, I prefer example 2 as UI experience in GitHub Actions is everything for me (see above). Still, I can understand why example 3 might be better for some people, especially as they go full steam ahead with environments in their deployment.

One key call out is all of these environment secrets and variables handling efforts do not inhibit you from still doing approval gate controls (again, see above how we're currently waiting for approval on Dev), which is ultimately the whole reason we do environments in the first place!  
  
Happy YAML'ing!
