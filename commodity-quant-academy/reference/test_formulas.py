"""
Reference tests: every formula in formulas.py against an independently known value.

Run:  python -m pytest reference -q      (or)      python reference/test_formulas.py
Also runnable inside the app: Settings -> "Run formula reference tests" (Pyodide).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import formulas as f  # noqa: E402


def close(a, b, tol):
    assert abs(a - b) <= tol, f"{a} != {b} (tol {tol})"


# ---- physical pricing: hand-computed values
def test_qp_average():
    close(f.qp_average([2800, 2810, 2790, 2820]), 2805.0, 1e-12)


def test_provisional_and_final_invoice():
    # 2,000 t at LME 2,800 + 250 premium, 90% provisional
    prov = f.provisional_invoice(2000, 2800, 250, 0.90)
    close(prov, 5_490_000.0, 1e-6)
    # final: 1,998.5 t, QP avg 2,850 -> value 1,998.5 * 3,100 = 6,195,350; balance = 705,350
    close(f.final_balance(1998.5, 2850, 250, prov), 705_350.0, 1e-6)


def test_fx_conversion_directions():
    close(f.usd_to_ccy(1_000_000, 1.10, "CCYUSD"), 909_090.909090909, 1e-6)  # EUR
    close(f.usd_to_ccy(1_000_000, 83.25, "USDCCY"), 83_250_000.0, 1e-6)       # INR


# ---- carry
def test_cost_of_carry():
    # Hull-style: S=100, r=5%, T=1, no storage -> 100*e^0.05 = 105.127
    close(f.cost_of_carry_forward(100, 0.05, 1.0), 105.12710963760242, 1e-9)
    # with storage 2% and convenience yield 2%: back to r only
    close(f.cost_of_carry_forward(100, 0.05, 1.0, 0.02, 0.02), 105.12710963760242, 1e-9)
    # desk carry: 2,800 spot, 5% ACT/360, 90 days, $0.15/t/day storage
    close(f.simple_carry_forward(2800, 0.05, 90, 0.15), 2800 * (1 + 0.05 * 90 / 360) + 13.5, 1e-9)


# ---- Black-76: Hull, Options Futures & Other Derivatives, futures-option example
def test_black76_hull_put():
    # F=20, K=20, r=9%, T=4/12, sigma=25% -> put = 1.12 (Hull)
    close(f.black76(20, 20, 4 / 12, 0.09, 0.25, "P"), 1.12, 0.005)


def test_black76_matches_black_scholes():
    # Black-Scholes textbook: S=42, K=40, r=10%, sigma=20%, T=0.5 -> c=4.76, p=0.81 (Hull)
    S, K, r, sig, T = 42, 40, 0.10, 0.20, 0.5
    F = S * math.exp(r * T)
    close(f.black76(F, K, T, r, sig, "C"), 4.76, 0.005)
    close(f.black76(F, K, T, r, sig, "P"), 0.81, 0.005)


def test_put_call_parity():
    F, K, T, r, s = 2850, 2900, 0.25, 0.045, 0.22
    c, p = f.black76(F, K, T, r, s, "C"), f.black76(F, K, T, r, s, "P")
    close(c - p, math.exp(-r * T) * (F - K), 1e-9)


def test_greeks_against_finite_differences():
    F, K, T, r, s = 2850, 2900, 0.25, 0.045, 0.22
    for kind in ("C", "P"):
        g = f.black76_greeks(F, K, T, r, s, kind)
        h = 0.01
        px = lambda **kw: f.black76(kw.get("F", F), K, kw.get("T", T), kw.get("r", r), kw.get("s", s), kind)  # noqa: E731
        close(g["delta"], (px(F=F + h) - px(F=F - h)) / (2 * h), 1e-6)
        close(g["gamma"], (px(F=F + h) - 2 * px() + px(F=F - h)) / h**2, 1e-4)
        close(g["vega"], (px(s=s + 1e-5) - px(s=s - 1e-5)) / 2e-5, 1e-4)
        close(g["theta"], -(px(T=T + 1e-6) - px(T=T - 1e-6)) / 2e-6, 1e-2)
        close(g["rho"], (px(r=r + 1e-6) - px(r=r - 1e-6)) / 2e-6, 1e-3)


def test_implied_vol_roundtrip():
    price = f.black76(2850, 2700, 0.5, 0.045, 0.31, "P")
    close(f.implied_vol_black76(price, 2850, 2700, 0.5, 0.045, "P"), 0.31, 1e-7)


# ---- risk
def test_parametric_var():
    # $1,000,000 position, 2% daily vol, 99%: z=2.3263 -> 46,527
    close(f.parametric_var(1_000_000, 0.02, 0.99), 46_526.957, 0.01)
    # 10-day scales by sqrt(10)
    close(f.parametric_var(1_000_000, 0.02, 0.99, 10), 46_526.957 * math.sqrt(10), 0.05)


def test_historical_var_and_cvar():
    pnl = list(range(-50, 50))  # 100 outcomes: -50 .. 49
    # 95%: k = ceil(100*0.05) = 5 -> 5th worst = -46 -> VaR 46; CVaR = mean(50,49,48,47,46) = 48
    close(f.historical_var(pnl, 0.95), 46, 1e-12)
    close(f.historical_cvar(pnl, 0.95), 48, 1e-12)


def test_hedge_ratio():
    # Hull example: rho=0.928, sigma_S=0.0263, sigma_F=0.0313 -> h=0.78
    close(f.min_variance_hedge_ratio(0.928, 0.0263, 0.0313), 0.78, 0.001)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    failed = 0
    for t in tests:
        try:
            t(); print(f"PASS {t.__name__}")
        except AssertionError as e:
            failed += 1; print(f"FAIL {t.__name__}: {e}")
    print(f"\n{len(tests) - failed}/{len(tests)} passed")
    sys.exit(1 if failed else 0)
