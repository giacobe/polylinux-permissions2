#!/bin/sh
set -eu
cd "$INSTALL_ROOT" || exit 1
. ./resources.sh
derive_parameters
mkdir -p "$LEVEL_HOME/work"
chmod 755 "$LEVEL_HOME/work"
mkdir -p "$LEVEL_HOME/work/departments/$DEPARTMENT"
write_document "$LEVEL_HOME/work/departments/$DEPARTMENT/$DOCUMENT"
chown "$TARGET_USER:$WRONG_DEPARTMENT" "$LEVEL_HOME/work/departments/$DEPARTMENT/$DOCUMENT"
chmod 640 "$LEVEL_HOME/work/departments/$DEPARTMENT/$DOCUMENT"
levelinstructions="Inside work/: The file departments/$DEPARTMENT/$DOCUMENT belongs to the $DEPARTMENT department. Change only its group ownership to $DEPARTMENT. Run validate when finished and submit the printed key to the exercise grading form."

finish_level
