We are retiring `oldbook`, an in-house contacts and calendar tool, and moving
everyone to `newbook`. You own the data migration.

What you have:

- `/app/legacy/oldbook`: the old tool (user guide: `/app/legacy/OLDBOOK.md`).
  Its source code is gone and its store format was never documented.
- `/data/legacy/`: a copy of one real oldbook data directory.
- `/app/newbook/`: the new tool. `SCHEMA.md` describes its SQLite database,
  `schema.sql` creates it, and `newbook.py` is its viewer.
- `/app/migrate.py`: the migrator, which so far only creates an empty database.

Finish `/app/migrate.py` so that

    python3 /app/migrate.py LEGACY_DIR OUTPUT_DB

reads the oldbook data directory `LEGACY_DIR` and writes a newbook database to
`OUTPUT_DB` (replacing any existing file and creating missing parent
directories). The result must hold exactly what oldbook itself shows for that
directory, in the form `SCHEMA.md` describes:

- every live record, with every field as `oldbook show` prints it;
- the revision history and the deleted records, as `SCHEMA.md` says;
- one `import_issues` row for each store file that oldbook refuses to read;
- for any date range, `python3 /app/newbook/newbook.py OUTPUT_DB agenda FROM TO`
  prints the same lines as `oldbook agenda FROM TO` on the original directory.

Treat what oldbook prints as the truth. Learn the store format by running
oldbook and by examining the data files. Do not disassemble, decompile, trace
or copy the oldbook binary. The `export.csv` that oldbook writes into its data
directory is known to be lossy (it drops fields, shortens text and damages
non-ASCII characters), so it is not a usable source.

How it will be checked: oldbook is deleted first. Your migrator is then run on
several other oldbook data directories written by the same oldbook version.
They hold different records but the same kinds of data, including files that
fail the integrity check. Each resulting database is compared with what oldbook
showed for that directory: every live and deleted record, the history, the
import issues, and several agenda ranges. Every check must pass. The migrator
must use only the Python 3.12 standard library, run in one process (starting
other programs is refused during grading), and finish within 5 minutes per
directory.
