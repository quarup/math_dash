#!/usr/bin/env python3
"""Rewrite the bundled dataset JSONs with teaching explanations and
cleaned-up items, in place.

The 2026-08-19 UX sweep found that dataset-sourced items mostly restate
the fact ("0 + 0 = 0") where the algorithmic generators teach a method,
that multiplication prompts use '*' instead of '×', that
mult_1digit_by_multiple_of_10 carries ×1 items which bypass the concept,
and that round_multidigit_any_place has distractors that aren't
multiples of the rounding factor (eliminable without rounding) and
digit-run prompts without thousands separators.

This script is deterministic (no randomness, no network): running it
twice is a no-op. It edits assets/data/dataset_questions/*.json in
place; re-run it after any future re-ingestion.

Usage:  python3 tools/question_generation/refresh_bundled_datasets.py
"""

from __future__ import annotations

import json
import re
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parents[2] / "assets" / "data" / "dataset_questions"

MINUS = "−"  # typeset minus used throughout the app


# ───────────────────────────────────────────────────────────────────────
# Helpers
# ───────────────────────────────────────────────────────────────────────


def commas(n: int) -> str:
    """Format like the app's formatWithCommas: separators only past 3 digits."""
    s = str(abs(n))
    if len(s) <= 3:
        out = s
    else:
        out = f"{abs(n):,}"
    return (MINUS if n < 0 else "") + out


def parse_int(s: str) -> int:
    return int(s.replace(MINUS, "-").replace(",", ""))


EQ_RE = re.compile(rf"^(\d+) ([+{MINUS}]) (\d+) = \?$")


