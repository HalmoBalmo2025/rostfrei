# Concurrency: threads, async, channels, timers

Read this before adding or changing threads, tasks, channels, timers,
retries or cancellation.

## Structure first

- Do not reach for `'static` (leaking, globals, `Arc` on everything) to
  satisfy `spawn`. First look for a structure the borrow checker accepts:
  `.await` the work directly, `join!`/`select!` on borrowed futures, a
  `JoinSet` owned by the caller, scoped threads, or move owned data in and
  send results back over a channel.
- A resource gets its own thread only if it blocks for long (inference,
  child-process I/O) or several threads use it. Every extra thread brings
  request and reply types, ids, stale results and shutdown order; each is a
  place for logic holes.
- Prefer message passing over shared `Mutex` state. Never hold a lock or a
  `RefCell` borrow across `.await`. No blocking calls on an async runtime;
  use `spawn_blocking`.

## Owners

- Threads start with `thread::Builder` (named, for crash logs);
  `thread::spawn` is forbidden in `clippy.toml`. A failed start is one
  start-up error, not a panic.
- Every thread or task has an owner that joins, awaits or aborts it, on every
  exit path; a guard type does it in `Drop`. A `JoinHandle` stored as `_x` and
  never joined is a bug. A dropped `tokio::JoinHandle` detaches the task: use
  a `JoinSet` or keep the handle.
- A thread that panicked is an error variant, not a second panic. With
  `panic = "abort"` this only happens in debug and tests; still map it.
- Every loop has a way out: a worker ends when its channel closes or a stop
  request arrives. A worker that holds a `Sender` to its own channel never
  sees it close.

## Requests and results

- Every request carries an id; results carry the id of the request they
  answer. The receiver drops results whose id is no longer current
  (cancelled or superseded). One mechanism, used everywhere.
- Every request gets exactly one reply, including "rejected" and "busy"; a
  caller never waits for an answer that cannot come. Every operation in
  flight ends in exactly one terminal event, also when the connection drops
  or the worker restarts: done, to be repeated, or dropped, decided
  explicitly. "Writing" never silently counts as "done".
- A timeout budget is nested: the callee's timeouts together fit inside the
  caller's.

## Retries and idle release

- Retries have a pause that grows and a limit (attempts or total time); the
  schedule is a pure, tested function of the attempt number; the last error
  reaches the user. After a failure, later calls fail fast instead of
  repeating a slow failure for every item.
- A resource released when idle is released by its owner: the owner waits
  for requests with a timeout and drops the resource when it fires. No
  watcher threads polling shared state.
- Slow work may start as soon as it becomes likely to be needed, but every
  such head start has a cancellation path and a test for it.

## Logs from several threads

- A log line is formatted together with its newline and written with one
  `write_all` (or by one owner thread): `writeln!` on an unbuffered file
  makes two writes, and lines from different threads run into each other.

## Shutdown

- Shutdown is ordered and written down in one function: stop accepting work,
  stop the producers, then the consumers, then the resources; join each.
  A component that is still running must not restart one already stopped.
- `Drop` does not run when the program aborts on a panic; see
  `processes.md` for children that must not outlive it.
