"""
serve.py: tiny standard-library server for Commodity Quant Academy.

    python serve.py              # laptop only: http://127.0.0.1:8000  (same as start.sh)
    python serve.py --phone      # also reachable from your iPhone on the same Wi-Fi,
                                 # but ONLY with the secret key printed at startup

Why not just `python -m http.server`? That also works for laptop-only use. This script adds:
  * --phone mode: every non-localhost request must carry the secret key (cookie after the
    first visit), and only private LAN addresses (192.168.x, 10.x, 172.16-31.x) may connect;
  * /api/sync: lets the iPhone and the laptop exchange progress JSON via progress-sync/;
  * correct MIME types for .wasm/.mjs/.md, no directory listings, dotfiles never served.
No third-party packages. Nothing leaves your network.
"""
from __future__ import annotations

import argparse
import http.cookies
import http.server
import ipaddress
import json
import secrets
import socket
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parent
TOKEN_FILE = ROOT / ".phone-token"
SYNC_DIR = ROOT / "progress-sync"
MAX_SYNC_BYTES = 5_000_000


def phone_token() -> str:
    if TOKEN_FILE.exists():
        return TOKEN_FILE.read_text().strip()
    tok = secrets.token_urlsafe(9)
    TOKEN_FILE.write_text(tok)
    return tok


def lan_ip() -> str:
    """The address other devices on the Wi-Fi use to reach this laptop (no packets are sent)."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


class Handler(http.server.SimpleHTTPRequestHandler):
    phone_mode = False
    token = ""
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      ".wasm": "application/wasm", ".mjs": "text/javascript", ".js": "text/javascript",
                      ".md": "text/markdown; charset=utf-8", ".json": "application/json",
                      ".webmanifest": "application/manifest+json", ".py": "text/plain; charset=utf-8"}

    def __init__(self, *a, **kw):
        super().__init__(*a, directory=str(ROOT), **kw)

    # ------------------------------------------------------------ access control
    def _client_is_local(self) -> bool:
        return ipaddress.ip_address(self.client_address[0]).is_loopback

    def _authorised(self) -> bool:
        if self._client_is_local():
            return True
        if not self.phone_mode:
            return False
        ip = ipaddress.ip_address(self.client_address[0])
        if not ip.is_private:
            return False
        cookie = http.cookies.SimpleCookie(self.headers.get("Cookie", ""))
        return "cqa_key" in cookie and secrets.compare_digest(cookie["cqa_key"].value, self.token)

    def _gate(self) -> bool:
        """Return True if the request may proceed; otherwise a response has been sent."""
        url = urlparse(self.path)
        key = parse_qs(url.query).get("key", [""])[0]
        if key and self.phone_mode and secrets.compare_digest(key, self.token) \
                and ipaddress.ip_address(self.client_address[0]).is_private:
            # first visit from the phone: remember the key as a cookie, then strip it from the URL
            self.send_response(303)
            self.send_header("Set-Cookie", f"cqa_key={self.token}; Max-Age=31536000; Path=/; HttpOnly; SameSite=Strict")
            self.send_header("Location", url.path or "/")
            self.end_headers()
            return False
        if self._authorised():
            return True
        self.send_response(403)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"<h1>Locked</h1><p>Open the private link printed in the laptop terminal (it contains ?key=...).</p>")
        return False

    def _blocked_path(self) -> bool:
        parts = Path(urlparse(self.path).path).parts
        return any(p.startswith(".") for p in parts) or "progress-sync" in parts

    # ------------------------------------------------------------ routes
    def do_GET(self):  # noqa: N802
        if not self._gate():
            return
        path = urlparse(self.path).path
        if path == "/api/ping":
            latest = SYNC_DIR / "latest.json"
            meta = {}
            if latest.exists():
                meta = json.loads((SYNC_DIR / "latest.meta.json").read_text()) if (SYNC_DIR / "latest.meta.json").exists() else {}
            return self._json({"ok": True, "latest": meta.get("savedAt"), "device": meta.get("device")})
        if path == "/api/sync":
            latest = SYNC_DIR / "latest.json"
            if not latest.exists():
                return self._json({"error": "no copy"}, 404)
            body = latest.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if self._blocked_path():
            return self.send_error(404)
        if path.endswith("/") and not (ROOT / path.lstrip("/") / "index.html").exists():
            return self.send_error(404)  # no directory listings
        super().do_GET()

    def do_HEAD(self):  # noqa: N802
        if not self._gate():
            return
        if self._blocked_path():
            return self.send_error(404)
        super().do_HEAD()

    def do_POST(self):  # noqa: N802
        if not self._gate():
            return
        if urlparse(self.path).path != "/api/sync":
            return self.send_error(404)
        n = int(self.headers.get("Content-Length", 0))
        if n <= 0 or n > MAX_SYNC_BYTES:
            return self._json({"error": "bad size"}, 413)
        raw = self.rfile.read(n)
        try:
            data = json.loads(raw)
            assert data.get("app") == "commodity-quant-academy"
        except (ValueError, AssertionError):
            return self._json({"error": "not a progress export"}, 400)
        SYNC_DIR.mkdir(exist_ok=True)
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        device = (self.headers.get("X-Device") or "device")[:20]
        (SYNC_DIR / f"progress-{stamp}-{device}.json").write_bytes(raw)  # history, never overwritten
        (SYNC_DIR / "latest.json").write_bytes(raw)
        (SYNC_DIR / "latest.meta.json").write_text(json.dumps({"savedAt": datetime.now().isoformat(timespec="seconds"), "device": device}))
        self._json({"ok": True})

    def _json(self, obj, code=200):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        super().end_headers()

    def log_request(self, code="-", size="-"):
        # keep the terminal quiet: only errors and sync calls are logged
        if str(getattr(code, "value", code)).startswith(("4", "5")) or "/api/" in self.path:
            super().log_request(code, size)


def main() -> None:
    ap = argparse.ArgumentParser(description="Serve Commodity Quant Academy locally.")
    ap.add_argument("--port", type=int, default=8000)
    ap.add_argument("--phone", action="store_true", help="also allow your phone on the same Wi-Fi (secret key required)")
    ap.add_argument("--new-key", action="store_true", help="rotate the phone key (old phone links stop working)")
    args = ap.parse_args()

    if args.new_key and TOKEN_FILE.exists():
        TOKEN_FILE.unlink()
    Handler.phone_mode = args.phone
    host = "127.0.0.1"
    if args.phone:
        Handler.token = phone_token()
        host = "0.0.0.0"  # listen on Wi-Fi too; the key + private-IP check decide who gets in
    httpd = http.server.ThreadingHTTPServer((host, args.port), Handler)
    print("\n  Commodity Quant Academy")
    print(f"  Laptop:  http://127.0.0.1:{args.port}/")
    if args.phone:
        ip = lan_ip()
        name = socket.gethostname().split(".")[0]
        print("\n  iPhone (same Wi-Fi), open ONE of these once in Safari:")
        print(f"    http://{name}.local:{args.port}/?key={Handler.token}   (stable: survives IP changes)")
        print(f"    http://{ip}:{args.port}/?key={Handler.token}")
        print("  Then Share > Add to Home Screen. Keep this key private; rotate with --new-key.")
        print("  Tip: use the same link every time. Progress is stored per address.")
    print("\n  Ctrl+C to stop.\n")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
        sys.exit(0)


if __name__ == "__main__":
    main()
