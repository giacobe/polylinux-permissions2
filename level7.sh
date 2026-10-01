#!/bin/sh
set -eu
cd "$INSTALL_ROOT" || exit 1
. ./resources.sh
derive_parameters
mkdir -p "$LEVEL_HOME/work"
chmod 755 "$LEVEL_HOME/work"
mkdir -p "$LEVEL_HOME/work/shared/$DEPARTMENT"
write_document "$LEVEL_HOME/work/shared/$DEPARTMENT/starter.txt"
chown -R root:"$DEPARTMENT" "$LEVEL_HOME/work/shared/$DEPARTMENT"
chmod 770 "$LEVEL_HOME/work/shared/$DEPARTMENT"
chmod 660 "$LEVEL_HOME/work/shared/$DEPARTMENT/starter.txt"
levelinstructions="Inside work/: The directory shared/$DEPARTMENT already has the correct ordinary access permissions. Configure it so newly created entries inherit the $DEPARTMENT group. Change nothing else. Run validate when finished and submit the printed key to the exercise grading form."

finish_level
