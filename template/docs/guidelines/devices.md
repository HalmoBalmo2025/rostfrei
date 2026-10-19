# Hardware, devices and network peers

Read this before talking to hardware, a device over a network or serial
link, or any peer whose behaviour you only learn by trying.

## Learn by experiment, keep what you learn

- Write down every finding in `docs/` (one file per device): what was sent,
  what happened, how it was observed, which firmware or version. Measured
  limits and timings go there too, with the date.
- Keep the experiment tools (small binaries under `examples/` or `tools/`)
  so a finding can be checked again after a firmware update.
- Turn each finding into a flow test against a fake device that behaves the
  way the experiment showed, including its odd behaviour.

## Talking to it

- Every message to the device is typed (enum of commands), every answer is
  parsed at the boundary into a typed reply; unknown answers are an error
  with the raw bytes logged (they are not user content).
- Byte order is explicit (`to_be_bytes`/`to_le_bytes`); `host_endian_bytes`
  is forbidden.
- Every operation in flight when the connection drops ends explicitly: done,
  to be repeated, or dropped (`concurrency.md`). After reconnecting, state
  is read back from the device, not assumed.
- A device that echoes your own writes back: tell echoes from real changes
  by value or by a sequence or operation id. A time window ("ignore changes
  for 2 s after a write") only if the device offers nothing else, as a named
  constant documented in the device notes.
- Retries follow `concurrency.md`: growing pause, a limit, fail fast after.

## Tests

- The fake device can drop the connection at any point, answer late, answer
  twice, echo, and send unsolicited changes. Flow tests cover each.
