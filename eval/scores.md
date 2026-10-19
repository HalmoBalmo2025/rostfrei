# Scores

Rules applied: CAUGHT = same place or mechanism and same consequence; PARTIAL = right place, related but weaker or vaguer problem; MISSED otherwise. A defect named only in a question counts as PARTIAL at most. Finding ids are the report's own (`F3`, or `#3` for numbered prose reports; `m` = an item in a "Minor" list). Borderline calls are explained in the quote column after "—".

## 1. Recall

| case | defect | label | verdict | finding | quote (≤15 words) |
|---|---|---|---|---|---|
| D-c22da25 | D1 | A | PARTIAL | F4 | "Shutdown is not ordered: five threads are detached, and work queued at exit is dropped" — `_worker` is among the unjoined handles, but the stated consequence is lost notifications and a llama restart; the GPU abort is never mentioned |
| D-c22da25 | D2 | A | PARTIAL | F4 | "main.rs:137 queues the notification on the feedback thread, and main.rs:138-139 return at once" — finds the early return that skips teardown, but the only consequence given is a lost notification |
| D-c98e2bf | D3 | A | CAUGHT | F1 | "The guard lets the model change numbers, amounts, dates and citation numbers" — negations are covered only by F7 (kein→ein) and F3 (不) |
| D-c98e2bf | D4 | A | CAUGHT | F7 | "A failed spell check is passed on as "no word is correct"" |
| D-7f582e3 | D5 | A | CAUGHT | F4 | "`Controller::run` can never end: it holds a sender to its own channel" |
| D-7f582e3 | D6 | A | CAUGHT | F5 | "a fn + ⌥ in that window sends `PolishRequest::Warmup`, which starts a server too" |
| D-a8bec38 | D7 | A | MISSED | – | — F2 and F8 flag false "eingefügt" notes on the panel and Esc paths; the fallback when the polish thread is gone (`start_polish` false → `finish_dictation`) is never named |
| D-a8bec38 | D7 | B | CAUGHT | #1 | "Polish-mode fallback never pastes the raw text" |
| D-a8bec38 | D8 | A | CAUGHT | F9 | "`escape_capture` is set and cleared in nine places; leaving `Recording` through `worker_gone` keeps Esc swallowed" |
| D-a8bec38 | D8 | B | CAUGHT | #2 | "Esc stays captured system-wide after the model thread is lost mid-recording" |
| D-a8bec38 | D9 | A | PARTIAL | Q1 | "worker.rs:518-523 drops a second `Job::Transcript` without any reply" — question only |
| D-a8bec38 | D9 | B | CAUGHT | #13 | "The worker discards a second `Transcript` job without ever reporting it" — filed as latent, low confidence |
| D-a8bec38 | D10 | A | PARTIAL | Q1 | "treats a `TranscriptFinished` that arrives during `Downloading` as the result of the current download" — question only |
| D-a8bec38 | D10 | B | CAUGHT | #13 | "`on_transcript_finished` in `Downloading` treats a stray result as belonging to the job being downloaded" |
| D-2638e4a | D11 | A | CAUGHT | F1 | "A panel save overwrites a settings.toml or dictionary.toml that failed to load" |
| D-2638e4a | D12 | A | CAUGHT | F3 | "`ensure`. It checks `exists()` and then writes with `fs::write`" — plus non-atomic `fs::write` in the title "User files are rewritten in place" |
| D-918aa83 | D13 | A | CAUGHT | #3 | "Helper timeout does not cover writing stdin; EPIPE can hide the helper's reason" |
| D-918aa83 | D13 | B | CAUGHT | F4 | "writes the input outside the timeout and reports a helper that exits early" (as "Broken pipe") |
| D-918aa83 | D14 | A | CAUGHT | #2 | "both use a blocking `Command::output()` with no timeout and no cancel" |
| D-918aa83 | D14 | B | CAUGHT | F1 | "`decode_file` and `fetch_info` block in `Command::output()` with no cancel flag and no timeout" |
| D-918aa83 | D15 | A | MISSED | – | — #5 cites the joins at youtube.rs:306-308, but only as a hang; dropped read errors and truncated output are never raised |
| D-918aa83 | D15 | B | CAUGHT | F12 | "youtube.rs's copy of `reader` and `read_all` ignores read errors" → "a truncated or empty transcript" |
| D-918aa83 | D16 | A | CAUGHT | #11 | "`child.try_wait()?` returns `LlamaError::Start` without killing the just-spawned server" |
| D-918aa83 | D16 | B | MISSED | – | — llama.rs:294 appears only in F14 as an untested `Exited` path |
| D-ccf2eeb | D17 | A | CAUGHT | F7 | "Dictated text and other user content go into the log" — same pattern lists ui.rs:164-166 (whole UI line) |
| D-ccf2eeb | D18 | A | CAUGHT | F16, F19 | "`self.lines.next()?.ok()?` returns None without calling `on_garbage`"; F19: `bundle_path` turns a `current_exe` error into the not-an-app message |
| D-ccf2eeb | D19 | A | CAUGHT | F14, F20 | "`FromStr for Language` … used only by language.rs's own test" + "`pub` in lib.rs hides this dead code"; F20 has the unreachable checks — an unused field is not named |
| D-ccf2eeb | D20 | A | MISSED | – | — F20 cites the `part_end` fallback lines only as a dead check, and the Checked section calls `part_end` fine; the last incomplete frame is never raised |
| D-ccf2eeb | D21 | A | CAUGHT | F13 | "Drift in the settings template: "mit ⇧ auf Englisch"" — F14 also covers literals copied into texts; "zehnmal pro Sekunde" (mod.rs:115) is not found |
| D-45f85c7 | D22 | A | CAUGHT | F9 | "the release is missed while the left key of the same kind is held" |
| D-45f85c7 | D23 | A | CAUGHT | F2 | "After the local model fails, every paragraph and every dictation repeats the slow failure" |
| D-45f85c7 | D24 | A | CAUGHT | F7 | "The clipboard restore is skipped when ⌘V fails, and otherwise overwrites a newer clipboard" (also Q2) |
| D-8fcb7c3 | D25 | A | MISSED | – | — `MAX_PART_SECONDS` 60 × `PART_MAX_FACTOR` 5 against the 30-s chunk is never raised; F14's "constants that must agree" is about `FRAME_LEN` |
| D-8fcb7c3 | D26 | A | CAUGHT | F5 | "written into a file that no longer loads" — `part_seconds: 90` from the panel |
| D-HEAD | D27 | A | CAUGHT | F3 | "A microphone failure during a dictation throws away the text already recognised" (+ `worker_gone` same pattern) |
| D-HEAD | D28 | A | CAUGHT | F2 | "Panel visibility is read once per part, so parts are lost or delivered twice" |
| D-HEAD | D29 | A | PARTIAL | F5 | "kills the llama-server under the running polish thread" — right mechanism, but the consequence given is an orphaned diktator-llm (Apple fallback), not a restarted llama-server |
| D-HEAD | D30 | A | CAUGHT | F1 | "`process::run`: timeout and cancel do not reach grandchildren" — test: 5.005 s against a 100 ms limit |
| H-b1edad2 | H1 | A | CAUGHT | F4 (+Q1) | "Maze randomness comes from `HashSet` iteration order" — borderline: filed as [klein]; the wasm32 repetition is only asked in Q1 |
| H-bd7552e | H2 | A | CAUGHT | F1, F3 | "move the running job into `Status::Busy(Job)`, so that it cannot outlive the computation" + "`measuring` … also outlives its measurement" |
| H-bd7552e | H2 | B | PARTIAL | #2, #4 | "a superseded queued job survives and runs after the current one" — the fix is only "set `engine.queued = None`"; the state beside `Status` is never named |
| H-HEAD-malachite | H3 | A | CAUGHT | #3 | "`//` and `mod` on approximate values claim reliability they cannot have" — `sqrt(2)^2 // 1` gives 1, true 2; #4 `fact(…)` Exact |
| H-HEAD-malachite | H3 | B | CAUGHT | F2 | "Zero, integer and floor decisions treat an approximate value as exact" — `1/sqrt(0.25 + 10^-70) // 1` gives 2, executed |
| H-HEAD-nh4no3 | H4 | A | CAUGHT | F1 | "A stored state that fails to load is overwritten with the defaults 500 ms later" |
| H-HEAD-nh4no3 | H5 | A | CAUGHT | F7 | "`parse_de` accepts `inf`, `NaN` and `1e400`" + "The target fields have no `max`, so `inf` is accepted" |

