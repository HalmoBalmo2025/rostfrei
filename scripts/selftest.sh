#!/usr/bin/env bash
# Checks that the template still works: a probe crate made from it passes
# the gate, and each rule the gate claims to enforce really fails the gate
# when broken. Run it after every change to template/ (/lernen does).
#
#   scripts/selftest.sh            uses the toolchain pinned in the template
#   RUSTUP_TOOLCHAIN=stable scripts/selftest.sh   another installed toolchain
#
# Written for the bash 3.2 that ships with macOS.

set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
probe="$work/probe"
trap 'rm -rf "$work"' EXIT
failed=0
ok() { printf 'ok    %s\n' "$*"; }
bad() { printf 'FAIL  %s\n' "$*"; failed=1; }

# The module table in CLAUDE.md names only files that exist.
for module in $(sed -n 's/.*`\(docs\/guidelines\/[a-z-]*\.md\)`.*/\1/p' "$here/template/CLAUDE.md"); do
    if [ -f "$here/template/$module" ]; then ok "module $module exists"; else bad "module $module listed in CLAUDE.md but missing"; fi
done
for file in "$here"/template/docs/guidelines/*.md; do
    name="docs/guidelines/$(basename "$file")"
    if grep -q "\`$name\`" "$here/template/CLAUDE.md"; then ok "module $name is in the table"; else bad "module $name is not in the table of CLAUDE.md"; fi
done
# Versions agree.
version="$(cat "$here/VERSION")"
if grep -q "^version = \"$version\"" "$here/template/.rostfrei"; then ok "version $version"; else bad "VERSION and template/.rostfrei disagree"; fi
channel="$(sed -n 's/^channel = "\(.*\)"/\1/p' "$here/template/rust-toolchain.toml")"
if grep -q "^rust-version = \"$channel\"" "$here/template/Cargo.toml"; then ok "toolchain $channel"; else bad "rust-version and rust-toolchain.toml disagree"; fi

# A probe crate from the template.
mkdir -p "$probe"
cp -R "$here/template/." "$probe/"
cd "$probe" || exit 1
git init -q -b main
sed -i.bak 's/PROJECT_NAME/probe/; s/PROJECT_DESCRIPTION/A probe of the rostfrei template/' Cargo.toml && rm Cargo.toml.bak
sed -i.bak 's/^Phase: Aufbau/Phase: Pflege/' CLAUDE.md && rm CLAUDE.md.bak
mkdir -p src
cat > src/main.rs <<'EOF'
//! Probe: counts commands until reset.

mod counter;

fn main() {
    let mut counter = counter::Counter::default();
    for command in [counter::Command::Increment, counter::Command::Reset] {
        counter.apply(command);
    }
    println!("{}", counter.value());
}
EOF
cat > src/counter.rs <<'EOF'
//! A counter driven by commands.

/// What the user asked for.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Command {
    /// Count one more.
    Increment,
    /// Back to zero.
    Reset,
}

/// Counts increments until reset.
#[derive(Debug, Default)]
pub(crate) struct Counter {
    value: u32,
}

impl Counter {
    /// The current count.
    pub(crate) const fn value(&self) -> u32 {
        self.value
    }

    /// Applies a command. The count stops at `u32::MAX`: a counter that
    /// stays at its maximum is the intended meaning.
    pub(crate) const fn apply(&mut self, command: Command) {
        match command {
            Command::Increment => self.value = self.value.saturating_add(1),
            Command::Reset => self.value = 0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn increment_then_reset() {
        let mut counter = Counter::default();
        counter.apply(Command::Increment);
        assert_eq!(counter.value(), 1);
        counter.apply(Command::Reset);
        assert_eq!(counter.value(), 0);
    }
}
EOF
cargo generate-lockfile -q
cargo fmt --all
git add -A
git -c user.name=selftest -c user.email=selftest@localhost commit -qm probe

if scripts/check.sh fast > "$work/fast.log" 2>&1; then ok "clean probe passes fast"; else bad "clean probe fails fast (log below)"; cat "$work/fast.log"; fi
if scripts/check.sh full --base HEAD > "$work/full.log" 2>&1; then ok "clean probe passes full"; else bad "clean probe fails full (log below)"; cat "$work/full.log"; fi

# Each broken rule must fail the fast gate, for the right reason. The cases
# run in Phase Aufbau, where rustc warnings (the unused probe functions) do
# not fail, so only the rule under test can.
sed -i.bak 's/^Phase: Pflege/Phase: Aufbau/' CLAUDE.md && rm CLAUDE.md.bak
git -c user.name=selftest -c user.email=selftest@localhost commit -qam aufbau
case_rs() {
    # case_rs NAME PATTERN BODY [PHASE]: a module with one violation must
    # fail the gate with PATTERN in its output.
    name="$1"; pattern="$2"; body="$3"; phase="${4:-Aufbau}"
    printf '\nmod extra;\n' >> src/main.rs
    sed -i.bak "s/^Phase: .*/Phase: $phase/" CLAUDE.md && rm CLAUDE.md.bak
    printf '//! Probe module.\n\n%s\n' "$body" > src/extra.rs
    cargo fmt --all > /dev/null 2>&1
    if scripts/check.sh fast > "$work/case.log" 2>&1; then
        bad "gate misses: $name"
    elif grep -q -- "$pattern" "$work/case.log"; then
        ok "gate catches: $name"
    else
        bad "gate fails, but not for: $name (expected: $pattern)"; tail -n 30 "$work/case.log"
    fi
    git checkout -q -- .
    rm -f src/extra.rs
}
case_rs "dead code in Pflege" "never used" 'fn unused() -> u8 { 3 }' Pflege
case_rs "thread::spawn" 'disallowed method `std::thread::spawn`' 'pub(crate) fn run() { let _: std::thread::JoinHandle<()> = std::thread::spawn(|| {}); }'
case_rs "fs::write" 'disallowed method `std::fs::write`' 'pub(crate) fn save() -> std::io::Result<()> { std::fs::write("x", "y") }'
case_rs "Instant::now" 'disallowed method `std::time::Instant::now`' 'pub(crate) fn now() -> std::time::Instant { std::time::Instant::now() }'
case_rs "Result<_, String>" 'Result<_, String> found' 'pub(crate) fn parse(raw: &str) -> Result<u8, String> { raw.parse().map_err(|_| String::new()) }'
case_rs "inner allow" 'inner #!\[allow\]' '#![allow(clippy::unwrap_used, reason = "probe")]'
case_rs "unwrap" 'unwrap()' 'pub(crate) fn first(items: &[u8]) -> u8 { *items.first().unwrap() }'
case_rs "as cast" 'silent `as` conversion' 'pub(crate) const fn narrow(value: u64) -> u32 { value as u32 }'
case_rs "bool parameter" 'bools in function parameters' 'pub(crate) fn flag(verbose: bool) -> u8 { u8::from(verbose) }'
case_rs "ignored Result" 'Result` that must be used' 'pub(crate) fn touch() { std::fs::read("x"); }'


printf '\n'
if [ "$failed" -eq 0 ]; then echo "selftest passed"; else echo "selftest FAILED"; fi
exit "$failed"
