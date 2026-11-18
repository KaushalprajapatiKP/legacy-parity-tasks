#!/usr/bin/env python3
"""Migrate an oldbook data directory into a newbook database.

Usage: python3 /app/migrate.py LEGACY_DIR OUTPUT_DB
"""
import os
import sqlite3
import sys

SCHEMA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "newbook", "schema.sql")


def main(legacy_dir, out_db):
    if os.path.exists(out_db):
        os.remove(out_db)
    os.makedirs(os.path.dirname(os.path.abspath(out_db)), exist_ok=True)
    conn = sqlite3.connect(out_db)
    with open(SCHEMA) as fh:
        conn.executescript(fh.read())
    # TODO: read the legacy store and fill the tables.
    conn.commit()
    conn.close()


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