## 2. Totals

| label set | defects | CAUGHT | PARTIAL | MISSED |
|---|---|---|---|---|
| single-report cases, A (10 cases) | 25 | 20 | 3 (D1, D2, D29) | 2 (D20, D25) |
| paired cases, A (4 cases) | 10 | 6 | 2 (D9, D10) | 2 (D7, D15) |
| paired cases, B (4 cases) | 10 | 8 | 1 (H2) | 1 (D16) |

Per paired case: D-a8bec38 A 1/2/1, B 4/0/0; D-918aa83 A 3/0/1, B 3/0/1; H-HEAD-malachite A 1/0/0, B 1/0/0; H-bd7552e A 1/0/0, B 0/1/0.

## 3. Precision spot check

For each report: the three highest-severity findings that are not in that case's ground truth. Where a finding matches a known defect of another case, the tag is in brackets.

| report | finding | claim | verdict | reasoning |
|---|---|---|---|---|
| D-c22da25 A | F1 [grob] | broken settings/dictionary file overwritten from the panel [= D11] | REAL | `show_settings` sends `SettingsEntries::default()` on a parse error (main.rs:249-255); save goes through `fs::write` (settings.rs:288) |
| D-c22da25 A | F2 [grob] | one failed piece discards the whole long transcript | REAL | worker.rs:391-395 returns `TranscriptOutcome::Failed(error)`; `texts` is dropped |
| D-c22da25 A | F3 [grob] | a transcript queued during loading never ends if the load fails | REAL | worker.rs:154-159 returns after `LoadFailed` and drops the queued job; the controller's `LoadFailed` arm leaves `transcript` alone |
| D-c98e2bf A | F2 [grob] | guard removes every line break | REAL | `tokens` uses `split_whitespace` and the output is `join(" ")` (guard.rs:126); voice commands insert "\n\n"/"\n" before polishing |
| D-c98e2bf A | F3 [grob] | Chinese sentence is one token, an inserted 不 passes | REAL | `close` allows 3 edits above 8 chars; the spell set is empty for zh, so `may_change` is true |
| D-c98e2bf A | F4 [grob] | polish thread not stopped, can restart llama-server after the kill [= D29] | REAL | main.rs:143 kills the server, `_polish` is never joined, `url_for` restarts a dead child (llama.rs:196-201) |
| D-7f582e3 A | F1 [grob] | broken settings file overwritten from the panel [= D11] | REAL | main.rs:262-268 shows defaults on a parse error; save writes them |
| D-7f582e3 A | F2 [grob] | panel state read per part [= D28] | REAL | `self.panel` is read per event at dictation.rs:275, 365, 398 |
| D-7f582e3 A | F3 [grob] | one failed chunk discards the long transcript | REAL | worker.rs:397-401, `Failed` carries no text |
| D-a8bec38 A | F1 [grob] | microphone failure drops recognised text [= D27] | REAL | dictation.rs:185-191 and 238-244 return `State::Ready` and drop the `Dictation` |
| D-a8bec38 A | F2 [grob] | panel state read per part [= D28] | REAL | dictation.rs:275 and 398 read `self.panel` at each part |
| D-a8bec38 A | F3 [grob] | hotkey listener failure leaves the recording running | REAL | `HotkeyFailed` only calls `problem` (mod.rs:346-349); `listen` returns `TapRefused` from its re-create loop (hotkey.rs:339-347) |
| D-a8bec38 B | #3 | quit/cancel block on ffmpeg and yt-dlp loaders | REAL | `load_file` gets no cancel flag (source.rs:214); `decode_file` uses `Command::output()` with no timeout |
| D-a8bec38 B | #4 | a failed queue item's note is overwritten at once | REAL | `process` calls `start_waiting` right after `handle` (mod.rs:326), which writes "… wird gelesen" |
| D-a8bec38 B | #6 | panel state read per part [= D28] | REAL | same lines as A F2 |
| D-2638e4a A | F2 [grob] | old settings.toml with `adresse` rejected | REAL | `PolishContent` is `deny_unknown_fields`; PLAN.md:204 says `adresse` "wird überlesen" |
| D-2638e4a A | F4 [grob] | lowercase replacement also replaces the capitalised word mid-sentence | REAL | `from_content` adds the capitalised variant unconditionally (dictionary.rs:320-327); `replace_words` has no sentence-start check |
| D-2638e4a A | F5 [grob] | polish thread not joined, server killed under it [= D29] | REAL | `shut_down` joins the controller, drops the model, kills the server; `_polish` has no stop (main.rs:406-427) |
| D-918aa83 A | #1 | `wait_for` ignores cancel after ffmpeg exits and blames yt-dlp | REAL | youtube.rs:395-402: `downloader.wait()` with no cancel check; `(false, _) => DownloaderFailed` wins (B F5 reproduces it) |
| D-918aa83 A | #4 | log lines from threads interleave | REAL | `writeln!` on an unbuffered `File` makes two `write(2)` calls (B F10: 110 of 24 000 lines broken) |
| D-918aa83 A | #5 | an error in `wait_for` leaves both processes running, then the joins hang | REAL | `try_wait()?`/`wait()?` return early; the joins at youtube.rs:306-308 run before `finished?`, and no child is stopped |
| D-918aa83 B | F2 [grob] | yt-dlp gets the minimal launchd PATH, so it finds neither ffmpeg nor deno | REAL | no `.env()` or `--ffmpeg-location` anywhere in src; the child inherits the environment (the reviewer did not check what yt-dlp then does) |
| D-918aa83 B | F3 | no process group, so timeout and cancel wait for grandchildren [= D30] | REAL | no `process_group` in src; failing test 5.02 s against 100 ms |
| D-918aa83 B | F5 | a failure in ffmpeg is reported as yt-dlp's broken pipe | REAL | same match as A #1; failing test with real ffmpeg |
| D-ccf2eeb A | F1 [grob] | failure notes overwritten in the same event | REAL | the paste-failure note (dictation.rs:373-375) is replaced by `finish_dictation`'s "eingefügt"; harness output shown |
| D-ccf2eeb A | F2 [grob] | panel state read per part [= D28] | REAL | dictation.rs:268, 357, 390 |
| D-ccf2eeb A | F3 [grob] | recording failure drops recognised text [= D27] | REAL | dictation.rs:180-185, 233-237 return `Ready` |
| D-45f85c7 A | F1 [grob] | clipboard restore keeps only plain text or one image | REAL | `save` tries `get_text`, then `get_image`, else `Empty` → `clear()` (paste.rs:99-121); paste.rs:14-15 admits other formats are lost, README:51 promises they are kept |
| D-45f85c7 A | F3 [grob] | Diktator's own ⌘V cancels the fn tap | REAL (timing-dependent) | `on_key_down` calls `other_key_pressed` for every KeyDown; ⌘V posted at HID passes the Session tap; needs a part pasted during the fn press |
| D-45f85c7 A | F4 [grob] | llama-server outlives an aborted Diktator | REAL | spawned with no process group and no parent watch (llama.rs:287-294); abort runs no `Drop`; `clean_up_stale` only at the next start |
| D-8fcb7c3 A | F1 [grob] | panel state read per part [= D28] | REAL | dictation.rs:284, 451 |
| D-8fcb7c3 A | F2 [grob] | a failed part ends as "Keine Sprache erkannt." or "N Wörter eingefügt." | REAL | the `Err` arm notes, then falls through to `finish_processing` → `finish_dictation` (dictation.rs:290-307, 444-458) |
| D-8fcb7c3 A | F3 [grob] | old `adresse` key rejects the whole file | REAL | `deny_unknown_fields` on `PolishContent` (settings.rs:543-544); executed test |
| D-HEAD A | F4 [grob] | model readiness folded into dictation state; a failed load leaves a transcript at 0 % forever | REAL | `LoadFailed` arm (mod.rs:431-437) only sets `Unavailable`; the worker returns after `LoadFailed` (worker.rs:211-213); Esc during `Loading` returns `Ready` |
| D-HEAD A | F6 [klein] | notes say "eingefügt" after a failed paste or when nothing was inserted | REAL | `finish_dictation`'s note follows the paste-failure note; the Esc note tests `text.is_empty()` |
| D-HEAD A | F9 [klein] | no panic hook; start-up errors reach only stderr | REAL | no `set_hook` in src; `run()` errors go to `eprintln!` |
| H-b1edad2 A | F1 [grob] | gate forces `mul_add` on WASM and `saturating_*` everywhere | REAL | Cargo.toml:243 nursery deny with no `suboptimal_flops` allow, no `mul_add` ban in clippy.toml, :265 and :337 as quoted; a gate-vs-guideline issue, rated higher than its runtime effect |
| H-b1edad2 A | F2 [grob] | each wall stored twice and drawn twice | REAL | `draw` emits every wall of every active cell (drawing.rs:114-125); test 198 against 117 |
| H-b1edad2 A | F3 [grob] | drawn route comes off the maze on resize or fullscreen | REAL (by reading) | strokes are `element_coordinates` of an `inset: 0` layer, the maze is centred and scaled on its own, the draw SVG has no `viewBox`; not run in a browser |
| H-bd7552e A | F2 [grob] | a worker that fails to load is respawned with no pause or limit | REAL | the restart coroutine runs `abort` → `spawn` on every `Crashed` (lib.rs:420-424, 487-497); `onerror` fires on a failed module load |
| H-bd7552e A | F3 [grob] | the "background" warning lands on the wrong table after cancel | REAL | `hidden` is reset on an accepted submit (compare.rs:103-106); `abort` keeps `output.shown`, so the old table returns |
| H-bd7552e A | F4 [klein] | error position mapped through the untrimmed draft | REAL | `marked` uses `draft.read()` (calc.rs:155-156) while `submit` sends the trimmed text; failing test |
| H-bd7552e B | #1 | old error span attached to a new local message | REAL | `marked` comes from `state.failure.span` whatever the message; a local `problem` does not clear `failure` (calc.rs:150-176) |
| H-bd7552e B | #3 | unbounded crash/restart loop | REAL | same as A F2; also `onmessageerror` is routed to `Crashed` (worker.rs:560) |
| H-bd7552e B | #4 | old table returns with a wrong "background" verdict | REAL | same as A F3 |
| H-HEAD-malachite A | #1 | precision cannot go below zero places, so wrong integer digits are printed as reliable | REAL | `shifted` clamps with `.max(0)` (number.rs:131-134); B's executed test shows `Reliable(0)` with 40 invented digits |
| H-HEAD-malachite A | #2 | an approximate zero is treated as exact | REAL | `mul`/`div` take the `is_zero()` shortcut regardless of precision (number.rs:368-391); B's test confirms |
| H-HEAD-malachite A | #5 | roots ignore the radicand's precision | REAL | `Self::approximate(…, digits)`, and the perfect-root branch copies `self.precision` (number.rs:596-628); B's test confirms |
| H-HEAD-malachite B | F1 [grob] | as A #1 | REAL | executed: `sqrt(2) * 10^100` shows 40 zero digits as `Reliable(0)` |
| H-HEAD-malachite B | F3 [grob] | as A #5 | REAL | executed: `sqrt(sqrt(2*10^-100))` claims 50 places, about 16 wrong |
| H-HEAD-malachite B | F4 [grob] | quotient and sum promise too many places | REAL | executed: 12 × `/(10/99)` wrong at places 49-50 under `Reliable(50)` |
| H-HEAD-nh4no3 A | F2 [grob] | a salt saved into a removed stock is dosed but shown nowhere | REAL | `upsert_salt`/`assign` store any `StockId` (state/mod.rs:264-277); two failing tests |
| H-HEAD-nh4no3 A | F3 [grob] | NumberField commits the in-range prefix of an out-of-range entry and clears the mark on blur | REAL | `oninput` calls `onchange` for every in-range parse (field.rs:157-163); `onblur` sets `rejected` to false |
| H-HEAD-nh4no3 A | F4 [grob] | comparison label says "unverändert" when a target is added or removed | REAL | `match (now.target, before.target)` ends in `_ => {}` (state/mod.rs:69-77); tolerance is not compared; failing tests |

