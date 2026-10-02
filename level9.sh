#!/bin/sh
set -eu
cd "$INSTALL_ROOT" || exit 1
. ./resources.sh
derive_parameters
mkdir -p "$LEVEL_HOME/work"
chmod 755 "$LEVEL_HOME/work"
mkdir -p "$LEVEL_HOME/work/audit/$DEPARTMENT"
write_document "$LEVEL_HOME/work/audit/$DEPARTMENT/$DOCUMENT"
write_document "$LEVEL_HOME/work/audit/$DEPARTMENT/control.txt"
chown root:"$DEPARTMENT" "$LEVEL_HOME/work/audit/$DEPARTMENT"
chmod 2750 "$LEVEL_HOME/work/audit/$DEPARTMENT"
chown root:root "$LEVEL_HOME/work/audit/$DEPARTMENT/$DOCUMENT"
chmod 666 "$LEVEL_HOME/work/audit/$DEPARTMENT/$DOCUMENT"
chown root:"$DEPARTMENT" "$LEVEL_HOME/work/audit/$DEPARTMENT/control.txt"
chmod 440 "$LEVEL_HOME/work/audit/$DEPARTMENT/control.txt"
levelinstructions="Target employee: $TARGET_USER.
Inside work/: Repair only audit/$DEPARTMENT/$DOCUMENT. Its required owner and group are $TARGET_USER:$DEPARTMENT and its required mode is 640. Do not alter control.txt or the audit directory. Run validate when finished and submit the printed key to the exercise grading form."

finish_level
