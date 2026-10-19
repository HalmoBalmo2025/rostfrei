# rostfrei

Keeps Rust projects free of slop, logic holes and dead code without having
to ask for it every time. A project that adopts rostfrei gets:

- **rules the model actually loads**: a short core in `CLAUDE.md`, and
  modules under `docs/guidelines/` that are read when the work touches
  their topic;
- **a gate machines enforce**: every clippy group that is stable on deny,
  picked restriction lints, path bans for the rules a lint cannot see, and
  one script (`scripts/check.sh`) for the pre-commit hook, `/ship` and CI;
- **an outside judge before every push**: `/ship` has fresh reviewer agents
  check the change; a finding counts only with evidence: a failing test, a
  surviving mutant, or two passages that contradict each other;
- **a loop that learns**: every confirmed finding is turned into the
  cheapest mechanism that would have caught it, and general ones flow back
  here as proposals.

Why: in the two projects this grew from, compiler and clippy were clean,
yet the history showed 34 fixed defects in 17 commits of one app and 38
commits of another that each fixed something the guidelines already asked
for. Replayed against those bugs, the review caught 26 of 35 (5 more in
part), and all 54 extra findings that were checked were real. A plain
review, run on four of the cases, caught about as many but backed none
with a test, and missed different ones. Details in
[`eval/RESULTS.md`](eval/RESULTS.md).

## What is in `template/`

| File | What it does |
| --- | --- |
| `CLAUDE.md` | Phase, workflow, checks, the core rules (0–6), the table of modules, project notes |
| `docs/guidelines/*.md` | Modules: testing, concurrency, processes, macOS, devices, UI, Dioxus/WASM, servers and data, updates |
| `Cargo.toml` | Project part with placeholders, profiles, rust/rustdoc/clippy lints, with reasons where they are not obvious |
| `clippy.toml` | Thresholds, test exemptions, banned methods, types and macros |
| `rust-toolchain.toml` | The pinned toolchain |
| `deny.toml`, `_typos.toml`, `.cargo/mutants.toml` | cargo-deny, typos, cargo-mutants |
| `scripts/check.sh` | The gate: `fast` (fmt, clippy, greps) and `full` (+ tests, docs, deny, shear, mutants on the diff) |
| `scripts/hooks/pre-commit` | Runs `check.sh fast` before every commit |
| `.claude/skills/ship/` | `/ship`: gate, independent review, one approval, fixes, re-check, lessons, push |
| `.claude/agents/rust-reviewer.md` | The reviewer `/ship` starts, with the evidence rules |
| `.claude/skills/zuschnitt/` | `/zuschnitt`: tailors everything to the project when the skeleton stands |
| `.claude/skills/rostfrei-update/` | `/rostfrei-update`: brings a project to the latest rostfrei |
| `.github/workflows/check.yml` | CI running the same gate |
| `.rostfrei` | Which rostfrei version the project follows |

## Using it

**New or existing project.** In the project folder, tell Claude Code:
"Set up rostfrei from https://github.com/HalmoBalmo2025/rostfrei". It
follows [`SETUP.md`](SETUP.md). Restart Claude Code afterwards: skills and
the reviewer agent load when a session starts.

**Working.** `Phase: Aufbau` in `CLAUDE.md`: build the skeleton fast; the
commit hook keeps fmt and clippy clean. Then `/zuschnitt` tailors the setup,
runs the first full review and switches to `Phase: Pflege`: a plan with one
approval before each change, and `/ship` before each push.

**Updating a project.** `/rostfrei-update`, every few months or when
rostfrei has changed something you want.

**Feeding lessons back.** `/ship` writes general lessons to
`ROSTFREI-VORSCHLAEGE.md` in the project. Open this repository in Claude
Code and run `/lernen <path to that file>`; it turns them into changes here,
checks the template still builds clean (`scripts/selftest.sh`) and bumps
the version.

**Tools**, installed once per machine:

    cargo install --locked cargo-mutants cargo-deny cargo-shear typos-cli

## Principles

1. A machine check beats a sentence: a type, then a lint, then a path ban,
   then a grep, then a test pattern, then a review question, and only then
   guideline text.
2. Nobody grades their own work: the reviewer has a fresh context and must
   prove what it claims.
3. One instance of a bug means a pattern: every instance is fixed.
4. Nothing changes under a project by itself: toolchain, lints and
   dependencies change in a deliberate step.
