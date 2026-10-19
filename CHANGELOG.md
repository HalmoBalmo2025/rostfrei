# Changelog

Versions: minor for new or changed rules, patch for fixes. Every entry
names where it came from.

## 1.1.0 (2026-10-19)

From an independent review of 1.0.0 and the first replay of real bugs
(`eval/`).

### Gate (`scripts/check.sh`)
- `--base` without a value no longer loops; an unknown base fails instead
  of passing green (CI after a force push).
- Reports in `target/rostfrei/` are cleared on every `full` run, so the
  reviewer never reads an old diff or old surviving mutants.
- The dependency-comment check works: a comment directly above each
  dependency or at the end of its line; `[dependencies.name]` tables too.
- `attention.txt` lists `path:line` and also `unwrap_or*`, `map_or`,
  `.err()`, `let _`, `wrapping_*`.
- The String-error grep also finds `type Err = String` and `&str` errors.
- A path in `clippy.toml` that does not resolve fails the gate.
- `gate.patch` also covers `CLAUDE.md` (the phase), `_typos.toml`,
  `.claude/`, `.github/` and `.rostfrei`.
- Extra targets (WASM) are checked without `--all-targets` and for
  `target_packages` only, so server crates are not built for WASM.
- A missing tool fails `full` and is reported by `fast`; no forced colours.

### Review
- The reviewer prints its worktree path and uses it literally (shell state
  does not carry over between calls) and removes it before answering.
- `/ship` stops when `rust-reviewer` is unknown (a restart is needed after
  setup) instead of using another agent; the re-check sees only the fixes
  (`fixes.patch`); `git push -u` when there is no upstream.
- `/zuschnitt`, `/rostfrei-update` and `/lernen` run only when the user
  types them.
- Checklist: two facts folded into one state; retired keys under
  `deny_unknown_fields`; a UI that starts from defaults after a failed load;
  an error message replaced by a later one in the same event; requests that
  supersede each other (A → B → A); input fields that commit every
  keystroke; separators and formulas in text exports; positions stored in
  layout pixels.
- A third reviewer with focus `free` (no checklist, no fixed order) runs
  in `diff` mode, and one per part in `--full` mode. In the replay, a
  free-form review and the structured one missed different defects; together
  they caught all ten known defects of the four paired cases.
- `/ship` settles the reviewers' questions itself (reading, a small test)
  before the user sees them; a confirmed question becomes a finding.
- Checklist: a `?` between starting a resource and handing it to its guard;
  fallback paths that drop what the main path delivers (both missed in the
  replay).
- Latent defects (unreachable today, one ordinary change away) are klein
  findings with quotes as evidence, not questions: in the replay, two such
  defects ended up as questions and counted as misses.
- Checklist: compute the extreme combination of constants that must agree
  (both misses of the replay were of this kind).
- The reviewer tests code that cannot build here in a scratch crate that
  includes the modules unchanged with `#[path]` and stands in for the
  platform (what the replay reviewers did on their own).

### Rules
- Core: work already done survives a failing step; a later message never
  replaces an error the user has not seen; `Ok(()) | Err(_)` for unit
  results; a type with an invariant keeps its fields private (not every
  struct); docs that only repeat the name are not written; integration
  tests reach the binary through `CARGO_BIN_EXE_*` instead of a `lib.rs`;
  equivalent mutants are excluded in `.cargo/mutants.toml` with a reason.
  The core is shorter: wire formats, abort and start-up details live in
  their modules.
- processes.md: stand-in tests force a real grandchild (`sleep 5; true`),
  because dash and bash differ in replacing themselves with the last
  command. concurrency.md: one `write_all` per log line.
- testing.md: kani for small pure functions, `insta --unreferenced=reject`,
  integration tests in `mod tests`, `cfg_attr` for target-specific
  `#[expect]`.
- dioxus-wasm.md: the Dioxus bans are a block `/zuschnitt` enables;
  `target_packages` for fullstack workspaces.
