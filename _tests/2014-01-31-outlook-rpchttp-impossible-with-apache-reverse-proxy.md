---

layout: post
author: trentsteenholdt
title:  "Outlook RPC/HTTP impossible with Apache Reverse Proxy"
date: 2014-01-31
categories: [exchange ]
tags:   apache   exchange   rpc-over-http   rpc-over-https
image: "/assets/images/from_wordpress/owa.png"
---


![The Apache vs. Microsoft RPC over HTTPS war!](/assets/images/from_wordpress/RPCerror.png)<br>
*The Apache vs. Microsoft RPC over HTTPS war!*

For those who may be thinking of moving to Apache reverse proxy either because they're looking to replace the now discontinued Microsoft TMG ([refer here](http://blogs.technet.com/b/server-cloud/archive/2012/09/12/important-changes-to-forefront-product-roadmaps.aspx)) or are looking to secure their internal CAS/Mailbox servers may need to think again, Outlook RPC/HTTP simply doesn't work.

This week I was hand balled a project (mid-way through) to move some Exchange services to Amazon for a client. While there was no problem (just the minor configuration issues with virtual directories etc.) with the internal Exchange hosts, the way that they were trying to present Exchange to external users with Apache was 'broken'.

![An overview of the Exchange environment in AWS](/assets/images/from_wordpress/exchangeoverview.png)<br>
*An overview of the Exchange environment in AWS*

