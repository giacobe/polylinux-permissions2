#!/bin/sh
. /etc/profile.d/polylinux-colors.sh
PS1='\w$ '
cd "$HOME" || exit 1
printf '\nPolyLinux Permissions | nextlevel | prevlevel | validate\n'
cat README.txt
