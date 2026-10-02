# PolyLinux Permissions

A deterministic ten-level permissions repair lab for the shared PolyLinux/v86
environment. Start with [the participant guide](participant-guide.md), consult
[the curriculum](LEVELS.md), and review [runtime requirements](TOOLSET.md) before
packaging. This directory is a standalone lab source tree.

## Installation

Place the runtime payload in `/root` of a compatible disposable Buildroot VM.
Root's `.profile` starts the installer. It derives the exercise code once from
the Buildroot VM's current ISO date and uses that same code in each level's
boxed README. During setup it prints the ten levels being created. Interactive
installation asks for the learner's email. For automated installation:

```sh
USER_ID=learner@example.edu CURRENT_DATE=2026-10-01 \
SYSTEM_PASSWORD=systemPassword sh /root/install.sh --non-interactive --no-login
```

`MAX_PARALLEL=1..10` controls builders, default 10. All homes start with a pending
README. Completed work is published before the final README; normal installation
enters level 1 while other workers finish. `--no-login` waits for every worker and
returns failure if any fail. A lock prevents simultaneous installers. A root rerun
resets precisely the ten lab homes; it does not remove other homes. A reboot clears
an interrupted runtime lock. Employee accounts are reused after group verification.

## Determinism

For level N, the answer seed uses the ISO date represented by the exercise code:

```text
SHA256(email + YYYY-MM-DD + SYSTEM_PASSWORD + LEVEL_PASSWORD_ROOT + N)
```

Exact UTF-8 bytes, no separators and no trailing newline. Defaults are
`systemPassword` and `levelPassword`; override both through environment variables.
Learner READMEs display the exercise code without a separate date. Their
instructions wrap inside a 40-column star box. Email spelling and case are
preserved, not silently normalized. Invalid dates or whitespace in the email are
rejected. Labeled SHA-256 subhashes choose department,
employee, names, blocker location, and record contents independently.

This deliberately replaces the starting repository's NUL-delimited seed scheme.
It requires new external expected keys; do not reuse that repository's grader.

## Submission contract: permissions-state-v1

`validate` hashes the current work tree as root, using C-locale relative-path sort.
For each path it records relative name, object type, octal mode, owner name and
group name, plus SHA-256 content for files or target text for symlinks. The header
contains the format version and level account. The first 16 lowercase hex digits
are submitted. Numeric UIDs, inode numbers, timestamps, absolute staging paths,
README, profiles and shell history are excluded. Unknown artifact types and read
errors fail explicitly; generated paths contain no newlines or delimiters.

The canonical record is `path|type|mode|owner|group` followed by a newline, then
file digest or symlink target followed by a newline where applicable. Root is `.`;
descendants begin `./`. Header: `permissions-state-v1\nlevelN\n`. Modes have no
leading zero. There are no expected answers or comparisons in the runtime payload.
Names and content carry seed variation into the resulting key.

External grading is a separate workflow. This delivery does not create or deploy a
Microsoft Form, Office Script, or Power Automate flow. `form_url` remains empty.
Tests and reference solvers stay outside the VM. Sudo makes the learner root in a
disposable client; the exercise is instructional, not a tamper-proof examination.

## Verification and packaging

```sh
sudo sh test.sh
python3 package.py
```

The test harness builds an isolated chroot and independently compares solved
filesystem states and keys against a Python model. `verify.sh` implements the
learner repair paths and never derives seeds or expected answers. `package.py`
emits an allowlisted runtime tarball and manifest under `dist/`.

Outside this workspace, pass a compatible Buildroot archive to the self-contained
test harness: `sudo sh test.sh /absolute/path/to/rootfs.cpio.gz`.

See `VALIDATION.md` for actual test results and deployment boundaries. A source
payload is not a boot-tested VM image.

## Source review

Adapted concepts and level generators from
[giacobe/polylinux-permissions](https://github.com/giacobe/polylinux-permissions),
commit `1128e5ad2547d1e835ed5987fd9fa3a5013d5b16`; upstream license retained.
Compared with the local Compression and Logs repositories and the current lab
framework. The original permissions runtime already preserved per-file ownership;
this remains essential, unlike a shared runtime that recursively chowns homes.

Replaced its timestamp-sensitive `ls`-based key, corrected the seed contract,
added noninteractive install and bounded workers, guarded reset, explicit sudo
policy, failure reporting, canonical colors, real solvers, regression tests, and
the browser participant guide. Level 8 adds sticky-bit protection to the original
shared-workspace repair.
