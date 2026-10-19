# Replay of real bugs

Does the `/ship` review find the bugs that compiler, clippy and the tests
let through? This folder records how that was measured and what came out
(`RESULTS.md`). The cases come from the two projects rostfrei grew from:
Diktator (a macOS dictation app) and Homepage (a Dioxus web workspace).

## Cases

Each case is a snapshot of a project at the commit *before* a fix, made
with `git archive` so that it has no history: a reviewer cannot read the
fix from `git log`. Two snapshots are at HEAD, for bugs that were still
open. 14 cases, 35 known defects:

| Case | Project, snapshot | Known defects |
| --- | --- | --- |
| D-c22da25 | Diktator, before "Beenden: Modell vor dem Prozessende freigeben" | 2 |
| D-c98e2bf | before "Sicherheitsnetz: Zahlen und Verneinungen ändert das Modell nie" | 2 |
| D-7f582e3 | before "Abbau in fester Reihenfolge" | 2 |
| D-a8bec38 | before "Steuerung: roher Text ohne Überarbeiten, Esc aus dem Zustand" | 4 |
| D-2638e4a | before "Panel überschreibt keine fehlerhafte Datei mehr" | 2 |
| D-918aa83 | before "Kindprozesse über ein Modul" | 4 |
| D-ccf2eeb | before "Doku, Protokoll und Kleinigkeiten" | 5 |
| D-45f85c7 | before "Rechte Sondertasten, Kontext schneller, …" | 3 |
| D-8fcb7c3 | before "…, Teile höchstens 28 s" | 2 |
| D-HEAD | Diktator HEAD (open bugs) | 4 |
| H-b1edad2 | Homepage, before "Adopt the new project template" | 1 |
| H-bd7552e | before "malachite_app: Running and queued jobs live inside the worker's Phase" | 1 |
| H-HEAD-malachite | Homepage HEAD, the calculator crate (open bug, reproduced) | 1 |
| H-HEAD-nh4no3 | Homepage HEAD, the fertiliser crate (open bugs) | 2 |

The known defects (`ground-truth.md`) were written from the fix commits and
from bugs confirmed at HEAD *before* any review ran. No reviewer saw them.

## Reviewers

**rostfrei 1.0.0**, one per case. A fresh agent was told to read
`template/.claude/agents/rust-reviewer.md` and follow it exactly, with
these changes for the replay: a copy of the snapshot instead of a git
worktree; mode `full`, focus `all`, task "Review these modules as they
are"; the rostfrei rules, modules and checklist instead of the snapshot's
older `CLAUDE.md`; no `check.sh` reports; the files to review named (the
ones the fix touched, plus neighbours). Diktator builds only on macOS, so
evidence there was quotes with `path:line`, plus scratch crates where a
behaviour of `std` could be shown on Linux.

**Baseline**, for four of the cases (D-a8bec38, D-918aa83, H-bd7552e,
H-HEAD-malachite): a fresh agent with the same files named and a plain
prompt:

> Review the Rust code in <case> for bugs and logic errors. Focus on these
> files: <the same files>; read other files for context as needed. […]
> Report each problem with file:line, what goes wrong in which situation,
> and how sure you are.

Both used the same model.

## Judge

A separate agent that had not seen the code or written a report scored
every report against the known defects. The reports had their setup
removed and were labelled A or B, with the labels shuffled per pair. The
rules:

- **CAUGHT**: the same place or mechanism and the same consequence.
- **PARTIAL**: the right place, but a related, weaker or vaguer problem. A
  defect that a report names only in a question counts as PARTIAL at most.
- **MISSED**: otherwise.

It also checked **precision**: for each report, the three most severe
findings outside the known defects, each checked against the code (REAL,
DOUBTFUL, WRONG). And it counted **evidence**: how many findings were
backed by an executed test, by quotes only, or by nothing. Its full
scoring is in `scores.md`. The key to the labels is at the end of that
file.

## Limits

- One run per case, so there is no measure of variance. 35 defects and 4
  pairs are a small sample.
- The known defects are incomplete. 12 of the 54 spot-checked extra
  findings were known defects of *another* case that were still open in
  this snapshot. A report was never marked down for them.
- Diktator could not be built here, so most evidence there is quotes.
- One judge, one model. The judge inferred from the report format which
  report was structured. The setups were hidden, but they were not
  indistinguishable.
- 1.1.0 changed the reviewer and the checklist based on these misses
  (`RESULTS.md`). Running these cases again would measure how well rostfrei
  learned these cases, not how well it reviews. A fair measure of 1.1.0
  needs new bugs, for example the next ones `/ship` or the user finds.

## Running it again

1. For each fixed bug, archive the parent of the fix commit (`git archive
   <commit>^ | tar -x -C cases/<name>`) and write its defects into the
   ground truth before reviewing.
2. Start one reviewer per case with the prompt above, against the rostfrei
   version under test. Start the baseline for a few cases.
3. Strip the setup from the reports, shuffle the labels, and give the judge
   the ground truth and the rules above.
