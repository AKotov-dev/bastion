Bastion - gateway and site filter for the office network
--
Dependencies: `iptables squid ipset bind-utils apache squidanalyzer polkit sakura openssh-server dnsmasq samba net-tools`

Three-level filtering HTTP/HTTPS:
+ Squid + Black/White lists of domains + VIP-users
+ IPTables + IPSet (blocking host=multiple IP) + dictionary filtering
+ SquidAnalyzer - internet connection log analyzer

Physically it consists of two parts:
+ GUI (rpm-package, pulls up all the necessary dependencies)
+ Archive of configuration files (.tar.gz unpacked manually `etc->etc`)

Configure the `WAN/LAN` on the computer acting as the gateway and run `Bastion`. Specify the interface names, the local network and click the `New Certificate` button. After the certificate is created, install it in the client browsers. To instantly apply the blocking rules from the lists or the first start, click the `Restart` button. Remote access to the server is `SSH:22` (Internet/LAN). Port 22 is protected from brute force: three failed passwords are blocked for 60 seconds.

Note:
+ Bastion can be configured/run without GUI (scripts only)
+ Bastion has built-in DNS/DHCP (dnsmasq); address pool `x.x.x.50-x.x.x.250`
+ When `samba` is enabled, a shared folder `/usr/local/Common` is created with a `.recycle` bin, which is cleaned every month. The `\\LAN-IP\Common` folder can be connected as a shared disk

![](https://github.com/AKotov-dev/bastion/blob/main/ScreenShot1.png)
