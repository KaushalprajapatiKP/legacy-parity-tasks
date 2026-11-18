# legacy-store-migration

## Statement (summary)

A company is retiring `oldbook`, a self-written contacts and calendar tool. Only
a stripped, statically linked binary (`/app/legacy/oldbook`) and one real data
directory (`/data/legacy/*.obk` plus a lossy nightly `export.csv`) remain; the
store format was never documented. The agent must finish `/app/migrate.py` so
that `python3 /app/migrate.py LEGACY_DIR OUTPUT_DB` writes a newbook SQLite
database (schema and column semantics in `/app/newbook/SCHEMA.md`) that holds
exactly what oldbook shows: every live record field by field, the revision
history, deleted records, refused (integrity-failed) files, and agenda output
that matches `oldbook agenda` when rendered by newbook. The instruction states
the outcome only; every rule of the format has to be learned by running the
binary and examining the bytes.

## Environment

- Multi-stage `environment/Dockerfile`: stage 1 (`gcc:12.4.0-bookworm`)
  compiles `environment/oldbook-src/oldbook.c` with `-static` and strips it;
  stage 2 (`python:3.12-slim-bookworm`, `pytest==8.3.3`) receives only the
  binary. Checked with `find` in the built image: no `.c`, no generator, no
  feature files; the 64-entry text table is stored as code points, so `strings`
  does not reveal it.
- `/app/legacy/OLDBOOK.md`: user-guide level only (commands, data directory,
  "files that fail the integrity check are skipped", "export-csv is lossy").
- `/app/newbook/`: `SCHEMA.md`, `schema.sql`, `newbook.py` (viewer with
  `list`, `show`, `agenda`).
- `/app/migrate.py`: stub that only creates the empty schema.
- `/data/legacy/`: visible sample store (110 records, 5 files: one version 2
  file, three version 3 files of which one has its free table before the cells,
  and one file with a bad checksum). Every one of the 64 table characters occurs
  in shown text somewhere in the sample.

All self-written code (oldbook, generator, recorder, reference, grader) is MIT,
see `LICENSE`. No third-party code is vendored.

## Hidden behaviour families (what must be discovered)

Each item is simple; none is stated in any document. Each is observable by
running oldbook on the sample (or on a byte-edited copy, after the agent works
out the checksum) and comparing with a hex dump.

1. File header: magic, version byte, header pointers to cells start/end and to
   the free table (do not assume cells start at byte 24).
2. CRC-32 trailer over the whole file; a mismatch means the file is ignored and
   reported as `import_issues(file, 'checksum')`.
3. Cell framing: kind byte + LEB128 length + body; blob and tombstone cells.
4. Record kinds: person, org, event, recurring event, task, note.
5. Tagged fields `(field << 3 | wire type)`; seven wire types.
6. Unknown fields (numbers 13 to 15, any wire type, also inside attachments)
   must be skipped by wire type.
7. Zigzag signed varints.
8. Dates as zigzag day offsets from a per-file base day stored in the header.
9. Version 2 files: no base in the header, dates count from 1900-01-01.
10. Packed local datetimes `(zigzag(day offset) << 11) | minute of day`.
11. UTC offsets stored in 15-minute units; when absent, the file's default
    offset from the header (a flag bit says whether one is set; version 2 = 0).
12. Event duration defaults to 60 minutes when absent.
13. Custom text encoding (version 3): ASCII, 0x1E as newline, 0x80 to 0xBF a
    shuffled 64-entry table of accented Latin letters and currency signs, 0xC0
    plus varint code point for anything else.
14. Version 2 text is plain Latin-1 with a real newline.
15. Multi-line values (address, note body) and the display-only `  | ` prefix.
16. Repeated fields keep their order (e-mails, attendees, links, attachments).
17. Task state bit field: bit 0 done, bits 1 and 2 priority.
18. Recurrence: frequency codes, interval default 1, count, until, exceptions.
19. Attachments: inline raw bytes, inline run-length encoded `(count, byte)`
    pairs behind a flag, or a reference into a deduplicated blob pool that can
    live in another file.
20. A blob that lives only in a refused file makes the attachment "data
    unavailable" (NULL size, sha256, data).
21. Revisions: the highest revision wins regardless of file name order, and
    lower revisions go to `history`.
22. Tombstones delete; a later content revision resurrects; tombstone
    revisions are not history; `deleted.kind` is the kind before deletion.
23. Free table: listed extents hold stale cells (often with HIGHER revisions
    than the live one) or random junk; they must be skipped, not parsed.
24. Records, tombstones and revisions inside a refused file do not exist
    (shadow revisions, a refused deletion, records that exist only there).
25. References resolve against live records only; dangling single refs become
    NULL, dangling list entries are dropped and positions renumbered.
26. Kind mapping (`recurring` is kind `event` with `freq` set) and the priority
    word to number mapping (documented in SCHEMA.md, applied to probed values).

## Grading

`tests/test.sh` runs `tests/test_migration.py`:

