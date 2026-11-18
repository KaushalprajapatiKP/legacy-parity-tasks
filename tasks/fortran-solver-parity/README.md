# fortran-solver-parity

## Statement (summary)

HYDRO is a self-written FORTRAN 77 pipe-network hydraulics program (MIT licence). Production runs
version 2.3, available only as a stripped executable at `/app/prod/hydro`. The surviving source in
`/app/src` is version 1.8 (about 980 lines in 8 files, COMMON blocks, an INCLUDE file). Docs in
`/app/docs` are the 1.8 user manual and a vague 2.3 release note. The agent must update the source
so that the program built with `gfortran -O2 -o hydro *.f` reproduces 2.3 for any deck: stdout text,
numbers within one unit of the last printed digit, and the exit status.

## Environment

- Base image `python:3.12.15-slim-bookworm`, `gfortran-12=12.2.0-14+deb12u1` (Debian bookworm),
  `pytest==8.3.4`. Image build takes about 3 minutes the first time.
- Multi-stage Dockerfile: stage `prodbuild` compiles the 2.3 source (`environment/prod-src/`) and
  strips it; only the executable is copied into the final image. Checked with
  `find / -xdev -name hydro.f -o -name fric.f -o -name solver.f -o -name prod-src` in the final
  image: no hits. The 2.3 source exists only in `environment/prod-src/` (build stage) and
  `solution/src/`.
- `/app/src` (1.8), `/app/docs`, `/app/examples` (3 easy SI decks), `/app/prod/hydro`.

## Difficulty

Cost to begin: the 1.8 tree does not build with the stated command. The failures appear in layers:
the INCLUDE names `HYDRO.INC` while the file is `hydro.inc` (fatal, hides everything else); then a
FORMAT statement that runs past column 72 is truncated (unterminated string), a LOGICAL compared with
`.EQ.`, and a REAL(8)/INTEGER argument mismatch in one file (all errors in gfortran 12 without
`-std=legacy`). Once it compiles, the friction-factor function is used without a DOUBLE PRECISION
declaration in the calling file, so it silently returns garbage and the first run stops with a
singular matrix.

After that, about thirty behaviour changes separate 1.8 from 2.3. The release notes only name the
areas; every value, text and rule below must be found by running the production executable.

Hidden behaviour families (each is simple, none is spelled out in the docs):

1. Banner and run-summary header (title, units, friction law, network counts, solver settings, steps).
2. 1.8 input echo, balance summary and "END OF RUN" removed.
3. Keywords case-insensitive; `!` inline comments; tabs; text after END ignored.
4. Links may name nodes defined later; undefined nodes reported after the whole deck is read, with
   the link's line number, after all card-level messages.
5. Numbered errors E101 to E113 and E302 with exact texts; checking continues after an error; abort
   line with the error count; one error per card with a fixed precedence (field count, id length,
   duplicate, capacity, self-loop, numbers, ranges).
6. Warnings W201 to W210 with exact texts and fixed placement (input warnings inline, W204 after the
   header in node-name order, hydraulic warnings after the totals of each step).
7. Identifier length 8 (E106), duplicate ids (E102), title length 60.
8. Option validation: TOL > 0, MAXIT integer >= 1, MAXIT above 200 clamped with W206, STEPS 1..24,
   HSTEP in (0, 24], FRICTION DW/HW, unknown option names now errors (METHOD retired).
9. UNITS US: ft, in, gpm, milli-feet roughness, psi; exact conversion factors.
10. Pressure column in kPa (factor 9.79 per m) or psi (0.4335 per ft) with different decimals.
11. Friction: Swamee-Jain above Re 4000, linear blend from 0.032 at Re 2000, laminar 64/Re at or
    below 2000 (1.8 used 8 Colebrook passes).
12. Gravity 9.80665 instead of 9.81.
13. Minor-loss K on PIPE cards applied (1.8 read and ignored it).
14. Hazen-Williams option with constants 10.667, 1.852, 4.871.
15. PUMP head curve with QMAX; starting flow QMAX/2; W207 above QMAX; W210 on reverse flow.
16. VALVE component (loss K, OPEN/CLOSED, case-insensitive status, E108 for others).
17. Zero-flow handling: laminar law used at zero flow, linearised HW and minor losses below
    0.001 L/s, friction shown as UNDEF and W203 below that flow.
18. Convergence test: relative sum of flow changes against TOL (default 1E-5), MAXIT default 50; the
    printed iteration counts depend on these, on the starting flows and on the gradient formulas.
19. Non-convergence: W205, the report is still printed, exit status 2.
20. Disconnected junctions: detected by reachability over open links, W204, ISOLATED rows, isolated
    links get status ISOLATED and zero flow; no reservoir is E302.
21. PATTERN cards (extendable, cyclic), STEPS/HSTEP, per-step headers with HH:MM labels, warm start
    from the previous step's flows.
22. Node table sorted by id and including reservoirs (supply shown as negative demand).
23. Link table: flow in L/s (1.8: m3/s), absolute head loss, blank velocity for pumps, friction
    column only for Darcy-Weisbach pipes, status column (OPEN, ON, CLOSED, ISOLATED).
24. Totals (demand, supply) and final warning count line.
25. Exit statuses 0 / 1 (input errors) / 2 (not converged).

Each of these was checked to be load-bearing with a mutation run (`authoring/mutants.py`, inside the
task image): 26 single-behaviour mutants of the 2.3 source, every one fails at least 3 hidden decks.

