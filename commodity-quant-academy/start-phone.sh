#!/usr/bin/env sh
# Laptop + your iPhone on the same Wi-Fi. Phone access needs the secret key printed below.
cd "$(dirname "$0")"
PY=python3; command -v python3 >/dev/null 2>&1 || PY=python
[ -f data/lme_prices.csv ] || $PY data/generate_data.py
exec $PY serve.py --port 8000 --phone
