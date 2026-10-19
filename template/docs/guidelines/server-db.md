# Servers, databases and data formats

Read this before adding a server, a database, a persisted file format, or a
format exchanged with another program.

## Choosing a data format

- Rust to Rust (fullstack, workspace crates): one shared types crate with
  serde; both sides compile against the same types.
- To another language: JSON with serde, typed on both sides, with shared
  fixture files (`processes.md`). `typeshare` can generate Swift or
  TypeScript types from the serde types.
- Protobuf only for independently deployed clients in a third language.
  proto3 has no required fields and cannot tell "unset" from `0` or `""`
  without `optional`: every presence check is hand-written. Field numbers
  are never reused.
- Binary formats only where both sides are built from the same commit
  (`postcard`). `bincode` is unmaintained (RUSTSEC-2025-0141).
- JavaScript loses precision above 2^53: send 64-bit ids as strings.

## Persisted data

- Every persisted format carries a version. Reading an unknown or newer
  version is an error that keeps the data untouched; it is never replaced
  by defaults and saved over.
- A test reads a committed fixture of every past version (`fixtures/v1.json`
  …), so old data stays readable.
- Writes are atomic: write a new file, then rename over the old one, in one
  file module.

## Databases

- SQL with a schema: the schema makes illegal states impossible
  (`NOT NULL`, `CHECK`, `UNIQUE`, foreign keys). SQLite for local data.
- `sqlx` with `query!`/`query_as!`: queries are checked against the schema
  at compile time. Commit `.sqlx/` (`cargo sqlx prepare`), check it in CI
  (`cargo sqlx prepare --check`), build with `SQLX_OFFLINE=true`.
- `rusqlite` for simple synchronous tools, with tests for every query.
- Migrations are files, applied in order, never edited after release.
- Several statements that belong together run in one transaction.

## Servers

- Handlers are idempotent where a client may retry; a request id makes a
  retry safe.
- A server builds with the `server-release` profile (`panic = "unwind"`), so
  a panic in one handler does not end the process; the panic is logged and
  turned into a 500.
- Inputs are parsed into types at the handler boundary; the rest of the code
  never sees raw strings from the network.
