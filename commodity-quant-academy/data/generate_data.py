"""
generate_data.py: builds every synthetic dataset used by Commodity Quant Academy.

All numbers are SYNTHETIC. They are shaped to look like LME base-metal and
physical-desk data (price levels, contango/backwardation regimes, premiums,
freight, FX) but no licensed exchange data is used or shipped.

Run from the app folder:
    python data/generate_data.py            # writes CSVs into data/
    python data/generate_data.py --seed 7   # different but reproducible world

Needs numpy and pandas (pip install numpy pandas). Pyodide is NOT needed.
Column dictionary: data/README.md
"""
from __future__ import annotations

import argparse
import math
from pathlib import Path

import numpy as np
import pandas as pd

OUT = Path(__file__).resolve().parent
START, END = "2022-01-03", "2026-09-30"
RISK_FREE = 0.045  # flat USD rate used for carry and option pricing


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------
def norm_cdf(x: np.ndarray | float) -> np.ndarray | float:
    """Standard normal CDF without scipy (vectorised via math.erf)."""
    return 0.5 * (1.0 + np.vectorize(math.erf)(np.asarray(x) / math.sqrt(2.0)))


def black76(F, K, T, r, sigma, kind):
    """Black-76 price of a European option on a forward/future."""
    F, K, sigma = np.asarray(F, float), np.asarray(K, float), np.asarray(sigma, float)
    d1 = (np.log(F / K) + 0.5 * sigma**2 * T) / (sigma * np.sqrt(T))
    d2 = d1 - sigma * np.sqrt(T)
    df = math.exp(-r * T)
    if kind == "C":
        return df * (F * norm_cdf(d1) - K * norm_cdf(d2))
    return df * (K * norm_cdf(-d2) - F * norm_cdf(-d1))


def business_days() -> pd.DatetimeIndex:
    return pd.bdate_range(START, END)


# --------------------------------------------------------------------------
# 1. LME-style cash and 3M prices with contango/backwardation regimes
# --------------------------------------------------------------------------
METALS = {
    # metal: (start cash $/t, annual vol, long-run drift, contango carry $/t, long-run anchor $/t)
    "zinc": (3550.0, 0.22, 0.0, 38.0, 2750.0),
    "copper": (9700.0, 0.20, 0.0, 95.0, 9300.0),
    "aluminium": (2850.0, 0.20, 0.0, 32.0, 2450.0),
}


def make_lme_prices(rng: np.random.Generator, days: pd.DatetimeIndex) -> pd.DataFrame:
    n, dt = len(days), 1 / 252
    frames = []
    for metal, (s0, vol, drift, carry, level) in METALS.items():
        # Cash price: GBM with mean reversion in log space toward a long-run level, so the
        # path stays in a range a base-metals desk would recognise
        log_p = np.empty(n)
        log_p[0] = math.log(s0)
        anchor = math.log(level)
        for t in range(1, n):
            shock = rng.normal(0, vol * math.sqrt(dt))
            pull = 0.9 * (anchor - log_p[t - 1]) * dt
            log_p[t] = log_p[t - 1] + (drift - 0.5 * vol**2) * dt + pull + shock
        cash = np.exp(log_p)

        # Regime: 0 = contango, 1 = backwardation (two-state Markov chain)
        regime = np.zeros(n, dtype=int)
        stay = {0: 0.992, 1: 0.985}
        for t in range(1, n):
            prev = regime[t - 1]
            regime[t] = prev if rng.random() < stay[prev] else 1 - prev

        # Spread = cash - 3M. Contango: negative (about -carry). Backwardation: positive.
        spread = np.empty(n)
        spread[0] = -carry
        for t in range(1, n):
            target = -carry if regime[t] == 0 else carry * 1.8
            spread[t] = spread[t - 1] + 0.08 * (target - spread[t - 1]) + rng.normal(0, carry * 0.12)
            # occasional squeeze spikes in backwardation (tight nearby supply)
            if regime[t] == 1 and rng.random() < 0.01:
                spread[t] += rng.uniform(2, 6) * carry
        three_m = cash - spread

        frames.append(pd.DataFrame({
            "date": days.date, "metal": metal,
            "cash": cash.round(2), "three_month": three_m.round(2),
            "cash_3m_spread": spread.round(2),
            "regime": np.where(regime == 1, "backwardation", "contango"),
            "stocks_t": (rng.normal(0, 1, n).cumsum() * 900 + {"zinc": 60_000, "copper": 120_000, "aluminium": 500_000}[metal]).clip(5_000).round(0).astype(int),
        }))
    return pd.concat(frames, ignore_index=True)


