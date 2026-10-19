# Testing

Read this before writing or changing tests, fakes or fixtures. The goal is
tests that fail when the behaviour is wrong, not tests that pass.

## What to test with what

| Code                                   | Test                                                                 |
| -------------------------------------- | -------------------------------------------------------------------- |
| Pure functions, conversions            | unit tests on edge cases: empty, one, max, boundaries ± 1, invalid    |
| Parsers, printers, codecs              | property tests: `parse(print(x)) == x`; invalid input is an error     |
| Numeric code with precision or limits  | property tests against a slower, obviously correct reference          |
| State machines                         | property tests over random event sequences, plus flow tests           |
| Code driving side effects              | flow tests through fakes that can fail                                |
| Code running other programs            | stand-in programs (`/bin/sh -c …`): timeouts, failures, big output    |
| Messages to another language or file   | fixture files shared by both sides (golden)                           |
| Tables keyed by an enum                | one test that iterates every variant (`strum::EnumIter` as dev-dep)   |
| Structured text output (CLI, SSR, JSON) | snapshot tests with `insta`, `--unreferenced=reject`                 |

## Property tests (proptest)

- State machines expose `fn check(&self) -> Result<(), Violation>`. A
  property test generates random sequences of events (including cancel,
  timeouts, failures and late results), applies `step` and asserts `check`
  after every step.
- Compare against a reference model: a deliberately simple version of the
  behaviour (a list of pending request ids, the expected visible state, a
  big-number or brute-force computation). Disagreement is a bug in one of
  them; find out which.
- Good properties: round trip; idempotence (`step(step(s, Cancel), Cancel)`
  equals `step(s, Cancel)`); monotonicity; conservation (every started
  operation ends exactly once); refinement (more precision never changes the
  digits already claimed reliable); equivalence of two implementations.
- Commit the `proptest-regressions/` files: they replay past failures.

## Fakes and flow tests

- Every side effect (devices, clipboard, file system of the user, network,
  other programs, clock) sits behind a small trait. The fake records what was
  asked and **can fail on command**: return an error, never answer, answer
  twice, answer late, disappear. A fake that can only succeed leaves every
  error branch untested.
- Flow tests for each state machine: the normal flow; cancel at every step;
  each dependency failing or vanishing in every state; a result arriving
  after its request was cancelled or superseded; shutdown in every state.
  Each asserts the user-visible outcome (what was pasted, saved, shown,
  logged), not just the final state.
- The clock is injected; tests advance it. No `sleep` in tests.

## Regression tests

- Every fixed bug gets a test that replays the sequence of events that
  caused it. The test must fail without the fix: revert the non-test part
  of the fix, run it, see it fail, restore. The reviewer checks this.

## Mutation testing

- `scripts/check.sh full` runs `cargo mutants --in-diff` on the changes.
  A mutant that survives on a changed line means no test pins that
  behaviour: add the test. Only a truly equivalent mutant (it changes
  nothing observable, e.g. only the split point of a divide-and-conquer)
  gets an `exclude_re` entry in `.cargo/mutants.toml` with its reason. Now
  and then run a full `cargo mutants` and work through
  `mutants.out/missed.txt`.

## Proofs and snapshots

- Small pure functions with a hard contract (the `numeric` conversions, an
  index computation, a checked parser step) can be proven for all inputs
  with `kani` (`cargo install --locked kani-verifier && cargo kani setup`,
  harnesses under `#[cfg(kani)]`). Use it where a property test leaves
  doubt, not as a default.
- With `insta`, CI also runs `cargo insta test --unreferenced=reject`, so a
  snapshot no test uses any more fails; `/zuschnitt` adds it to
  `scripts/check.sh`.

## Hygiene

- Tests never touch the user's real files, settings or devices: pass paths
  in, use a temporary directory, inject log and notification sinks.
- `assert_eq!`/`assert_ne!` show both values and need no message; a bare
  `assert!(condition)` carries one. Tests return `()` and may `unwrap`
  (`clippy.toml`); `panic_in_result_fn` forbids asserts in `Result` tests.
- Tests live in a `#[cfg(test)] mod tests` beside the code, or in a sibling
  `tests.rs` once they outgrow it, split by the same topics as the code.
  Integration tests under `tests/` also wrap their tests in
  `#[cfg(test)] mod tests { … }` (`tests_outside_test_module`).
- A lint that fires only for one target (WASM or host) is expected only
  there: `#[cfg_attr(target_arch = "wasm32", expect(…, reason = "…"))]`;
  otherwise `unfulfilled_lint_expectations` fails the other run.
- Logic that only runs in the browser or behind a UI framework is moved into
  plain functions or crates so it can be tested on the host.
