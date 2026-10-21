---
id: l1-m1-l3
title: Money, rounding and float traps
minutes: 15
concepts: [rounding]
objectives:
- Round money to cents with round()
- Explain why 0.1 + 0.2 != 0.3
- Compare floats safely with math.isclose
---

## Learn
Floats are stored in binary, so most decimals are approximations:

```python example
print(0.1 + 0.2)
print(0.1 + 0.2 == 0.3)
```

Consequences on a desk:

1. **Round at the end, for presentation.** Keep full precision while calculating; round the final invoice amount to cents: `round(x, 2)`.
2. **Never test floats with `==`.** Use `math.isclose(a, b, abs_tol=0.005)` (within half a cent).
3. **Round the way the contract says.** Some contracts round the *unit price* to 2 decimals before multiplying by tonnes; that can give a different total from rounding only the total.

```python example
import math
tonnes = 1998.725
price = 3047.4567
print(round(tonnes * price, 2))                 # round the total
print(round(tonnes * round(price, 2), 2))       # round the unit price first
print(math.isclose(0.1 + 0.2, 0.3))
```

`round()` uses "banker's rounding" on exact halves (`round(2.5)` is `2`). Real money amounts are rarely exact halves in binary, so in practice this rarely matters; production systems use Python's `decimal` module (Level 8).

## Desk
An invoice that is $0.01 off its supporting calculation gets bounced by a careful AP department and delays payment by days. Payment terms of "30 days from BL" mean a bounced invoice costs real interest. Knowing where rounding happens is part of getting paid on time.

## Exercise
The contract says: *unit price = QP average + premium, rounded to 2 decimals; invoice amount = net weight × unit price, rounded to 2 decimals.*

Create `unit_price`, `invoice_amount`, and `difference`: how much the contract method differs from rounding only the final total (`round(net_weight * (qp_average + premium), 2)`), as `invoice_amount - naive`, rounded to 2 decimals.

```python starter
qp_average = 2847.89537
premium = 236.5
net_weight = 2499.875

```

```python solution
qp_average = 2847.89537
premium = 236.5
net_weight = 2499.875
unit_price = round(qp_average + premium, 2)
invoice_amount = round(net_weight * unit_price, 2)
naive = round(net_weight * (qp_average + premium), 2)
difference = round(invoice_amount - naive, 2)
```

```python test "unit_price = 3,084.40"
assert approx(unit_price, 3084.40, 1e-9), f"unit_price is {unit_price}; expected round(2847.89537 + 236.5, 2) = 3084.40."
```

```python test "invoice_amount = 7,710,614.45"
assert approx(invoice_amount, 7710614.45, 0.001), f"invoice_amount is {invoice_amount}; expected round(2499.875 x 3084.40, 2) = 7,710,614.45. Round the unit price BEFORE multiplying."
```

```python test "difference = 11.57"
assert approx(difference, 11.57, 0.001), f"difference is {difference}; the unrounded method gives 7,710,602.88, so the contract method is 11.57 higher."
```

### Hint 1
Two different calculations: one rounds the unit price first, one doesn't. Compute both, then subtract.

### Hint 2
`round(value, 2)` rounds to cents. Apply it to the unit price, then again to the total.

### Hint 3
```python
unit_price = round(qp_average + premium, 2)
invoice_amount = round(net_weight * unit_price, 2)
naive = round(net_weight * (qp_average + premium), 2)
difference = round(___ - ___, 2)
```

## Cards

### Card recall
concept: rounding
Q: Why shouldn't you check `invoice_total == expected` when both are floats? What do you use instead?
A: Floats are binary approximations (`0.1 + 0.2 != 0.3`). Use `math.isclose(a, b, abs_tol=0.005)` or compare rounded values.

### Card code
concept: rounding
Q: Set `amount` to **1,250.5 t × 2,901.237 USD/t**, rounded to cents.
```python starter
```
```python solution
amount = round(1250.5 * 2901.237, 2)
```
```python test "amount rounded to cents"
assert approx(amount, 3627996.87, 0.001), f"amount is {amount}; expected round(1250.5 * 2901.237, 2) = 3,627,996.87."
```

## Next
Zinc ships about 25 t to a container. How many boxes do you book for 1,060 t, and how much is left over?
