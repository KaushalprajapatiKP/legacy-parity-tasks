# Notes: what I checked, what I changed, what I would do next

## What I checked

- **Every task in real Docker with Harbor 0.25:** the reference solution scores 1 on two runs,
  a no-op scores 0, and every script in `cheats/` scores 0. The results are in each task's
  README and on the sample page.
- **The agent image holds no answers.** In each built image I searched the filesystem: the
  production source, the hidden suites, the generators and the reference solution are absent.
  Only the stripped production binary, the old source (for the two legacy tasks) and the docs
  are present.
- **The graders can see every behaviour they claim to test.** I built one-behaviour mutants of
  the production programs: 54 for COBOL and 26 for Fortran. Every one fails at least one hidden
  case.
- **The recorded outputs are stable.** Recordings were repeated. The Fortran decks were
  re-checked under `-O0`, `-O2 -ffp-contract=off`, `-O3 -ffast-math` and a reversed assembly
  order, and still match within the stated tolerance with identical iteration counts.
- **An agent can actually do them.** One cold run of a strong coding agent per task, graded by
  the real verifier:

| Task | Tool calls | Result |
|---|---|---|
| cobol-production-parity | 83 | 1 (480 / 480) |
| fortran-solver-parity | 235 | 0 (352 / 353, missed the too-many-patterns error) |
| legacy-store-migration | 72 | 1 (640 / 640) |

## Ambiguities and unfair spots found, and what I changed

1. **Migration: a hidden layout was missing from the sample.** The hidden stores contain files
   whose free table comes before the record cells, but the visible sample had none. A correct
   reader built from the sample could fail for a reason it could not see, so the sample
   generator now always includes one such file.
2. **Migration: a lookup table leaked through `strings`.** The 64-entry text table was readable
   with `strings` on the binary, which made one feature transcription instead of discovery. It
   is now stored as code points.
3. **Fortran: unstable decks.** In the first deck set, iteration counts differed between
   compiler builds on badly conditioned zero-flow networks. I fixed the zero-flow numerics in
   both versions and tightened the generator, rather than filtering out the decks that failed.
4. **Fortran: tolerance stated precisely.** The instruction says text must match exactly
   (including line lengths) and decimals may differ by at most one unit in the last printed
   digit.
5. **COBOL: graded input range stated.** The instruction limits graded inputs to at most 50
   accounts, 200 activity records, 80-column lines and LF line endings, so behaviour outside
   that range cannot fail a solution.
6. **Coverage gaps found by mutants.** Two Fortran behaviours (the zero-flow threshold and the
   order of isolated-node warnings) were caught by no deck, so I added decks for both.

## One shortcut and how the grader stops it

The obvious shortcut in both legacy tasks is to keep the production binary doing the work:
call it from COBOL (`CALL "SYSTEM"`) or Fortran (`EXECUTE_COMMAND_LINE`), or ship a renamed copy.
The graders stop it three ways:
- they scan the source for process-starting constructs;
- they delete `/app/prod` and every byte-identical copy of the binary before grading;
- they build the program from source with their own command.

`cheats/` in each task contains this wrapper, and it scores 0.

## What I would do next

- **Separate verifier containers.** Today the verifiers share the agent's container, so an
  agent with root could tamper with the toolchain used for grading.
- **Validate on x86-64.** Every run so far was on arm64. The Fortran task grades iteration
  counts exactly, so it is the one most at risk.
- **More runs, more agents.** Five runs each from several agents, to get pass rates with
  intervals instead of one run per task.
- **Private hidden suites per release.** These repos are public, so these exact suites should
  not be used to score models.
- **Turn the sample page into the marketplace shape:** filters by kind and language, a download
  link for each task bundle, and a trajectory viewer.
