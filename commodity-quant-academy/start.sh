#!/usr/bin/env sh
# Laptop only. Serves on 127.0.0.1, so nothing else on your network can reach it.
cd "$(dirname "$0")"
PY=python3; command -v python3 >/dev/null 2>&1 || PY=python
[ -f data/lme_prices.csv ] || $PY data/generate_data.py
( sleep 1; (command -v open >/dev/null && open http://127.0.0.1:8000/) || (command -v xdg-open >/dev/null && xdg-open http://127.0.0.1:8000/) ) >/dev/null 2>&1 &
# serve.py = python -m http.server 8000 --bind 127.0.0.1 plus laptop<->iPhone progress sync.
exec $PY serve.py --port 8000
