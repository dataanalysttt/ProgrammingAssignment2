@echo off
REM Laptop + your iPhone on the same Wi-Fi. Phone access needs the secret key printed below.
REM Windows may ask to allow Python through the firewall: allow it on PRIVATE networks only.
cd /d "%~dp0"
if not exist data\lme_prices.csv python data\generate_data.py
python serve.py --port 8000 --phone
pause
