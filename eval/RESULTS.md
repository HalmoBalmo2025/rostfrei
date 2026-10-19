# Results (rostfrei 1.0.0, October 2026)

The method is in `README.md` and the full scoring in `scores.md`. In short:
the review finds most real bugs, almost never reports a false one, and
proves far more of what it reports than a plain review does. It does not
find more of the known bugs than a plain review does. The two find
*different* bugs, so 1.1.0 runs both kinds.

## Recall: the 35 known defects

| Case | Defects | Caught | Partial | Missed |
| --- | --- | --- | --- | --- |
| D-c22da25 | 2 | 0 | 2 (D1, D2) | 0 |
| D-c98e2bf | 2 | 2 | 0 | 0 |
| D-7f582e3 | 2 | 2 | 0 | 0 |
| D-a8bec38 | 4 | 1 | 2 (D9, D10) | 1 (D7) |
| D-2638e4a | 2 | 2 | 0 | 0 |
| D-918aa83 | 4 | 3 | 0 | 1 (D16) |
| D-ccf2eeb | 5 | 4 | 0 | 1 (D20) |
| D-45f85c7 | 3 | 3 | 0 | 0 |
| D-8fcb7c3 | 2 | 1 | 0 | 1 (D25) |
| D-HEAD | 4 | 3 | 1 (D29) | 0 |
| H-b1edad2 | 1 | 1 | 0 | 0 |
| H-bd7552e | 1 | 1 | 0 | 0 |
| H-HEAD-malachite | 1 | 1 | 0 | 0 |
| H-HEAD-nh4no3 | 2 | 2 | 0 | 0 |
| **all** | **35** | **26 (74 %)** | **5** | **4** |

Caught or partial: 31 of 35 (89 %). The aim was 80 % caught, so it was
missed.

Among the caught defects are all four bugs that were still open in the two
projects:
- dictated text thrown away when the microphone fails mid-dictation (D27);
- the panel setting read per part instead of once per dictation (D28);
- timeouts that do not reach grandchild processes (D30), proven by a test:
  5.005 s against a 100 ms limit;
- `sqrt(2) * sqrt(2) // 1` giving 1 with 48 "reliable" places (H3).

## Against a plain review (4 cases)

| Case | rostfrei caught / partial / missed | plain caught / partial / missed |
| --- | --- | --- |
| D-a8bec38 | 1 / 2 / 1 | 4 / 0 / 0 |
| D-918aa83 | 3 / 0 / 1 (D16) | 3 / 0 / 1 (D15) |
| H-HEAD-malachite | 1 / 0 / 0 | 1 / 0 / 0 |
| H-bd7552e | 1 / 0 / 0 | 0 / 1 / 0 |
| **all** | **6 / 2 / 2** | **8 / 1 / 1** |

| Evidence in these 4 cases | rostfrei | plain |
| --- | --- | --- |
| findings with an executed test | 16 | 0 |

- The plain review caught slightly more known defects (8 against 6). Its
  advantage came from one case, D-a8bec38.
- The rostfrei review proved its findings: 16 executed tests against none.
  In H-HEAD-malachite, its tests also confirmed claims the plain review
  had only asserted.
- They missed different defects: in D-918aa83 each caught the one the
  other missed. **Together they caught all 10.**

## Precision and evidence

- 54 of 54 spot-checked findings outside the known defects were real. One
  depends on timing, and one was confirmed by reading only. 12 of them were
  known defects of other cases that were still open in that snapshot.
- 287 findings in all reports: 78 backed by an executed test, 209 by
  quotes with `path:line`, none by nothing. The 226 rostfrei findings
  include all 78 executed ones.
- Two rostfrei reports executed nothing (D-a8bec38, D-45f85c7): macOS
  controller code that does not build here.

## Why defects were missed, and what 1.1.0 changes

| Defect | Why it was missed | Change in 1.1.0 |
| --- | --- | --- |
| D9, D10 (a request without a reply, a result credited to the wrong request) | Seen, but filed as a question, because no path reached them yet | Latent defects are klein findings with quotes as evidence. `/ship` settles questions itself before the user sees them |
| D7 (text never pasted when the polish worker is gone) | Fallback path not followed | Checklist: does every fallback deliver what the main path delivers? Plus a `free` reviewer that follows the user's paths |
| D16 (`try_wait()?` leaks a started server) | Read as "untested path", not as a leak | Checklist: a `?` between starting a resource and handing it to its guard |
| D20 (a cut can land in the last, incomplete frame) | The fallback looked like dead code | Checklist: compute the extreme combination (last partial chunk, final frame) |
| D25 (parts up to 5 × 60 s, the model takes 30 s) | Constants checked one by one, not multiplied | Same checklist entry: largest setting times its factor, against the limit it feeds |
| D1, D2, D29 (partial) | Right place, wrong consequence (lost notification instead of GPU abort) | None. The finding led to the right fix either way |
| No executed evidence in two reports | The code needs macOS | The reviewer copies the modules unchanged into a scratch crate (`#[path]`) with stand-ins for the platform |

The `free` reviewer works like the plain review, with the rostfrei
evidence rules. The two kinds of review caught all ten defects together,
which is the reason for running both. That 1.1.0 catches more is an
expectation, not a measurement. The checklist now names these exact
misses, so rerunning the same cases would flatter it (`README.md`,
Limits).