Result: 54 of 54 REAL (one timing-dependent, one by reading only), 0 DOUBTFUL, 0 WRONG. Twelve of the 54 match a known defect of another case (D11, D27, D28, D29, D30). So the ground truth for an earlier snapshot leaves out bugs that are still open later.

## 4. Evidence

Executed = a command plus failing (or defect-showing) output. Quotes = code cited by file:line, verbatim or as a line reference, without a run. Nothing = no code location at all.

| report | findings | executed | quotes only | nothing | remark |
|---|---|---|---|---|---|
| D-c22da25 A | 15 | 10 | 5 | 0 | Linux harness against the real worker.rs |
| D-c98e2bf A | 19 | 7 | 12 | 0 | also a mutants run on guard.rs |
| D-7f582e3 A | 16 | 7 | 9 | 0 | |
| D-a8bec38 A | 18 | 0 | 18 | 0 | test patches "not run", "Predicted test result" |
| D-a8bec38 B | 16 | 0 | 16 | 0 | hand-traced; 6 of 16 give line refs with no verbatim excerpt |
| D-2638e4a A | 18 | 3 | 15 | 0 | std-only harness for F4, F8, F9 |
| D-918aa83 A | 18 | 0 | 18 | 0 | read only; 8 of 18 give line refs with no verbatim excerpt |
| D-918aa83 B | 17 | 5 | 12 | 0 | stand-in yt-dlp/ffmpeg, measured timings |
| D-ccf2eeb A | 20 | 13 | 7 | 0 | harness deleted after the run |
| D-45f85c7 A | 16 | 0 | 16 | 0 | every patch "not run" |
| D-8fcb7c3 A | 15 | 5 | 10 | 0 | includes `cargo mutants` |
| D-HEAD A | 17 | 1 | 16 | 0 | only process.rs ran |
| H-b1edad2 A | 16 | 9 | 7 | 0 | |
| H-bd7552e A | 13 | 5 | 8 | 0 | Dioxus `VirtualDom` harness |
| H-bd7552e B | 15 | 0 | 15 | 0 | 6 of 15 give line refs with no verbatim excerpt |
| H-HEAD-malachite A | 12 | 0 | 12 | 0 | says "reproduced with probe tests" and shows values in 10 findings, but gives no command or test |
| H-HEAD-malachite B | 11 | 6 | 5 | 0 | 246-input reference grid |
| H-HEAD-nh4no3 A | 15 | 7 | 8 | 0 | |
| **all** | **287** | **78** | **209** | **0** | |

