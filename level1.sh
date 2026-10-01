#!/bin/sh
set -eu
cd "$INSTALL_ROOT" || exit 1
. ./resources.sh
derive_parameters
mkdir -p "$LEVEL_HOME/work"
chmod 755 "$LEVEL_HOME/work"
mkdir -p "$LEVEL_HOME/work/records"
write_document "$LEVEL_HOME/work/records/$DOCUMENT"
chown root:"$DEPARTMENT" "$LEVEL_HOME/work/records/$DOCUMENT"
chmod 640 "$LEVEL_HOME/work/records/$DOCUMENT"
levelinstructions="Inside work/: Change the owner of records/$DOCUMENT to $TARGET_USER. Preserve the current group ownership and permissions. Run validate when finished and submit the printed key to the exercise grading form."

finish_level
