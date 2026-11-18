#!/bin/bash
# Runs the HYDRO parity grader and writes the reward (1 = all decks match).
mkdir -p /logs/verifier
cd /tests || exit 1
python3 -m pytest -s -q -p no:cacheprovider test_parity.py 2>&1 | tee /logs/verifier/pytest.log
if [ "${PIPESTATUS[0]}" -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
