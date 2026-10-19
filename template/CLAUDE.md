# CLAUDE.md

This project follows rostfrei (version in `.rostfrei`). The rules below are
loaded in every session; the modules under `docs/guidelines/` are read when
the work touches their topic (table at the end). Project-specific notes and
every deliberate deviation from rostfrei go into "Project notes".

Phase: Aufbau

## Working

- **Aufbau** (building the skeleton): write code fast. Every commit passes
  fmt and clippy; unused-code warnings fail only from Pflege on. When the
  skeleton stands, the user runs `/zuschnitt`; it tailors the setup to the
  project and switches the phase to Pflege.
- **Pflege** (maintenance, features, fixes): before writing code, write a
  short plan: what changes, which types, states, callers, persisted data and
  wire formats it touches, what could break as a side effect, and which tests
  will prove it. Group the items as grob / klein / nice to have and get one
  approval for the groups, then work through them without asking again.
- **`/ship` before every push** in Pflege: an independent reviewer checks
  the change; only findings with evidence count.
- The gate is never weakened on the side. Lints, `clippy.toml`,
  `scripts/check.sh`, the phase, the toolchain and dependency versions
  change only as a separate, deliberate step with a stated reason
  (`docs/guidelines/update.md`).
- Fixing one instance of a pattern means finding every instance (grep) and
  fixing them all, or listing the rest in the commit message.

## Checks

    scripts/check.sh fast   # fmt, clippy, greps, typos (the pre-commit hook)
    scripts/check.sh full   # + tests, docs, deny, shear, mutants on the diff

The git hook is installed once per clone: `git config core.hooksPath scripts/hooks`.

## Core rules

**0. Ground rules**
- A lint is silenced only with `#[expect(lint, reason = "…")]` on the
  smallest item, with a reason that would convince a reviewer. Never
  `#[allow]`, never an inner `#![allow]`/`#![expect]` over a whole module.
- No `unsafe` outside one `sys` module per platform API, each block with a
  `// SAFETY:` comment; prefer a maintained binding crate (`macos.md`).
- English for names, comments, docs, logs, errors and commits; text shown to
  the user is in the product's language.
- Comments say why. A doc comment states the contract: preconditions, units,
  invariants, errors, edge behaviour; one that only repeats the name is not
  written. When behaviour changes, comments, docs, README and messages change
  in the same commit. No references to plans, phases or tickets.
- Knowledge the code cannot show (protocols, measured limits, experiment
  results) is written down once under `docs/` and the code points there.

**1. Types model the domain**
- A fixed set of cases is an enum, values that belong together are a struct.
  No magic strings, parallel vectors, positional tuples, `Option<Option<T>>`,
  and no bools as parameters or as more than one field: use an enum.
- Illegal states are unrepresentable: data that exists only in some states
  lives inside those variants, never in an `Option` or bool beside the state.
  A field that can be derived from others is a method.
- No sentinels: absent is `None`, not `""`, `0`, `-1`, `1e9`, `∞` or a
  fallback path. No `Default` where no value is meaningful.
- Newtypes for ids, units and validated values; durations are `Duration`.
  Parse, don't validate: raw input becomes such a type once, at the boundary
  (`TryFrom`, `FromStr`, `serde(try_from)`), and the type travels on. A type
  with an invariant keeps its fields private; its constructor checks and
  returns `Result`.
- One source of truth for defaults, limits, names and lists. Constants that
  must agree are checked together (a `const` assertion or a test).
- Exhaustive by construction: adding a variant makes the compiler point at
  every place to change; tables keyed by an enum get a test over all variants.

**2. Control flow and state machines**
- Branch with `match`. On your own enums list every variant; no `_`, also not
  inside tuples, where the lint is blind: nest state-major
  (`match state { … => match event { … } }`) instead of a tuple match. No
  `matches!` or `if let` to decide a transition.
- A state machine is a pure `step(state, event, now) -> (State, Vec<Effect>)`;
  a thin shell performs the effects. Classify each input into an enum first;
  steps due after every input run after the `match`, never skipped by an
  early `return`.
- Every started operation ends in exactly one terminal event (done, failed,
  cancelled); every request gets exactly one reply, rejections included.
  Work already done survives a failing step. Cancel and stop are idempotent.
- Happy path at the left margin (`let … else`, `?`). Iterators, not index
  arithmetic. Results never depend on hash order. Small functions with one
  job. An order that matters (pipeline, start-up, shutdown) is written down
  in one function.

