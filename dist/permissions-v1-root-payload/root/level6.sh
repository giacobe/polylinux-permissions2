#!/bin/sh
set -eu
cd "$INSTALL_ROOT" || exit 1
. ./resources.sh
derive_parameters
mkdir -p "$LEVEL_HOME/work"
chmod 755 "$LEVEL_HOME/work"
mkdir -p "$LEVEL_HOME/work/path/$PROJECT/archive"
write_document "$LEVEL_HOME/work/path/$PROJECT/archive/$DOCUMENT"
chown -R "$TARGET_USER:$DEPARTMENT" "$LEVEL_HOME/work/path"
chmod 751 "$LEVEL_HOME/work/path"
chmod 750 "$LEVEL_HOME/work/path/$PROJECT" "$LEVEL_HOME/work/path/$PROJECT/archive"
chmod 640 "$LEVEL_HOME/work/path/$PROJECT/archive/$DOCUMENT"
if [ "$variant" -eq 0 ]; then chmod 740 "$LEVEL_HOME/work/path/$PROJECT"; else chmod 740 "$LEVEL_HOME/work/path/$PROJECT/archive"; fi
levelinstructions="Inside work/: The file path/$PROJECT/archive/$DOCUMENT already has the correct permissions. Members of $DEPARTMENT cannot traverse the complete path. Locate and repair the one blocking directory. Do not change the file. Run validate when finished and submit the printed key to the exercise grading form."

finish_level
