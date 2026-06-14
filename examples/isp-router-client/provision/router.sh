#!/bin/ash
# shellcheck shell=dash
set -eux

# Prevent the Vagrant management interface from affecting routing/DNS
uci set network.mgmt.defaultroute='0'
uci set network.mgmt.peerdns='0'
uci set network.mgmt.peerroutes='0'

# Configure WAN interface on eth1 (connected to ISP network)
uci set network.wan=interface
uci set network.wan.device='eth1'
uci set network.wan.proto='static'
uci set network.wan.ipaddr='100.78.213.11'
uci set network.wan.netmask='255.255.255.0'
uci set network.wan.gateway='100.78.213.10'
uci set network.wan.dns='1.1.1.1'

# Configure LAN interface on eth2 (connected to client network)
uci set network.lan=interface
uci set network.lan.device='eth2'
uci set network.lan.proto='static'
uci set network.lan.ipaddr='192.168.120.1'
uci set network.lan.netmask='255.255.255.0'

uci commit network

# Apply network changes and restart dependent services
/etc/init.d/network restart
/etc/init.d/dnsmasq restart
/etc/init.d/firewall restart
