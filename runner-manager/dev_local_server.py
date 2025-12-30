#!/usr/bin/env python3
"""
Simple dev HTTP server to emulate runner-manager for local testing.
Usage: DEV_API_KEY=foo PORT=3001 python3 dev_local_server.py
"""
import os
import json
from http.server import HTTPServer, BaseHTTPRequestHandler

API_KEY = os.environ.get('DEV_API_KEY', 'testkey')
PORT = int(os.environ.get('PORT', '3001'))


class Handler(BaseHTTPRequestHandler):
    def _set_json(self, code=200):
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()

    def do_POST(self):
        if self.path != '/register-runner':
            self._set_json(404)
            self.wfile.write(json.dumps({'error': 'not found'}).encode())
            return

        key = self.headers.get('X-API-KEY','')
        if key != API_KEY:
            self._set_json(401)
            self.wfile.write(json.dumps({'error':'invalid api key'}).encode())
            return

        length = int(self.headers.get('Content-Length','0'))
        body = self.rfile.read(length).decode() if length else '{}'
        try:
            data = json.loads(body)
        except Exception:
            data = {}

        owner = data.get('owner')
        repo = data.get('repo')
        if not owner or not repo:
            self._set_json(400)
            self.wfile.write(json.dumps({'error':'owner and repo required'}).encode())
            return

        token = f"dev-token-{owner}-{repo}-{int(os.times()[4])}"
        resp = {'token': token, 'expires_at': '2099-12-31T23:59:59Z'}
        self._set_json(200)
        self.wfile.write(json.dumps(resp).encode())


def main():
    httpd = HTTPServer(('127.0.0.1', PORT), Handler)
    print(f"Dev runner-manager mock listening on http://127.0.0.1:{PORT} (API_KEY={API_KEY})")
    httpd.serve_forever()


if __name__ == '__main__':
    main()
