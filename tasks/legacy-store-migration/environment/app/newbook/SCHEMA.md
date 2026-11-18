# newbook database

newbook keeps everything in one SQLite file. The tables are created by
`schema.sql` in this directory (use it as is; do not add, drop or rename
columns). This document says what each column holds. When the data comes from
oldbook, "as oldbook shows it" means the value printed by `oldbook show`.

## General rules

- Text is stored as UTF-8 exactly as oldbook shows it. Multi-line values
  (an org address, a note body) use a single `\n` between lines, with no
  trailing newline. oldbook prints the second and later lines of such a value
  prefixed by `  | `; that prefix is display only and is not part of the value.
- A field that a record does not have is stored as NULL (never as an empty
  string or a placeholder).
- Calendar dates are `YYYY-MM-DD`. A local date and time is `YYYY-MM-DD HH:MM`.
- Every id is the record number oldbook prints after `#`.

## records

One row per live record (a record oldbook lists with `oldbook list`).
`kind` is one of `person`, `org`, `event`, `task`, `note`; oldbook's recurring
events are kind `event`. `rev` is the revision oldbook currently shows.

## people, person_emails

`people`: `name`, `phone`, `birthday` (a date), `org_id`.
`person_emails`: one row per e-mail address, `pos` counting from 0 in the order
oldbook shows them.

## orgs

`name`, `website`, `address` (multi-line), `parent_id`.

## events, event_exceptions, event_attendees

`title`, `location` as shown. `start_local` is the local start date and time and
`utc_offset_min` the UTC offset of that local time in minutes (east of UTC is
positive, so `+05:30` is 330 and `-03:30` is -210). `duration_min` is the length
of the event in minutes (the difference between the End and Start that oldbook
shows).

For a recurring event, `freq` is one of `daily`, `weekly`, `monthly`, `yearly`,
`interval` is the step between occurrences in units of `freq` (at least 1),
`count` is the number of occurrences or NULL when not limited by a count, and
`until` is the last allowed date or NULL. Each excepted date is a row in
`event_exceptions`. For a one-off event `freq`, `interval`, `count` and `until`
are all NULL and there are no exception rows.

`event_attendees` holds the attendees in the order oldbook shows them, `pos`
counting from 0.

## tasks

`title`, `due` (a date). `priority` is 0 for none, 1 for low, 2 for normal and
3 for high. `done` is 1 when the task is done, otherwise 0. `person_id` is the
related person.

## notes, note_links

`title`, `body` (multi-line). `note_links` holds the linked records in the
order oldbook shows them, `pos` counting from 0.

## References

`org_id`, `parent_id`, `person_id`, attendees and note links refer to other
records by id. A reference is kept only when it points at a live record. A
single reference to anything else (oldbook shows it as `(unavailable)`) is
stored as NULL. In a list (attendees, note links) such entries are left out and
the remaining entries are numbered 0, 1, 2, ... in their shown order.

## attachments

One row per attachment, in the order oldbook shows them, `pos` counting from 0
within the owning record. `filename` and `mime` as shown. When the content is
available, `data` holds the exact bytes, `size` their length and `sha256` the
lowercase hex SHA-256 of `data`. When oldbook reports the data as unavailable,
`size`, `sha256` and `data` are NULL.

## history

One row `(record_id, rev)` for every revision of a record's content that oldbook
still has but does not currently show, for live and for deleted records alike.
Deletion markers are not content revisions and never appear here.

## deleted

One row per record whose current state in oldbook is deleted (listed by
`oldbook list --deleted`). `rev` is the revision of the deletion and `kind` is
the kind of the record's content before it was deleted (recurring events are
`event`).

## import_issues

One row per legacy store file that oldbook refuses to read: `file` is the file
name without directory, `reason` is `checksum` when the file fails its
integrity check and `format` for any other refusal. Nothing from such a file is
imported.
