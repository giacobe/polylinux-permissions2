#!/bin/sh
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
command_required() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }
derive_hex() { printf '%s:%s' "$level_HASH" "$1" | sha256sum | awk '{print $1}'; }
index_for() { hex=$(derive_hex "$1"); byte=$(printf '%s' "$hex" | cut -c1-2); printf '%s\n' "$((0x$byte % $2))"; }
word_at() { wanted=$1; shift; while [ "$wanted" -gt 0 ]; do shift; wanted=$((wanted - 1)); done; printf '%s\n' "$1"; }
derive_parameters() {
    . "$INSTALL_ROOT/company-data.sh"
    department_index=$(index_for department 4)
    DEPARTMENT=$(word_at "$department_index" $DEPARTMENTS)
    WRONG_DEPARTMENT=$(word_at "$(((department_index + 1) % 4))" $DEPARTMENTS)
    case "$DEPARTMENT" in
        management) people=$MANAGEMENT_USERS;; engineering) people=$ENGINEERING_USERS;;
        sales) people=$SALES_USERS;; support) people=$SUPPORT_USERS;;
    esac
    TARGET_USER=$(word_at "$(index_for employee 6)" $people)
    PROJECT=$(word_at "$(index_for project 4)" $PROJECTS)-$(derive_hex project-name | cut -c1-6)
    DOCUMENT=report-$(derive_hex document-name | cut -c1-6).txt
    variant=$(index_for blocker 2)
}
write_document() {
    relative=${1#"$LEVEL_HOME"/}
    printf 'PolyLinux fictional company record\nRecord: %s\n' "$(derive_hex "content:$relative")" > "$1"
}
finish_level() {
    cat > "$LEVEL_HOME/README.txt" <<EOF
PolyLinux Permissions — Level $levelnumber
Participant: $USER_ID
Date: $currentDate
Exercise code: $(printf '%X' "$(printf '%s' "$currentDate" | tr -d '-')")

$levelinstructions

Work from your home directory; paths in the task above are relative to work/.
Use sudo for administrative repairs; sudo is passwordless in this disposable VM.
Inspect with ls -ld, stat, id and sudo -u USER when appropriate.
Do not change file contents, names, or unrelated permissions or ownership.
Run validate after your repair. Submit its 16 lowercase hexadecimal characters
to the external exercise grading form. The key is case-sensitive, with no spaces.
validate fingerprints your current work; it never says correct or incorrect.
nextlevel and prevlevel do not require an answer. Each level is independent.
EOF
}
