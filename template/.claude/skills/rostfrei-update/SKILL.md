---
name: rostfrei-update
description: Brings this project up to the latest rostfrei version as a deliberate update step. Use when the user types /rostfrei-update or asks to update the project's rostfrei setup, guidelines, lints or review skills from the rostfrei repository.
---

# /rostfrei-update

Talk to the user in their language.

1. Read `.rostfrei` (version, source, dropped modules) and "Project notes"
   in `CLAUDE.md` (the project's deliberate deviations).
2. Get the latest rostfrei: `git clone --depth 1 <source> "$(mktemp -d)/rostfrei"`
   (the repository is private: `gh` or git credentials on this machine are
   needed). Read its `CHANGELOG.md` from the project's version up to the
   latest.
3. For every file under `template/`, compare three things: the version the
   project started from (the CHANGELOG says what changed since), the
   project's file, and the latest. Upstream changes are applied unless they
   collide with a deviation recorded in "Project notes" or touch a dropped
   module; placeholders and project parts stay the project's.
4. One plan, grouped as grob / klein / nice to have, one approval
   (AskUserQuestion, multi-select). New lints that now fire count as grob:
   fixing them is part of the update.
5. Apply, run `scripts/check.sh full`, fix what the new rules report,
   update `version` in `.rostfrei`, commit ("Update rostfrei to <version>").
6. If `ROSTFREI-VORSCHLAEGE.md` has entries, remind the user to take them to
   rostfrei (`/lernen` there).