Troubleshooting was pretty easy... I identified the issue by reviewing the IIS logs on the Exchange 2010 CAS host (C:\\inetpub\\log\\) that there was some traffic, but not all the traffic you'd expect for RPC over HTTPS. It was starting a connection (HTTP 200 GET's), but no establishing it. Just to make sure that there wasn't an RPC issue where it couldn't talk to day Active Directory etc., I ran the "**Test-OutlookConnectivity -Protocol HTTP**" powershell cmdlet and it came back with all "Success"... Hmmm, onto [Microsoft Remote Connectivity Analyzer](https://testconnectivity.microsoft.com/) to test for Outlook Anywhere and lo and behold we had a RPC time out (rpc\s\server\unavailable error (0x6ba)). So it's only external users that will see this problem... So what sits between them and the client Exchange hosts!

The Apache Reverse Proxy `mod_proxy` module was identified to be  'man handling' the traffic and dropping it like a hot potato! It was easy to see this within the Apache logs (typically in /var/log/apache2/ on Linux) that the RPC\DATA\IN and RPC\DATA\OUT traffic that is channelled over HTTPS was blocked being by Apache. Poo!

**So why is this happening?** Well in the opinion of Apache, Microsoft is not following proper RFC standard when it comes to the HTTP protocol. Take a read of the 'bug report' [here](https://issues.apache.org/bugzilla/show_bug.cgi?id=40029) and see how it's been marked as invalid and therefore resolved with no change to the complied module.

> ```
> This is an incorrect use of the http protocol. Bad luck for Microsoft. 
> -- Apache Team
> ```

So what now? What are the options? Well there is a couple... some are okay, some are dirty and some I wouldn't touch with a 20 foot pole!

1. Move to a hardware based appliance like Microsoft/ Exchange team is [suggesting](http://blogs.technet.com/b/exchange/archive/2013/02/18/exchange-firewalls-and-support-oh-my.aspx). They're not cheap and are overkill for a small client like the one I'm dealing with.
2. You could spin up another Reverse Proxy Server like Squid or HA Proxy that is known to allow the RPC over HTTPS traffic through. This option is okay, but you're spinning up another server for just Exchange Reverse Proxy, unless of course you move all your other applications and websites to the same service. Is your applications team ready for that type of migration? Do you have enough IPv4 addresses?!
3. You could run up Squid on the same server (assuming the host is Linux). Squid could handle Exchange and then pass everything else to Apache! Pretty neat, but again you're managing two services that require patching etc. Hmmm, not ideal.
4. You could just be lazy and compromise security by using NAT/PAT rules on your external firewall to an Exchange host that is internet facing. (I.e.. The ExternalURL is set on the virtual directories and Outlook Anywhere is enabled.). I hate this, but I know of a major organisation in Australia doing just this with no security or monitoring of traffic!
5. You could run up an older version of Apache that doesn't have the 'fix' for RPC over HTTPS. Anything version 2.0.X is apparently able to allow the RPC traffic. Yuck! Running out of date Apache is just a disaster waiting to happen. Again, people seem to be falling back to this option.
6. You could go open source and use something like `mod_proxy_msrpc`. I personally am not a fan of relying on the 'interwebs' for keeping my environment secure! Refer [here](https://github.com/bombadil/mod_proxy_msrpc) for `mod_proxy_msrpc` if you're okay with this of course.
7. Give up... Stick with TMG if you're already on it, or tell the business it's not possible... Not possible.

Unfortunatley for this client, the horse had already bolted and they were becoming a little impatient that things weren't working. Added to this, the client insisted I couldn't move away from the Apache server they had already built. They expected me to get Apache to work /sigh.... The solution I chose after a lot of thinking was option 3. I configured up Squid to deal with Exchange and then let it pass the rest through to Apache for the non-Exchange reverse proxy needs. For reference, here is an example of the config I used:

```
# CONTOSO Squid Configuration - Trent Steenholdt 30/01/2014
# =======================================================

# Extensions for Exchange RPC over HTTPS
extension_methods RPC_IN_DATA RPC_OUT_DATA

# We listen on 123.123.123.123 This is the internet facining IP
https_port 123.123.123.123:443 accel cert=/LOCATIONOFCERT/contoso_com.crt key=/LOCATIONOFCERTKEY/contoso_com.key defaultsite=contoso.com vhost

# Apache is running locally.
# Exchange Server is 10.100.7.99 
cache_peer 127.0.0.1 parent 443 0 proxy-only no-query no-digest originserver login=PASS ssl sslflags=DONT_VERIFY_PEER cert=/LOCATIONOFCERT/otherSANcert_contoso_com.crt key=/LOCATIONOFCERTKEY/otherSANcert_contoso_com.key name=webServer
cache_peer 10.1.1.14 parent 443 0 proxy-only no-query no-digest originserver login=PASS front-end-https=on ssl sslflags=DONT_VERIFY_PEER cert=/LOCATIONOFCERT/SANcert_contoso_com.crt key=/LOCATIONOFCERTKEY/SANcert_contoso_com.key name=exchangeServer

# List of acceptable URLs to send to the Exchange server
acl exch_url url_regex -i contoso.com/exchange
acl exch_url url_regex -i contoso.com/exchweb
acl exch_url url_regex -i contoso.com/public
acl exch_url url_regex -i contoso.com/owa
acl exch_url url_regex -i contoso.com/ecp
acl exch_url url_regex -i contoso.com/microsoft-server-activesync
acl exch_url url_regex -i contoso.com/rpc
acl exch_url url_regex -i contoso.com/rpcwithcert
acl exch_url url_regex -i contoso.com/exadmin

# Send the Exchange URLs to the Exchange server
cache_peer_access exchangeServer allow exch_url

# Send everything else to the Apache
cache_peer_access webServer deny exch_url

# This is to protect Squid
never_direct allow exch_url

# Logging Configuration
redirect_rewrites_host_header off
cache_mem 32 MB
maximum_object_size_in_memory 128 KB
cache_log none
cache_store_log none

access_log /SQUIDLOCATION/access.log squid

# Set the hostname so that we can see Squid in the path (Optional)
visible_hostname contoso.com/squid
deny_info TCP_RESET all

# ACL - required to allow
acl all src 0.0.0.0/0.0.0.0

# Allow everyone through, internal and external connections
http_access allow all
miss_access allow all
```

Cheers,

Trent
