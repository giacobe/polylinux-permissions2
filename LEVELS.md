# Permissions curriculum

Learners act as administrators in a themed operations environment in a disposable
VM. One of the shared PolyLinux themes is selected for the attempt from the lab ID,
learner email, and VM date. Its organization, place, system, project, and asset
vocabulary appears in each level's generated records, paths, and instructions.
Each level starts from a fresh, independent fault. Inspect, make the smallest repair,
then submit the current-state fingerprint from `validate`.

| Level | Primary skill | Starting evidence and required repair | Preserve |
| --- | --- | --- | --- |
| 1 | File ownership | A root-owned record must belong to the named employee; use `chown`. | Group, mode 640, contents. |
| 2 | Group ownership | A department report has another department's group; use `chgrp`. | Employee owner, mode 640, contents. |
| 3 | Read/write permission bits | A report starts at 604; give owner read/write, group read, others nothing (640). | Owner, group, contents. |
| 4 | Directory read versus execute | A project directory starts at 740; enable group listing and traversal (750). | Its document and ownership. |
| 5 | Home-directory privacy | Close a simulated employee home from 755 to 700. | Private subdirectory, notes, ownership. |
| 6 | Permissions along a path | One of two ancestors is 740; identify it and add group execute to restore 750. | Other ancestors, file, ownership. |
| 7 | Setgid inheritance | Change a shared department directory from 0770 to 2770. | Ordinary permission bits, ownership, starter file. |
| 8 | Sticky-bit deletion protection | Repair the workspace group and change 2777 to 3770: setgid + sticky + owner/group rwx. | Root directory owner, draft owner/group/mode/content. |
| 9 | Targeted administrative repair | Fix one report from root:root 666 to the named employee:department 640. | Department directory 2750 and control file root:department 440. |
| 10 | Independent permissions audit | Fix report group/mode to employee:department 640, project to root:department 2770, simulated home to 700. | Parent department 2750, plan 660, notes 600, all contents. |

Every answer has the same canonical shape: exactly 16 lowercase hexadecimal
characters, matching `[0-9a-f]{16}`, without spaces. The fingerprint includes all
paths beneath `work`, including the work directory itself. It is a submission key,
not a login password and not a correct/incorrect decision.

## Invariants

Only a deliberately specified set of metadata changes is necessary. The selected
theme, filenames, project names, record contents and level 6 blocker vary by seed.
Wrong groups are chosen from a different department by construction. Level 6
has exactly one blocker. Level 10 has all of its own evidence and needs no prior
answer. Department membership is real, not simulated in a text file.

Homes and the containing work directories permit traversal so an employee account
can exercise the intended permissions. The company home in levels 5 and 10 is a
simulated home beneath work; do not change `/home/levelN`. Root bypasses ordinary
permission checks, so access tests use `sudo -u EMPLOYEE`.

Setgid controls group inheritance, not write permissions; umask still applies to
new files. Sticky protects directory entries against deletion/rename by other
members, not against editing a group-writable file's contents. Directory owners
and root can still remove entries. No setuid script exercise is used.
