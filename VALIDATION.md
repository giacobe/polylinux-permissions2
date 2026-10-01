# Validation and handoff

Validation date: 2026-10-01.

## Locally validated

- POSIX shell syntax for installer, generators, runtime, navigation, profiles,
  fingerprint command, and reference solvers.
- Sixty successful reference repairs: ten levels across six installations,
  including repeat inputs, serial versus parallel generation, changed learner,
  changed ISO date, and changed exercise password.
- Independent Python expected-state model checks every path, owner, group,
  mode and file content, and the exact submission fingerprint.
- Initial states are reproducible, initially incorrect, and reset after repair.
- Both seeded level 6 blocker locations are exercised. A different employee in
  the same department cannot read before repair and can read afterward.
- New level 7 entries inherit the department group. A second department member
  cannot delete another member's level 8 draft after sticky-bit repair.
- Missing sudo fails before account/home creation. Worker failure produces a
  failed-level README and marker, nonzero installer result, and releases the lock.
- Unsafe cleanup targets are rejected; unrelated home content survives reset.
- Passwordless next/previous navigation works without answer checks.
- Canonical color profile matches the shared asset; redirected `ls` has no escapes.
- Timestamp and README edits do not change the key; unintended permissions on
  either a target or a preserved control file do change it.
- Participant-guide front matter and Markdown structure pass the project validator.
- Runtime tarball contains exactly the 21 allowlisted runtime files, with no
  reference solver, tests, expected-state model, answer store, or checklevel.

Tests run in a temporary WSL Linux chroot with real Unix metadata, the existing
Buildroot BusyBox account tools, and Ubuntu sudo/coreutils/PAM. Host accounts and
host sudo policy are not modified. These tests validate lab behavior, not exact
guest-package compatibility or browser boot.

## Delivered

- Complete lab sources, curriculum, participant guide, tool manifest, regression
  harness and instructor reference solvers.
- `dist/permissions-v1-root-payload.tar.gz`: runtime-only files beneath `root/`.
- `dist/payload-sha256.txt`: SHA-256 for every runtime file.

## Pending deployment

No bzImage/rootfs pair was produced or modified, and no v86 boot was claimed.
The local baseline archives inspected lack sudo and visudo. The lab assumes these
commands as requested; supply a clean baseline with them to complete VM packaging
and exact-image boot verification. Do not copy the test jail into a release image.

No website or upstream repository was changed. No external grader was created,
imported, activated, or verified. The participant guide intentionally leaves the
submission-form URL empty. The new seed and fingerprint contracts require matching
external grading before student release.
