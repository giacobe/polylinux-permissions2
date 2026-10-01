#!/bin/sh
# Instructor reference solvers. NEVER package in the learner VM.
# Run as the selected level account, with this script passed over stdin.
set -eu
n=${1:?level number required}
cd "$HOME"
person=$(sed -n 's/.*to \([a-z][a-z0-9]*\)\. Preserve.*/\1/p;s/.*are \([a-z][a-z0-9]*\):.*/\1/p;s/.*must be \([a-z][a-z0-9]*\):.*/\1/p' README.txt | head -n1)
case "$n" in
    1) sudo chown "$person" work/records/*;;
    2) for dir in work/departments/*; do sudo chgrp "${dir##*/}" "$dir"/*; done;;
    3) sudo chmod 640 work/reports/*;;
    4) sudo chmod 750 work/projects/*;;
    5) sudo chmod 700 work/homes/*;;
    6) for dir in $(sudo find work/path -type d); do
           mode=$(sudo stat -c %a "$dir")
           [ "$mode" != 740 ] || sudo chmod g+x "$dir"
       done;;
    7) sudo chmod g+s work/shared/*;;
    8) group=$(sed -n 's/.*so its group is \([a-z]*\) and.*/\1/p' README.txt)
       sudo chgrp "$group" work/workspaces/*
       sudo chmod 3770 work/workspaces/*;;
    9) for dir in work/audit/*; do
           report=$(sudo find "$dir" -type f -name 'report-*.txt')
           sudo chown "$person:${dir##*/}" "$report"
           sudo chmod 640 "$report"
       done;;
    10) for dir in work/company/management work/company/engineering work/company/sales work/company/support; do
            [ -d "$dir" ] || continue
            report=$(sudo find "$dir" -type f -name 'report-*.txt')
            project=$(sudo find "$dir" -mindepth 1 -maxdepth 1 -type d)
            sudo chgrp "${dir##*/}" "$report"
            sudo chmod 640 "$report"
            sudo chmod 2770 "$project"
        done
        sudo chmod 700 work/company/homes/*;;
    *) exit 1;;
esac
validate
