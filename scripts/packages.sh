#!/bin/ash
# shellcheck shell=dash

set -eux

# Install prerequisites for synced folders
if command -v apk > /dev/null 2>&1; then
    apk update
    apk add rsync sudo
else
    opkg update
    opkg install rsync sudo
fi