| mutant | decks failed | mutant | decks failed |
|---|---|---|---|
| g = 9.81 | 123 | default MAXIT 40 | 280 |
| Colebrook instead of Swamee-Jain | 246 | no MAXIT clamp | 5 |
| no transition blend | 56 | no W209 | 6 |
| minor losses ignored | 32 | case-sensitive keywords | 8 |
| kPa factor 9.80665 | 267 | no inline comments | 3 |
| psi factor 0.433 | 20 | 40-character title | 3 |
| gpm factor 6.31E-5 | 14 | cold start every step | 18 |
| HW constant 10.67 | 13 | pump start flow 0.03 | 10 |
| nodes in input order | 291 | signed head loss | 225 |
| default TOL 1E-6 | 280 | exit 0 when not converged | 4 |
| zero-flow threshold 1E-5 | 5 | velocity warning at 2.5 m/s | 11 |
| W204 in input order | 5 | laminar gradient doubled | 24 |
| absolute convergence test | 112 | no W210 | 10 |

Why probing is required: the 1.8 source and manual describe a different program, and the release
note gives card syntax only. The rules live only in the executable's behaviour (message texts are
visible with `strings`, but codes, order, conditions, formulas and constants are not).

## Grading

`tests/test_parity.py`:

1. Fingerprints and deletes `/app/prod`, then searches `/app`, `/tmp`, `/root`, `/home`,
   `/usr/local`, `/opt`, `/srv`, `/var/tmp` for files with the same SHA-256 (deleted; test fails).
2. Rejects `EXECUTE_COMMAND_LINE`, `SYSTEM`, `BIND`, `ISO_C_BINDING`, `EXEC*`, `POPEN`, `FORK`,
   `DLOPEN`, `DLSYM` in code (comments and character constants excluded).
3. Copies `/app/src`, keeps only `.f` and `.inc` files, builds with `gfortran -O2 -o hydro *.f`.
4. Runs 353 hidden decks (`tests/decks`, generated by `authoring/gen_decks.py`, seed 20261118) and
   compares with recordings made from the production executable in the built image
   (`authoring/record.sh`): 288 normal runs, 61 input-error runs, 4 non-converged runs. Prints a
   per-category table (basic 40, errors 62, regime 31, warnings 30, pattern 25, pump 25, parsing 25,
   hazen 20, minor 20, valve 20, us_units 20, topology 20, large 15). Reward 1 only if all match.

Comparison (`tests/compare.py`, stated in the instruction): trailing whitespace and trailing empty
lines ignored; same line count and line lengths; tokens exact except decimal numbers, which need the
same number of decimals and may differ by one unit in the last digit.

Round-off robustness: the recordings were reproduced exactly (under these rules) by builds of the 2.3
source with `-O0`, `-O2 -ffp-contract=off` (no FMA, as on x86-64), `-O3 -ffast-math`, and a variant
that assembles the matrix in reverse link order. All 353 decks matched for every variant, including
iteration counts. An earlier generator produced decks that were not robust (ill-conditioned zero-flow
links); the solver's zero-flow treatment was changed and the generator tightened until this held.
Decks were not cherry-picked against the variants.

## Shortcuts and how the grader stops them

| cheat (`cheats/`) | idea | result |
|---|---|---|
| `callout.sh` | Fortran wrapper calling the production executable via `EXECUTE_COMMAND_LINE`, with a private copy of the binary | 0: forbidden construct, copy found by hash, `/app/prod` deleted (0/353 decks) |
| `docs_only.sh` | docs-only baseline: fix the 1.8 build and keep the behaviour of the 1.8 manual | 0: passes 0/353 decks (banner, header and report layout already differ) |
| `hardcode.sh` | record production output for the sample decks and print it verbatim | 0: 0/353 decks |

## What it does not measure

Hydraulic modelling skill beyond what is needed to recognise formulas from output; numerical
methods design (the solver structure is already in 1.8); Fortran style. It does not check behaviour
on decks longer than 80 columns per line beyond truncation, and it does not test performance.

## Validation (real Docker runs, harbor 0.25, arm64 host)

| command | outcome |
|---|---|
| `harbor run -p fortran-solver-parity -a oracle` (run 1) | reward 1, 353/353 |
| `harbor run -p fortran-solver-parity -a oracle` (run 2) | reward 1, 353/353 |
| `harbor run -p fortran-solver-parity -a nop` | reward 0 (1.8 source does not build) |
| cheat `callout.sh` as solve.sh, `-a oracle` | reward 0 |
| cheat `docs_only.sh` as solve.sh, `-a oracle` | reward 0 (0/353 decks) |
| cheat `hardcode.sh` as solve.sh, `-a oracle` | reward 0 (0/353 decks) |
| `authoring/mutants.py` in the task image | 26/26 mutants rejected |

Cheat runs used scratch copies of the task with `solution/solve.sh` replaced; the copies and all
`jobs/` directories were deleted afterwards.

## Files

- `environment/prod-src/` 2.3 source (build stage only); `environment/app/` agent-visible tree.
- `solution/solve.sh`, `solution/src/` reference (2.3 source).
- `tests/` grader, comparison rules, 353 decks, recorded outputs and exit statuses.
- `authoring/` deck generator, recorder, mutation check (not used by harbor).
- `cheats/` shortcut scripts (not used by harbor).
