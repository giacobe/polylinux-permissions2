# Runtime and deployment requirements

Target: Buildroot Linux on v86, POSIX `/bin/sh`, real Unix ownership/modes, and
passwordless level-account navigation with `su`. The installer must run as root
in a disposable VM. It deliberately grants the ten learner accounts administrative
sudo access for these exercises; it is not a host-hardening installer.

## Installer and generators

Required commands: `addgroup adduser awk cat chmod chgrp chown cp cut date find
grep id ls mkdir mktemp mv passwd readlink rm rmdir sed sha256sum sleep sort stat
su sudo touch tr visudo`. Shell builtins include `printf`, `kill`, `wait`, and
`test`. Accounts use BusyBox `adduser -D -H -G` and `addgroup` syntax. A normal
Ubuntu/Debian adduser frontend is not an interchangeable guest implementation.

Required behavior: `date -d YYYY-MM-DD`, `stat -c '%a|%U|%G'`, sorted `find` output,
symbolic chmod, preservation of special directory bits, `sudo -n`, `sudo -u`,
`sudo -l -U`, and `visudo -c/-f`. GNU Coreutils `ls` supplies the canonical color
profile. Do not rely on an arbitrary BusyBox color palette.

The installer checks commands before changing accounts or evidence. It validates
the sudoers fragment and complete sudo policy. Account/group name conflicts fail
if a fictional employee has an unexpected primary group. Password deletion errors
are fatal rather than silently leaving navigation password-protected.

## Learner commands

`cat`, `ls -l/-ld`, `stat`, `id`, `sudo`, `chown`, `chgrp`, `chmod`, shell navigation,
`nextlevel`, `prevlevel`, and `validate`. Optional access experiments can use
`sudo -u EMPLOYEE cat PATH` or temporary files. Remove any experimental files in
work before generating the final submission key.

## Baseline handoff

The local baselines inspected for this delivery do not contain sudo or visudo.
Use a clean sudo-enabled baseline; do not patch host binaries into a release cpio.
The requested sudo package symbol is `BR2_PACKAGE_SUDO=y`, verified in the local
Buildroot 2025.02.15 source at `package/sudo/Config.in`. Preserve the existing GNU
Coreutils and BusyBox applets listed above. No additional kernel feature is needed
for ordinary Unix permissions, setgid directories, or sticky directories.

Validate the commands and their flags in the selected baseline, then package the
allowlisted payload under `/root`, keeping its `.profile` and the kernel unchanged.
Boot that exact output in v86. Check root auto-install, real learner sudo, all ten
repairs, next/previous navigation, reset, and readable colors with clean redirected
`ls` output. Preserve baseline identity/configs, source and output hashes, payload
manifest, and boot-test results. Source tests are not a replacement for this step.

## Development-only tests

`test.sh` requires Linux root, Python 3, an existing Buildroot archive for BusyBox,
and an Ubuntu host with sudo, PAM, and coreutils. It constructs a disposable chroot
on a Linux filesystem; host accounts and sudoers are never modified. Ubuntu tools
in that jail are test fixtures only and are never packaged as a baseline.
