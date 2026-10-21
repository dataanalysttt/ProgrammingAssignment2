@echo off
REM Laptop only. Serves on 127.0.0.1, so nothing else on your network can reach it.
cd /d "%~dp0"
if not exist data\lme_prices.csv python data\generate_data.py
start "" http://127.0.0.1:8000/
REM serve.py = python -m http.server 8000 --bind 127.0.0.1 plus laptop/iPhone progress sync.
python serve.py --port 8000
pause
