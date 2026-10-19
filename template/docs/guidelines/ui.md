# User interfaces

Read this before changing any user interface: native, web or terminal.

## State

- What the UI shows is derived from the application state in one place
  after each change, not set and cleared at many call sites. A flag that is
  a function of the state (a key capture, a busy indicator, an enabled
  button) is computed, not stored.
- A choice shown before it is confirmed has an explicit pending state
  (`Pending { shown, previous, request }`). Confirmation replaces it,
  rejection or timeout reverts to `previous` and tells the user. Without the
  explicit state, optimism hides failures; without optimism, the UI flickers
  back to the old value.
- Settings take effect immediately where possible; the few that need a
  restart are listed in one place and the user is told.

## Input

- Input is parsed at the edge of the UI into typed values (`FromStr`,
  newtypes with ranges). Bad input is shown to the user as an error next to
  the field, never silently replaced by a default, the old value or zero.
- Limits enforced by a control (slider range, `min`/`max`) are enforced
  again by the type: correctness must not rely on the control alone.
- `f64::from_str` accepts `inf`, `NaN` and `1e400`; a parser for user
  numbers rejects non-finite values.

## Text and language

- Text shown to the user is in the product's language(s) and lives in one
  place per language; errors shown to the user have a user-facing text in
  every supported language, not `err.to_string()`.
- The UI never displays or logs user content it does not need to.

## Files the user owns

- Loading a file that fails to parse shows the error and keeps the file
  untouched; the UI then runs read-only for that data or with explicit
  defaults that are never saved over the user's file.
