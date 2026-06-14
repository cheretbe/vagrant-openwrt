#!/bin/bash
set -euo pipefail

# The client has two interfaces:
#   eth0 - VirtualBox NAT, used only for Vagrant management ('vagrant ssh')
#   eth1 - LAN, DHCP served by the OpenWRT router
#
# We want the client's traffic to go through the OpenWRT router, not the
# VirtualBox NAT. eth1 is configured for DHCP here (Vagrant leaves it alone via
# 'auto_config: false') so the router provides its address, default route and
# DNS. A dhclient hook stops the management interface from installing its own.

# eth0: ignore the routes and DNS offered by the VirtualBox NAT. Clearing the
# domain options too leaves /etc/resolv.conf untouched on eth0 leases, so the
# router's DNS (set via eth1) is preserved.
cat > /etc/dhcp/dhclient-enter-hooks.d/no-mgmt-defaults <<'EOF'
if [ "$interface" = "eth0" ]; then
    new_routers=""
    new_domain_name_servers=""
    new_domain_search=""
    new_domain_name=""
    new_rfc3442_classless_static_routes=""
    new_classless_static_routes=""
fi
EOF

# eth1: bring it up with DHCP. The router supplies the address, default route
# and DNS. Unlike Vagrant's 'type: dhcp' stanza this has no 'post-up' route
# deletion, so the router's default route stays in place.
cat > /etc/network/interfaces.d/eth1 <<'EOF'
allow-hotplug eth1
iface eth1 inet dhcp
EOF

# Apply now without disrupting the 'vagrant ssh' connection on eth0
while ip route del default dev eth0 2>/dev/null; do :; done
ifdown eth1 || true
ifup eth1
