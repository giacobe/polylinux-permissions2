#!/bin/sh
. /etc/profile.d/polylinux-colors.sh
PS1='\w$ '
cd "$HOME" || exit 1
. /etc/profile.d/polylinux-colors.sh
clear
box_line() { printf '* %-36.36s *\n' "$1"; }
printf '%s\n' '****************************************'
box_line 'PolyLinux: Permissions'
box_line 'Read README.txt to begin.'
box_line 'Submit answers to the exercise'
box_line 'grading form.'
box_line 'Use nextlevel and prevlevel.'
printf '%s\n' '****************************************'
cat README.txt
