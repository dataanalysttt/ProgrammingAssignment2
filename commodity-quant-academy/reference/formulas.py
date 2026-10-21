"""
reference/formulas.py: the "answer key" for every financial formula used in the course.

Lessons, graders and CV projects check their numbers against these functions,
and reference/test_formulas.py checks THESE functions against textbook values.
Pure Python + math only, so it runs unchanged in CPython and in Pyodide.

Conventions
- Prices in USD/t unless stated. Rates are continuously compounded decimals (0.045 = 4.5%).
- T is time in years (ACT/365 unless a lesson says otherwise).
"""
from __future__ import annotations

import math
from statistics import NormalDist

_N = NormalDist()


def N(x: float) -> float:
    """Standard normal CDF."""
    return _N.cdf(x)


def n(x: float) -> float:
    """Standard normal PDF."""
    return _N.pdf(x)


# ---------------------------------------------------------------- physical pricing
def qp_average(prices: list[float]) -> float:
    """Arithmetic average of the daily settlement prices published in the quotational period.

    LME-linked contracts normally average the official cash settlement price over every
    LME business day in the QP (e.g. M+1 = the calendar month after shipment). Days with no
    publication are simply absent from the list, not filled.
    """
    if not prices:
        raise ValueError("QP has no published prices")
    return sum(prices) / len(prices)


def invoice_value(tonnes: float, lme_price: float, premium: float) -> float:
    """Gross invoice value = tonnes x (LME price + premium)."""
    return tonnes * (lme_price + premium)


def provisional_invoice(tonnes: float, provisional_price: float, premium: float, pct: float = 1.0) -> float:
    """Provisional invoice amount: pct (e.g. 0.90) of the provisional value."""
    return pct * invoice_value(tonnes, provisional_price, premium)


def final_balance(final_tonnes: float, qp_avg: float, premium: float, provisional_paid: float) -> float:
    """Final invoice balance = final value - amount already paid on provisional.

    Positive: buyer owes the seller. Negative: seller issues a credit note.
    """
    return invoice_value(final_tonnes, qp_avg, premium) - provisional_paid


def usd_to_ccy(amount_usd: float, rate: float, quote: str) -> float:
    """Convert a USD amount using a quoted FX rate.

    quote="CCYUSD" for EUR/USD-style quotes (USD per 1 EUR): divide.
    quote="USDCCY" for USD/INR-style quotes (INR per 1 USD): multiply.
    """
    if quote == "CCYUSD":
        return amount_usd / rate
    if quote == "USDCCY":
        return amount_usd * rate
    raise ValueError("quote must be 'CCYUSD' or 'USDCCY'")


# ---------------------------------------------------------------- carry and forwards
def cost_of_carry_forward(spot: float, r: float, T: float, storage: float = 0.0, conv_yield: float = 0.0) -> float:
    """Theoretical forward F = S * exp((r + u - y) T); u, y as continuous annual rates."""
    return spot * math.exp((r + storage - conv_yield) * T)


def simple_carry_forward(spot: float, r: float, days: int, storage_per_t_day: float, insurance_rate: float = 0.0) -> float:
    """Desk-style carry using simple interest on ACT/360: F = S(1 + rd/360) + storage*d + insurance."""
    return spot * (1 + r * days / 360) + storage_per_t_day * days + spot * insurance_rate * days / 360


# ---------------------------------------------------------------- Black-76
def _d1_d2(F: float, K: float, T: float, sigma: float) -> tuple[float, float]:
    vs = sigma * math.sqrt(T)
    d1 = (math.log(F / K) + 0.5 * sigma * sigma * T) / vs
    return d1, d1 - vs


def black76(F: float, K: float, T: float, r: float, sigma: float, kind: str = "C") -> float:
    """Black (1976) price of a European option on a forward or future."""
    d1, d2 = _d1_d2(F, K, T, sigma)
    df = math.exp(-r * T)
    if kind == "C":
        return df * (F * N(d1) - K * N(d2))
    if kind == "P":
        return df * (K * N(-d2) - F * N(-d1))
    raise ValueError("kind must be 'C' or 'P'")


def black76_greeks(F: float, K: float, T: float, r: float, sigma: float, kind: str = "C") -> dict:
    """Greeks of the Black-76 price with respect to F (delta, gamma), sigma (vega per 1.00),
    time (theta per year, as calendar time passes) and r (rho)."""
    d1, d2 = _d1_d2(F, K, T, sigma)
    df = math.exp(-r * T)
    price = black76(F, K, T, r, sigma, kind)
    gamma = df * n(d1) / (F * sigma * math.sqrt(T))
    vega = df * F * n(d1) * math.sqrt(T)
    if kind == "C":
        delta = df * N(d1)
        theta = -df * F * n(d1) * sigma / (2 * math.sqrt(T)) + r * price
    else:
        delta = -df * N(-d1)
        theta = -df * F * n(d1) * sigma / (2 * math.sqrt(T)) + r * price
    rho = -T * price
    return {"price": price, "delta": delta, "gamma": gamma, "vega": vega, "theta": theta, "rho": rho}


def implied_vol_black76(price: float, F: float, K: float, T: float, r: float, kind: str = "C",
                        lo: float = 1e-4, hi: float = 5.0, tol: float = 1e-10) -> float:
    """Implied volatility by bisection (robust, monotone in sigma)."""
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if black76(F, K, T, r, mid, kind) > price:
            hi = mid
        else:
            lo = mid
        if hi - lo < tol:
            break
    return 0.5 * (lo + hi)


# ---------------------------------------------------------------- risk
def parametric_var(position_value: float, sigma_daily: float, confidence: float = 0.99, horizon_days: int = 1) -> float:
    """Normal (variance-covariance) VaR, zero mean: z * sigma * sqrt(h) * |V|. Reported as a positive loss."""
    z = _N.inv_cdf(confidence)
    return z * sigma_daily * math.sqrt(horizon_days) * abs(position_value)


def _tail_count(n_obs: int, confidence: float) -> int:
    """k = ceil(n * (1 - c)), rounded first so 100 * (1 - 0.95) = 5.0000000000000004 gives 5, not 6."""
    return max(1, math.ceil(round(n_obs * (1 - confidence), 9)))


def historical_var(pnl: list[float], confidence: float = 0.99) -> float:
    """Historical VaR: the loss at the (1-confidence) quantile of the P&L distribution.

    Convention used throughout the course: sort P&L ascending and take the k-th worst
    observation with k = ceil(n * (1 - confidence)). Reported as a positive loss.
    """
    s = sorted(pnl)
    k = _tail_count(len(s), confidence)
    return -s[k - 1]


def historical_cvar(pnl: list[float], confidence: float = 0.99) -> float:
    """Expected shortfall: mean of the k worst outcomes (same k as historical_var)."""
    s = sorted(pnl)
    k = _tail_count(len(s), confidence)
    return -sum(s[:k]) / k


def min_variance_hedge_ratio(rho: float, sigma_spot: float, sigma_fut: float) -> float:
    """h* = rho * sigma_S / sigma_F (Hull)."""
    return rho * sigma_spot / sigma_fut
