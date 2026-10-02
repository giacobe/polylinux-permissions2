---
title: "PolyLinux Users, Groups, and Permissions"
short_title: "Permissions"
panel_title: "Learning Path"
form_url: ""

---

# Users, Groups, and Permissions

Become the administrator of a small fictional company. Across ten levels, repair
ownership, protect private information, and configure shared workspaces. Each
level contains a separate assignment; you can complete them in any order.

## Start the lab

Log in as `root` when prompted. The lab starts its installer automatically. Enter
your email exactly as you will enter it on the submission form, and confirm it.
The installer uses that email and the lab date to create your assignments, then
opens level 1. If installation does not start, run:

```sh
cd /root
sh install.sh
```

At each level, begin with:

```sh
pwd
cat README.txt
ls -l work
```

The README names your employee, department, paths, and required final state.
Paths in the task are relative to `work/`. Prefix those paths with `work/` when
running commands from your home directory. Do not copy another learner's names.

## Repair and submit

Inspect first, make the requested change, and preserve everything else. Use `sudo`
for commands requiring administrative privileges. It does not ask for a password
in this lab. These privileges are intended for the disposable exercise VM.

When you have finished a repair, run:

```sh
validate
```

Submit the resulting **16 lowercase hexadecimal characters** to the external
exercise form. Preserve every character, including leading zeroes. Do not add
spaces or quotes. A key is produced for an unfinished or incorrect repair too;
the command records your current work and does not evaluate it. Run it again if
you make further changes. It is not a password for the next level.

The Form also asks for the **Exercise code** printed in your README. Copy it as
text; it represents the date used to build this session. Enter your email with
the same capitalization used during installation. Do not substitute today's
date if you are submitting an earlier session.

```sh
nextlevel
prevlevel
```

Navigation never depends on an answer. If a level says it is preparing, return
shortly and read its README again. A reset or page reload discards your work.

## Command reference

| Command | Purpose |
| --- | --- |
| `id employee` | Inspect a user's primary and supplementary groups. |
| `ls -l path` | Inspect a file or list directory contents. |
| `ls -ld directory` | Inspect the directory itself. |
| `stat path` | Inspect detailed metadata. |
| `stat -c '%a %U %G' path` | Show octal mode, owner, and group. |
| `sudo chown employee path` | Change the owner without specifying a group. |
| `sudo chgrp department path` | Change the group. |
| `sudo chmod g+x directory` | Add group traversal permission. |
| `sudo -u employee command` | Test a command as another user. |

The permission columns describe owner, group, and others. Read is worth 4, write
2, and execute 1. On a directory, read lists names, execute allows traversal, and
write plus execute permits creating or removing entries. File write permission
does not determine whether its directory entry can be deleted.

Setgid on a directory makes new entries inherit its group. Sticky restricts who
can remove or rename entries. These special bits appear in addition to ordinary
read/write/execute permissions. Avoid recursive changes unless a task explicitly
asks for them; these assignments require precise repairs.

## Learning path and hints

### Level 1: Who owns this file?

Read the owner column and identify the employee named in your README. Hint: an
owner-only change does not require specifying a group after a colon.

### Level 2: Which team owns this report?

Compare the department directory name with the file's group. Hint: changing a
group does not require changing the owner or mode.

### Level 3: Translate the access policy

Work through owner, group, and others separately. Hint: add read/write/execute
values within each category before combining the three digits.

### Level 4: Listing is not traversal

Inspect the project directory itself. Hint: a group may see names yet still be
unable to access the named files if directory execute is missing.

### Level 5: Close the front door

The nested notes are already private. Hint: repair the simulated home directory
named in the README, without applying the mode recursively.

### Level 6: Follow the entire path

Inspect each ancestor of the document. Hint: one directory is missing a group
permission that the other relevant directory already has.

### Level 7: Keep new files in the team

The ordinary access bits are already right. Hint: group inheritance is controlled
by a special directory bit; it does not force every new file to be writable.

### Level 8: Share without deleting each other's work

Fix both the group and the special permission bits. Hint: inheritance and deletion
protection solve different problems. Sticky does not stop editing a writable file.

### Level 9: Repair only the damaged report

Compare the report against its required owner, group, and mode. Hint: the control
file and containing directory are deliberately different and must stay that way.

### Level 10: Complete the audit

Make a small checklist from the README, one row per requested repair. Hint: audit
each changed item afterward and leave the plan, notes, and parent directories alone.

## Troubleshooting

- **Permission denied:** use `sudo` for administrative inspection or repairs.
  To test a user's access, use `sudo -u` with that employee; testing as root hides
  ordinary permission problems.
- **A command cannot find a file:** return with `cd`, reread `README.txt`, and
  check the `work/` prefix and your generated names.
- **Your key changes:** check for unintended edits, new files, renamed paths,
  ownership changes, or extra permission bits within `work/`.
- **You made a broad recursive change:** restore the exact requested state or
  restart the VM and begin again. Resetting discards all ten levels' work.
- **validate fails or installation reports a missing command:** record the error
  for your instructor. Do not install software inside the exercise.
