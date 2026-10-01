#!/bin/sh
cd /root || exit 1
if [ ! -f /run/polylinux-permissions/all-ready ]; then
    sh ./install.sh
else
    printf 'Lab already initialized. Use su - level1, or sh /root/install.sh to reset.\n'
fi