## 5. Paired comparison

In every pair, one report uses the long structured format (Rule/Scenario/Evidence/Test patch, `F`-ids) and the other is short prose with numbered items. The labels are shuffled: structured is A for D-a8bec38 and H-bd7552e, and B for D-918aa83 and H-HEAD-malachite. This is my inference from the format only. Pooled by format, the prose reports caught 8 / partial 1 / missed 1 and executed 0 findings. The structured reports caught 6 / 2 / 2 and executed 16.

**D-a8bec38.** Recall: B is clearly better. It catches all four known defects (D7–D10). A catches one (D8), has D9 and D10 only as a question (Q1), and misses D7. That is 4 against 1 caught. Additional real findings: A is ahead on breadth. The two share about eight findings: panel per part, overwritten notes, loading state, false notes, loaders blocking quit, Esc capture, piece number. A adds five runtime bugs of its own: the microphone failure that drops text (the open defect D27), hotkey failure during a recording, a failed piece dropping the whole transcript, user content in logs, and clipboard read errors. It also adds six structural or test findings. B adds four runtime bugs: Processing stuck forever, untrimmed timestamps, spaces around line breaks, and the cancel gap. All six spot checks are REAL. Evidence: a tie at zero executed. A has verbatim quotes and unrun test patches, while B has hand-traced line references, so A has a slight edge.

