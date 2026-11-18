#!/bin/bash
# Runs the grader. Needs no network: pytest is baked into the image.
mkdir -p /logs/verifier
cd /tests || exit 1
python3 -m pytest -p no:cacheprovider -rA -q /tests/test_migration.py 2>&1 | tee /logs/verifier/pytest.txt
if [ "${PIPESTATUS[0]}" -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
cat /logs/verifier/feature_table.txt 2>/dev/null
exit 0
