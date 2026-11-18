# Bring the billing batch source back to production parity

BILLRUN is a COBOL batch program that bills one cycle of customer accounts. Production runs version 4.2, installed at `/app/prod/billrun`. The 4.2 source has been lost. `/app/src` holds the last surviving source, version 3.7. `/app/docs` has the 3.7 user guide and the 4.2 release notes, and `/app/samples` has an example input set.

Update the source in `/app/src` so that the program built with

```
cd /app/src && cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl
```

behaves exactly like production 4.2.

## Requirements

1. For any input set in the record formats documented in `/app/docs`, with valid or invalid field values, the built program, run with the input set in its current working directory, must write `STATEMENTS.RPT`, `REJECTS.RPT` and `SUMMARY.RPT` byte-identical to the files production 4.2 writes for the same input, and must exit with the same return code. Graded input sets contain a `CONTROL.DAT`, an `ACCOUNTS.DAT` and an `ACTIVITY.DAT`, with at most 50 accounts and 200 activity records, lines of at most 80 characters and LF line endings.
2. Production 4.2 is the reference for its own behaviour. You may run it as often as you like on inputs you create. Treat it as execute-only: do not disassemble, decompile, dump, read or copy the binary.
3. The program must compute its outputs itself:
   - it may only open the six documented files, assigned by their literal names (`CONTROL.DAT`, `ACCOUNTS.DAT`, `ACTIVITY.DAT`, `STATEMENTS.RPT`, `REJECTS.RPT`, `SUMMARY.RPT`);
   - every `CALL` must name, as a literal, a program whose source is in `/app/src`;
   - no `SYSTEM`, `C$` or `CBL_` routines, `CHAIN`, `EXEC`, or procedure, program or function pointers.
4. Keep the build layout: main program `billrun.cbl`, subprograms in `/app/src/lib/*.cbl`, copybooks in `/app/src/copy`. Do not modify the compiler, toolchain or runtime configuration.

## Grading

The grader removes `/app/prod/billrun` and any copy of it, builds `/app/src` with the command above, replays several hundred hidden input sets that were recorded from production 4.2, and compares the three report files and the return code byte for byte. Every input set must match.
