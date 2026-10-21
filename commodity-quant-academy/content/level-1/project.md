---
id: l1-project
type: project
title: Provisional vs Final Invoice Calculator
minutes: 120
xp: 500
concepts: [project-invoicing]
datasets: [lme_prices.csv, fx_rates.csv]
objectives:
- Price a QP-based physical sale from provisional to final invoice
- Handle weight and price adjustments and FX conversion
- Produce a statement a counterparty's AP team would accept
---

## Brief
**To:** you  **From:** Head of Zinc Desk  **Re:** final invoicing

We still build final invoices in a spreadsheet that one person understands. Last quarter we sent two finals with the wrong QP window and one with the provisional % applied to the final. Each one cost a week of back-and-forth and delayed cash.

I want a small, tested Python module that takes a trade, the daily LME cash settlements and the final weights, and produces:

1. the provisional invoice (price at BL date + premium, at the contract %),
2. the QP average over the contract window,
3. the final invoice and the balance (debit or credit note),
4. the balance in EUR or INR when the buyer asks,
5. a plain-text statement I can paste into an email.

Use **ZS-00001 (Java Coated Steel Tbk)** from the trade book to prove it works: 400 t provisional, 399.420 t final weight, M+1 QP (February 2025), premium 158 USD/t, provisional at 90%.

## Acceptance
- `qp_prices(daily, start, end)` returns the settlements with `start <= date <= end`, in date order. Dates are ISO strings (`"2025-02-03"`).
- `qp_average(prices)` returns the mean rounded to 2 decimals and raises `ValueError` for an empty QP.
- `provisional_invoice(tonnes, prov_price, premium, pct=0.9)` returns `{"unit_price", "amount"}`; the unit price is rounded to 2 decimals **before** multiplying; the amount is rounded to 2 decimals.
- `final_invoice(final_tonnes, qp_avg, premium, provisional_amount)` returns `{"unit_price", "final_value", "balance", "note"}`, where the final value is at **100%** and `note` is `"debit note"`, `"credit note"` or `"nil"`.
- `convert(amount_usd, rate, pair)` handles `"EURUSD"` (USD per EUR, so divide) and `"USDINR"` (INR per USD, so multiply), rounds to 2 decimals, and raises `ValueError` for anything else.
- `statement(trade, daily)` returns text that includes the trade id, the QP average, the final value, the provisional amount and the balance with its note.
- Every function rejects tonnes ≤ 0 with `ValueError`.

## Learn
**How the money flows on a QP-priced sale**

| Step | Price basis | Tonnes | % |
|---|---|---|---|
| Provisional invoice (at BL) | LME cash on BL date + premium | BL / provisional weight | contract %, e.g. 90% |
| Final invoice (after QP) | QP average + premium | final (outturn) weight | 100% |
| Balance | final value − provisional paid | | debit if > 0, credit if < 0 |

The setup code has already loaded:

- `zinc_cash`: dict of date → LME zinc cash settlement (from `data/lme_prices.csv`)
- `fx`: dict of date → `{"usdinr": ..., "eurusd": ...}` (from `data/fx_rates.csv`)
- `trade`: the ZS-00001 trade as a dict

Build each function, Run to check it, then Submit to see which acceptance tests pass. When everything passes, **Download .py**, put it in a GitHub repo with a README, and mark it shipped.

```python example
print(trade)
print(len(zinc_cash), "zinc settlements; first:", min(zinc_cash), "last:", max(zinc_cash))
```

## Exercise
Build the module. The starter has the function signatures and docstrings; replace each `raise NotImplementedError`.

```python setup
import csv
zinc_cash = {}
with open("data/lme_prices.csv") as f:
    for row in csv.DictReader(f):
        if row["metal"] == "zinc":
            zinc_cash[row["date"]] = float(row["cash"])
fx = {}
with open("data/fx_rates.csv") as f:
    for row in csv.DictReader(f):
        fx[row["date"]] = {"usdinr": float(row["usdinr"]), "eurusd": float(row["eurusd"])}
trade = {"id": "ZS-00001", "counterparty": "Java Coated Steel Tbk", "tonnes": 400.0, "final_tonnes": 399.42,
         "premium": 158.0, "bl_date": "2025-01-15", "qp_type": "M+1", "qp_start": "2025-02-01", "qp_end": "2025-02-28", "pct": 0.9}
```

