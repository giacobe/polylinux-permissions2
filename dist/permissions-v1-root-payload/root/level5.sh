#!/bin/sh
set -eu
cd "$INSTALL_ROOT" || exit 1
. ./resources.sh
derive_parameters
mkdir -p "$LEVEL_HOME/work"
chmod 755 "$LEVEL_HOME/work"
mkdir -p "$LEVEL_HOME/work/homes/$TARGET_USER/private"
write_document "$LEVEL_HOME/work/homes/$TARGET_USER/private/notes.txt"
chown -R "$TARGET_USER:$DEPARTMENT" "$LEVEL_HOME/work/homes/$TARGET_USER"
chmod 755 "$LEVEL_HOME/work/homes/$TARGET_USER"
chmod 700 "$LEVEL_HOME/work/homes/$TARGET_USER/private"
chmod 600 "$LEVEL_HOME/work/homes/$TARGET_USER/private/notes.txt"
levelinstructions="Inside work/: The simulated home directory homes/$TARGET_USER must be accessible only by $TARGET_USER. Repair only that home directory mode. Run validate when finished and submit the printed key to the exercise grading form."

finish_level
