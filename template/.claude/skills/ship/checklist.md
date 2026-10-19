# Review checklist

Questions for the reviewer, by step. Each one comes from a real bug that
compiled, passed clippy and passed the tests. Ask every question of your
focus for every changed function; for `full` mode, for every module.

## 1. Scope and gate
- Does the diff do exactly what the task asked? Unrequested refactors,
  renames, deleted or weakened tests?
- `gate.patch`: a relaxed lint, a new `allow`/`warn`, a raised threshold, a
  new mutants exclusion, a toolchain or dependency change: was it part of
  the approved plan, with a reason next to it?
- Every new `#[expect]`: is the reason true, and is it on the smallest item?

## 2. Data and state model
- Does any bool, `Option`, number, string or tuple carry a meaning (absent,
  unit, sentinel, position) that only a comment or the caller explains?
- Can a field be derived from another field? Are two fields valid only
  together? Then there are two sources of truth.
- Is there data beside the state that is valid only in some states?
- Are two independent facts folded into one state (whether a resource is
  ready, and which operation runs)? Leaving the operation then loses the
  other fact.
- Persisted data and wire formats: is every older file and message still
  read? With `deny_unknown_fields`, a removed or renamed key makes every
  old file unreadable. Is there a fixture for it, on both sides of a
  language boundary?
- Constants that must agree (a size and a limit, two timeouts, a range in
  code and in the UI): do they, and does a test or `const` check it?
  Compute the extreme combination (the largest setting times its factor,
  the last partial chunk, the final frame) and compare it with the limit it
  feeds.
- Is the type of a measured or user-supplied value checked at the boundary
  (finite numbers, non-empty, in range)?

## 3. Lifecycle and concurrency
- For every new thread, task, child process, timer, listener, closure or
  loaded resource: who owns it, who stops and joins or reaps it, on which
  exit paths, including error returns and early returns?
- Is a `JoinHandle` or guard stored as `_x` and never joined?
- During shutdown, can a component that is still running restart one that
  is already stopped? Is the order written down in one place?
- Does a loop that ends when its channel closes hold a `Sender` to that
  channel itself?
- With `panic = "abort"`, does correctness rely on `Drop`?
- Do the callee's timeouts together fit inside the caller's timeout?
- Can a result arrive for a request that was cancelled or superseded? Is it
  dropped by its id?
- Can a grandchild process keep a pipe open after the child is killed?
- Between starting a resource and handing it to its owner or guard, is
  there a `?` or an early return (`child.try_wait()?`, a failed handshake,
  a parse of the first reply)? That path leaks the resource.

## 4. Transition logic
- The table of state × event for every changed handler: is every cell
  intended? Is any transition decided by `_`, `matches!` or `if let`?
- Does every request get exactly one reply, including rejection and
  "busy"? Does every started operation end in exactly one terminal event,
  also when a dependency disappears?
- Does an early `return` or `?` skip a shared tail: resetting a state,
  clearing an error, delivering a result, saving?
- Is a flag set and cleared in several places instead of derived from the
  state once after each transition?
- When a step fails, what happens to the work already done (text already
  recognised, data already buffered, input already typed)? Is it lost?
- Every fallback path (a worker thread or helper gone, a feature
  unavailable, a mode switched off): does it still deliver what the main
  path delivers (insert the text, save the file, send the reply), and does
  its message say what really happened? Fallbacks are the paths no test
  reaches.
- Are cancel, stop and quit idempotent? What happens on a second press?
- Is a value checked per item that should be fixed once per operation (a
  setting read at every part instead of at the start)?
- Requests that supersede each other: after A → B → A, is B still queued
  behind the running A? Does a cancel also drop what is queued?

## 5. Failure paths
- For every `.ok()`, `unwrap_or…`, `if let Ok`, `let … else { return }`,
  `Ok(_) | Err(_)` and `saturating_*`: where does the error go? Does
  ignoring it change the content of the result (a truncated text, a missing
  entry, a wrong number)?
- Can a value produced by a failed read be written back, such as defaults
  saved over a user file that failed to parse? Does the UI start from an
  empty or default state when loading failed, so the next save replaces
  the user's data?
- Is an error message shown to the user replaced by a later message in the
  same event ("failed" followed by "done"), so the user never sees it?
- Before restoring the user's state (clipboard, focus, selection), is it
  checked that it is still what was left?
- After a failure, do later calls fail fast, or does every item repeat the
  slow failure? Do retries have a pause and a limit?
- Environment: a minimal `PATH` when started from Finder or launchd, the
  working directory, missing permissions, sleep and wake, time zone and
  daylight saving, locale?
- Numbers: NaN, infinity, empty input, zero, one, maximum, overflow,
  division, precision claimed versus precision actually computed?
- Does correctness rely on a range that only the UI enforces? Does an input
  field commit every keystroke, so that a prefix of a too-large number
  passes the range check and stays?
- Text exports (CSV, TSV): are separators and quotes in user text quoted,
  and a leading `=`, `+`, `-`, `@` neutralised?
- Positions stored in layout pixels (drawings, selections) when the layout
  can change size: are they stored in model coordinates instead?

## 6. Tests
- Is every surviving mutant on a changed line killed by a test or truly
  equivalent?
- Does every fix come with a test that fails when the fix is reverted?
- Can the fakes fail? Is every error branch of the changed code reached by
  a test?
- New parser, numeric code or state machine: is there a property test
  (round trip, invariant after every step, reference model)?
- Could this logic run in a host test instead of only in the UI or browser?

## 7. Dead code, duplication, structure
- Unused functions, fields, variants, CSS classes, files no module links,
  test-only code in production, `pub` that hides dead code?
- Code copied from another module instead of shared? A second definition
  of something that exists already?
- A file over about 800 lines, or one that mixes concerns?
- The change fixes one instance of a pattern: where else does it occur?

## 8. Drift
- Which comments, docs, README lines, help texts, user messages and
  templates mention what changed? Are constants copied into docs as
  literal numbers?
- Code in English, user-facing text in the product's language(s), every
  user-facing error in every supported language?
- References to plans, phases or tickets; leftovers of templates or other
  projects?
- User content (typed text, file names, paths, titles) in log lines?