**D-918aa83.** Recall: a tie at 3 caught and 1 missed each, with different misses. A misses D15 (dropped pipe read errors), which B catches in F12. B misses D16 (the `try_wait` leak), which A catches in #11. Additional real findings: roughly even. They overlap on wait_for, log interleaving, process groups and the UI `.ok()?`. A adds five small unique bugs and four minor notes. B adds four unique runtime bugs, including the only grob one (the yt-dlp PATH), plus six test or structure findings. All six spot checks are REAL. Evidence: B is decisively better, with 5 findings backed by failing tests and measured timings against A's 0. B's tests also confirm two of A's unrun claims (#1, #4).

**H-HEAD-malachite.** Recall: a tie, since both catch H3. B executed it, while A only states it with values. Additional real findings: the same six-item numeric core in both (precision clamp, approximate zero, approximate integers, roots, quotient/sum bounds, `//` width). A adds three runtime bugs: trivial bases with a huge exponent, a stack overflow when dropping a deep tree (crash-level), and the `lcm` width. B adds one runtime-adjacent bug (unchecked `Context.digits`) plus five test and structure findings. A is slightly ahead on bugs, B on tests and structure. Evidence: B is far better. It backs 6 of 11 findings with commands and failing output, plus a 246-input reference grid. A shows results in 10 of 12 findings but never the command, so 0 count as executed.

