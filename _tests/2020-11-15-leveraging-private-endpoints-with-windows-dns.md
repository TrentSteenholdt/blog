---

layout: post
author: trentsteenholdt
title:  "Leveraging Private Endpoints with Windows DNS"
date: 2020-11-15
categories: [azure   devops   windows-azure ]
tags:   azure-dns   dns   private-endpoints   sql-managed-instance   windows-dns
image: "/assets/images/from_wordpress/network.png"
---


**_This was originally posted [here while working for Telstra Purple](https://purple.telstra.com/blog/Leveraging-Private-Endpoints-with-Windows-DNS)._**

In recent weeks, I’ve been working with Private Endpoints for some new Azure SQL server instances as we move some databases from traditional SQL IaaS VMs.

I don’t think I should have to advocate for the usage of [Private Endpoints](https://docs.microsoft.com/en-us/azure/private-link/private-link-overview) if an Azure resource type supports it. If you’re not already, then I highly encourage taking all the necessary steps to strengthen and protect your data by bringing all that public and potentially exposed traffic into your internal (networking) environment with this feature. The [cost of using Private Endpoints](https://azure.microsoft.com/en-au/pricing/details/private-link/) is only a few cents per GB, so it's very cost effective for all the benefits it brings.

In this particular story, when we enabled Private Endpoints for the Azure SQL server instances, I pointed a Windows System Administrator to a particular [Microsoft Doc’s page](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns) about configuring DNS correctly so the private, rather than the public, IP address would resolve.

As the Windows System Administrator read the documentation, the several flow diagrams on the page scared him. Seeing all these flow lines going up, down, left and right, I could immediately see his concern that the solution was overly complicated. At that point, I started searching for a simple how-to guide to assist with his scenario. However, I was amazed not to see anything available. So, this is why this blog post now exists. To help with what I considered was a common setup scenario with Azure and on-premises infrastructure. To follow along:

- They are using Windows DNS and Windows Active Directory Directory (AD on-premises).

- As part of building out their Azure Landing Zone, they have extended their Windows DNS and Windows Active Directory into Azure on a new virtual machine.

- The Virtual Networks DNS settings in Azure are configured to point to the Windows DNS server(s).

- AD Sites and Services have been configured for the new sites and subnets in Azure.

- The domain controller(s) on-premises are replicating without issue to the domain controller(s) in Azure.

Here is a high-level diagram of what the network looks like with just two domain controllers, one in Azure, that also run Windows DNS.

[![](/assets/images/from_wordpress/network-1024x620.png)](/assets/images/from_wordpress/network.png)

If that sounds like or is similar to you, then this guide will get you set up with being able to resolve private IP address DNS records for any of the Private EndPoint Azure resources you may have.

First, let’s configure your Private DNS Zone for all your virtual networks (vNets). For this customer, they deployed the Azure SQL server instance Private EndPoint into the Production spoke vNet, so when the Private DNS Zone is created automatically, only the spoke vNet was linked. To correct this in your setup, head to the Azure Portal, find the Private DNS Zone and select “Virtual Network links” on the left-hand pane.

[![](/assets/images/from_wordpress/endpoints-1024x728.png)](/assets/images/from_wordpress/endpoints.png)

From there, you’ll need to link at least the vNet where the Windows DNS/ AD Domain Controller resides. For the purposes of this customer, that was the Hub virtual network.

Once you have done this, you’re now done with Azure and the Azure Portal. All changes here on out will be with the Windows DNS configuration itself.

Start by connecting to the Windows DNS management console first on the server in Azure. _If you are using RDP to do this, it might be time to read up on [Windows Admin Centre](https://docs.microsoft.com/en-us/windows-server/manage/windows-admin-center/understand/what-is)._

On the Windows DNS server in Azure, you’ll need to change the forwarder to [168.63.129.16](https://docs.microsoft.com/en-us/azure/virtual-network/what-is-ip-address-168-63-129-16). You can achieve this by:  

1. Right-clicking on the server node and selecting Properties.

3. Selecting the Forwarders tab.

5. On the current IP addresses you may have, select Edit…  
    ![](/assets/images/from_wordpress/dns1-50.png)  

7. Update the details as needed, so the servers sole DNS forwarder is 168.63.129.16.
    ![](/assets/images/from_wordpress/dns2-50.png)  

9. Click OK.

It’s important to note that 168.63.129.16 is a highly available virtual IP address. If you’re replacing something like 1.1.1.1 or Google DNS, you really should not see any degradation to DNS performance with this change.

Once you’ve made this change on the Windows DNS Server in Azure, you should be able to nslookup and resolve the private IP address. The below screenshot highlights the same nslookup being made before (red) and after (green) the change in the steps above were made.

[![](/assets/images/from_wordpress/dns4-1024x584.png)](/assets/images/from_wordpress/dns4.png)

With Windows DNS in Azure now resolving the private IP, we now need to make on-premises Windows DNS aware of how to resolve the same IP. To do this, connect to the DNS management console for your on-premises DNS server(s) and follow the instructions to create a conditional forwarder:

1. Open the server node and go to Conditional Forwarders.

3. In the main pane, right-click and select New Conditional Forwarder…

5. In the new window, provide the [Public DNS zone name](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration) for the private endpoint you want to be able to resolve the Private IP for. (Note: Repeat this whole process if you want more than one Azure resource type leveraging Private Endpoints).

7. For the IP address of the master server, provide the IP address of your Windows DNS server in Azure. E.g. On-premises, the server is 192.168.254.221. In Azure the server IP is 192.168.250.111 so you use this IP.  

    ![](/assets/images/from_wordpress/dns5-50.png)  

9. Click OK.

That’s it! You’ve configured your environment per Microsoft best practices and using DNS forwarding as mentioned [here](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns#virtual-network-and-on-premises-workloads-using-a-dns-forwarder). What you’ve essentially done is given your on-premises Windows DNS server(s) a bunny hop server (the Windows DNS server in Azure), so it can resolve the 168.63.129.16 records for it and send that result back down the ExpressRoute circuit.

Best of luck securing your Azure workloads!
