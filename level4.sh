#!/bin/sh
set -eu
cd "$INSTALL_ROOT" || exit 1
. ./resources.sh
derive_parameters
mkdir -p "$LEVEL_HOME/work"
chmod 755 "$LEVEL_HOME/work"
mkdir -p "$LEVEL_HOME/work/projects/$PROJECT"
write_document "$LEVEL_HOME/work/projects/$PROJECT/$DOCUMENT"
chown -R "$TARGET_USER:$DEPARTMENT" "$LEVEL_HOME/work/projects/$PROJECT"
chmod 740 "$LEVEL_HOME/work/projects/$PROJECT"
chmod 640 "$LEVEL_HOME/work/projects/$PROJECT/$DOCUMENT"
levelinstructions="Inside work/: Members of $DEPARTMENT must be able to list and traverse projects/$PROJECT. The owner requires full access and everyone else requires no access. Repair only the project directory mode. Run validate when finished and submit the printed key to the exercise grading form."

finish_level
