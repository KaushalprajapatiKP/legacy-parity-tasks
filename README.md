# Legacy parity tasks

Three Terminal-Bench style tasks in Harbor format about keeping old software alive:

- two **language-driven** tasks in legacy languages (COBOL and Fortran 77), where only an old
  version of the source survives and the code must be brought up to what production does;
- one **outcome-driven** task that states only the goal: migrate a retired tool's undocumented
  data store into a documented SQLite schema.

In every task the truth lives in a compiled, stripped production program the agent can run
but not read. The docs are user-guide level, release notes are vague on purpose, and the
hidden suites are recorded from the production program, which is deleted before grading.

Author: Kaushal Prajapati (kaushalprajapati5296@gmail.com). Tools used: see [TOOLS.md](TOOLS.md).

## Tasks

| Task | Kind | Statement in one line | Hidden suite | Docs-only baseline |
|---|---|---|---|---|
| [`cobol-production-parity`](tasks/cobol-production-parity) | language-driven (GnuCOBOL 3) | Only the 3.7 source of a COBOL billing batch survived; update it so the build matches production 4.2 byte for byte | 480 input sets in 12 categories, 3 reports plus return code | 2 / 480 |
| [`fortran-solver-parity`](tasks/fortran-solver-parity) | language-driven (gfortran 12, FORTRAN 77) | Only the 1.8 source of a pipe-network solver survived; make it reproduce production 2.3 (text exact, numbers within a stated tolerance) | 353 decks in 13 categories | 0 / 353 |
| [`legacy-store-migration`](tasks/legacy-store-migration) | outcome-driven | Migrate every record of a retired contacts and calendar tool into the new app's SQLite schema exactly as the old tool shows it | 640 cases over 4 hidden stores, 30+ feature checks | CSV-export import: 21 / 640 |

Each task needs real work before probing even starts: the old COBOL and Fortran sources do not
build on the current toolchain, and the migration needs the store format worked out from the
binary.

## Environment, statement and difficulty note

Each task folder follows the same format:

- `instruction.md`: the statement the agent sees.
- `environment/Dockerfile`: pinned toolchain; production is compiled in a separate build stage
  and only the stripped binary reaches the agent image.
- `task.toml`: difficulty explanation, solution explanation, verification explanation, timeouts.
- `README.md`: the hidden behaviour families, the shortcuts and how the grader stops them,
  and the validation table.

## Validation (real Docker runs with Harbor 0.25)

Every task: reference solution scores 1 on two runs, a no-op agent scores 0, and every
shortcut in `cheats/` scores 0. The COBOL and Fortran tasks were also checked with single-change
mutants of the production source (54 and 26 mutants); every mutant is caught by the suite.

## Agent trajectories

`trajectories/<task>/` holds one cold attempt per task by a strong coding agent working inside
the task container, graded by the task's own verifier:

| Task | Tool calls | Reward | Result |
|---|---|---|---|
| cobol-production-parity | 83 | 1 | 480 / 480 input sets |
| fortran-solver-parity | 235 | 0 | 352 / 353 decks; missed the error for more than 12 patterns |
| legacy-store-migration | 72 | 1 | 640 / 640 cases |

`trajectory.md` is the run (prompt, commands, truncated outputs). `grading.txt` is the
verifier output. One run per task is a length and difficulty signal, not a pass rate.

## Running a task

```bash
pip install harbor            # or uv tool install harbor
harbor run -p tasks/cobol-production-parity -a oracle   # expect reward 1
harbor run -p tasks/cobol-production-parity -a nop      # expect reward 0
```

To check a shortcut, copy the task, replace `solution/solve.sh` with a script from `cheats/`,
and run the oracle agent on the copy; it should score 0.

## Shortcuts the graders stop (examples)

- **Calling production from the new code** (COBOL `CALL "SYSTEM"`, Fortran
  `EXECUTE_COMMAND_LINE`, Python subprocess): source scans, an audit hook, and deletion of the
  production binary and any copy of it by hash.
- **Hardcoding sample outputs:** the hidden inputs are different from every visible sample.
- **Fixing only the build:** the old behaviour fails nearly every hidden case.
- **Importing the lossy CSV export** in the migration task: 21 / 640.

## Known limitations

- Validation ran on arm64 (Docker on Apple silicon). The Fortran task grades iteration counts
  exactly; this held across four compiler settings, but not on native x86-64.
- `strings` on the production binaries can reveal message texts, though not constants or
  rounding rules.
- The hidden suites are in this public repository, so these copies should not be used to score
  models that may have been trained on them.