```python starter
"""Provisional vs Final Invoice Calculator: QP pricing for physical metal sales."""


def qp_prices(daily, start, end):
    """Settlement prices with start <= date <= end, in date order. daily: {"YYYY-MM-DD": price}."""
    raise NotImplementedError


def qp_average(prices):
    """Arithmetic mean of the QP prices, rounded to 2 dp. Raises ValueError if the QP is empty."""
    raise NotImplementedError


def provisional_invoice(tonnes, prov_price, premium, pct=0.9):
    """Returns {"unit_price": ..., "amount": ...}. Unit price rounded before multiplying."""
    raise NotImplementedError


def final_invoice(final_tonnes, qp_avg, premium, provisional_amount):
    """Returns {"unit_price", "final_value", "balance", "note"}; final value at 100%."""
    raise NotImplementedError


def convert(amount_usd, rate, pair):
    """USD -> EUR for pair "EURUSD" (divide), USD -> INR for "USDINR" (multiply). 2 dp."""
    raise NotImplementedError


def statement(trade, daily):
    """Plain-text final invoice statement for one trade."""
    raise NotImplementedError


if __name__ == "__main__":
    print(statement(trade, zinc_cash))
```

```python solution
"""Provisional vs Final Invoice Calculator: QP pricing for physical metal sales."""


def _check_tonnes(t):
    if not t > 0:
        raise ValueError(f"tonnes must be > 0, got {t}")


def qp_prices(daily, start, end):
    """Settlement prices with start <= date <= end, in date order. daily: {"YYYY-MM-DD": price}."""
    return [daily[d] for d in sorted(daily) if start <= d <= end]


def qp_average(prices):
    """Arithmetic mean of the QP prices, rounded to 2 dp. Raises ValueError if the QP is empty."""
    if not prices:
        raise ValueError("QP has no published prices")
    return round(sum(prices) / len(prices), 2)


def provisional_invoice(tonnes, prov_price, premium, pct=0.9):
    """Returns {"unit_price": ..., "amount": ...}. Unit price rounded before multiplying."""
    _check_tonnes(tonnes)
    unit = round(prov_price + premium, 2)
    return {"unit_price": unit, "amount": round(pct * tonnes * unit, 2)}


def final_invoice(final_tonnes, qp_avg, premium, provisional_amount):
    """Returns {"unit_price", "final_value", "balance", "note"}; final value at 100%."""
    _check_tonnes(final_tonnes)
    unit = round(qp_avg + premium, 2)
    value = round(final_tonnes * unit, 2)
    balance = round(value - provisional_amount, 2)
    note = "debit note" if balance > 0 else "credit note" if balance < 0 else "nil"
    return {"unit_price": unit, "final_value": value, "balance": balance, "note": note}


def convert(amount_usd, rate, pair):
    """USD -> EUR for pair "EURUSD" (divide), USD -> INR for "USDINR" (multiply). 2 dp."""
    if pair == "EURUSD":
        return round(amount_usd / rate, 2)
    if pair == "USDINR":
        return round(amount_usd * rate, 2)
    raise ValueError(f"unsupported pair {pair!r}")


def statement(trade, daily):
    """Plain-text final invoice statement for one trade."""
    prov = provisional_invoice(trade["tonnes"], daily[trade["bl_date"]], trade["premium"], trade["pct"])
    prices = qp_prices(daily, trade["qp_start"], trade["qp_end"])
    avg = qp_average(prices)
    fin = final_invoice(trade["final_tonnes"], avg, trade["premium"], prov["amount"])
    return "\n".join([
        f"FINAL INVOICE STATEMENT  {trade['id']}",
        f"Buyer: {trade['counterparty']}",
        f"QP {trade['qp_type']}: {trade['qp_start']} to {trade['qp_end']} ({len(prices)} days), average USD {avg:,.2f}/t",
        f"Final: {trade['final_tonnes']:,.3f} t x USD {fin['unit_price']:,.2f} = USD {fin['final_value']:,.2f}",
        f"Less provisional ({trade['pct']:.0%} of {trade['tonnes']:,.3f} t x USD {prov['unit_price']:,.2f}): USD {prov['amount']:,.2f}",
        f"Balance: USD {fin['balance']:,.2f} ({fin['note']})",
    ])


if __name__ == "__main__":
    print(statement(trade, zinc_cash))
```

```python test "QP window: M+1 February 2025"
import formulas as ref
exp = [zinc_cash[d] for d in sorted(zinc_cash) if "2025-02-01" <= d <= "2025-02-28"]
got = qp_prices(zinc_cash, "2025-02-01", "2025-02-28")
assert got == exp, f"qp_prices returned {len(got)} prices; expected the {len(exp)} February settlements in date order (inclusive of start and end)."
```

```python test "QP average"
import formulas as ref
prices = [zinc_cash[d] for d in sorted(zinc_cash) if "2025-02-01" <= d <= "2025-02-28"]
assert qp_average(prices) == round(ref.qp_average(prices), 2), f"qp_average gave {qp_average(prices)}; expected {round(ref.qp_average(prices), 2)}."
try:
    qp_average([])
    raise AssertionError("qp_average([]) should raise ValueError.")
except ValueError:
    pass
```