**3. Failures**
- The program does not panic on input or environment. Lossy number
  conversions go through one `numeric` module, never `as`.
- No silent defaults. An impossible case is (1) made impossible by structure
  (`split_once`, `char_indices`, `strip_prefix(…)?`), else (2)
  `debug_assert!(cond, "invariant: …")` plus a named fallback, else (3) for a
  provably dead match arm `unreachable!("…")` under
  `#[expect(clippy::unreachable, reason = "…")]`. `unwrap_or_default`,
  `unwrap_or(0)`, `saturating_*` and `.ok()` only where that value is the
  domain meaning, with a comment saying so.
- Arithmetic on outside input (parsers, protocols, sizes from files or
  devices) lives in modules marked `#![deny(clippy::arithmetic_side_effects)]`;
  elsewhere `overflow-checks` stops the program instead of computing on.
- Errors are enums per module or concern, variants carry the context to
  report them; no `String` errors. Propagate with `?`, convert keeping the
  source. Another program's error keeps that program's message as a field.
- No error is swallowed. For every ignored error ask: does it change the
  result's content? Then it reaches the user or the log. Where failure is
  truly irrelevant: `Ok(()) | Err(_) => {}` with a comment why. A later
  message never replaces an error the user has not seen.
- A value produced by a failed read is never written back: a user file that
  fails to parse is never overwritten with defaults. User files are never
  overwritten at all (`create_new`; atomic replace only in one file module).
- A panic hook logs location and thread (no user content), because the
  release build aborts.

**4. Ownership and lifecycle**
- Borrow before you clone; a `.clone()` must be needed. `Arc`/`Rc` only for
  genuinely shared ownership, cloned as `Arc::clone(&x)`. No global mutable
  state, no leaking, no `'static` to satisfy the borrow checker.
- Every resource (thread, task, child process, timer, listener, file, loaded
  model) has exactly one owner: usually a struct field; its own thread only
  if it blocks for long or several threads use it. A guard type stops and
  joins or reaps it on every exit path, error returns included; nothing is
  fire-and-forget. On abort no `Drop` runs (`processes.md`).
- Start-up cleans up what a crashed run left; shutdown runs in reverse
  order, and nothing still running can restart what is already stopped.
  `main` maps an enum of how the program ended to the exit code.
- Logs record events, decisions, sizes and durations, never user content;
  user text is a newtype without `Display` and with a redacting `Debug`.
- Time and randomness are injected (a `now` parameter, a clock trait).

**5. Tests** (`testing.md`)
- Property tests for parsers, numeric code and state machines; fakes that
  can fail on command; flow tests for every dependency failing in every state.
- Every fixed bug gets a test that replays it and fails without the fix.
- A surviving mutant on a changed line is killed by a test, or excluded in
  `.cargo/mutants.toml` with the reason it is equivalent.

**6. Structure**
- Visibility as narrow as possible. Apps have no `lib.rs` unless a second
  binary needs one (`pub` hides dead code); integration tests reach the
  binary through `env!("CARGO_BIN_EXE_<name>")`.
- One module or directory per feature; split a file when it mixes concerns.
  A module with submodules is a directory with `mod.rs`.
- Names say what a thing is in the domain; no abbreviations.
- Every dependency earns its place and has a comment saying what it is for;
  `default-features = false` where the defaults pull in more.

## Modules: read before touching

`/zuschnitt` adds this project's paths to each row and deletes the rows
that do not apply.

| The work touches                                            | Read first                         |
| ----------------------------------------------------------- | ---------------------------------- |
| tests, fakes, fixtures                                      | `docs/guidelines/testing.md`       |
| threads, async, channels, timers, retries, cancellation     | `docs/guidelines/concurrency.md`   |
| child processes, helper programs, other languages           | `docs/guidelines/processes.md`     |
| macOS APIs, FFI, clipboard, sleep and wake, launching       | `docs/guidelines/macos.md`         |
| hardware, devices, network peers                            | `docs/guidelines/devices.md`       |
| any user interface                                          | `docs/guidelines/ui.md`            |
| Dioxus, WASM, the browser                                   | `docs/guidelines/dioxus-wasm.md`   |
| servers, databases, persisted or exchanged data formats     | `docs/guidelines/server-db.md`     |
| toolchain, lint or dependency changes                       | `docs/guidelines/update.md`        |

## Project notes

<!-- Language of the product, exceptions to the rules above (each with its
reason), how to run the program. -->
