---
id: l1-m6-boss
type: boss
title: Final invoice dispute at 4:55pm
minutes: 12
timeLimit: 720
concepts: [functions, function-args, exceptions, validation]
---

## Scenario
4:55pm. The LME close is in. Nordhavn Steel Coating disputes the final invoice: "Your balance is wrong, and why is it in the wrong direction?" The function that produced it was written in a hurry last quarter. Find and fix every bug before 5:10, when their AP team closes. No hints.

The contract: final value = final tonnes × (QP average + premium), **100%** (the 90% applies only to provisionals). Balance = final value − provisional paid. If `eurusd` is given, also return the balance in EUR (EUR/USD = USD per 1 EUR). An empty QP must raise `ValueError`.

## Exercise
Fix `final_invoice` so it returns a dict with `qp_avg` (rounded to 2), `unit_price`, `final_value`, `balance_usd` and `balance_eur` (or `None` when no rate is given), all money rounded to 2 decimals.

```python starter
def final_invoice(final_tonnes, qp_prices, premium, provisional_paid, eurusd=None):
    qp_avg = sum(qp_prices) / (len(qp_prices) - 1)
    unit_price = round(qp_avg + premium + premium, 2)
    final_value = round(final_tonnes * unit_price * 0.9, 2)
    balance = provisional_paid - final_value
    balance_eur = balance * eurusd if eurusd else None
    return {"qp_avg": qp_avg, "unit_price": unit_price, "final_value": final_value,
            "balance_usd": round(balance, 2), "balance_eur": balance_eur}
```

```python solution
def final_invoice(final_tonnes, qp_prices, premium, provisional_paid, eurusd=None):
    if not qp_prices:
        raise ValueError("QP has no published prices")
    qp_avg = round(sum(qp_prices) / len(qp_prices), 2)
    unit_price = round(qp_avg + premium, 2)
    final_value = round(final_tonnes * unit_price, 2)
    balance = round(final_value - provisional_paid, 2)
    balance_eur = round(balance / eurusd, 2) if eurusd else None
    return {"qp_avg": qp_avg, "unit_price": unit_price, "final_value": final_value,
            "balance_usd": balance, "balance_eur": balance_eur}
```

```python test "QP average"
r = final_invoice(1998.5, [2850, 2861, 2839, 2870, 2845], 248, 5_508_000)
assert r["qp_avg"] == 2853.0, f"qp_avg is {r['qp_avg']}; the mean of 5 prices divides by 5."
```

```python test "unit price and final value"
r = final_invoice(1998.5, [2850, 2861, 2839, 2870, 2845], 248, 5_508_000)
assert r["unit_price"] == 3101.0, f"unit_price is {r['unit_price']}; premium should be added once: 2,853 + 248."
assert r["final_value"] == 6197348.5, f"final_value is {r['final_value']}; final invoices are 100%: 1,998.5 x 3,101."
```

```python test "balance direction"
r = final_invoice(1998.5, [2850, 2861, 2839, 2870, 2845], 248, 5_508_000)
assert r["balance_usd"] == 689348.5, f"balance_usd is {r['balance_usd']}; balance = final value - provisional paid = +689,348.50 (buyer owes)."
```

```python test "EUR conversion"
r = final_invoice(1998.5, [2850, 2861, 2839, 2870, 2845], 248, 5_508_000, eurusd=1.085)
assert r["balance_eur"] == 635344.24, f"balance_eur is {r['balance_eur']}; USD to EUR divides by EUR/USD: 689,348.50 / 1.085."
assert final_invoice(1, [100], 0, 0)["balance_eur"] is None, "Without a rate, balance_eur should be None."
```

```python test "empty QP rejected"
try:
    final_invoice(100, [], 200, 0)
    raise AssertionError("An empty QP should raise ValueError.")
except ValueError:
    pass
```
