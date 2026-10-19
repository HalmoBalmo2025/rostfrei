# Child processes and helper programs

Read this before running another program, adding a helper program in
another language, or changing the messages exchanged with one.

## One process module

- All child processes go through one module; `Command::new` is forbidden
  elsewhere (`clippy.toml`, one `#[expect]` in that module). It:
  - finds the program and returns `Option`, never a fallback path;
  - sets the environment explicitly: a GUI app started from Finder or
    launchd has a minimal `PATH`, so tools found in a terminal are missing;
  - writes stdin and reads stdout and stderr concurrently while the child
    runs (a full pipe blocks it; writing stdin before reading can deadlock);
  - runs with a timeout and a cancel signal;
  - starts the child in its own process group (`process_group(0)`) and on
    timeout, cancel or error kills the whole group, then reaps it:
    grandchildren that inherited the pipes otherwise keep the reader blocked;
  - reports a child that exits early with its own exit status and stderr,
    not as "broken pipe".
- Tests use stand-ins (`/bin/sh -c …`, `sleep`, `exit 3`, 1 MB of output,
  a grandchild that keeps the pipe open, an empty environment).

## Children must not outlive the program

- A guard reaps the child on every exit path (`Drop`), but `Drop` does not
  run when the program aborts. So a child that could outlive its parent also
  watches the parent: it reads a pipe on stdin and ends when it closes.
- Start-up first cleans up what a crashed run left behind: stale PID files,
  orphaned children (verify by name before killing).

## Helper programs in another language

- Only where no binding crate exists and the API is UI-only (SwiftUI) or a
  crash must be isolated (see `macos.md`). A helper turns a call into a
  distributed system: partial failure, version skew, start-up races,
  timeouts and a wire format in two languages.
- The first message is a protocol-version handshake; a mismatch is a
  start-up error with a clear message.
- Every message type has a fixture file in `fixtures/`: the Rust test
  serialises to it byte for byte, the other language's test decodes the same
  file, both in CI. Enums go over the wire as fixed strings decoded into
  enums on both sides; a decode error is logged and reported, never dropped.
- Messages to the user from a helper carry the same languages as the app.

## Supervisor

- A long-running program that must survive a crash runs under the system's
  supervisor (launchd `KeepAlive = { SuccessfulExit = false }` with
  `ThrottleInterval` on macOS, systemd elsewhere) instead of a hand-written
  watchdog. A CLI needs none.
