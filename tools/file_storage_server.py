#!/usr/bin/env python3
"""개발용 — Flutter web이 프로젝트 data/runtime/ 에 읽기·쓰기 하도록 HTTP 제공."""

from __future__ import annotations

import argparse
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parent.parent / "data" / "runtime"
DEFAULT_PORT = 8765


def safe_path(url_path: str) -> Path | None:
    if not url_path.startswith("/files/"):
        return None
    rel = unquote(url_path[len("/files/") :]).replace("\\", "/").lstrip("/")
    if not rel or ".." in rel.split("/"):
        return None
    target = (ROOT / rel).resolve()
    root_resolved = ROOT.resolve()
    if not str(target).startswith(str(root_resolved)):
        return None
    return target


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:
        print(f"[storage] {self.address_string()} {fmt % args}")

    def _cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, PUT, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self) -> None:
        target = safe_path(urlparse(self.path).path)
        if target is None:
            self.send_error(400)
            return
        if not target.is_file():
            self.send_response(404)
            self._cors()
            self.end_headers()
            return
        data = target.read_bytes()
        self.send_response(200)
        self._cors()
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(data)

    def do_PUT(self) -> None:
        target = safe_path(urlparse(self.path).path)
        if target is None:
            self.send_error(400)
            return
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(body)
        self.send_response(204)
        self._cors()
        self.end_headers()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=DEFAULT_PORT)
    args = ap.parse_args()
    ROOT.mkdir(parents=True, exist_ok=True)
    host = "127.0.0.1"
    print(f"Kiosk file storage: http://{host}:{args.port}/files/...")
    print(f"Root: {ROOT}")
    HTTPServer((host, args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
