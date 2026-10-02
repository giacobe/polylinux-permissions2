#!/bin/sh
set -eu
case "$0" in */*) cd "${0%/*}";; esac
INSTALL_ROOT=$(pwd)
. "$INSTALL_ROOT/resources.sh"
export LC_ALL=C
[ "$(id -u)" -eq 0 ] || die 'run installer as root in a disposable lab VM'
NO_LOGIN=0
NON_INTERACTIVE=0
for arg in "$@"; do
    case "$arg" in --non-interactive) NON_INTERACTIVE=1;; --no-login) NO_LOGIN=1;; *) die "unknown option: $arg";; esac
done
for cmd in addgroup adduser awk cat chmod chgrp chown cp cut date find grep id ls mkdir mktemp mv passwd readlink rm rmdir sed sha256sum sleep sort stat su sudo touch tr visudo; do command_required "$cmd"; done
SYSTEM_PASSWORD=${SYSTEM_PASSWORD:-systemPassword}
LEVEL_PASSWORD_ROOT=${LEVEL_PASSWORD_ROOT:-levelPassword}
currentDate=${CURRENT_DATE:-$(date +%Y-%m-%d)}
case "$currentDate" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) die 'date must be YYYY-MM-DD';; esac
[ "$(date -d "$currentDate" +%Y-%m-%d)" = "$currentDate" ] || die 'invalid calendar date'
EXERCISE_CODE=$(printf '%X' "$(printf '%s' "$currentDate" | tr -d '-')")
if [ "$NON_INTERACTIVE" -eq 1 ]; then
    [ -n "${USER_ID:-}" ] || die 'USER_ID required with --non-interactive'
else
    while :; do
        printf 'Email address (use exactly the same spelling in the form): '
        IFS= read -r USER_ID
        printf 'Use %s? (y/n) ' "$USER_ID"
        IFS= read -r confirmed
        [ "$confirmed" != y ] || break
    done
fi
case "$USER_ID" in *[[:space:]]*|'') die 'email cannot contain whitespace';; ?*@?*.?*) ;; *) die 'invalid email';; esac
MAX_PARALLEL=${MAX_PARALLEL:-10}
case "$MAX_PARALLEL" in [1-9]|10) ;; *) die 'MAX_PARALLEL must be 1..10';; esac
export INSTALL_ROOT USER_ID currentDate EXERCISE_CODE SYSTEM_PASSWORD LEVEL_PASSWORD_ROOT
umask 022
# An atomic lock prevents simultaneous reset/build workers from mixing sessions.
mkdir -p /run/polylinux-permissions /etc/profile.d /etc/sudoers.d /home
mkdir /run/polylinux-permissions/lock 2>/dev/null || die 'installation already running; reboot if a prior build was interrupted'
trap 'rmdir /run/polylinux-permissions/lock 2>/dev/null || :' EXIT
. "$INSTALL_ROOT/company-data.sh"
for group in $DEPARTMENTS; do
    grep -q "^$group:" /etc/group || addgroup "$group"
done
for group in $DEPARTMENTS; do
    case "$group" in management) people=$MANAGEMENT_USERS;; engineering) people=$ENGINEERING_USERS;; sales) people=$SALES_USERS;; support) people=$SUPPORT_USERS;; esac
    for person in $people; do
        id "$person" >/dev/null 2>&1 || adduser -D -H -G "$group" -s /bin/sh "$person"
        [ "$(id -gn "$person")" = "$group" ] || die "existing $person has unexpected primary group"
    done
done
for n in 1 2 3 4 5 6 7 8 9 10; do
    id "level$n" >/dev/null 2>&1 || adduser -D -s /bin/sh "level$n"
    passwd -d "level$n" >/dev/null
done
# Explicit users avoid reliance on usermod or preexisting sysadmin membership.
policy=/etc/sudoers.d/polylinux-permissions
pending_policy=/run/polylinux-permissions/sudoers.pending
printf 'level1,level2,level3,level4,level5,level6,level7,level8,level9,level10 ALL=(ALL:ALL) NOPASSWD: ALL\n' > "$pending_policy"
chmod 440 "$pending_policy"
visudo -cf "$pending_policy" >/dev/null
cp "$pending_policy" "$policy"
chmod 440 "$policy"
rm -f "$pending_policy"
# Some baselines do not include sudoers.d. Append only this lab's exact include.
if ! grep -Eq '^[#@]includedir[[:space:]]+/etc/sudoers.d([[:space:]]|$)' /etc/sudoers; then
    grep -qxF '#include /etc/sudoers.d/polylinux-permissions' /etc/sudoers || printf '\n#include /etc/sudoers.d/polylinux-permissions\n' >> /etc/sudoers
fi
visudo -c >/dev/null
sudo -l -U level1 | grep -q NOPASSWD || die 'passwordless sudo policy is not effective'
cp "$INSTALL_ROOT/polylinux-colors.sh" /etc/profile.d/polylinux-colors.sh
chmod 644 /etc/profile.d/polylinux-colors.sh
for helper in nextlevel prevlevel validate; do cp "$INSTALL_ROOT/$helper" "/usr/bin/$helper"; chmod 755 "/usr/bin/$helper"; done
. "$INSTALL_ROOT/runtime.sh"
printf 'Creating Level'
for n in 1 2 3 4 5 6 7 8 9 10; do printf ' %s' "$n"; done
printf '\n'
prepare_levels
# Supervisor owns the lock once launched; stdin/HUP do not kill background builds.
(trap '' HUP; trap 'rmdir /run/polylinux-permissions/lock 2>/dev/null || :' EXIT; build_levels) </dev/null >> /var/log/polylinux-permissions.log 2>&1 &
supervisor=$!
trap - EXIT
if [ "$NO_LOGIN" -eq 1 ]; then
    wait "$supervisor" || die 'build failed; see /var/log/polylinux-permissions.log'
else
    until [ -f /run/polylinux-permissions/level1.ready ]; do
        [ ! -f /run/polylinux-permissions/level1.failed ] || die 'level 1 failed; see build log'
        kill -0 "$supervisor" 2>/dev/null || die 'build supervisor stopped; see build log'
        sleep 1
    done
    exec su -l level1
fi
