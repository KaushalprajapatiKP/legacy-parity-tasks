# Tools used

- **Claude Code (Anthropic)**: I took its help in authoring these tasks: writing parts of the
  code, graders, Dockerfiles and documentation, and running the validation. The design and the
  core idea of every task are mine: the failure category each task targets, the choice to put
  the source of truth in a compiled program that has to be probed, the difficulty targets, and
  the review of every task before it was accepted.
- **Claude Sonnet**, run through Claude Code under my existing subscription with no extra spend,
  as the agent under test for the trajectories in `trajectories/`.
- **Harbor 0.25** and **Docker** for building, running and validating every task (oracle, no-op
  and shortcut runs).
- **GnuCOBOL 3.1.2**, **gfortran 12**, **GCC 12** and **Python 3** as the task toolchains.

## Where I corrected the AI help

- **Difficulty was in the wrong place.** The first drafts were fair but easy: their statements
  listed the symptoms, or the truth sat in readable docs. Cold agent runs solved them in 3 to 23
  tool calls. I rejected that batch and set the rule these tasks follow: the source of truth
  must be a compiled program that has to be probed, with a bar of at least 50 tool calls for a
  cold attempt.
- **Fairness gaps.** In the migration task the sample store did not contain a layout used by
  the hidden stores, and a lookup table was readable with `strings`. Both were fixed before
  release. In the recurrence-rule draft, 3 expected answers taken from a library contradicted
  RFC 5545 and were removed after cross-checking.
- **Unstable expected outputs.** Recording the queue-server sessions in parallel produced 2
  unstable sessions. I required every recording to be repeated three times and kept only
  byte-identical sessions. In the Fortran task, decks whose results changed between compiler
  builds were removed by fixing the zero-flow numerics and re-checking under four compiler
  settings.
- **Coverage claims.** I required mutation runs (54 and 26 one-behaviour mutants for the COBOL
  and Fortran tasks). In the Fortran task they exposed two behaviours no deck covered, and decks
  were added until every mutant was caught.
- **My own evaluation harness.** A pipeline bug in my grading script made one run look
  ungraded. I fixed it and re-ran it rather than reporting a result.
