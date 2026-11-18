#!/bin/bash
# Grades /app/src against recorded production 4.2 outputs. No network needed.
mkdir -p /logs/verifier
cd /tests || exit 1
python3 -m pytest -q -s -p no:cacheprovider test_parity.py > /logs/verifier/pytest.log 2>&1
rc=$?
cat /logs/verifier/pytest.log
if [ "$rc" -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
