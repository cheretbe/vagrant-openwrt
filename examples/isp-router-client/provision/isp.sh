#!/bin/bash
set -euo pipefail

# Install iptables-persistent to save/restore rules across reboots
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-ip-forward.conf
sysctl -p /etc/sysctl.d/99-ip-forward.conf

# NAT traffic from the customer-facing network to the internet.
# No output interface specified so it applies to all uplinks (incl. Vagrant NAT).
iptables -t nat -A POSTROUTING -s 100.78.213.0/24 -j MASQUERADE

# Persist rules so they survive reboots
iptables-save > /etc/iptables/rules.v4