# --------------------------------------------------------------------------
# 2. Forward curves: monthly snapshots, tenors 0-27 months
# --------------------------------------------------------------------------
def make_forward_curves(prices: pd.DataFrame) -> pd.DataFrame:
    rows = []
    prices = prices.copy()
    prices["date"] = pd.to_datetime(prices["date"])
    month_ends = prices.groupby(prices["date"].dt.to_period("M"))["date"].max().iloc[-12:]
    for as_of in month_ends:
        snap = prices[prices["date"] == as_of]
        for _, r in snap.iterrows():
            carry_rate = METALS[r["metal"]][3] * 4 / r["cash"]  # annualised carry implied by full contango
            for tenor in range(0, 28):
                # long end: contango carry; front end: current spread decays with tenor
                contango_px = r["three_month"] * math.exp(carry_rate * (tenor - 3) / 12)
                front = r["cash_3m_spread"] * math.exp(-tenor / 4.0) * (1 if tenor < 3 else 0.6)
                rows.append({"as_of": as_of.date(), "metal": r["metal"], "tenor_months": tenor,
                             "price": round(contango_px + front, 2)})
    return pd.DataFrame(rows)


# --------------------------------------------------------------------------
# 3. FX: USD/INR and EUR/USD
# --------------------------------------------------------------------------
def make_fx(rng: np.random.Generator, days: pd.DatetimeIndex) -> pd.DataFrame:
    n, dt = len(days), 1 / 252
    inr = np.empty(n); eur = np.empty(n)
    inr[0], eur[0] = 74.4, 1.135
    for t in range(1, n):
        inr[t] = inr[t - 1] * math.exp(0.035 * dt + rng.normal(0, 0.045 * math.sqrt(dt)))
        eur_target = 1.05 if t < n * 0.55 else 1.16
        eur[t] = eur[t - 1] * math.exp(0.6 * math.log(eur_target / eur[t - 1]) * dt + rng.normal(0, 0.075 * math.sqrt(dt)))
    return pd.DataFrame({"date": days.date, "usdinr": inr.round(4), "eurusd": eur.round(5)})


# --------------------------------------------------------------------------
# 4. Freight: weekly container and dry-bulk rates in USD per tonne
# --------------------------------------------------------------------------
ROUTES = {
    # route: (base USD/t, vol, mode)
    "Nhava Sheva-Rotterdam": (62, 0.35, "container"),
    "Nhava Sheva-Antwerp": (64, 0.35, "container"),
    "Nhava Sheva-Genoa": (58, 0.35, "container"),
    "Nhava Sheva-Jebel Ali": (22, 0.25, "container"),
    "Nhava Sheva-Casablanca": (55, 0.30, "container"),
    "Chennai-Durban": (38, 0.28, "container"),
    "Chennai-Port Klang": (24, 0.25, "container"),
    "Nhava Sheva-Santos": (78, 0.32, "container"),
    "Richards Bay-Krishnapatnam": (19, 0.40, "dry bulk (coal, Supramax)"),
}


def make_freight(rng: np.random.Generator) -> pd.DataFrame:
    weeks = pd.date_range(START, END, freq="W-FRI")
    n = len(weeks)
    rows = []
    for route, (base, vol, mode) in ROUTES.items():
        x = np.zeros(n)
        for t in range(1, n):
            x[t] = x[t - 1] * 0.93 + rng.normal(0, vol * 0.25)
        level = base * np.exp(x)
        # Red-Sea style disruption: Europe/Med container lanes spike Jan-Jun 2024
        if mode == "container" and any(k in route for k in ("Rotterdam", "Antwerp", "Genoa", "Casablanca")):
            spike = (weeks >= "2024-01-05") & (weeks <= "2024-06-28")
            level = np.where(spike, level * 2.1, level)
        for w, v in zip(weeks, level):
            rows.append({"week_ending": w.date(), "route": route, "mode": mode, "usd_per_t": round(float(v), 2)})
    return pd.DataFrame(rows)


