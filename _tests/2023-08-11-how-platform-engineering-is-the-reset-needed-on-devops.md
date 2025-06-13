---

layout: post
author: trentsteenholdt
title:  "How Platform Engineering is the reset needed on DevOps"
date: 2023-08-11
categories: [devops ]
tags:   thoughts
image: "/assets/images/from_wordpress/aaaa-1.png"
---


[![](/assets/images/from_wordpress/1674806413266-1.jpg)](/assets/images/from_wordpress/1674806413266-1.jpg)

Over the past decade working in the industry, we have all witnessed an evolution in approach to development and operations, culminating in the advent of DevOps. The merging of these disciplines has resulted in numerous advantages, like faster time to market, reduced recovery times and improved feedback loops. However, today, I feel there has been an unproportionate imbalance of development **over** operations in comparison to development and operations working together. Let me try to explain.

### The Overstretch of the 'Dev' in DevOps

When DevOps emerged as a mindset and behaviour, it aimed to bridge the communication gap between developers and operations. Over the past few years, particularly in the explosion of Cloud deployment APIs like Azure Resource Manager and AWS CDK, I feel this has metamorphosed into developers often taking over the operations entirely. While this can boost efficiency and, in some instances, reduce the cost of hires, it's also given rise to a plethora of challenges:

1. **Lack of specialised knowledge** **to pick** **best/right practices**: Despite their adaptability, developers might not always possess in-depth knowledge of the nuanced operations domain. This lack can lead to overlooking certain technologies over others because it's the flavour of the month. In the past few years alone, I've had countless situations where the wheel was unnecessarily reinvented for no reason other than to allow someone or a team to work on something new. While that's great for a developer team spiking awesomeness, it usually always ends up to the detriment of the business left with something they now need all those developers to stick around and support.

3. **Compromised security and countless backdoors**: As developers juggle coding with operations, security takes a back seat or becomes the forgotten child. Sometimes, businesses can get away with this, but other times, you only have to look at breaches like the Optus data hack to know just how badly it can all happen.

5. **Operational overhead leads to** **sudden or more repeatable burnout**: As more developers take on operational tasks that they were never meant to take on, the internal fights begin where developers wanting to work on more new things are stuck in the perpetual loop they created by taking on work they should have never taken in the first place!

### Platform Engineering**,**shifting it back to the right

We often talk about shifting testing as far left as possible because this makes a lot of sense to catch it early. This is where I feel there is something that we can actually move to the **right**! Enter Platform Engineering!

While still rooted in the core principles of DevOps (again, DevOps is the approach and mindset), Platform Engineering introduces a more structured and dedicated approach to the underlying infrastructure, security, and operational tasks.

Here's how Platform Engineering addresses the challenges mentioned above:

1. **Dedicated expertise** **with depths of real-world experience**: Platform Engineers focus on creating robust, scalable, and secure platforms on which applications run. Their specialised skill set ensures that the infrastructure is optimised, resilient, and secure for the business to be at ease while enabling the developers to still chase their fever-pitched dreams within reason.

3. **Proactive security measures**: By prioritising security, Platform Engineering mitigates risks early in the development lifecycle by taking tests that are often not done (who sees a Unit test ever written for Infrastructure as Code) and moving them left with the developers. Making systems less susceptible to breaches.

5. **Enhanced collaboration**: While DevOps emphasises collaboration, Platform Engineering takes it further by providing consistency across multiple verticals. Developers can focus on coding, knowing that a dedicated team ensures the underlying platform's integrity no matter where they'll be developing.

### A Balanced Approach

[![](/assets/images/from_wordpress/0_eKEsVSoDBpa16eBd-1.jpg)](/assets/images/from_wordpress/0_eKEsVSoDBpa16eBd-1.jpg)

My thoughts on this are not suggesting that somehow DevOps is obsolete; far from it. The practices, tools, and culture promoted by DevOps remain critical to the software delivery process. However, with Platform Engineering, there's a deliberate effort to give specialised attention to the often overlooked aspects of software development, particularly infrastructure and security.

In light of the recent security breaches, it's apparent that a one-size-fits-all approach might not always be the best solution. As technology and its associated challenges evolve, so should our strategies. Platform Engineering offers the balance that today's complex software ecosystems demand.

### In conclusion

While DevOps laid the groundwork for a unified approach to software delivery, Platform Engineering is paving the way for a future where efficiency, security, and robustness coexist in harmony. It's not about replacing DevOps (you can't) but refining and expanding upon its foundation to meet today's dynamic technological landscape.