- `/zuschnitt` fixes references to dropped modules, adds the project's
  paths to the module table, and plans the adoption of an existing
  codebase pattern by pattern.

### Settings
- `clippy.toml` bans also `std::env::args` (panics on non-UTF-8; use
  `args_os`), `thread::sleep`, the clocks of tokio, chrono,
  jiff and time, `rand::random`, `fs::rename`, `fs::remove_file`,
  `OpenOptions::create` and the tokio file functions.
- `deny.toml` allows MPL-2.0 and CDLA-Permissive-2.0 (common through
  `dirs` and `rustls`); `_typos.toml` lists German words typos misreads;
  `.cargo/mutants.toml` excludes `main`; `.gitignore` ignores
  `mutants.out*`; CI has read-only permissions; no claim about a `debug`
  profile.
- `SETUP.md`: prints the clone path, lists collisions and copies without
  overwriting, `git init` for an empty folder, restart before `/zuschnitt`.
- `/rostfrei-update` diffs between version tags; `/lernen` tags releases.
- `selftest.sh` also runs mutants on a real diff, checks `--base`
  handling, the dependency comments and that dead code passes in Aufbau.
- Dioxus: `same_name_method` fires on every `#[component]`.

## 1.0.0 (2026-10-19)

First version as rostfrei, replacing the template whose guidelines lived as
comments in `Cargo.toml`. Sources: the git histories of Diktator (34 fixed
defects in 17 commits) and Homepage (38 commits bringing code in line with
rules that already existed), an independent expert review, a lint audit
against clippy 1.98/master, and research on current tools (October 2026).

### Structure
- Rules moved out of `Cargo.toml`: a core in `CLAUDE.md` (loaded in every
  session) and modules in `docs/guidelines/` (testing, concurrency,
  processes, macOS, devices, UI, Dioxus/WASM, servers and data, updates),
  read when the work touches their topic.
- `Phase: Aufbau | Pflege` in `CLAUDE.md`; a plan with one grouped approval
  before each change in Pflege.
- `.rostfrei` records the version a project follows.

### Gate
- `scripts/check.sh fast|full`, the same for the pre-commit hook, `/ship`
  and CI. Warnings are errors (`CARGO_BUILD_WARNINGS=deny`), except in the
  fast gate during Aufbau. Before, dead code, ignored `Result`s and stale
  `#[expect]`s passed `cargo clippy` with exit code 0.
- Greps for inner `#![allow]`/`#![expect]`, `Result<_, String>` and
  dependencies without a comment; reports of gate changes and of added
  lines with silent defaults for the reviewer.
- `full` adds tests, docs, cargo-deny, cargo-shear and cargo-mutants on the
  diff.
- CI workflow running the same gate.

### Review and learning
- `/ship` with the `rust-reviewer` agent: fresh context, fixed order of
  steps, findings only with evidence (failing test, surviving mutant, or
  two contradicting passages), one approval per group, re-check of fixes,
  lessons written to `ROSTFREI-VORSCHLAEGE.md`.
- `checklist.md`: review questions, each from a real bug of Diktator or
  Homepage.
- `/zuschnitt` tailors the setup when the skeleton stands; `/rostfrei-update`
  brings a project to the latest version; `/lernen` (in this repository)
  turns proposals into template changes; `scripts/selftest.sh` checks that
  the template passes its own gate and that each enforced rule fails it.

### Rules
- No silent defaults: an impossible case is made impossible by structure,
  else `debug_assert!` with a named fallback, else an `#[expect]`ed
  `unreachable!` for a provably dead arm (expert review; 56/55
  `unwrap_or_default` and 49/169 `saturating_*` in the two projects).
- `arithmetic_side_effects` off globally, on in boundary modules;
  `overflow-checks` stays on in release.
