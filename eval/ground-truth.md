# Ground truth

The known defects of each case, written from the fix commits and from bugs
confirmed at HEAD before any review ran. The reviewers never saw this file;
the judge scored against it (rules in `README.md`). "Unconfirmed" marks
open bugs that were suspected but not yet shown when the file was written.

## D-c22da25 (Diktator, before "Beenden: Modell vor dem Prozessende freigeben")
- D1: At quit, `main` returns while the model thread still owns the speech model on the GPU (thread not stopped/joined before process exit); ggml/Metal aborts (SIGABRT) and the watchdog restarts the app.
- D2: An error return (`return Err` / `?`) in main's start-up after the model thread was spawned skips the shared teardown, leaking/not stopping the model thread.

## D-c98e2bf (before "Sicherheitsnetz: Zahlen und Verneinungen ändert das Modell nie")
- D3: The polish safety guard lets the language model change numbers and negations (e.g. §433→§434, 15→16, 2,5→25, unwirksam→wirksam): similar-spelling/edit-distance acceptance does not protect digits or negation prefixes.
- D4: A failed spell check is turned into an empty set ("nothing is spelled right" / no info), which makes every change allowed — a sentinel instead of an explicit "unchecked" state.

## D-7f582e3 (before "Abbau in fester Reihenfolge: Steuerung, Modell, llama-server")
- D5: The controller loop never ends because it holds a Sender to its own channel; without a UI the process (child) outlives the watchdog.
- D6: During shutdown, while main waits for the model thread, the controller can still start a new llama-server, which is left orphaned (shutdown order).

## D-a8bec38 (before "Steuerung: roher Text ohne Überarbeiten, Esc aus dem Zustand")
- D7: When the polish thread/worker is gone (fn+⌥ / polish mode), the held-back text is never pasted although the note says it was inserted (lost text).
- D8: Esc capture is set/cleared in many places instead of derived from the state; if the model thread dies mid-recording, Esc stays captured system-wide.
- D9: A second long job is silently cancelled/dropped by the worker and the controller waits forever for its answer (request without reply).
- D10: A transcript result arriving during a download is credited to the download (results not matched to their request).

## D-2638e4a (before "Panel überschreibt keine fehlerhafte Datei mehr")
- D11: A broken (unparseable) settings/dictionary TOML makes the panel show defaults, and the next panel edit writes those defaults over the user's file.
- D12: `fs::write` is not atomic, and an `exists()`-then-write check is a race (check-then-act).

## D-918aa83 (before "Kindprozesse über ein Modul: Zeitgrenze, Abbruch, keine stillen Fehler")
- D13: stdin of a child is written before reading output/waiting, so a child that doesn't read hangs forever; an early exit is reported as "Broken pipe" instead of the child's own error.
- D14: `Command::status/output` calls have no timeout (osascript, YouTube info/decode): a hung child blocks later work and cannot be cancelled.
- D15: Pipe read errors are dropped (`Ok(_) | Err(_)`, `join().unwrap_or_default()`), giving a silently truncated transcript.
- D16: `try_wait()?` returns early and leaks the started llama-server process.

## D-ccf2eeb (before "Doku, Protokoll und Kleinigkeiten")
- D17: Logs contain user content (characters around the cursor; UI lines with dictionary entries/paths).
- D18: `.ok()?` turns a UI read error into a silent shutdown; `current_exe().ok()` is misreported as "not an app".
- D19: Dead code hidden by `pub` in the library: an unreachable branch, a test-only `FromStr`, an unused field.
- D20: The fallback cut position for audio chunks can land in the last, incomplete frame (cut at buffer end).
- D21: Stale comments/docs (e.g. "⇧ = English", "10× per second"); constants copied as literal numbers into docs.

## D-45f85c7 (before "Rechte Sondertasten, Kontext schneller, llama-Start, Zwischenablage, Swift-Enums")
- D22: Right ⌘/⌥/⌃ use the generic modifier flag bit, so holding the left key swallows the tap of the right one.
- D23: A failed llama-server start is retried for every translation chunk, each attempt up to 180 s (no fail-fast after failure).
- D24: Restoring the clipboard overwrites whatever the user copied in the meantime (no check that the clipboard is still what was left).

## D-8fcb7c3 (before "Sprachbefehle zum Bearbeiten wieder entfernt, Teile höchstens 28 s")
- D25: Audio parts can be up to 5×60 s although the model handles at most 30 s, so the model re-splits them at a random spot (constants that must agree).
- D26: `part_seconds` (and similar settings) are validated only when reading the file; a bad value from the panel is saved and makes the file unreadable (parse, don't validate).

## D-HEAD (Diktator HEAD, open)
- D27 (confirmed by reading): when `finish()` or `next_part()` of the recording fails (dictation.rs ~192–197, ~243–249), the state goes to Ready and the dictation is dropped: in polish mode the recognised but held-back text is lost; in raw mode the captured buffer is lost. Same for worker_gone / LoadFailed.
- D28 (unconfirmed): panel visibility is checked per part instead of once per dictation, so parts are lost or duplicated when the panel is toggled mid-dictation.
- D29 (unconfirmed): shutdown kills llama-server by PID but doesn't stop/join the polish thread; a queued warmup can restart the server after the kill.
- D30 (unconfirmed): process.rs kills only the direct child on timeout; a grandchild holding the pipe keeps `run()` blocked past its limit (needs a process group).

## H-b1edad2 (Homepage, before "Adopt the new project template")
- H1: The maze generator has no RNG: its only randomness is `HashSet`/`HashMap` iteration order, so on wasm32 mazes repeat (hash-order dependence).

## H-bd7552e (before "malachite_app: Running and queued jobs live inside the worker's Phase")
- H2: `running`/`queued: Option<Job>` (and `measuring: Option<u64>`) live beside the status instead of inside it; `measuring` can outlive its job, so "Computing F(n)" shows for another job (parallel state / illegal state representable).

## H-HEAD-malachite (open, confirmed by running)
- H3: `int_div` and `modulo` (calc/number.rs ~406–421) floor an approximate value but keep its claimed precision: `sqrt(2)*sqrt(2) // 1` gives 1 with 48 "reliable" places (true 2); `fact(sqrt(10)*sqrt(10) // 1)` gives 9! marked exact.

## H-HEAD-nh4no3 (open, likely)
- H4: A stored state that fails to decode (corrupt or newer VERSION) is replaced by defaults and the autosave writes them over the stored data (persist.rs ~149–165 with components/app.rs).
- H5: `parse_de` (ui/format.rs) uses `f64::from_str`, which accepts "inf", "NaN" and "1e400"; ∞ passes a min-only field and reaches the solver.
