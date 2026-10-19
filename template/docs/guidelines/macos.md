# macOS

Read this before using macOS APIs, FFI, the clipboard, hotkeys, sleep and
wake, or changing how the app is launched.

## Reaching platform APIs

1. A maintained binding crate first: `objc2-*` (AppKit, Foundation,
   CoreGraphics …), `core-foundation`, `arboard`, `global-hotkey`.
2. Otherwise `unsafe` lives in one `sys` module per API with a safe,
   documented interface. Each block is minimal and carries `// SAFETY:`
   (`undocumented_unsafe_blocks`, `multiple_unsafe_ops_per_block`); the
   module carries the one `#[expect(unsafe_code, reason = "…")]`.
3. A helper program (Swift) only for SwiftUI interfaces or to isolate code
   that can crash the process; then follow `processes.md`.

## Time

- `Instant` stops while the Mac sleeps: use it for durations inside a run
  only. Anything shown to the user or meant to hold across sleep uses the
  wall clock. Times of day are tested across a daylight saving change.
- Wake from sleep is an event: timers, connections and devices are checked
  again, not assumed alive.

## The user's state

- Before restoring something you changed on the user's behalf (clipboard,
  focus, selection), check that it is still what you left; otherwise leave
  the user's newer state alone.
- Hotkeys and modifier flags: left and right keys have separate flag bits;
  test the combinations.
- Permissions (Accessibility, Microphone, Screen Recording) can be missing or
  revoked at any time: each is checked where used and reported with a way to
  fix it.

## Launch and lifetime

- The app is supervised by launchd (`processes.md`), not by a hand-written
  watchdog.
- AppKit calls run on the main thread. `cargo careful` (nightly) runs the
  tests with Apple's Main Thread Checker; use it when UI code changes.
- The app bundle is rebuilt by one script; its steps are written down in
  the README.
