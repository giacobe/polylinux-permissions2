#!/bin/sh
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
command_required() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }
derive_hex() { printf '%s:%s' "$level_HASH" "$1" | sha256sum | awk '{print $1}'; }
index_for() { hex=$(derive_hex "$1"); byte=$(printf '%s' "$hex" | cut -c1-2); printf '%s\n' "$((0x$byte % $2))"; }
word_at() { wanted=$1; shift; while [ "$wanted" -gt 0 ]; do shift; wanted=$((wanted - 1)); done; printf '%s\n' "$1"; }
derive_parameters() {
    . "$INSTALL_ROOT/company-data.sh"
    . "$INSTALL_ROOT/polylinux-theme-catalog.sh"
    THEME_TITLE=$(theme_field title)
    THEME_ORG=$(theme_field org)
    THEME_PLACE=$(theme_field place)
    THEME_SYSTEM=$(theme_field system)
    THEME_PROJECT=$(theme_field project)
    THEME_ASSET=$(theme_field asset)
    THEME_EVENT=$(theme_field event)
    THEME_STATUS=$(theme_field status)
    THEME_SERVICE=$(theme_field service)
    THEME_HOST=$(theme_field host)
    THEME_FILE=$(theme_field file)
    THEME_PERSON=$(theme_field person)
    department_index=$(index_for department 4)
    DEPARTMENT=$(word_at "$department_index" $DEPARTMENTS)
    WRONG_DEPARTMENT=$(word_at "$(((department_index + 1) % 4))" $DEPARTMENTS)
    case "$DEPARTMENT" in
        management) people=$MANAGEMENT_USERS;; engineering) people=$ENGINEERING_USERS;;
        sales) people=$SALES_USERS;; support) people=$SUPPORT_USERS;;
    esac
    TARGET_USER=$(word_at "$(index_for employee 6)" $people)
    PROJECT=$THEME_PROJECT-$(derive_hex project-name | cut -c1-6)
    DOCUMENT=$THEME_FILE-$(derive_hex document-name | cut -c1-6).txt
    variant=$(index_for blocker 2)
}
write_document() {
    relative=${1#"$LEVEL_HOME"/}
    printf '%s operations record\nOrganization: %s\nDepartment: %s\nLocation: %s\nSystem: %s\nProject: %s\nAsset: %s\nEvent: %s\nStatus: %s\nService: %s\nHost: %s\nContact: %s\nReference: %s\n' \
        "$THEME_TITLE" "$THEME_ORG" "$DEPARTMENT" "$THEME_PLACE" \
        "$THEME_SYSTEM" "$THEME_PROJECT" "$THEME_ASSET" "$THEME_EVENT" \
        "$THEME_STATUS" "$THEME_SERVICE" "$THEME_HOST" "$THEME_PERSON" \
        "$(derive_hex "content:$relative")" > "$1"
}
render_box_file() {
    input=$1
    output=$2
    awk '
        BEGIN { width=70; border="**************************************************************************"; print border }
        function boxed(text, cut, i) {
            if (text == "") { printf "* %-70s *\n", ""; return }
            while (length(text) > width) {
                cut=width
                for (i=width; i>1; i--) if (substr(text,i,1)==" ") { cut=i-1; break }
                printf "* %-70s *\n", substr(text,1,cut)
                text=substr(text,cut+1); sub(/^[[:space:]]+/,"",text)
            }
            printf "* %-70s *\n", text
        }
        {
            line=$0
            if (line ~ /^[[:space:]]*__POLYLINUX_DIVIDER__[[:space:]]*$/) { print border; next }
            boxed(line)
        }
        END { print border }
    ' "$input" > "$output"
}
write_level_metadata() {
    printf 'Level: %s\n' "$1"
    printf 'PolyLinux: Permissions\n'
    printf 'Participant: %s\n' "$USER_ID"
    printf 'Exercise code: %s\n' "$EXERCISE_CODE"
    printf 'Theme: %s\n' "$THEME_TITLE"
    printf '%s\n' '__POLYLINUX_DIVIDER__'
}
finish_level() {
    raw_readme="$LEVEL_HOME/.README.raw.$levelnumber"
    {
        write_level_metadata "$levelToBuild"
        printf '%s\n' "$levelinstructions"
    } > "$raw_readme"
    render_box_file "$raw_readme" "$LEVEL_HOME/README.txt"
    rm -f "$raw_readme"
}
