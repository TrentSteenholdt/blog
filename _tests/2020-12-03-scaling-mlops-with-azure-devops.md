---

layout: post
author: trentsteenholdt
title:  "Scaling MLOps with Azure DevOps"
date: 2020-12-03
categories: [azure   devops ]
tags:   agile   devops   machine-learning   mlops
image: "/assets/images/from_wordpress/teams-3.png"
---


**_This was originally posted [here while working for Telstra Purple](https://purple.telstra.com/blog/scaling-mlops-with-azure-devops)._**

As organisations build more custom and tailored solutions to solve their most complex business problems, the scalability of supporting platforms and systems are always tested. Unfortunately, when it comes to Azure DevOps, they are tested in ways that contradict best practices and the correct way to scale an organisation. This article will hopefully bring some light into how, with the MLOps methodology, you can scale an Azure DevOps organisation effectively without causing significant double up!

## What is Azure DevOps best practice for scaling?

First, let’s talk about the repeated problem in the IT industry. It’s common, almost folklore, that when a new IT development team starts a new initiative or program of work, they go to their Azure DevOps organisation and click the big giant “New Project” button. _That is a no-no!_ As [Microsoft Docs](https://docs.microsoft.com/en-us/azure/devops/organizations/projects/about-projects?view=azure-devops) best practice suggests, the best way to scale an organisation is to consider projects in Azure DevOps as Business Units to your organisation. What does that mean exactly? Well, a business unit could be your entire IT division, or an essential function like Machine Learning, all in one project! From that one project, you then split it up with multiple teams to the various vertical and horizontal pieces of work they are tasked with.

The one project per business unit approach comes with several benefits. These include:

- Supporting various teams in adopting [Agile practices](https://docs.microsoft.com/en-us/azure/devops/boards/plans/agile-culture?view=azure-devops) that are universal and consistent. E.g. All teams have the same cadence, ceremonies and structure to stories or backlog items.

- Allowing for better reporting. Azure DevOps Projects are the highest possible level metrics are surfaced before you would need to start building custom reporting solutions. For C-Level executives, building dashboards and leveraging PowerBI at a Project level is an excellent way for them to understand and track all the work in progress.

- Allowing for more organic, cross-team collaboration. Teams still using their own boards, can share stories amongst other area-paths (teams) in their business unit without having to duplicate the item.

Here are a couple of screenshots of a good and bad Azure DevOps organisation set up. First is a bad example organisation, with lots of small projects for niche things but no real consistency of what and who should have access to them.

[![](/assets/images/from_wordpress/image-25-1024x684-1.png)](/assets/images/from_wordpress/image-25-1024x684-1.png)

Then here is a good example organisation, where they have used business units. The CIO of the IT division can get a visualisation of all things happening in IT by going into their project, and each team within that has their own board, repositories and so on. Then with the Finance System project, the CFO has the same level of visibility into the various teams managing it.

[![](/assets/images/from_wordpress/t-1024x684.png)](/assets/images/from_wordpress/t.png)

## Taking best practice and applying it to MLOps

Now with that understanding of the best practice, let’s think about how that works in MLOps. MLOps is defined as the collaboration between data scientists and operation professionals. These two teams play very distinct roles in making MLOps happen, and sometimes it can be complicated with multiple data scientists teams working with the single group of operation professionals. So, how do we scale this without giving data scientists access to say production deployment pipelines but still have the ability to collaborate?

The best way to manage this is to have multiple teams for each group of the MLOps makeup and then use custom role-based access controls (RBAC) in an Azure DevOps Project. A custom RBAC solution would then limit data scientist teams from controlling pipelines, repositories or other artefacts they shouldn’t need to touch.

### Example Configuration

Let’s hypothetically have two separate data scientist teams, building their own unique models with just the one centralised operations team, as shown in this diagram below.

[![](/assets/images/from_wordpress/image-26-1024x454-1.png)](/assets/images/from_wordpress/image-26-1024x454-1.png)

To get them collaborating in a highly governed manner, the first thing to do is to [create them all a team](https://docs.microsoft.com/en-us/azure/devops/organizations/settings/add-teams?view=azure-devops&tabs=preview-page) inside the same Azure DevOps Project. When you are creating your teams, consider the following:

- Make sure to select the checkbox to create an associated an area-path. This is important for teams to share stories and backlog items between boards.

- For the data scientist teams, grant them no permission as we’ll do custom RBAC. For the centralised Ops Team, giving them the default Contributor permission rights is suitable.

[![](/assets/images/from_wordpress/Create-Team.png)](/assets/images/from_wordpress/Create-Team.png)

With your teams created, now create the supporting artefacts in Azure DevOps they’ll use. That’s things like [repositories](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-new-repo?view=azure-devops#:~:text=In%20the%20Project%20area%20in,a%20README%20and%20create%20a%20.), [pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline?view=azure-devops&tabs=java%2Ctfs-2018-2%2Cbrowser) and [service connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml). I recommend keeping these artefacts at a 1:1 ratio with a team as it allows for better governance with the custom RBAC model, but nothing is stopping you from creating more than one for a team.

[![](/assets/images/from_wordpress/teams-2-1024x488.png)](/assets/images/from_wordpress/teams-2.png)

With all these artefacts created, you now need to grant the data scientist teams explicit permission to these artefacts. By default, without any permission, these teams have no access to any of the artefacts you’ve just created. The centralised Ops team do because they are **Contributors**, but that’s a good thing as their job will be to make sure governance is kept up not only in the ML environments but in Azure DevOps too.

To make the data scientist teams have just enough permission to build out and train models (continuous integration/ continuous testing), complete the following for each of them:

**TIP:** _<https://dev.azure.com/YourOrgName/YourProjectName> needs to be replaced with your details. E.g. <https://dev.azure.com/Contoso/MLOps>_

1. **For Azure DevOps access.** On <https://dev.azure.com/YourOrgName/YourProjectName/\settings/permissions>, open up their team and set the **View project-level Information** to **Allow**. All other settings should be left as default/ **Not Set**.

3. **For Git Repository access**. On <https://dev.azure.com/YourOrgName/YourProjectName/\settings/repositories>, select the repository created for the data scientist team then go to the **Permissions** tab. In the main pane area, grant the data scientist team the same level of permissions as the Contributor permission has.

5. **For Pipeline access**. On <https://dev.azure.com/YourOrgName/YourProjectName/\build?view=folders>, create folders for all your teams, including the Ops team for organisational reasons. Then on the folder for the data scientist team, select the vertical ellipses, and then **manage security** where once again you’ll assign the same level of permissions as the Contributor has.

7. **For Azure Board access**. Lastly, but most importantly, on <https://dev.azure.com/YourOrgName/YourProjectName> /\settings/work-team?\a=areas, select your data scientist team in the top menu, then select the ellipses of the area-path and select **Security**. In the pop-up menu, once again, you’ll grant that data scientist team the same permissions as the Contributor permission set.

[![](/assets/images/from_wordpress/ml1-1024x629.png)](/assets/images/from_wordpress/ml1.png)

Once you have done this for each data scientist team, you have set up a custom RBAC model in your Azure DevOps Project, as shown in the diagram below.

[![](/assets/images/from_wordpress/teams-3-1024x504.png)](/assets/images/from_wordpress/teams-3.png)

- Green lines denote paths that permission has been granted, and

- Red lines show paths that can’t be accessed.  

This custom RBAC model makes it impossible for either data scientist team to see the Ops team or other data scientist team repositories or pipelines. Ideal and very suitable if the data scientist teams work independently of one another and need to safeguard any sensitive data sets they may be working on. As only an example, your organisation’s needs may be different, so I encourage you to implement an MLOps custom RBAC model that works best for you.

I hope this blog article helps illustrate that you can, and should, have just one Azure DevOps Project for the MLOps methodology and the business unit function that it is. Doing so brings so many benefits, and I guarantee, that over time with several machine learning model deployments, getting design consistency with something over multiple projects would be a nightmare. It would also make tracking change volumes, success/failure rates and deployment times harder too, something your C-Level executives won’t like when they need to validate their MLOps return on investment and total cost ownership!
