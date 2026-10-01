#!/bin/sh
set -eu
cd "$INSTALL_ROOT" || exit 1
. ./resources.sh
derive_parameters
mkdir -p "$LEVEL_HOME/work"
chmod 755 "$LEVEL_HOME/work"
mkdir -p "$LEVEL_HOME/work/reports"
write_document "$LEVEL_HOME/work/reports/$DOCUMENT"
chown "$TARGET_USER:$DEPARTMENT" "$LEVEL_HOME/work/reports/$DOCUMENT"
chmod 604 "$LEVEL_HOME/work/reports/$DOCUMENT"
levelinstructions="Inside work/: Set reports/$DOCUMENT so the owner can read and write, the group can read, and everyone else has no access. Preserve its owner and group. Run validate when finished and submit the printed key to the exercise grading form."

finish_level