# --------------------------------------------------------------------------
# 5. Physical trade book
# --------------------------------------------------------------------------
COUNTERPARTIES = [
    # Fictional names. (name, country, region, base premium $/t, default incoterm)
    ("Rheinwerk Galvanik GmbH", "Germany", "Europe", 245, "DAP"), ("Nordhavn Steel Coating A/S", "Denmark", "Europe", 250, "DAP"),
    ("Lombardia Zincatura SpA", "Italy", "Europe", 235, "CIF"), ("Iberica Metales SL", "Spain", "Europe", 230, "CIF"),
    ("Flandres Alloys NV", "Belgium", "Europe", 240, "DDP"), ("Vistula Ocynkownia Sp. z o.o.", "Poland", "Europe", 238, "DAP"),
    ("Tyne Galvanisers Ltd", "United Kingdom", "Europe", 242, "DAP"), ("Rhone Metallurgie SA", "France", "Europe", 236, "CFR"),
    ("Bosporus Galvaniz AS", "Turkey", "Middle East", 205, "CFR"), ("Gulf Coil Coating LLC", "UAE", "Middle East", 190, "CFR"),
    ("Najd Steel Products Co", "Saudi Arabia", "Middle East", 195, "CIF"), ("Qatar Wire & Strip WLL", "Qatar", "Middle East", 192, "CFR"),
    ("Oman Coated Metals SAOC", "Oman", "Middle East", 188, "CFR"), ("Levant Die Casting SAL", "Lebanon", "Middle East", 200, "CIF"),
    ("Atlas Galvanisation SARL", "Morocco", "North Africa", 215, "CIF"), ("Nile Steel Pipes SAE", "Egypt", "North Africa", 210, "CFR"),
    ("Carthage Metaux SA", "Tunisia", "North Africa", 212, "CIF"), ("Maghreb Toles SPA", "Algeria", "North Africa", 214, "CFR"),
    ("Highveld Galvanising (Pty) Ltd", "South Africa", "South Africa", 175, "CFR"), ("Cape Zinc Die Casters (Pty) Ltd", "South Africa", "South Africa", 178, "CIF"),
    ("Natal Wire Products (Pty) Ltd", "South Africa", "South Africa", 172, "FOB"), ("Gauteng Coil Lines (Pty) Ltd", "South Africa", "South Africa", 176, "CFR"),
    ("Selangor Zinc Industries Sdn Bhd", "Malaysia", "SE Asia", 150, "CFR"), ("Saigon Galvanized Steel JSC", "Vietnam", "SE Asia", 145, "CFR"),
    ("Java Coated Steel Tbk", "Indonesia", "SE Asia", 148, "CIF"), ("Chao Phraya Metal Works Co", "Thailand", "SE Asia", 147, "CFR"),
    ("Luzon Steel Sheet Corp", "Philippines", "SE Asia", 152, "CIF"), ("Mekong Die Casting Co", "Vietnam", "SE Asia", 144, "FCA"),
    ("Straits Alloy Trading Pte Ltd", "Singapore", "SE Asia", 140, "FCA"), ("Paulista Galvanizacao Ltda", "Brazil", "LATAM", 260, "CIF"),
    ("Andes Recubrimientos SA", "Chile", "LATAM", 255, "CFR"), ("Rio Plata Metales SA", "Argentina", "LATAM", 265, "CIF"),
    ("Monterrey Laminados SA de CV", "Mexico", "LATAM", 250, "DAP"), ("Bogota Aceros Galvanizados SAS", "Colombia", "LATAM", 258, "CFR"),
    ("Lima Zinc Industrial SAC", "Peru", "LATAM", 252, "FOB"), ("Gujarat Galva Strips Pvt Ltd", "India", "India", 120, "FCA"),
    ("Deccan Die Casting Pvt Ltd", "India", "India", 118, "DAP"), ("Konkan Wire & Cable Ltd", "India", "India", 122, "DDP"),
]
SUPPLIERS = [("Vindhya Smelting Ltd", "India", "India"), ("Coromandel Zinc Refinery Ltd", "India", "India"),
             ("Kola Peninsula Metals JSC", "Kazakhstan", "CIS")]
DEST_PORT = {"Europe": "Rotterdam", "Middle East": "Jebel Ali", "North Africa": "Casablanca",
             "South Africa": "Durban", "SE Asia": "Port Klang", "LATAM": "Santos", "India": "Nhava Sheva", "CIS": "Nhava Sheva"}


def qp_window(shipment: pd.Period, qp_type: str) -> tuple[pd.Timestamp, pd.Timestamp]:
    offset = {"M-1": -1, "M": 0, "M+1": 1, "M+2": 2}[qp_type]
    p = shipment + offset
    return p.start_time, p.end_time.normalize()


