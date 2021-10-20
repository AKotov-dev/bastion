Bastion - Website filter for the office network
--
Dependencies: `iptables squid ipset bind-utils apache squidanalyzer polkit sakura openssh-server dnsmasq`

Three-level filtering HTTP/HTTPS:
+ Squid + Black/White lists of sites + VIP-users
+ IPTables + IPSet (blocking host=multiple IP) + dictionary filtering
+ SquidAnalyzer - internet connection log analyzer

Physically it consists of two parts:
+ GUI (rpm-package, pulls up all the necessary dependencies)
+ Archive of configuration files (.tar.gz unpacked manually `etc->etc`)

Configure the `WAN/LAN` on the computer acting as the gateway and run `Bastion`. Specify the interface names, the local network and click the `New Certificate` button. After the certificate is created, install it in the client browsers. To instantly apply the blocking rules from the lists or the first start, click the `Restart` button. Remote access to the server is `SSH:22` (Internet/LAN). Port 22 is protected from brute force: three failed passwords are blocked for 60 seconds.

Note1: Bastion can be configured/run without GUI (scripts only).
Note2: Bastion has built-in DNS/DHCP (dnsmasq); address pool x.x.x.20-x.x.x.250.

![](https://github.com/AKotov-dev/bastion/blob/main/ScreenShot1.png)
