# Setting up rostfrei in a project

Instructions for Claude Code, followed when the user asks to set up
rostfrei in the current project. Talk to the user in their language.

## 1. Get rostfrei

    tmp="$(mktemp -d)" && git clone --depth 1 https://github.com/HalmoBalmo2025/rostfrei "$tmp/rostfrei"

The repository is private; `gh auth login` or git credentials on this
machine are needed. Read `$tmp/rostfrei/README.md` and `CHANGELOG.md`.

## 2. Copy the template

Copy everything under `template/`, dotfiles included, into the project root
(`cp -R "$tmp/rostfrei/template/." .`), but never overwrite an existing file
blindly:

- **New project** (empty folder or a fresh `cargo new`): take the template
  files as they are; keep the generated `src/`.
- **Existing project**: merge.
  - `Cargo.toml`: keep the project's `[package]`, `[workspace]`,
    dependencies, features and profiles; replace every lint section with the
    template's; take the template profiles only where the project has none.
    Remove guideline prose from comments: the rules now live in `CLAUDE.md`
    and `docs/guidelines/`.
  - `clippy.toml`: the template's file plus the project's own entries
    (disallowed paths, allowed types), each with its comment.
  - `CLAUDE.md`: the template's file; the project's existing notes go under
    "Project notes", rules that contradict the core rules are listed there
    as deliberate deviations with their reason, or dropped.
  - `rust-toolchain.toml`: the template's channel; keep the project's extra
    targets and components.
  - Existing CI: keep it and add the gate step (`scripts/check.sh full`), or
    replace it with the template workflow if it checks less.

Fill in `PROJECT_NAME` and `PROJECT_DESCRIPTION`. `rust-version` stays the
template's (the same as `rust-toolchain.toml`).

## 3. Make it work

    chmod +x scripts/check.sh scripts/hooks/pre-commit
    git config core.hooksPath scripts/hooks
    cargo install --locked cargo-mutants cargo-deny cargo-shear typos-cli   # missing ones only
    cargo generate-lockfile                                                 # if there is no Cargo.lock

A new project needs `src/main.rs` (or `src/lib.rs`) with a crate doc
comment (`//! What this program does.`), which `missing_docs` asks for.

Run `scripts/check.sh fast`. If the toolchain reports a lint as unknown,
remove it from `Cargo.toml` and write a proposal into
`ROSTFREI-VORSCHLAEGE.md` (format in `.claude/skills/ship/SKILL.md`).

## 4. Phase

- **New project**: `Phase: Aufbau` stays. Commit ("Adopt rostfrei
  <version>") and tell the user: build the skeleton, then `/zuschnitt`.
- **Existing project**: commit, then run `/zuschnitt` right away; it
  includes the first full review (`/ship --full`).
