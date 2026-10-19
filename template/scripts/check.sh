#!/usr/bin/env bash
# The gate of this project (rostfrei). One script for the git pre-commit
# hook, for /ship and for CI, so all three check the same things.
#
#   scripts/check.sh fast              fmt, clippy, greps, typos
#   scripts/check.sh full [--base REF] fast + tests, docs, deny, shear,
#                                      mutants on the diff against REF
#
# Warnings are errors (CARGO_BUILD_WARNINGS=deny), except in `fast` mode
# while CLAUDE.md says `Phase: Aufbau`: then rustc warnings (unused code
# while drafting) are shown but do not fail; clippy's deny lints always do.
# Without --base, `full` diffs against the upstream branch, else origin/HEAD,
# else it skips the mutants step and says so.
#
# Written for the bash 3.2 that ships with macOS.

set -u

mode="${1:-}"
shift || true
base=""
while [ $# -gt 0 ]; do
    case "$1" in
        --base) base="${2:-}"; shift 2 || true ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done
case "$mode" in
    fast|full) ;;
    *) echo "usage: scripts/check.sh fast|full [--base REF]" >&2; exit 2 ;;
esac

root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not inside a git repository" >&2; exit 2; }
cd "$root" || exit 2
out="target/rostfrei"
mkdir -p "$out"
summary="$out/check-$mode.txt"
: > "$summary"

phase="$(sed -n 's/^Phase:[[:space:]]*\([A-Za-z]*\).*/\1/p' CLAUDE.md 2>/dev/null | head -n 1)"
if [ "$mode" = "fast" ] && [ "$phase" = "Aufbau" ]; then
    warnings="warn"
else
    warnings="deny"
fi
export CARGO_TERM_COLOR="${CARGO_TERM_COLOR:-always}"

failed=0
note() { printf '%s\n' "$*" | tee -a "$summary"; }
step() {
    # step NAME COMMAND...: runs the command, records PASS or FAIL.
    name="$1"; shift
    printf '\n── %s ──\n' "$name"
    if "$@"; then note "PASS  $name"; else note "FAIL  $name"; failed=1; fi
}
skip() { note "SKIP  $1 ($2)"; }
have() { command -v "$1" >/dev/null 2>&1; }
have_cargo() { cargo "$1" --version >/dev/null 2>&1; }

# Extra targets from rust-toolchain.toml, e.g. wasm32-unknown-unknown.
targets="$(sed -n 's/^[[:space:]]*targets[[:space:]]*=[[:space:]]*\[\(.*\)\].*/\1/p' rust-toolchain.toml 2>/dev/null | tr -d '"' | tr ',' ' ')"

clippy_host() { CARGO_BUILD_WARNINGS="$warnings" cargo clippy --workspace --all-targets --locked; }
clippy_target() { CARGO_BUILD_WARNINGS="$warnings" cargo clippy --workspace --all-targets --locked --target "$1"; }

# Inner `#![allow(...)]` / `#![expect(...)]` over a whole module escape the
# allow lints (rule 0). `#![deny(...)]` is fine.
no_inner_allow() {
    if git grep --untracked -nE '^[[:space:]]*#!\[[[:space:]]*(cfg_attr[[:space:]]*\(.*)?(allow|expect)[[:space:]]*\(' -- '*.rs'; then
        echo "inner #![allow]/#![expect] found: put an #[expect(…, reason)] on the smallest item instead"
        return 1
    fi
}
# String errors (rule 3).
no_string_errors() {
    if git grep --untracked -nE 'Result<([^<>(),;{]|<[^<>]*>|\([^()]*\))*,[[:space:]]*String[[:space:]]*>' -- '*.rs'; then
        echo "Result<_, String> found: errors are enums"
        return 1
    fi
}
# Every dependency line has a comment above it (rule 6).
dependency_comments() {
    awk '
        FNR == 1 { section = ""; previous = "" }
        /^\[/ { section = $0; previous = $0; next }
        section ~ /dependencies\]$/ && /^[A-Za-z0-9_-]+[[:space:]]*=/ {
            if (previous !~ /^[[:space:]]*#/ && previous !~ /^[A-Za-z0-9_-]+[[:space:]]*=/) {
                printf "%s:%d: dependency without a comment: %s\n", FILENAME, FNR, $0; bad = 1
            }
        }
        { if ($0 !~ /^[[:space:]]*$/) previous = $0 }
        END { exit bad }
    ' $(git ls-files --cached --others --exclude-standard 'Cargo.toml' '*/Cargo.toml')
}

