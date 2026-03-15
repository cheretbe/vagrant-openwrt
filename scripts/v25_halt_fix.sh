#!/bin/ash
# shellcheck shell=dash

set -eux

# Fix for OpenWrt >= 25 where /sbin/halt doesn't trigger poweroff,
# causing Vagrant to hang on `vagrant halt`.

VERSION=$(sed -n "s/^DISTRIB_RELEASE='\\{0,1\\}//p" /etc/openwrt_release | cut -d. -f1)

if [ "$VERSION" -ge 25 ]; then
  rm /sbin/halt
  printf '#!/bin/sh\nexec /sbin/poweroff "$@"\n' > /sbin/halt
  chmod +x /sbin/halt
fi
