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
