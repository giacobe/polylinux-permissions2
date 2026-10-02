#!/bin/sh
set -eu
cd "$INSTALL_ROOT" || exit 1
. ./resources.sh
derive_parameters
mkdir -p "$LEVEL_HOME/work"
chmod 755 "$LEVEL_HOME/work"
mkdir -p "$LEVEL_HOME/work/workspaces/$PROJECT"
write_document "$LEVEL_HOME/work/workspaces/$PROJECT/draft.txt"
chown root:"$WRONG_DEPARTMENT" "$LEVEL_HOME/work/workspaces/$PROJECT"
chmod 2777 "$LEVEL_HOME/work/workspaces/$PROJECT"
chown "$TARGET_USER:$DEPARTMENT" "$LEVEL_HOME/work/workspaces/$PROJECT/draft.txt"
chmod 660 "$LEVEL_HOME/work/workspaces/$PROJECT/draft.txt"
levelinstructions="Target department: $DEPARTMENT.
Inside work/: Repair workspaces/$PROJECT so its group is $DEPARTMENT and its mode is 3770 (setgid plus sticky, with full owner/group access and no other access). Members must inherit the department group for new entries and cannot delete another member's files. Preserve draft.txt exactly as it is. Run validate when finished and submit the printed key to the exercise grading form."

finish_level