def split_places(n: int) -> list[int]:
    """735 → [700, 30, 5], zeros dropped."""
    parts = []
    scale = 1
    while n >= scale * 10:
        scale *= 10
    while scale >= 1:
        d = (n // scale) % 10
        if d:
            parts.append(d * scale)
        scale //= 10
    return parts


# ───────────────────────────────────────────────────────────────────────
# Explanation builders
# ───────────────────────────────────────────────────────────────────────


def explain_add_small(a: int, b: int) -> list[str]:
    """Counting-on for sums within 10 (and the trivial +0/+1 cases)."""
    total = a + b
    hi, lo = max(a, b), min(a, b)
    if lo == 0:
        return [f"Adding 0 changes nothing: {a} + {b} = {total}."]
    steps = ", ".join(str(hi + i) for i in range(1, lo + 1))
    return [f"Start at {hi} and count up {lo}: {steps}.", f"{a} + {b} = {total}."]


def explain_sub_small(a: int, b: int) -> list[str]:
    """Counting-back for differences within 10."""
    total = a - b
    if b == 0:
        return [f"Taking away 0 changes nothing: {a} {MINUS} {b} = {total}."]
    if a == b:
        return [f"Taking away all {a} leaves nothing: {a} {MINUS} {b} = 0."]
    if b <= 4:
        steps = ", ".join(str(a - i) for i in range(1, b + 1))
        return [f"Start at {a} and count back {b}: {steps}.", f"{a} {MINUS} {b} = {total}."]
    return [
        f"Think addition: {b} + ? = {a}.",
        f"{b} + {total} = {a}, so {a} {MINUS} {b} = {total}.",
    ]


def explain_add_teen(a: int, b: int) -> list[str]:
    """Make-ten strategy for sums within 20 that cross ten."""
    total = a + b
    hi, lo = max(a, b), min(a, b)
    if lo == 0:
        return [f"Adding 0 changes nothing: {a} + {b} = {total}."]
    if hi < 10 and hi + lo > 10:
        to_ten = 10 - hi
        rest = lo - to_ten
        return [
            f"Make ten: {hi} + {to_ten} = 10.",
            f"Then add the rest: 10 + {rest} = {total}.",
        ]
    if hi >= 10:
        return [f"{hi} is a ten and {hi - 10} ones; add {lo} ones: {total}."]
    return explain_add_small(a, b)


def explain_sub_teen(a: int, b: int) -> list[str]:
    """Take-from-ten strategy for differences within 20 that cross ten."""
    total = a - b
    if b == 0:
        return [f"Taking away 0 changes nothing: {a} {MINUS} {b} = {total}."]
    if a > 10 and b > a % 10:
        to_ten = a - 10
        rest = b - to_ten
        return [
            f"Take away {to_ten} to reach 10: {a} {MINUS} {to_ten} = 10.",
            f"Then take away the rest: 10 {MINUS} {rest} = {total}.",
        ]
    return explain_sub_small(a, b)


def explain_add_places(a: int, b: int) -> list[str]:
    """Place-value expansion for multi-digit addition."""
    total = a + b
    lines = []
    parts_a = split_places(a)
    parts_b = split_places(b)
    sums = []
    scale_sums: dict[int, int] = {}
    for p in parts_a + parts_b:
        s = 10 ** (len(str(p)) - 1)
        scale_sums[s] = scale_sums.get(s, 0) + p
    for s in sorted(scale_sums, reverse=True):
        sums.append(scale_sums[s])
    if len(sums) > 1:
        by_place = "; ".join(
            f"{'+'.join(str(x) for x in [p for p in parts_a if 10 ** (len(str(p)) - 1) == s] + [p for p in parts_b if 10 ** (len(str(p)) - 1) == s])}"
            f" = {scale_sums[s]}"
            for s in sorted(scale_sums, reverse=True)
            if len([p for p in parts_a + parts_b if 10 ** (len(str(p)) - 1) == s]) > 1
        )
        if by_place:
            lines.append(f"Add each place: {by_place}.")
        lines.append(f"Then combine: {' + '.join(str(x) for x in sums)} = {total}.")
    lines.append(f"{a} + {b} = {total}.")
    return lines


def explain_add_carry(a: int, b: int) -> list[str]:
    """Column addition with explicit carries (2-digit + 2-digit)."""
    total = a + b
    ones = a % 10 + b % 10
    carry = 1 if ones >= 10 else 0
    lines = []
    if carry:
        lines.append(
            f"Ones: {a % 10} + {b % 10} = {ones} — write {ones % 10}, carry 1."
        )
        lines.append(f"Tens: {a // 10} + {b // 10} + 1 = {total // 10}.")
    else:
        lines.append(f"Ones: {a % 10} + {b % 10} = {ones}.")
        lines.append(f"Tens: {a // 10} + {b // 10} = {a // 10 + b // 10}.")
    lines.append(f"So {a} + {b} = {total}.")
    return lines


def explain_sub_borrow(a: int, b: int) -> list[str]:
    """Column subtraction with an explicit borrow (2-digit − 2-digit)."""
    total = a - b
    ao, bo = a % 10, b % 10
    lines = []
    if ao < bo:
        lines.append(
            f"Ones: {ao} < {bo}, so borrow a ten: {ao + 10} {MINUS} {bo} = {ao + 10 - bo}."
        )
        lines.append(f"Tens: {a // 10 - 1} {MINUS} {b // 10} = {total // 10}.")
    else:
        lines.append(f"Ones: {ao} {MINUS} {bo} = {ao - bo}.")
        lines.append(f"Tens: {a // 10} {MINUS} {b // 10} = {a // 10 - b // 10}.")
    lines.append(f"So {a} {MINUS} {b} = {total}.")
    return lines


def explain_sub_count_up(a: int, b: int) -> list[str]:
    """Adding-up strategy for multi-digit subtraction: b → milestones → a."""
    total = a - b
    if total == 0:
        return [f"{a} {MINUS} {b} = 0."]
    milestones = []
    cur = b
    for step in (10, 100, 1000):
        nxt = ((cur // step) + 1) * step
        if cur % step and nxt < a:
            milestones.append(nxt)
            cur = nxt
    milestones.append(a)
    hops = []
    cur = b
    for m in milestones:
        hops.append((cur, m - cur, m))
        cur = m
    hops = [h for h in hops if h[1] > 0]
    if len(hops) <= 1:
        return [f"Count up from {b} to {a}: that is {total}.", f"{a} {MINUS} {b} = {total}."]
    hop_lines = "; ".join(f"{f} + {d} = {t}" for f, d, t in hops)
    jumps = " + ".join(str(d) for _, d, _ in hops)
    return [
        f"Count up from {b}: {hop_lines}.",
        f"The jumps add to {jumps} = {total}, so {a} {MINUS} {b} = {total}.",
    ]


ADD_SUB_STRATEGY = {
    "add_within_5": explain_add_small,
    "add_within_10": explain_add_small,
    "sub_within_5": explain_sub_small,
    "sub_within_10": explain_sub_small,
    "add_within_20": explain_add_teen,
    "sub_within_20": explain_sub_teen,
    "add_within_100": explain_add_carry,
    "add_within_1000": explain_add_places,
    "add_2digit_carry": explain_add_carry,
    "sub_within_100": explain_sub_count_up,
    "sub_within_1000": explain_sub_count_up,
    "sub_2digit_borrow": explain_sub_borrow,
}


# ───────────────────────────────────────────────────────────────────────
# Rounding
# ───────────────────────────────────────────────────────────────────────

PLACE_WORDS = {
    "ten": 10,
    "hundred": 100,
    "one hundred": 100,
    "thousand": 1000,
    "one thousand": 1000,
    "ten thousand": 10_000,
    "hundred thousand": 100_000,
    "one hundred thousand": 100_000,
    "million": 1_000_000,
    "one million": 1_000_000,
    "ten million": 10_000_000,
}

ROUND_RE = re.compile(r"^Round (\d+) to the nearest (.+?)\.?$")


def parse_round(prompt: str) -> tuple[int, int] | None:
    m = ROUND_RE.match(prompt)
    if not m:
        return None
    n = int(m.group(1))
    place_raw = m.group(2).strip().lower()
    if place_raw.isdigit():
        factor = int(place_raw)
    elif place_raw in PLACE_WORDS:
        factor = PLACE_WORDS[place_raw]
    else:
        return None
    return n, factor


def refresh_round_item(item: dict, fix_distractors: bool, add_commas: bool) -> None:
    parsed = parse_round(item["prompt"])
    if parsed is None:
        return
    n, factor = parsed
    correct = parse_int(item["correct_answer"])
    deciding = (n // (factor // 10)) % 10 if factor >= 10 else n % 10
    direction = "up" if deciding >= 5 else "down"
    other = correct + factor if direction == "down" else correct - factor
    fmt = commas if add_commas else lambda x: str(x)
    if add_commas:
        item["prompt"] = f"Round {commas(n)} to the nearest {commas(factor)}."
        item["correct_answer"] = commas(correct)
    item["explanation"] = [
        f"Look at the digit one place right of the {fmt(factor)} place: "
        f"it is {deciding}, so round {direction}.",
        f"{fmt(n)} is closer to {fmt(correct)} than to {fmt(other)}.",
    ]
    if fix_distractors:
        cands = [other, correct + factor, correct - factor, correct + 2 * factor]
        out: list[int] = []
        for c in cands:
            if c >= 0 and c != correct and c not in out:
                out.append(c)
            if len(out) == 3:
                break
        item["distractors"] = [fmt(c) for c in out]


# ───────────────────────────────────────────────────────────────────────
# Polynomial evaluation (function_evaluate_at_point)
# ───────────────────────────────────────────────────────────────────────

FUNC_RE = re.compile(
    rf"^Let (\w)\((\w)\) = (.+)\. Calculate \1\(({MINUS}?\d+)\)\.$"
)
TERM_RE = re.compile(rf"([+{MINUS}]?)\s*(\d*)(\w?)(²?)")


def parse_poly(body: str, var: str) -> list[tuple[int, int]] | None:
    """'6b² + 20b − 10' → [(6, 2), (20, 1), (−10, 0)]."""
    terms = []
    # Tokenise on the +/− separators while keeping them.
    tokens = re.split(rf" ([+{MINUS}]) ", body)
    sign = 1
    for tok in tokens:
        if tok == "+":
            sign = 1
            continue
        if tok == MINUS:
            sign = -1
            continue
        m = re.match(rf"^({MINUS}?)(\d*)({re.escape(var)})?(²?)$", tok.strip())
        if not m:
            return None
        neg, digits, v, sq = m.groups()
        coeff = int(digits) if digits else 1
        if neg:
            coeff = -coeff
        coeff *= sign
        power = 2 if sq else (1 if v else 0)
        terms.append((coeff, power))
        sign = 1
    return terms


def fmt_signed(n: int) -> str:
    return f"{MINUS}{abs(n)}" if n < 0 else str(n)


def fmt_paren(n: int) -> str:
    return f"({MINUS}{abs(n)})" if n < 0 else str(n)


def refresh_function_item(item: dict) -> None:
    m = FUNC_RE.match(item["prompt"])
    if not m:
        return
    fname, var, body, val_raw = m.groups()
    val = int(val_raw.replace(MINUS, "-"))
    terms = parse_poly(body, var)
    if terms is None:
        return
    total = sum(c * val**p for c, p in terms)
    lines = [f"Substitute {var} = {fmt_signed(val)}:"]
    pieces = []
    for c, p in terms:
        if p == 2:
            sq = val * val
            part = c * sq
            if abs(c) == 1:
                prefix = MINUS if c < 0 else ""
                lines.append(f"{prefix}{fmt_paren(val)}² = {fmt_signed(part)}")
            else:
                lines.append(
                    f"{fmt_signed(c)} × {fmt_paren(val)}² = "
                    f"{fmt_signed(c)} × {sq} = {fmt_signed(part)}"
                )
            pieces.append(part)
        elif p == 1:
            part = c * val
            if abs(c) == 1:
                pieces.append(part)
            else:
                lines.append(
                    f"{fmt_signed(c)} × {fmt_paren(val)} = {fmt_signed(part)}"
                )
                pieces.append(part)
        else:
            pieces.append(c)
    sum_str = " + ".join(fmt_paren(x) for x in pieces)
    lines.append(f"{sum_str} = {fmt_signed(total)}.")
    item["explanation"] = lines


# ───────────────────────────────────────────────────────────────────────
# Multiplication files
# ───────────────────────────────────────────────────────────────────────

MULT_FILES = [
    "mult_1digit_by_multiple_of_10.json",
    "mult_2digit_by_2digit.json",
    "mult_4digit_by_1digit.json",
    "mult_facts_within_100.json",
    "mult_multidigit_standard_alg.json",
]

MUL_PROMPT_RE = re.compile(
    r"(\d+)\s*[*×]\s*(\d+)|Multiply (\d+) and (\d+)|(\d+) times (\d+)"
    r"|[Pp]roduct of (\d+) and (\d+)"
)


def mul_operands(prompt: str) -> tuple[int, int] | None:
    m = MUL_PROMPT_RE.search(prompt)
    if not m:
        return None
    nums = [int(g) for g in m.groups() if g is not None]
    return (nums[0], nums[1]) if len(nums) == 2 else None


def refresh_mult_by_10_item(item: dict) -> bool:
    """Returns False if the item should be dropped (×1 bypasses the
    concept). Otherwise rewrites distractors as plausible multiplication
    errors and adds the ×10 strategy line."""
    ops = mul_operands(item["prompt"])
    if ops is None:
        return True
    a, b = ops
    if a == 1 or b == 1:
        return False
    mult10, single = (a, b) if a % 10 == 0 else (b, a)
    if mult10 % 10 != 0 or mult10 == 0:
        return True
    base = mult10 // 10
    correct = a * b
    cands = [
        single * base,  # dropped the zero
        (single + 1) * mult10,
        (single - 1) * mult10,
        correct + 10,
    ]
    out: list[int] = []
    for c in cands:
        if c > 0 and c != correct and c not in out:
            out.append(c)
        if len(out) == 3:
            break
    item["distractors"] = [str(c) for c in out]
    item["explanation"] = [
        f"{single} × {mult10}: first {single} × {base} = {single * base}.",
        f"Then × 10: {single * base} × 10 = {correct}.",
    ]
    return True


# ───────────────────────────────────────────────────────────────────────
# Main
# ───────────────────────────────────────────────────────────────────────


def main() -> None:
    changed: dict[str, int] = {}

    def load(name: str) -> tuple[Path, dict]:
        path = DATA_DIR / name
        return path, json.loads(path.read_text())

    def save(path: Path, doc: dict, n: int) -> None:
        path.write_text(json.dumps(doc, ensure_ascii=False, indent=1) + "\n")
        changed[path.name] = n

    # 1. '*' → '×' in every mult prompt.
    for name in MULT_FILES:
        path, doc = load(name)
        n = 0
        for item in doc["items"]:
            # Normalise every '*' (spaced or not) to a spaced '×'.
            new = re.sub(r"(\d)\s*[*×]\s*(\d)", r"\1 × \2", item["prompt"])
            if new != item["prompt"]:
                item["prompt"] = new
                n += 1
        save(path, doc, n)

    # 2. add/sub strategy explanations.
    for concept, strategy in ADD_SUB_STRATEGY.items():
        path, doc = load(f"{concept}.json")
        n = 0
        for item in doc["items"]:
            m = EQ_RE.match(item["prompt"])
            if not m:
                continue
            a, op, b = int(m.group(1)), m.group(2), int(m.group(3))
            item["explanation"] = strategy(a, b)
            n += 1
        save(path, doc, n)

    # 3. Rounding: digit rule everywhere; distractor + comma fixes for
    #    the multi-digit file (matching the generator's comma format).
    for name, fix_d, add_c in [
        ("round_to_10.json", False, False),
        ("round_to_100.json", False, False),
        ("round_multidigit_any_place.json", True, True),
    ]:
        path, doc = load(name)
        n = 0
        for item in doc["items"]:
            before = json.dumps(item, ensure_ascii=False)
            refresh_round_item(item, fix_distractors=fix_d, add_commas=add_c)
            if json.dumps(item, ensure_ascii=False) != before:
                n += 1
        save(path, doc, n)

    # 4. mult_1digit_by_multiple_of_10: drop ×1 items, real distractors,
    #    ×10 strategy explanation.
    path, doc = load("mult_1digit_by_multiple_of_10.json")
    before_len = len(doc["items"])
    doc["items"] = [it for it in doc["items"] if refresh_mult_by_10_item(it)]
    save(path, doc, before_len - len(doc["items"]))

    # 5. function_evaluate_at_point: substitution arithmetic.
    path, doc = load("function_evaluate_at_point.json")
    n = 0
    for item in doc["items"]:
        before = json.dumps(item, ensure_ascii=False)
        refresh_function_item(item)
        if json.dumps(item, ensure_ascii=False) != before:
            n += 1
    save(path, doc, n)

    for name, n in sorted(changed.items()):
        print(f"{name}: {n} items changed")


if __name__ == "__main__":
    main()
