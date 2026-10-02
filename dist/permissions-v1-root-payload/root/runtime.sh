#!/bin/sh
safe_remove_home() {
    case "$1" in /home/level[1-9]|/home/level10|/home/.permissions-level[1-9]|/home/.permissions-level10) rm -rf "$1";; *) die "unsafe reset: $1";; esac
}
write_level_status_readme() {
    status=$1
    home=$2
    level=$3
    raw="$home/.README.raw.$$"
    {
        write_level_metadata "$level"
        printf '%s\n' "$status"
        if [ "$status" = 'This level has not completed building yet.' ]; then
            printf '\n%s\n' 'You may continue to another level or return here shortly.'
        else
            printf '\n%s\n' 'Restart this lab to try again. If the problem continues, report it to your instructor.'
        fi
    } > "$raw"
    render_box_file "$raw" "$home/README.txt"
    rm -f "$raw"
}
prepare_levels() {
    rm -f /run/polylinux-permissions/*.ready /run/polylinux-permissions/*.failed /run/polylinux-permissions/all-ready
    : > /var/log/polylinux-permissions.log
    for n in 1 2 3 4 5 6 7 8 9 10; do
        home=/home/level$n
        safe_remove_home "$home"
        mkdir "$home"
        cp "$INSTALL_ROOT/profile" "$home/.profile"
        write_level_status_readme 'This level has not completed building yet.' "$home" "level$n"
        chown "level$n:level$n" "$home"
        chmod 755 "$home"
    done
}
build_one() (
    levelnumber=$1
    levelToBuild=level$1
    LEVEL_HOME=/home/.permissions-$levelToBuild
    level_HASH=$(printf '%s%s%s%s' "$USER_ID" "$currentDate" "$SYSTEM_PASSWORD" "${LEVEL_PASSWORD_ROOT}${levelnumber}" | sha256sum | awk '{print $1}')
    export levelnumber levelToBuild LEVEL_HOME level_HASH
    failed() {
        result=$?
        if [ "$result" -ne 0 ]; then
            write_level_status_readme 'This level could not be prepared.' "/home/$levelToBuild" "$levelToBuild"
            touch "/run/polylinux-permissions/$levelToBuild.failed"
        fi
    }
    trap failed EXIT
    safe_remove_home "$LEVEL_HOME"
    mkdir -m 700 "$LEVEL_HOME"
    sh "$INSTALL_ROOT/level$levelnumber.sh"
    [ -s "$LEVEL_HOME/README.txt" ]
    cp "$INSTALL_ROOT/profile" "$LEVEL_HOME/.profile"
    # Only the containing home belongs to the learner; never recursively chown.
    chown "$levelToBuild:$levelToBuild" "$LEVEL_HOME"
    chmod 755 "$LEVEL_HOME"
    chmod 644 "$LEVEL_HOME/.profile" "$LEVEL_HOME/README.txt"
    # Publish completed work while the pending README remains in place.
    mv "$LEVEL_HOME/work" "/home/$levelToBuild/work"
    mv "$LEVEL_HOME/README.txt" "/home/$levelToBuild/README.txt"
    safe_remove_home "$LEVEL_HOME"
    touch "/run/polylinux-permissions/$levelToBuild.ready"
)
build_levels() {
    failures=0; running=0; pids=
    for n in 1 2 3 4 5 6 7 8 9 10; do
        build_one "$n" &
        pids="$pids $!"; running=$((running + 1))
        if [ "$running" -eq "$MAX_PARALLEL" ]; then
            for pid in $pids; do wait "$pid" || failures=$((failures + 1)); done
            pids=; running=0
        fi
    done
    for pid in $pids; do wait "$pid" || failures=$((failures + 1)); done
    [ "$failures" -eq 0 ] || return 1
    touch /run/polylinux-permissions/all-ready
}
