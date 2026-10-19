---
disable-model-invocation: true
name: zuschnitt
description: Tailors rostfrei to this project once the skeleton stands (end of Phase Aufbau) or when an existing project adopts rostfrei. Use when the user types /zuschnitt or asks to tailor, fit or adapt the rostfrei setup, the guidelines, Cargo.toml or clippy.toml to the project. Removes what does not apply, resolves contradictions, picks the profiles, runs the first full review and switches the phase to Pflege.
---

# /zuschnitt

The general setup becomes this project's setup: nothing in it that does not
apply, nothing that contradicts, every deviation written down with its
reason. Talk to the user in their language.

## 1. Take stock

Read `CLAUDE.md`, every file in `docs/guidelines/`, `Cargo.toml`,
`clippy.toml`, `rust-toolchain.toml`, `deny.toml`, `.cargo/mutants.toml`,
`scripts/check.sh`, then the code. Write down:
- crates and binaries; targets (native, `wasm32`, server); frameworks
  (Dioxus, tokio, …);
- side effects: child processes, helper programs, devices, network, files
  of the user, clipboard, UI;
- the language(s) of the product; how the program is run and released.

## 2. Plan

Make one plan, grouped as grob / klein / nice to have, and get one approval
(AskUserQuestion, multi-select). It covers:

- **Guideline modules**: which apply. A module that does not apply is
  deleted together with its row in the table of `CLAUDE.md`, and listed in
  `dropped-modules` in `.rostfrei`; then grep for its file name and fix
  every reference to it (`CLAUDE.md`, `Cargo.toml`, `clippy.toml`, the
  other modules). The rows that stay get this project's paths.
- **Core rules**: a rule that does not fit this project is changed in
  "Project notes" of `CLAUDE.md` with its reason, never silently ignored.
  Examples: the language of comments; an app that needs a `lib.rs`.
- **Profiles** in `Cargo.toml`: keep what the project needs, delete the
  rest. Compute-heavy code (signal processing, simulations, big numbers)
  may need `opt-level = 3` in dev; WASM gets `wasm-dev`/`wasm-release`; a
  server gets `server-release`. Measure where it matters (build time,
  runtime, binary size with `cargo bloat` or `wasm-opt --func-metrics`).
- **Lints**: run `scripts/check.sh fast` with `Phase: Pflege` set
  temporarily. For each lint that fights the project: an `#[expect]` on the
  item when the cause is local (a macro, one API), relaxing in `Cargo.toml`
  with a comment only when it fights the whole project. Each relaxation is
  listed in "Project notes".
- **clippy.toml**: the framework's entries (e.g. the Dioxus block), the
  `arithmetic-side-effects-allowed` types, threshold changes with reasons.
  Probe every new path: one deliberate violation must fail clippy.
- **Boundary modules**: which modules compute on outside input and get
  `#![deny(clippy::arithmetic_side_effects)]`; which module is the one
  process module, the one file module, the one clock module.
- **deny.toml** licenses, **.cargo/mutants.toml** exclusions (each with a
  reason), **rust-toolchain.toml** targets and `target_packages` in
  `scripts/check.sh` (only the web packages in a workspace with server
  crates), `cargo insta test --unreferenced=reject` in `scripts/check.sh` if
  the project uses insta, the CI workflow (delete it or adapt the runner,
  e.g. `macos-latest` for macOS-only code).
- **An existing codebase** usually breaks many rules at once. Count the
  findings per lint and per rule first; the plan fixes them pattern by
  pattern, one commit per lint or rule, possibly over several sessions.
  The phase stays Aufbau until the gate is green in Pflege mode.
- **Contradictions**: read everything again side by side. Two settings or
  rules that contradict each other, or a placeholder left over, are fixed.

## 3. Apply and check

Apply the approved plan, run `scripts/check.sh full` until green, commit
("Tailor rostfrei to <project>").

## 4. First full review

Run `/ship --full --no-push`. Its fixes are the last step of Aufbau.

## 5. Switch the phase

Set `Phase: Pflege` in `CLAUDE.md`, commit, and tell the user in two or
three lines what was tailored and what the first review found.
