-- newbook database schema (see SCHEMA.md for the meaning of every column)
CREATE TABLE records (
    id    INTEGER PRIMARY KEY,
    kind  TEXT    NOT NULL CHECK (kind IN ('person', 'org', 'event', 'task', 'note')),
    rev   INTEGER NOT NULL
);
CREATE TABLE people (
    id        INTEGER PRIMARY KEY REFERENCES records(id),
    name      TEXT,
    phone     TEXT,
    birthday  TEXT,
    org_id    INTEGER
);
CREATE TABLE person_emails (
    person_id INTEGER NOT NULL,
    pos       INTEGER NOT NULL,
    email     TEXT    NOT NULL,
    PRIMARY KEY (person_id, pos)
);
CREATE TABLE orgs (
    id        INTEGER PRIMARY KEY REFERENCES records(id),
    name      TEXT,
    website   TEXT,
    address   TEXT,
    parent_id INTEGER
);
CREATE TABLE events (
    id             INTEGER PRIMARY KEY REFERENCES records(id),
    title          TEXT,
    start_local    TEXT    NOT NULL,
    utc_offset_min INTEGER NOT NULL,
    duration_min   INTEGER NOT NULL,
    location       TEXT,
    freq           TEXT CHECK (freq IN ('daily', 'weekly', 'monthly', 'yearly')),
    interval       INTEGER,
    count          INTEGER,
    until          TEXT
);
CREATE TABLE event_exceptions (
    event_id INTEGER NOT NULL,
    date     TEXT    NOT NULL,
    PRIMARY KEY (event_id, date)
);
CREATE TABLE event_attendees (
    event_id  INTEGER NOT NULL,
    pos       INTEGER NOT NULL,
    person_id INTEGER NOT NULL,
    PRIMARY KEY (event_id, pos)
);
CREATE TABLE tasks (
    id        INTEGER PRIMARY KEY REFERENCES records(id),
    title     TEXT,
    due       TEXT,
    priority  INTEGER NOT NULL,
    done      INTEGER NOT NULL,
    person_id INTEGER
);
CREATE TABLE notes (
    id    INTEGER PRIMARY KEY REFERENCES records(id),
    title TEXT,
    body  TEXT
);
CREATE TABLE note_links (
    note_id   INTEGER NOT NULL,
    pos       INTEGER NOT NULL,
    target_id INTEGER NOT NULL,
    PRIMARY KEY (note_id, pos)
);
CREATE TABLE attachments (
    owner_id INTEGER NOT NULL,
    pos      INTEGER NOT NULL,
    filename TEXT    NOT NULL,
    mime     TEXT    NOT NULL,
    size     INTEGER,
    sha256   TEXT,
    data     BLOB,
    PRIMARY KEY (owner_id, pos)
);
CREATE TABLE history (
    record_id INTEGER NOT NULL,
    rev       INTEGER NOT NULL,
    PRIMARY KEY (record_id, rev)
);
CREATE TABLE deleted (
    record_id INTEGER PRIMARY KEY,
    kind      TEXT    NOT NULL,
    rev       INTEGER NOT NULL
);
CREATE TABLE import_issues (
    file   TEXT NOT NULL,
    reason TEXT NOT NULL
);