- State machines as a pure `step`, state-major nested matches (the wildcard
  lint does not see `_` inside tuple matches), exactly one terminal event per
  operation, idempotent cancel, injected clock and randomness.
- Fakes must be able to fail; property tests with invariants and a reference
  model; a regression test per bug, verified by reverting the fix; surviving
  mutants killed or explained.
- A failed read is never written back; user files are never overwritten.
- FFI: binding crates (`objc2-*`) first, else one `sys` module with SAFETY
  lints; helper programs only for SwiftUI or crash isolation, with a version
  handshake and shared fixtures; launchd instead of a hand-written watchdog.
- One owner per resource, usually a field; a thread only when it blocks.
- Apps without `lib.rs` unless needed; doc comments state contracts.
- Accepted from Diktator's proposals: knowledge in `docs/`, golden fixtures
  on both sides, units and time types, classify-then-run handlers,
  in-flight operations resolved explicitly, retries with pause and limit,
  echo detection, `Instant` versus wall clock, panic hook, device
  experiments, explicit pending state for optimistic UI, `assert_eq!`
  without message, regression test per bug, split by concern.
- Accepted from Homepage: fire-and-forget bans for Dioxus, no `mul_add` on
  WASM, `let_underscore_untyped`, `arithmetic-side-effects-allowed` per
  project. Rejected: `allow-dbg-in-tests`.

### Lints
- `nursery` no longer on as a group; picked: `redundant_clone`,
  `significant_drop_in_scrutinee`, `fallible_impl_from`,
  `debug_assert_with_mut_call`, `collection_is_never_read`,
  `path_buf_push_overwrite`, `read_zero_byte_vec`,
  `non_send_fields_in_send_ty`, `unused_peekable`, `branches_sharing_code`,
  `needless_collect`.
- Removed: `cognitive_complexity` (disowned by clippy), `get_unwrap`,
  `unwrap_in_result`, `as_underscore` (covered), `rest_pat_in_fully_bound_structs`
  and `unneeded_field_pattern` (superseded in 1.99). Allowed:
  `option_if_let_else`, `manual_assert` (both push against the rules).
- Added restriction lints: `let_underscore_untyped`, `return_and_then`,
  `unnecessary_rest_pattern`, `rest_pattern_accessible_field`,
  `non_zero_suggestions`, `same_name_method`, `empty_drop`,
  `precedence_bits`, `suspicious_xor_used_as_pow`, `host_endian_bytes`,
  `filetype_is_file`, `cfg_not_test`, `tests_outside_test_module`,
  `redundant_test_prefix`, `undocumented_unsafe_blocks`,
  `multiple_unsafe_ops_per_block`, `unnecessary_safety_comment`.
- Added rustc lints: `unused_must_use`, `unfulfilled_lint_expectations`,
  `ambiguous_negative_literals`, `unnameable_types`,
  `missing_debug_implementations`, `non_ascii_idents`,
  `deprecated_in_future`, `macro_use_extern_crate`.
- `clippy.toml`: nesting threshold 4 (the lint was off), 60 lines per
  function, no bool parameters, at most one bool field, five arguments,
  `avoid-breaking-exported-api = false`; bans for unnamed threads, the
  clock, randomness, overwriting files, leaking, `Command::new` outside the
  process module, detached tokio tasks, `serde_json::Value`, `thread_local!`;
  a Dioxus/WASM block.

### Profiles and tools
- Toolchain 1.99.1 with `llvm-tools`.
- dev: `debug = "line-tables-only"`, dependencies at `opt-level = 1`;
  release: `strip = "debuginfo"`; new `profiling` and `mutants` profiles;
  templates for `wasm-release` and `server-release`.
- `deny.toml` (instead of cargo-audit), `_typos.toml`,
  `.cargo/mutants.toml`, `.gitignore`.
- Not adopted as default: `no_panic` (needs `panic = "unwind"`, a link step
  and optimisation; the lints already ban the usual panic sources).
