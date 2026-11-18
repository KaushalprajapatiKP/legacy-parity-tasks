# oldbook 3.4 user guide

oldbook keeps contacts, organisations, calendar entries, tasks and notes.

## Data

oldbook reads every `*.obk` file in its data directory (default
`/data/legacy`, or the directory in `OLDBOOK_DATA`, or `-d DIR`). Several
machines synchronised into the same directory over the years, so one record can
have been saved in more than one file. Each record has a number (`#123`) and a
revision; oldbook always shows the current state of a record. Deleted records
are remembered.

A store file that fails oldbook's integrity check is skipped with a warning on
standard error, and nothing in it is used.

## Commands

    oldbook [-d DIR] list                 live records
    oldbook [-d DIR] list --deleted       deleted records
    oldbook [-d DIR] show ID              one record
    oldbook [-d DIR] show ID --history    the revisions oldbook has of a record
    oldbook [-d DIR] show ID --attachment N
                                          write attachment N (from 1) to stdout
    oldbook [-d DIR] search TEXT          case-insensitive search
    oldbook [-d DIR] agenda FROM TO       calendar between two dates (YYYY-MM-DD,
                                          inclusive), recurring entries expanded
    oldbook [-d DIR] export-csv           CSV export of live records
    oldbook version

Record kinds: person, org, event, recurring (a repeating event), task, note.

## Known issues

- `export-csv` is lossy: it leaves out many fields, shortens long text and
  damages non-ASCII characters. A nightly job writes it to `export.csv` in the
  data directory.
