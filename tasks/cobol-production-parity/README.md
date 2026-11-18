# cobol-production-parity

## Statement (summary)

BILLRUN is a self-written COBOL billing batch (MIT). Production runs version 4.2, shipped only as a
stripped executable at `/app/prod/billrun`. The 4.2 source is lost. `/app/src` holds version 3.7
(1275 lines: a main program, five subprograms, ten copybooks). `/app/docs` has the 3.7 user guide and a
loose 4.2 release note. The agent must change `/app/src` so that the program built with

    cd /app/src && cobc -x -fstatic-call -I copy -o /app/build/billrun billrun.cbl lib/*.cbl

writes `STATEMENTS.RPT`, `REJECTS.RPT` and `SUMMARY.RPT` byte-identical to production, with the same
return code, for any input set in the documented formats. The binary is execute-only by instruction
and is deleted before grading.

## Environment

- `debian:bookworm-slim` pinned by digest; `gnucobol3=3.1.2-5+b1`, `python3=3.11.2-1+b1`,
  `python3-pytest=7.2.1-2`.
- Multi-stage Dockerfile. Stage `prodbuild` compiles `environment/prod42/` (the 4.2 source) and strips
  it; only the stripped binary is copied into the final image. Checked in the built image: the only
  COBOL sources present are the 3.7 tree in `/app/src` and GnuCOBOL's own system copybooks;
  `strings` on the binary shows no 4.2 data names.
- `/app/samples/basic` is one easy input set (full cycle, no edge cases, no rejects).
- The 4.2 source exists in `environment/prod42/` (build stage only) and `solution/src42/`.

## Difficulty

Cost to begin: 3.7 does not build on GnuCOBOL 3.1.2. Three layers, each revealed only after the
previous one is fixed: `MESSAGE` is a reserved word (copybook and main program), `COPY RATETAB` but the
file is `ratetab.cpy` (case-sensitive filesystem), and `PROGRAM-ID. TaxCalc.` against the static
`CALL "TAXCALC"` (a link error that appears only after compilation succeeds).

Then more than 40 independent behaviour differences between 3.7 and 4.2. The release note names
most of them as features but gives no rules, numbers or texts; the user guide documents 3.7. Every
one is observable by running the production binary on crafted input, and none is in readable source.

Hidden behaviour families (each verified by at least one single-behaviour mutant that the hidden
suite kills, see below):

| Family | Behaviours the agent must discover by probing |
|---|---|
| New records | DS coupon and SU suspension accepted and billed (3.7 rejects them as unknown type) |
| Dates | leap-year and century rules (2000 leap, 2100 not), years before 1900 invalid, month lengths |
| Account edits | duplicate account id rejected (A02), invalid tax class rejected (A06, 3.7 bills it as N), close before open rejected, balance sign must be `+` or `-` |
| Activity edits | outside cycle (R04), exact duplicate of an accepted line (R07), account not active on the date (R08), plan change (R09), payment not positive (R10), coupon kind/value/over 100 percent (R11), suspension end (R12); check precedence when several fields are bad |
| Control | cycles longer than 31 days refused, abort summary text, return code 16 |
| Accounts out of cycle | not billed, counted as "not in cycle"; their activity becomes R08 |
| Data pricing | tiers 10/40 GB (3.7 10/50), 0.80 beyond (3.7 0.90), allowance S 2 GB and P 5 GB |
| Voice | each record rounded up to whole minutes, premium rate 0.03 |
| SMS | integer count per record, premium 100 free, basic 0.03 |
| Roaming | charged per record with round-half-even (3.7: truncated total) |
| Proration | base fee per plan segment by active day, opening and closing mid-cycle, plan changes effective from their date, suspended days at half rate, half-up rounding per segment; plan for usage is the plan on the last active day |
| Discounts | loyalty on base fee only, new L3 15 percent; fixed coupons first (capped at the remainder), then percentage coupons compounding on the remainder; total capped at 50 percent with a "DISCOUNT CAP" line; no discounts when the discountable amount is not positive |
| Charges and tax | late fees capped at 15.00 net per cycle; deposits excluded from the discount and tax base; tax half-up and never negative |
| Reports | new statement layout (QTY column, ISO dates, CR credits, per-line adjustments and payments), statements ordered by region then account, lines in date order, "NO ACTIVITY THIS PERIOD", new reject report columns and messages, new summary sections (rejects by code, amount due by region) |
| Return code | 4 when anything is rejected |

Why probing is needed: the documents say for example "data tiers rebalanced", "roaming rounding
changed", "total discounts are capped", "reject messages were reworded", without values. The visible
sample exercises only the easy regime. The constants, rounding modes, stacking order, check
precedence and exact texts exist only inside the stripped binary.

## Grading

`tests/test_parity.py` (run by `tests/test.sh`, no network):

1. Hashes `/app/prod/billrun`, deletes `/app/prod`, and deletes any byte-identical copy found under
   `/app /tmp /root /home /opt /srv /usr/local /var/tmp /var/lib /etc /mnt /media`.
2. Source guard on every `.cbl/.cob/.cpy` under `/app/src` (comment lines removed, no column
   truncation): every `CALL` target must be a literal naming a `PROGRAM-ID` in `/app/src`; no
   `TO ENTRY`, `C$`, `CBL_`, `CHAIN`, `EXEC`, pointer usages or `>>CALL` directives; every `ASSIGN`
   must be one of the six documented file names.
3. Toolchain integrity: `dpkg -V` shows no modified non-conffile, the GnuCOBOL conffiles match their
   packaged md5, no `/etc/ld.so.preload`, `cobc/gcc/as/ld` resolve to packaged files, no gcc specs file.
4. Builds with the documented command (clean environment, `COB_RUNTIME_CONFIG` pointed at an empty file).
5. Replays 480 hidden input sets (12 categories x 40) recorded from the stripped production binary at
   authoring time (`tests/cases.json.gz`), compares the return code and all three files byte for byte,
   prints a per-category table with per-file match counts (also written to
   `/logs/verifier/parity_table.txt`). Reward 1 only if all 480 match.

Inputs are generated by `authoring/gen.py` with fixed seeds (deterministic); expected outputs were
recorded by `authoring/record.py` inside the built image.

### Suite coverage check (mutation analysis)

`authoring/mutants.py` holds 54 single-behaviour mutants of the 4.2 source (each reverts one 4.2 rule
to 3.7 or to a plausible guess). `authoring/mut_run.py` builds each and replays the suite. All 54 are
killed. Weakest kills: cycle longer than 31 days (3 sets), net late-fee cap with negative late
charges (6), balance with a blank sign (7), duplicate account (9), invalid tax class (9), check
precedence service vs quantity (10). Two mutants I first wrote turned out to be behaviourally
identical to 4.2 (rounding per data tier versus once, and moving the duplicate check earlier) and were
dropped, so they are not claimed as behaviours.

## Shortcuts and how the grader stops them

| Cheat (`cheats/`) | Idea | Stopped by | Reward |
|---|---|---|---|
| `wrapper` | COBOL front end that does `CALL "SYSTEM" USING "/app/prod/billrun"` | binary deleted before grading; source guard rejects the CALL | 0 |
| `hardcoded` | runs production on the sample at agent time and emits a program that always writes those bytes | hidden inputs differ; 0 of 480 sets match | 0 |
| `fixed37` | only the three build fixes, 3.7 behaviour | every set differs | 0 |
| `docs_only_baseline` | the generous docs-only baseline: 4.2 report layouts copied as if from a run, every rule the release note leaves open filled with the natural guess (3.7 tiers, 1/3 GB allowances, nearest-minute voice, 50 free SMS, half-up roaming, free suspension days, loyalty on fees plus usage, coupons in file order, late cap 25.00, 3.7 messages for the old codes, control return code 8) | 2 of 480 sets match; per file: STATEMENTS 16, REJECTS 347, SUMMARY 14, return code 466 | 0 |

## What this does not measure

- Not COBOL authoring skill beyond the existing program structure; the changes fit the 3.7 design.
- Not performance (inputs are small).
- Behaviour outside the generator's distribution (more than 50 accounts or 200 activity records,
  lines over 80 characters, missing control file) is not graded, and the instruction says so.
- The rule against reading the binary (strings, objdump) is stated but cannot be enforced; literal
  texts are visible to `strings`, constants and rounding rules are not.

## Validation (real Docker runs, harbor 0.25)

Jobs were written outside the task directory (`-o <scratch>/jobs/...`); no `jobs/` is left in the task.

| Command | Result |
|---|---|
| `harbor run -p cobol-production-parity -a oracle` (run 1) | reward 1.0 |
| `harbor run -p cobol-production-parity -a oracle` (run 2) | reward 1.0 |
| `harbor run -p cobol-production-parity -a nop` | reward 0.0 (3.7 does not build: reserved word MESSAGE, missing copybook RATETAB) |
| cheat `wrapper` as solution, `-a oracle` | reward 0.0 (source guard: CALL to SYSTEM; parity 0/480) |
| cheat `hardcoded` as solution, `-a oracle` | reward 0.0 (parity 0/480) |
| cheat `fixed37` as solution, `-a oracle` | reward 0.0 (parity 0/480) |
| cheat `docs_only_baseline` as solution, `-a oracle` | reward 0.0 (parity 2/480) |

Oracle per-category table: 40/40 in all 12 categories, 480/480. Verifier runtime about 25 s.

