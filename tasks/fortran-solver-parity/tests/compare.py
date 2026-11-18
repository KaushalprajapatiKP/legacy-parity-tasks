"""Report comparison used by the HYDRO parity grader.

Rules (also stated in the task instruction):
  * stdout is compared line by line after removing trailing whitespace from
    every line and dropping trailing empty lines;
  * the number of lines and the length of every line must match exactly;
  * whitespace-separated tokens must match exactly, except decimal numbers
    written with a decimal point: those must have the same number of digits
    after the point and may differ by at most one unit in the last digit;
  * the process exit status must match exactly.
"""
import re

NUM = re.compile(r"^[+-]?\d*\.(\d+)$")


def _norm(text):
    lines = [ln.rstrip() for ln in text.replace("\r\n", "\n").split("\n")]
    while lines and lines[-1] == "":
        lines.pop()
    return lines


def tok_equal(a, b):
    if a == b:
        return True
    ma, mb = NUM.match(a), NUM.match(b)
    if not (ma and mb):
        return False
    nd = len(mb.group(1))
    if len(ma.group(1)) != nd:
        return False
    try:
        return abs(float(a) - float(b)) <= 10.0 ** (-nd) * 1.000001
    except ValueError:
        return False


def compare(expected, actual):
    """Return None when equal, else a short description of the first diff."""
    e, a = _norm(expected), _norm(actual)
    for i in range(max(len(e), len(a))):
        if i >= len(e):
            return f"line {i+1}: unexpected extra line {a[i]!r}"
        if i >= len(a):
            return f"line {i+1}: missing line, expected {e[i]!r}"
        le, la = e[i], a[i]
        if le == la:
            continue
        if len(le) != len(la):
            return f"line {i+1}: expected {le!r}, got {la!r}"
        te, ta = le.split(), la.split()
        if len(te) != len(ta) or not all(tok_equal(x, y) for x, y in zip(ta, te)):
            return f"line {i+1}: expected {le!r}, got {la!r}"
    return None