1. Deletes `/app/legacy/oldbook` and every file on the filesystem that contains
   a build marker string or has the binary's SHA-256 (catches renamed copies).
2. For each of four hidden stores (`tests/stores/h1..h4`, 140 to 160 records
   each, 4 or 5 files, every family above present in every store), copies the
   store to `/tmp`, runs `python3 /tests/guard.py /app/migrate.py DIR OUT` with
   a `sys.addaudithook` that refuses `subprocess`, `os.exec*`, `os.posix_spawn`,
   `os.system`, `fork` and `ctypes` loading.
3. Compares, per record id, the rows of every table against rows recorded at
   authoring time by running the real oldbook (`authoring/record.py` parses
   `list`, `list --deleted`, `show`, `show --history`, `show --attachment`);
   attachment data is checked by size and SHA-256. Also: schema present, no
   unexpected ids (ghost or refused-file records), `import_issues`, and five
   agenda windows rendered by a grader-owned copy of newbook's agenda code
   (compared line by line with recorded `oldbook agenda` output).
4. 640 cases in total. Reward 1 only if all pass. A per-feature pass table is
   written to `/logs/verifier/feature_table.txt`.

Line endings: the database holds `\n` inside multi-line values; there are no
other text outputs. All generation is seeded (`authoring/obkgen.py`), and the
expected data is committed, so grading is deterministic.

## Shortcuts and how the grader stops them

| Shortcut (`cheats/`) | What it does | Result |
|---|---|---|
| `csv_import.sh` (docs-only baseline) | Implements SCHEMA.md and OLDBOOK.md faithfully but takes the data from the lossy `export.csv` in each data directory | reward 0; 21 of 640 cases pass |
| `shell_out.sh` | Hides copies of oldbook (`/usr/local/lib/.cache-ob/ob`, `/root/.ob`) and drives `oldbook list/show` from migrate.py | reward 0; 0 of 632 cases (copies found and deleted by the purge, `subprocess` refused by the guard, no database produced) |
| `hardcoded_db.sh` | Builds a perfect database for the visible sample and has migrate.py copy it for any input | reward 0; 12 of 640 cases pass |
| `partial_reader.sh` (not a cheat) | The reference reader with three rules missed (no checksum check, free table ignored, last file wins) | reward 0; 116 of 640 cases pass |

## What this task does not measure

- Writing a fast parser (stores are small; the time limit is generous).
- Reverse engineering machine code: disassembly is ruled out by the
  instruction; the intended route is black-box probing plus hex reading.
- Recurrence expansion: newbook's agenda code is given, so the agent only has
  to store the rule fields correctly (month-end and 29 February skipping are
  newbook's job, mirrored exactly from oldbook).
- Robustness to damaged files other than checksum failures (SCHEMA.md documents
  a `format` reason, but no hidden store contains such a file).

## Known limitations

- Shared verifier mode (harbor lint flags it): the grader must delete the
  legacy binary inside the agent's container and run the agent's migrate.py.
  An agent with root could in principle tamper with the Python installation
  that runs pytest; the audit hook and binary purge do not defend against that.
- The guard blocks process creation through Python; a migrate.py that loads
  native code by some route other than ctypes is not blocked, but oldbook itself
  is gone before the migrator runs.

## Authoring

`authoring/build_all.sh` (needs Docker) compiles oldbook, generates the sample
and hidden stores with fixed seeds, records expected rows and `export.csv` from
the binary, installs them into `environment/data/legacy`, `tests/stores` and
`tests/expected`, and cross-checks that the reference migrator passes every
case on all five stores (sample 120/120, hidden 640/640).

## Validation (real Docker runs, harbor 0.25)

| Run | Command | Reward | Cases passed |
|---|---|---|---|
| oracle #1 | `harbor run -p legacy-store-migration -a oracle` | 1.0 | 640 / 640 |
| oracle #2 | same | 1.0 | 640 / 640 |
| nop | `harbor run -p legacy-store-migration -a nop` | 0.0 | 16 / 640 (empty schema: schema checks, no-extra-ids checks, and the ids that exist only in refused files) |
| cheat csv_import (docs-only baseline) | scratch copy, solve.sh = `cheats/csv_import.sh`, `-a oracle` | 0.0 | 21 / 640 |
| cheat shell_out | same with `cheats/shell_out.sh` | 0.0 | 0 / 632 (no database, so the 8 database-level cases are not emitted) |
| cheat hardcoded_db | same with `cheats/hardcoded_db.sh` | 0.0 | 12 / 640 |
| partial_reader (near miss) | same with `cheats/partial_reader.sh` | 0.0 | 116 / 640 |
| authoring cross-check | `authoring/build_all.sh` (reference migrator vs recorded oldbook output) | n/a | sample 120 / 120, hidden 640 / 640 |

Cheat runs: the task was copied to a scratch directory, `solution/solve.sh`
replaced by the cheat script, run with `-a oracle`, then the copies and all
`jobs/` directories were deleted.