def make_trade_book(rng: np.random.Generator, prices: pd.DataFrame, fx: pd.DataFrame) -> pd.DataFrame:
    zinc = prices[prices["metal"] == "zinc"].copy()
    zinc["date"] = pd.to_datetime(zinc["date"])
    cash_by_day = zinc.set_index("date")["cash"]
    fx_by_day = fx.assign(date=pd.to_datetime(fx["date"])).set_index("date")["eurusd"]
    last_day = cash_by_day.index.max()

    rows, tid = [], 1
    for ship in pd.period_range("2025-01", "2026-12", freq="M"):
        # 10-12 kt/month of sales, built from 25-t lots across counterparties
        target, done = rng.uniform(10_000, 12_000), 0.0
        while done < target:
            name, country, region, prem, inc = COUNTERPARTIES[rng.integers(len(COUNTERPARTIES))]
            tonnes = float(rng.choice([100, 150, 200, 250, 300, 400, 500, 750, 1000]))
            trade_date = (ship.start_time - pd.Timedelta(days=int(rng.integers(20, 75)))).normalize()
            qp_type = rng.choice(["M+1", "M", "M-1", "fixed"], p=[0.5, 0.25, 0.15, 0.10])
            incoterm = inc if rng.random() < 0.8 else rng.choice(["FCA", "FOB", "CFR", "CIF", "DAP", "DDP"])
            premium = round(prem + rng.normal(0, 12), 0)
            currency = "EUR" if (region == "Europe" and rng.random() < 0.35) else "USD"
            rows.append(_trade_row(tid, "S", name, country, region, tonnes, trade_date, ship, qp_type,
                                   incoterm, premium, currency, cash_by_day, fx_by_day, last_day, rng))
            tid += 1; done += tonnes
        # purchases from smelters covering roughly the same volume
        bought = 0.0
        while bought < done * 0.97:
            name, country, region = SUPPLIERS[rng.integers(len(SUPPLIERS))]
            tonnes = float(rng.choice([1000, 1500, 2000, 2500]))
            trade_date = (ship.start_time - pd.Timedelta(days=int(rng.integers(45, 100)))).normalize()
            qp_type = rng.choice(["M+1", "M", "M-1"], p=[0.4, 0.4, 0.2])
            premium = round(rng.normal(95, 10), 0)
            rows.append(_trade_row(tid, "P", name, country, region, tonnes, trade_date, ship, qp_type,
                                   "FCA", premium, "USD", cash_by_day, fx_by_day, last_day, rng))
            tid += 1; bought += tonnes
    return pd.DataFrame(rows)


def _trade_row(tid, direction, name, country, region, tonnes, trade_date, ship, qp_type, incoterm, premium,
               currency, cash_by_day, fx_by_day, last_day, rng):
    if qp_type == "fixed":
        px_on = cash_by_day.asof(min(trade_date, last_day))
        qp_start = qp_end = trade_date
        fixed_price = round(float(px_on), 2)
    else:
        qp_start, qp_end = qp_window(ship, qp_type)
        fixed_price = np.nan
    # provisional price: cash on (or before) the bill-of-lading date, mid-shipment month
    bl_date = ship.start_time + pd.Timedelta(days=int(rng.integers(3, 25)))
    prov_basis = cash_by_day.asof(min(bl_date, last_day))
    provisional = fixed_price if qp_type == "fixed" else round(float(prov_basis), 2)

    if qp_type == "fixed":
        final_price, status = fixed_price, "priced"
    elif qp_end <= last_day:
        qp_avg = cash_by_day.loc[qp_start:qp_end].mean()
        final_price, status = round(float(qp_avg), 2), "priced"
    elif qp_start <= last_day:
        final_price, status = np.nan, "pricing"  # QP running
    else:
        final_price, status = np.nan, "open"
    if bl_date > last_day:
        status = "open"
    return {
        "trade_id": f"{'ZS' if direction == 'S' else 'ZP'}-{tid:05d}", "trade_date": trade_date.date(),
        "direction": direction, "counterparty": name, "country": country, "region": region,
        "metal": "zinc", "grade": "SHG 99.995%", "tonnes": tonnes, "shipment_month": str(ship),
        "bl_date": bl_date.date(), "incoterm": incoterm,
        "load_port": "Nhava Sheva" if direction == "S" else "Works FCA",
        "destination": DEST_PORT[region], "qp_type": qp_type,
        "qp_start": qp_start.date(), "qp_end": qp_end.date(),
        "premium_usd_t": premium, "provisional_price_usd_t": provisional,
        "provisional_pct": 0.9 if direction == "S" else 1.0,
        "final_price_usd_t": final_price, "invoice_currency": currency,
        "eurusd_at_bl": round(float(fx_by_day.asof(min(bl_date, last_day))), 5),
        "payment_terms": rng.choice(["CAD", "LC at sight", "30 days from BL", "60 days from BL"]) if direction == "S" else "30 days from BL",
        "status": status,
    }


