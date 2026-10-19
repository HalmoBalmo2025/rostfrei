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
# Reports for the reviewer go to target/rostfrei/ and are rewritten on every
# run. Written for the bash 3.2 that ships with macOS.

set -u

mode="${1:-}"
[ $# -gt 0 ] && shift
base=""
while [ $# -gt 0 ]; do
    case "$1" in
        --base)
            [ $# -ge 2 ] || { echo "--base needs a REF" >&2; exit 2; }
            base="$2"; shift 2 ;;
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
if [ "$mode" = "full" ]; then
    rm -rf "$out/mutants.out" "$out/mutants.out.old"
    rm -f "$out/diff.patch" "$out/gate.patch" "$out/attention.txt"
fi

phase="$(sed -n 's/^Phase:[[:space:]]*\([A-Za-z]*\).*/\1/p' CLAUDE.md 2>/dev/null | head -n 1)"
if [ "$mode" = "fast" ] && [ "$phase" = "Aufbau" ]; then
    warnings="warn"
else
    warnings="deny"
fi

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
# A required tool that is missing fails `full`; `fast` (the commit hook)
# only says so.
missing() {
    if [ "$mode" = "full" ]; then note "FAIL  $1 (not installed: $2)"; failed=1; else skip "$1" "not installed: $2"; fi
}

# Extra targets from rust-toolchain.toml, e.g. wasm32-unknown-unknown, and
# the packages to check for them (all by default; a workspace with server
# crates names the web packages here, e.g. `-p web`).
targets="$(sed -n 's/^[[:space:]]*targets[[:space:]]*=[[:space:]]*\[\(.*\)\].*/\1/p' rust-toolchain.toml 2>/dev/null | tr -d '"' | tr ',' ' ')"
target_packages="--workspace"

# clippy, failing also when clippy.toml names a path that does not exist
# (clippy only warns about it, and that warning is not a lint).
run_clippy() {
    log="$out/clippy-$1.log"; shift
    CARGO_BUILD_WARNINGS="$warnings" cargo clippy "$@" --locked 2>&1 | tee "$log"
    status=${PIPESTATUS[0]}
    if grep -q 'does not refer to' "$log"; then
        echo "clippy.toml names a path that does not exist (see above)"
        return 1
    fi
    return "$status"
}
clippy_host() { run_clippy host --workspace --all-targets; }
clippy_target() { run_clippy "$1" $target_packages --target "$1"; }

# Inner `#![allow(...)]` / `#![expect(...)]` over a whole module escape the
# allow lints (rule 0). `#![deny(...)]` is fine.
no_inner_allow() {
    if git grep --untracked -nE '^[[:space:]]*#!\[[[:space:]]*(cfg_attr[[:space:]]*\(.*)?(allow|expect)[[:space:]]*\(' -- '*.rs'; then
        echo "inner #![allow]/#![expect] found: put an #[expect(…, reason)] on the smallest item instead"
        return 1
    fi
}
# String errors (rule 3), including `type Err = String` and `&str` errors.
no_string_errors() {
    if git grep --untracked -nE 'Result<([^<>(),;{]|<[^<>]*>|\([^()]*\))*,[[:space:]]*(String|&[^;>]*str)[[:space:]]*>|type[[:space:]]+(Err|Error)[[:space:]]*=[[:space:]]*(String|&[^;]*str)[[:space:]]*;' -- '*.rs'; then
        echo "String error found: errors are enums"
        return 1
    fi
}
# Every dependency has a comment directly above it or at the end of its
# line (rule 6). A comment may cover a group of consecutive lines only by
# repeating; `[dependencies.name]` tables need one above the header.
dependency_comments() {
    awk '
        FNR == 1 { section = ""; previous = "" }
        /^\[/ {
            section = $0
            if ($0 ~ /dependencies\.[A-Za-z0-9_-]+\]$/ && previous !~ /^[[:space:]]*#/) {
                printf "%s:%d: dependency without a comment: %s\n", FILENAME, FNR, $0; bad = 1
            }
            previous = $0; next
        }
        section ~ /dependencies\]$/ && /^[A-Za-z0-9_-]+[[:space:]]*=/ && $0 !~ /#/ && previous !~ /^[[:space:]]*#/ {
            printf "%s:%d: dependency without a comment: %s\n", FILENAME, FNR, $0; bad = 1
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
if have typos; then step "typos" typos; else missing "typos" "cargo install --locked typos-cli"; fi

if [ "$mode" = "full" ]; then
    step "tests" env CARGO_BUILD_WARNINGS=deny cargo test --workspace --locked
    step "docs" env CARGO_BUILD_WARNINGS=deny RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps --document-private-items --locked
    if have_cargo deny; then step "deny" cargo deny check; else missing "deny" "cargo install --locked cargo-deny"; fi
    if have_cargo shear; then step "shear" cargo shear; else missing "shear" "cargo install --locked cargo-shear"; fi

    # The diff under review.
    if [ -z "$base" ]; then
        base="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)" || base=""
    fi
    if [ -z "$base" ] && git rev-parse --verify --quiet origin/HEAD >/dev/null; then
        base="origin/HEAD"
    fi
    merge_base=""
    if [ -n "$base" ] && ! merge_base="$(git merge-base "$base" HEAD 2>/dev/null)"; then
        note "FAIL  base $base has no merge base with HEAD (shallow clone or force push?)"
        failed=1
        merge_base=""
    fi
    if [ -n "$merge_base" ]; then
        git diff "$merge_base" > "$out/diff.patch"
        note "BASE  $base ($merge_base)"

        # Gate files changed in this diff: the reviewer treats every relaxed
        # setting as a finding unless the plan approved it.
        git diff "$merge_base" -- Cargo.toml '*/Cargo.toml' clippy.toml rust-toolchain.toml deny.toml _typos.toml CLAUDE.md .rostfrei .cargo/ .claude/ .github/ scripts/ > "$out/gate.patch"
        if [ -s "$out/gate.patch" ]; then note "NOTE  gate files changed: $out/gate.patch"; fi

        # Added lines the reviewer must justify (rule 3, hygiene), as path:line.
        git diff -U0 "$merge_base" -- '*.rs' | awk '
            /^\+\+\+ b\// { file = substr($0, 7); next }
            /^\+\+\+ / { file = ""; next }
            /^@@/ { split($3, range, ","); line = substr(range[1], 2) + 0; next }
            /^\+/ {
                if (file != "" && $0 ~ /(unwrap_or|map_or|\.ok\(\)|\.err\(\)|if let Ok\(|let _ =|let _:|Err\(_\) =>|saturating_|wrapping_|TODO|FIXME|XXX|println!|eprintln!)/) {
                    printf "%s:%d: %s\n", file, line, substr($0, 2)
                }
                line++
            }
        ' > "$out/attention.txt"
        if [ -s "$out/attention.txt" ]; then note "NOTE  added lines to justify: $out/attention.txt"; fi

        if ! have_cargo mutants; then
            missing "mutants" "cargo install --locked cargo-mutants"
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
    elif [ -z "$base" ]; then
        skip "mutants" "no base: pass --base REF"
    fi
fi

printf '\n══ summary (%s, phase %s) ══\n' "$mode" "${phase:-unknown}"
cat "$summary"
exit "$failed"
