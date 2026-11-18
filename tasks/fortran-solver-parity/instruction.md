HYDRO is a FORTRAN 77 program that computes steady flows and heads in water pipe networks. It reads an input deck on standard input and writes a report on standard output.

Production runs HYDRO 2.3. Only the stripped production executable survives, at `/app/prod/hydro`. The newest source that still exists is HYDRO 1.8, in `/app/src`. Documentation is in `/app/docs`: the 1.8 user manual and the 2.3 release notes. A few sample decks are in `/app/examples`.

Update the Fortran source in `/app/src` so that the program built from it behaves exactly like production 2.3, for any input deck that 2.3 accepts or rejects.

How your work is checked:

- The contents of `/app/src` are copied to a new directory and built there with exactly `gfortran -O2 -o hydro *.f` (GNU Fortran 12, as installed). Only files ending in `.f` are compiled; files they `INCLUDE` must also be in `/app/src`.
- `/app/prod` is deleted before the program is run, and any copy of the production executable found elsewhere fails the check. The production executable may only be used by running it on input decks. Do not disassemble, decompile, or copy it.
- The source must not use `EXECUTE_COMMAND_LINE`, `SYSTEM`, `BIND`, `ISO_C_BINDING`, or any other way of starting processes or calling C (`EXEC*`, `POPEN`, `FORK`, `DLOPEN`, `DLSYM`), even in dead code. Comments and character constants are not checked.
- Several hundred hidden decks are run, covering everything 2.3 does: all card types and options, both unit systems, both friction laws, time steps, input errors, warnings, unusual networks, and solver control. Each was recorded from production 2.3. All of them must match.
- For each deck, standard output and the process exit status are compared. Standard error is ignored.
- Output comparison: trailing whitespace on each line and trailing empty lines are ignored. Otherwise the number of lines and the length of every line must be identical, and the blank-separated tokens of each line must be identical, with one exception: a number written with a decimal point must show the same number of digits after the point, and may differ from production by at most one unit in its last digit. Integers, codes and all text must match exactly.

The program must keep reading the deck from standard input and writing the report to standard output.
