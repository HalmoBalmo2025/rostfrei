# Dioxus and WASM

Read this before changing Dioxus components, browser APIs, or anything built
for `wasm32-unknown-unknown`. Written against Dioxus 0.7; check paths and
names after a Dioxus update (`update.md`).

## Structure

- Logic lives in plain Rust modules or crates without Dioxus or `web-sys`,
  so its tests run on the host. Components hold state and wire events to it.
- Clippy runs twice: for `wasm32-unknown-unknown` (what ships) and for the
  host (where the tests run). `scripts/check.sh` does both whenever
  `rust-toolchain.toml` lists the target. In a workspace with server crates,
  `target_packages` in `scripts/check.sh` names the web packages only
  (`-p web`), so tokio or sqlx are not built for WASM.

## Ownership in the browser

- Tasks, timers, listeners, animation-frame loops and JS closures belong to a
  component and end with it. The Dioxus block of `clippy.toml` (enabled by
  `/zuschnitt`) forbids the fire-and-forget entry points: `wasm_bindgen_futures::spawn_local`, `dioxus_core::spawn_forever`,
  `wasm_bindgen::closure::ScopedClosure::forget`,
  `gloo_timers::callback::{Timeout, Interval}::forget`,
  `dioxus_document::eval`. A task that outlives its route writes to freed
  signals; with `panic = "abort"` the whole page stops.
- An animation-frame loop or listener is a struct whose `Drop` stops it,
  owned by the component (`use_drop` calls into that owner). An `Rc` cycle
  broken only by an explicit `stop()` leaks when someone forgets it.
- Do not keep a signal's read guard alive across a write to the same signal:
  `match *signal.peek() { … }` holds the guard for the whole match; copy the
  value out first. `peek()` reads without subscribing, `read()` subscribes.

## Lints and macros

- `#[component]` generates methods that trip `same_name_method` on every
  component (96 times in one workspace): a Dioxus project relaxes it in
  `Cargo.toml` with that reason.
- `rsx!` code triggers `unused_qualifications` in components with event
  handlers: one `#[expect]` per component, never module-wide.
- Lints do not see inside `rsx!` string interpolations: arithmetic and
  indexing there go into a named function first.
- Props with signals: derive `PartialEq` (signals implement it). A
  hand-written `PartialEq` that always returns `false` breaks the contract.

## Numbers and performance

- WASM has no fused multiply-add: `mul_add` becomes a slow software call
  (10× slower in a force loop). `suboptimal_flops` is allowed and `mul_add`
  is forbidden in `clippy.toml` for WASM projects.
- WebGL and many JS APIs return `-1` or `null` as "not found": convert to
  `Option` at the call.
- Randomness comes from a seeded or `getrandom` RNG, never from hash order.

## Builds

- `dx` uses the profiles `wasm-dev` and `wasm-release` (and
  `server-*`, `desktop-*`, `android-*`); a profile defined in `Cargo.toml`
  wins. `dx` passes `strip = false` itself; `llvm-tools` must be in the
  toolchain components for release stripping. `wasm-opt` runs only in
  release; configure it under `[web.wasm_opt]` in `Dioxus.toml`.
- Size: `wasm-opt --func-metrics` or `wasm-tools` show what is big
  (`twiggy` is archived).
- A panic hook shows an error message on the page and logs it, so a dead page
  is never silent.

## CSS

- One CSS file per crate with prefixed class names, or Tailwind. Class names
  are written out in full (no `format!`), so tools can find them.
- A host test per crate checks both directions: every class selector in the
  CSS is used in a string literal of the crate, and every class used in
  markup has a rule (safelist for the exceptions).
