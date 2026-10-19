---
name: ship
argument-hint: "[--full] [--base REF] [--no-push]"
description: The independent review before a push in a rostfrei project. Use when the user types /ship or asks to push, ship or finish a change. Runs the full gate, has fresh reviewer agents check the change and prove every finding, gets one approval for the fixes, fixes them, checks again, records lessons for rostfrei, then pushes. Arguments - --full reviews the whole codebase instead of the diff; --base REF sets the base; --no-push stops before pushing.
---

# /ship

The author of a change does not judge it. Fresh reviewers do, and only
findings with evidence count. Talk to the user in their language; keep
files, commits and the reviewer's work in English (unless the project notes
in `CLAUDE.md` say otherwise).

Arguments: `--full` (review every module, not the diff: used by
`/zuschnitt` and when a project adopts rostfrei), `--base REF`,
`--no-push`.

## 1. Prepare

- Read `CLAUDE.md`: the phase, the project notes, the module table.
- Uncommitted changes: commit them first (the pre-commit hook runs the fast
  gate). Never use `--no-verify`.
- Base: `--base`, else the upstream branch, else `origin/HEAD`. With none,
  ask the user, or in `--full` mode use the root commit.
- The task statement: what the user asked for in this session; otherwise
  the commit messages since the base. One paragraph, no judgement.

## 2. Gate

Run `scripts/check.sh full --base <base>`. While it is red, fixing it is
your job, not the reviewer's: fix, commit, run again.
- A surviving mutant gets a test that kills it. Only a truly equivalent
  mutant (it changes nothing observable) gets an `exclude_re` entry in
  `.cargo/mutants.toml` with a comment why; that is a gate change the
  reviewer will see.
- A missing tool is installed (`cargo install --locked cargo-mutants
  cargo-deny cargo-shear typos-cli`), not skipped.

## 3. Review

Start reviewers with the Agent tool, `subagent_type: rust-reviewer`, in
parallel, each with a fresh context. If `rust-reviewer` is not available
(it is loaded when the session starts; a template copied into the project
during this session is not yet known), stop and ask the user to restart
Claude Code; never substitute another agent type.
- `diff` mode: three reviewers, focus `logic`, `hygiene` and `free`.
- `--full` mode: split the code into parts of roughly 1,500–3,000 lines
  along module boundaries; per part one reviewer with focus `all` and one
  with focus `free`, plus one `hygiene` reviewer over the whole tree for
  duplication and drift.

Each prompt contains only: the task statement, the mode and focus, the
base, the paths of `target/rostfrei/{diff.patch,gate.patch,attention.txt,
check-full.txt,mutants.out/missed.txt}`, the files or modules to review in
`--full` mode, and the guideline modules that apply (from the table in
`CLAUDE.md`, by the paths touched; none for focus `free`). Never your
reasoning about the code, your opinion of it, or hints about where bugs
might be.

## 4. Sort the findings

- Check each finding's evidence. If it is unclear, run the reviewer's test
  patch yourself in a scratch worktree. A finding without working evidence
  becomes a question.
- Settle the questions before the user sees them: for each, read the code
  it names and, where you can, write a small test in a scratch worktree. A
  question you confirm becomes a finding with your evidence; one you refute
  is dropped with a line in the report; only what neither reading nor a
  test can settle goes to the user. (In the replay, two real defects ended
  up only as questions.)
- Merge duplicates across reviewers; keep the list of other instances.
- Group as **grob**, **klein**, **nice to have** (the reviewer's severity,
  corrected where it is plainly wrong).

## 5. One approval

Show the user the groups: one line per finding (what goes wrong, where,
which evidence), then the open questions (at most five). Ask once, with
AskUserQuestion, which groups to fix (multi-select; exceptions by number
under "Other"). The user may answer a question in the same go.

If nobody answers (an unattended run), fix grob and klein, leave nice to
have in the report, and say so at the top.

## 6. Fix

Note the commit before the first fix (`git rev-parse HEAD`): the re-check
reviews only what changed after it. For each approved finding:
- the reviewer's failing test becomes the regression test;
- fix the cause, and every other instance of the same pattern the reviewer
  listed or a grep finds;
- `scripts/check.sh fast`, then commit, one commit per finding or per small
  group, the message naming what went wrong.

## 7. Check again

- `scripts/check.sh full --base <base>` until green.
- One reviewer, fresh context, focus `all`, gets the earlier findings and
  the fixes only (`git diff <commit before the first fix>` written to
  `target/rostfrei/fixes.patch`): for each fix it confirms that the regression
  test fails with the fix reverted and passes with it, and looks for new
  problems in the fix itself. New grob or klein findings go back to step 5.

## 8. Learn

For every confirmed finding, ask: which mechanism would have caught it
earliest and cheapest? In this order: a type that makes it impossible, a
lint, an entry in `clippy.toml`, a grep in `scripts/check.sh`, a test
pattern, a question in `checklist.md`, a sentence in the guidelines.
- Specific to this project: change this project's files (project notes in
  `CLAUDE.md`, `clippy.toml`) as part of the fixes.
- General: append a proposal to `ROSTFREI-VORSCHLAEGE.md` in the project
  root, in this shape, unless the same proposal is already there:

      ## <YYYY-MM-DD> · <project> · <short title>
      - Finding: <what went wrong, path:line, commit>
      - Class: <defect class>
      - Caught by: /ship reviewer, step <n> | the user | in use
      - Cheapest mechanism: <type | lint | clippy.toml | check.sh | test pattern | checklist | guideline>
      - Proposal: <the exact text or setting, and where it goes>
      - General because: <why it applies beyond this project>

## 9. Push and report

- `git push` (`git push -u origin HEAD` when the branch has no upstream yet),
  unless `--no-push`.
- Report to the user in a few lines: what was found and fixed, what was
  left and why, surviving mutants, proposals written for rostfrei.