```python test "Provisional invoice"
p = provisional_invoice(400, zinc_cash["2025-01-15"], 158, 0.9)
unit = round(zinc_cash["2025-01-15"] + 158, 2)
assert p["unit_price"] == unit, f"unit_price is {p['unit_price']}; expected LME cash on the BL date + premium = {unit}."
assert p["amount"] == round(0.9 * 400 * unit, 2), f"amount is {p['amount']}; expected 90% x 400 t x {unit} = {round(0.9 * 400 * unit, 2):,.2f}."
assert provisional_invoice(100, 2800, 200, pct=1.0)["amount"] == 300000.0, "pct=1.0 should invoice 100%."
```

```python test "Final invoice and balance"
import formulas as ref
f1 = final_invoice(399.42, 3123.23, 158, 1164859.20)
assert f1["unit_price"] == 3281.23 and f1["final_value"] == round(399.42 * 3281.23, 2), f"Got {f1}; final value = final tonnes x (QP avg + premium) at 100%."
assert approx(f1["balance"], ref.final_balance(399.42, 3123.23, 158, 1164859.20), 0.011) and f1["note"] == "debit note", f"balance/note wrong: {f1}."
assert final_invoice(360, 3000, 158, 1164859.20)["note"] == "credit note", "360 t x 3,158 = 1,136,880 is below the 1,164,859.20 paid: a negative balance is a credit note."
```

```python test "FX conversion"
assert convert(145729.69, 1.1423, "EURUSD") == round(145729.69 / 1.1423, 2), "EURUSD is USD per 1 EUR: divide to get EUR."
assert convert(145729.69, 85.0222, "USDINR") == round(145729.69 * 85.0222, 2), "USDINR is INR per 1 USD: multiply to get INR."
try:
    convert(100, 1.1, "GBPUSD")
    raise AssertionError("Unsupported pairs should raise ValueError.")
except ValueError:
    pass
```

```python test "Rejects bad tonnes"
for fn, args in ((provisional_invoice, (0, 2800, 200)), (final_invoice, (-5, 2800, 200, 0))):
    try:
        fn(*args)
        raise AssertionError(f"{fn.__name__} should raise ValueError for tonnes <= 0.")
    except ValueError:
        pass
```

```python test "Statement contains the key figures"
s = statement(trade, zinc_cash)
prices = [zinc_cash[d] for d in sorted(zinc_cash) if trade["qp_start"] <= d <= trade["qp_end"]]
avg = round(sum(prices) / len(prices), 2)
prov = round(0.9 * 400 * round(zinc_cash["2025-01-15"] + 158, 2), 2)
fv = round(399.42 * round(avg + 158, 2), 2)
for label, needle in (("trade id", "ZS-00001"), ("QP average", f"{avg:,.2f}"), ("final value", f"{fv:,.2f}"), ("provisional amount", f"{prov:,.2f}"), ("balance", f"{fv - prov:,.2f}"), ("note", "debit note")):
    assert needle in s, f"The statement should show the {label} ({needle}); format money with :,.2f."
```

### Hint 1
Build and Run one function at a time, from the top. `statement` just calls the others.

### Hint 2
ISO date strings sort and compare correctly as text, so `start <= d <= end` works on `"2025-02-03"`. Loop over `sorted(daily)` to keep date order. The provisional price is `daily[trade["bl_date"]]`.

### Hint 3
```python
def qp_prices(daily, start, end):
    return [daily[d] for d in sorted(daily) if start <= d <= end]

def final_invoice(final_tonnes, qp_avg, premium, provisional_amount):
    unit = round(qp_avg + premium, 2)
    value = round(final_tonnes * unit, 2)
    balance = round(value - provisional_amount, 2)
    ...
```

## Interview
**Problem.** Final invoices on QP-priced physical zinc sales were built by hand in spreadsheets. Errors in the QP window, the provisional % and the rounding caused disputes and delayed cash collection.

**Approach.** Small pure functions (`qp_prices`, `qp_average`, `provisional_invoice`, `final_invoice`, `convert`, `statement`), each with input validation and automated tests against hand-checked values and a reference implementation. Rounding follows the contract: unit price to 2 dp before multiplying by tonnes.

**Result.** Reproduces the provisional-to-final flow for a real trade structure (400 t, M+1 QP, 90% provisional, outturn-weight adjustment) and produces a statement ready to email. Mention your quantified result here, e.g. time per final invoice or disputes avoided.

**Trade-offs.**
- Floats are fine for a calculator, but a production invoicing system should use `decimal.Decimal` and the contract's rounding mode. You'd switch in Level 8.
- Holidays are handled by using only published settlements (no fill), which matches LME practice. Some contracts specify a different average (e.g. excluding the first day), and that would need a parameter.
- The provisional basis (cash on BL date) is a parameter of the contract. Others use the prior month's average, which is a one-line change because the pricing is separated from the data.

## CV bullet
Built a tested Python invoicing engine for QP-priced physical zinc sales (provisional at BL, QP averaging, outturn-weight and FX adjustments, debit/credit notes), replacing a manual spreadsheet process and cutting final-invoice preparation time by **[X]%** across **[N]** invoices per month.
