# Toolchain, lints and dependencies

Read this before changing `rust-toolchain.toml`, `rust-version`, the lints,
`clippy.toml`, `scripts/check.sh` or dependency versions.

Nothing changes under the project by itself: no new lints, no new compiler
behaviour, no new dependency versions. Updates are a deliberate step, every
few months or when a fix or feature is needed, in commits of their own.

## Steps

1. Raise `channel` in `rust-toolchain.toml` and `rust-version` in
   `Cargo.toml` together to the current stable release.
2. Read the release notes of rustc, Cargo and Clippy since the old version.
   New lints in the enabled groups now fire; renamed or removed lints in
   `Cargo.toml` produce warnings, which the gate turns into errors. Decide
   for every new restriction lint whether rostfrei should enable it, and
   write a proposal (`ROSTFREI-VORSCHLAEGE.md`) if so.
3. `cargo update` for compatible versions; raise major versions in
   `[dependencies]` one at a time, reading their changelogs.
4. Probe `clippy.toml`: a `disallowed-methods` path into a crate that is not
   a dependency is ignored silently, and a wrong path inside a dependency
   only prints a warning that the gate does not catch. After every update,
   read the clippy output for "does not refer to" warnings, and for a new
   or changed entry add one deliberate violation, see it fail, remove it.
5. Fix what the compiler and clippy report, run `scripts/check.sh full` and
   `cargo deny check`.

## Changing the gate

- A lint is relaxed only for a stated reason, in a commit of its own, with
  the reason as a comment next to it. The reviewer of `/ship` treats any
  added `allow`/`warn` line in `Cargo.toml` or `clippy.toml` as a finding
  unless the plan approved it.
- A rule that turns out wrong for every project goes back to rostfrei as a
  proposal; one that is wrong only here is recorded in "Project notes" of
  `CLAUDE.md` with its reason.