**H-bd7552e.** Recall: A is better by one step. It catches H2, naming the running job beside `Status` with the structural fix, and notes that `measuring` outlives its measurement. B only gets PARTIAL, for the point bug that `queued` is not cleared. Additional real findings: B is ahead. They overlap on five (stale queued job, restart loop, background warning, error position, failed cancel). B adds four runtime bugs of its own (old span on a local error, Render overwriting a Calc result, a history recall overwritten, cancel keeping the queued job) plus four cosmetic ones. A adds about one runtime bug (no worker means "starting" forever) and six lint, test and structure findings. All six spot checks are REAL. Evidence: A is clearly better, with 5 findings backed by failing tests (a Dioxus harness and hand mutants) against B's 0.

## Summary

1. Single-report cases: 25 known defects, 20 CAUGHT, 3 PARTIAL (D1, D2, D29), 2 MISSED (D20 chunk cut at the last frame, D25 part length against the 30-s limit).
2. Paired: A 6/2/2, B 8/1/1. B wins D-a8bec38 (4 caught against 1) and A wins H-bd7552e (CAUGHT against PARTIAL). D-918aa83 and H-HEAD-malachite are ties, D-918aa83 with different misses.
3. Precision: all 54 spot-checked findings outside the ground truth are REAL (one timing-dependent, one checked by reading only), and 12 of them re-find known defects of other cases.
4. Evidence: 78 of 287 findings have an executed test, and none is unsupported. Six reports executed nothing: D-a8bec38 A and B, D-918aa83 A, D-45f85c7 A, H-bd7552e B and H-HEAD-malachite A.
5. In each pair one report is long and structured, the other short prose, and the labels do not map to one setup. Prose had slightly better known-defect recall (8 against 6 caught). Structured had far better evidence (16 against 0 executed).

## Key to the labels

Added after scoring; the judge did not have it.

| Case | A | B |
| --- | --- | --- |
| D-a8bec38 | rostfrei | plain |
| D-918aa83 | plain | rostfrei |
| H-HEAD-malachite | plain | rostfrei |
| H-bd7552e | rostfrei | plain |
| every other case | rostfrei | – |