# --------------------------------------------------------------------------
# 6. Option chains: LME zinc (on 3M) and a NIFTY-style index (on futures)
# --------------------------------------------------------------------------
def make_option_chains(rng: np.random.Generator, prices: pd.DataFrame) -> pd.DataFrame:
    last = prices[prices["date"] == prices["date"].max()]
    as_of = pd.Timestamp(last["date"].iloc[0])
    rows = []
    zinc_f = float(last[last["metal"] == "zinc"]["three_month"].iloc[0])
    for months in (1, 2, 3, 6, 12):
        T = months / 12
        for K in np.arange(round(zinc_f * 0.8 / 50) * 50, zinc_f * 1.2, 50):
            m = math.log(K / zinc_f)
            iv = 0.22 + 0.02 / math.sqrt(T + 0.25) - 0.10 * m + 0.35 * m * m  # smile with put skew
            for kind in ("C", "P"):
                px = float(black76(zinc_f, K, T, RISK_FREE, iv, kind))
                rows.append(_opt_row(as_of, "LME Zinc 3M", zinc_f, as_of + pd.DateOffset(months=months), T, K, kind, iv, px, 25, rng))
    nifty_f = 25_150.0
    for weeks in (1, 2, 4, 8, 13):
        T = weeks * 7 / 365
        for K in np.arange(23_500, 26_850, 50):
            m = math.log(K / nifty_f)
            iv = 0.125 + 0.01 / math.sqrt(T * 52) - 0.45 * m + 2.0 * m * m
            for kind in ("C", "P"):
                px = float(black76(nifty_f, K, T, 0.065, iv, kind))
                rows.append(_opt_row(as_of, "NIFTY (synthetic)", nifty_f, as_of + pd.Timedelta(weeks=weeks), T, K, kind, iv, px, 75, rng))
    return pd.DataFrame(rows)


def _opt_row(as_of, und, F, expiry, T, K, kind, iv, px, lot, rng):
    tick = 0.05 if "NIFTY" in und else 0.5
    half_spread = max(tick, px * 0.015)
    return {"as_of": as_of.date(), "underlying": und, "underlying_price": round(F, 2), "expiry": expiry.date(),
            "t_years": round(T, 5), "strike": float(K), "type": kind, "implied_vol": round(iv, 4),
            "mid": round(px, 2), "bid": round(max(px - half_spread, 0), 2), "ask": round(px + half_spread, 2),
            "open_interest": int(rng.integers(0, 5000) * math.exp(-abs(math.log(K / F)) * 12)), "lot_size": lot}


# --------------------------------------------------------------------------
# 7. Synthetic index daily bars (for the Level 7 options backtester)
# --------------------------------------------------------------------------
def make_index_daily(rng: np.random.Generator, days: pd.DatetimeIndex) -> pd.DataFrame:
    n = len(days)
    close = np.empty(n); close[0] = 17_400.0
    vol = np.empty(n); vol[0] = 0.14
    for t in range(1, n):
        vol[t] = max(0.08, vol[t - 1] + 0.05 * (0.14 - vol[t - 1]) + rng.normal(0, 0.006))
        close[t] = close[t - 1] * math.exp(0.11 / 252 + rng.normal(0, vol[t] / math.sqrt(252)))
    rng_hl = np.abs(rng.normal(0, 0.006, n))
    open_ = close * (1 + rng.normal(0, 0.003, n))
    return pd.DataFrame({"date": days.date, "open": open_.round(2),
                         "high": (np.maximum(open_, close) * (1 + rng_hl)).round(2),
                         "low": (np.minimum(open_, close) * (1 - rng_hl)).round(2),
                         "close": close.round(2), "india_vix_like": (vol * 100).round(2)})


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--seed", type=int, default=2026)
    args = ap.parse_args()
    rng = np.random.default_rng(args.seed)
    days = business_days()

    prices = make_lme_prices(rng, days)
    fx = make_fx(rng, days)
    outputs = {
        "lme_prices.csv": prices,
        "forward_curves.csv": make_forward_curves(prices),
        "fx_rates.csv": fx,
        "freight_rates.csv": make_freight(rng),
        "trade_book.csv": make_trade_book(rng, prices, fx),
        "option_chains.csv": make_option_chains(rng, prices),
        "index_daily.csv": make_index_daily(rng, days),
    }
    for name, df in outputs.items():
        df.to_csv(OUT / name, index=False)
        print(f"wrote data/{name:<20} {len(df):>6} rows")


if __name__ == "__main__":
    main()