step "fmt" cargo fmt --all --check
step "clippy (host)" clippy_host
for target in $targets; do
    step "clippy ($target)" clippy_target "$target"
done
step "no inner allow" no_inner_allow
step "no String errors" no_string_errors
step "dependency comments" dependency_comments
if have typos; then step "typos" typos; else skip "typos" "not installed: cargo install --locked typos-cli"; fi

if [ "$mode" = "full" ]; then
    step "tests" env CARGO_BUILD_WARNINGS=deny cargo test --workspace --locked
    step "docs" env CARGO_BUILD_WARNINGS=deny RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps --document-private-items --locked
    if have_cargo deny; then step "deny" cargo deny check; else note "FAIL  deny (not installed: cargo install --locked cargo-deny)"; failed=1; fi
    if have_cargo shear; then step "shear" cargo shear; else note "FAIL  shear (not installed: cargo install --locked cargo-shear)"; failed=1; fi

    # The diff under review.
    if [ -z "$base" ]; then
        base="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)" || base=""
    fi
    if [ -z "$base" ] && git rev-parse --verify --quiet origin/HEAD >/dev/null; then
        base="origin/HEAD"
    fi
    if [ -n "$base" ]; then
        merge_base="$(git merge-base "$base" HEAD)"
        git diff "$merge_base" > "$out/diff.patch"
        note "BASE  $base ($merge_base)"

        # Gate files changed in this diff: the reviewer treats every relaxed
        # setting as a finding unless the plan approved it.
        git diff "$merge_base" -- Cargo.toml '*/Cargo.toml' clippy.toml rust-toolchain.toml deny.toml .cargo/ scripts/ > "$out/gate.patch"
        if [ -s "$out/gate.patch" ]; then note "NOTE  gate files changed: $out/gate.patch"; fi

        # Added lines the reviewer must look at (rule 3, hygiene).
        git diff "$merge_base" -- '*.rs' | grep -nE '^\+.*(unwrap_or_default\(|unwrap_or\(0|saturating_|\.ok\(\)|if let Ok\(|Ok\(_\) \| Err\(_\)|TODO|FIXME|XXX|println!|eprintln!)' > "$out/attention.txt"
        if [ -s "$out/attention.txt" ]; then note "NOTE  added lines to justify: $out/attention.txt"; fi

        if ! have_cargo mutants; then
            note "FAIL  mutants (not installed: cargo install --locked cargo-mutants)"; failed=1
        elif ! grep -qE '^\+\+\+ b/.*\.rs' "$out/diff.patch"; then
            skip "mutants" "no Rust changes in the diff"
        else
            printf '\n── mutants (diff) ──\n'
            cargo mutants --in-diff "$out/diff.patch" --output "$out" --no-shuffle
            status=$?
            # 0 all caught, 3 only timeouts (count as caught); 2 missed.
            case "$status" in
                0|3) note "PASS  mutants (diff)" ;;
                2) note "FAIL  mutants (diff): survivors in $out/mutants.out/missed.txt"; failed=1 ;;
                *) note "FAIL  mutants (diff): cargo-mutants exited $status"; failed=1 ;;
            esac
        fi
    else
        skip "mutants" "no base: pass --base REF"
    fi
fi

printf '\n══ summary (%s, phase %s) ══\n' "$mode" "${phase:-unknown}"
cat "$summary"
exit "$failed"
