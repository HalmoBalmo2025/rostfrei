---
name: lernen
description: Turns proposals from projects (ROSTFREI-VORSCHLAEGE.md files written by /ship) into changes of the rostfrei template. Use in the rostfrei repository when the user types /lernen, passes such files, or asks to take lessons from projects into rostfrei.
---

# /lernen

Talk to the user in their language; write the template in English.

## 1. Collect

Read every proposal file the user names (paths on this machine, or pasted
text), then the current template: `template/CLAUDE.md`,
`template/docs/guidelines/`, `template/Cargo.toml`, `template/clippy.toml`,
`template/scripts/check.sh`, `template/.claude/`.

## 2. Judge each proposal

- **Already covered?** Then it shows that a rule exists but was not
  followed: the fix is a stronger mechanism, not a second sentence.
- **General?** It must apply beyond the project it came from. A lesson that
  only one kind of project needs goes into the matching module, not the core.
- **Cheapest mechanism**, in this order: a type pattern, a lint, a
  `clippy.toml` entry, a grep in `check.sh`, a test pattern in `testing.md`,
  a question in `checklist.md`, guideline text. Prefer the earliest that
  works; text in the core only when nothing else can carry it.
- **Conflicts**: does it contradict another rule, a lint, or a project's
  documented deviation? Resolve it or reject it.
- **Size**: the core in `template/CLAUDE.md` stays short. Something that
  goes in may push something else out into a module.

## 3. One approval

One plan, grouped as grob / klein / nice to have, each item with its
origin (project, date) and the mechanism; rejected proposals with one line
why. Ask once (AskUserQuestion, multi-select).

## 4. Apply and check

- Change the template. New lints and path bans: verify them with
  `scripts/selftest.sh`, and for a path ban add one deliberate violation in
  a scratch crate and see it fail.
- `scripts/selftest.sh` must pass.
- `VERSION`: minor for new or changed rules, patch for fixes. Update
  `template/.rostfrei` to the same version. `CHANGELOG.md`: one line per
  change with its origin.
- Commit ("Learn from <projects>: …").

## 5. Close the loop

Tell the user which proposals were taken, changed or rejected, so the
entries can be removed from the projects' files, and that the projects get
the changes with `/rostfrei-update`.
