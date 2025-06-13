---

layout: post
author: trentsteenholdt
title:  "Azure Networking Changes are coming! Are you ready for Private Subnets?"
date: 2023-11-27
categories: [azure ]
tags:   azure   networking
image: "/assets/images/from_wordpress/explicit-outbound-options.png"
---


Azure’s landscape is evolving, and with the announcement of the retirement of default route behaviour in Azure Virtual Networks, set for September 2025, the impact will resonate across the board. From those local fish and chip shop owners who rely on cloud services for their daily business operations to the tech giants who juggle enormous amounts of data daily, everyone must brace for this pivotal shift.

* * *

## The Inevitable Change

![Networking options post September 2025. Credit - Microsoft Docs](/assets/images/from_wordpress/image-32.png)

The change in default route behaviour signifies a move away from the implicit, less secure, and unpredictable means of outbound connectivity. It’s like Microsoft have finally caved into the pressure set on it for years by the way traffic is handled in AWS! This move reflects a wider Microsoft commitment at Ignite 2023 to enhancing security and network manageability. Read more about this update on Azure’s official [update page](https://azure.microsoft.com/en-us/updates/default-outbound-access-for-vms-in-azure-will-be-retired-transition-to-a-new-method-of-internet-access/).

## Who’s Affected?

Virtually every organisation utilising Azure Virtual Networks must take heed. The diversity of businesses affected underscores the importance of Azure’s network services in today’s cloud-reliant economy. For the years I’ve been working in the Azure space, nearly every organisation as allowed outbound network access with little control.

## Preparing for Transition

It’s time to assess your cloud environments and consider the most suitable options for transitioning to a more secure networking setup. Although the private subnet feature is currently in public preview and not recommended for production workloads yet, it’s an opportune time to start planning. For more information, visit the [public preview page](https://azure.microsoft.com/en-us/updates/public-preview-private-subnet/).

## A Personal Recommendation

Directly attaching an Azure Public IP to a virtual machine is generally not advisable due to the potential for dangerous ingress traffic flows. Instead, steering towards solutions that provide secure and controlled access is paramount; such as the other two paths suggested by Microsoft.

NAT gateways emerge as a leading solution based on the Microsoft approach, offering a blend of security, scalability, and manageability. For those without a clear strategy, it’s an opportune time to consult with networking teams or external experts who can help in that space.

## Start Now

The 2025 deadline may seem distant, but it’s crucial to act promptly. Transitioning network configurations and ensuring compliance with new security models will require time and deliberate planning. Begin your journey by understanding the [default outbound access](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access) on Microsoft’s documentation site.

In summary, the changes to Azure’s networking are not just a future concern but an immediate call to action. Organisations must begin preparations now to navigate this change successfully, ensuring their cloud environments remain robust, secure, and efficient in the evolving digital landscape.
