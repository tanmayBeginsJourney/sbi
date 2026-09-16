#!/usr/bin/env bash
# One arm of the n-workers benchmark. $1 = label, $2 = value for -n
set -u
label="$1"; nval="$2"
if [ "${SMOKE:-false}" = "true" ]; then
  SEL=(tests/torchutils_test.py)
else
  SEL=(--splitting-algorithm least_duration --splits 4 --group 2 tests/)
fi
s=$(date +%s)
# Flags copied from cd.yml. -x dropped: a flaky test must not truncate an arm.
# No --durations-path: that option also controls READING and would break the split.
uv run pytest -v -n "$nval" -m "not gpu" --cov=sbi --cov-report=xml \
  "${SEL[@]}" > "out_${label}.txt" 2>&1 || true
secs=$(( $(date +%s) - s ))
workers=$(grep -m1 -o "created: [0-9]*/[0-9]* workers" "out_${label}.txt" || true)
# pytest's summary line, e.g. "1700 passed, 12 skipped, 3 xfailed in 2811.55s"
summary=$(grep -m1 -E "^=+ .*(passed|failed|error).* =+$" "out_${label}.txt" || true)
passed=$(printf '%s' "$summary" | grep -o "[0-9]* passed" | grep -o "[0-9]*" || true)
failed=$(printf '%s' "$summary" | grep -o "[0-9]* failed" | grep -o "[0-9]*" || true)
{
  echo "${label}_seconds=${secs}"
  echo "${label}_workers=${workers:-unknown}"
  echo "${label}_tests=${passed:-0}"
  echo "${label}_failed=${failed:-0}"
  echo "${label}_summary=${summary:-none}"
} | tee -a provenance.txt
