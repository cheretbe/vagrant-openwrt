# ISP / Router / Client example

A three-VM setup where an OpenWRT router routes traffic between an upstream
ISP gateway (WAN) and a LAN client.

```
                        [ Internet ]
                             |
   +----------------------------------------------------+
   |  isp  (bento/debian-12)                            |
   |  - NATs 100.78.213.0/24 to the internet            |
   +----------------------------------------------------+
                             | eth1: 100.78.213.10/24
                             |   intnet: vagrant-isp
                             |
                             | eth1 WAN: 100.78.213.11/24
   +----------------------------------------------------+
   |  router  (cheretbe/openwrt-25)                     |
   |  - WAN on eth1, LAN on eth2                         |
   |  - host port 8000 -> guest 80                      |
   +----------------------------------------------------+
                             | eth2 LAN: 192.168.120.1/24
                             |   intnet: vagrant-lan
                             |
                             | eth1: DHCP from router
   +----------------------------------------------------+
   |  client  (bento/debian-12)                         |
   |  - default route and DNS via the router            |
   +----------------------------------------------------+
```

## Usage

```bash
vagrant up
```

## Notes

* The `isp` VM masquerades the `100.78.213.0/24` network so the router has
  internet access through it.
* The `router` uses its Vagrant management interface (`mgmt`) only for
  `vagrant ssh`; default route and DNS go through the WAN.
* The `client` gets its address, default route and DNS over DHCP from the
  router via the LAN interface, bypassing the VirtualBox NAT.
* The router's LuCI web interface is reachable from the host at
  http://localhost:8000 (host port 8000 -> guest port 80).
* DNS: the router uses `1.1.1.1` as its upstream resolver (set on the WAN
  interface). The client receives the router (`192.168.120.1`) as its DNS
  server over DHCP, and the router's dnsmasq forwards queries upstream.
