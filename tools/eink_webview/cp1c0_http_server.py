#!/usr/bin/env python3
"""Small CP1-C0 fixture server with explicit response completion evidence."""

import http.server
import os
import sys


class FixtureHandler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.0"

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        print("request accepted path=%s" % path, flush=True)
        if path not in ("/test_page.html", "/nav_minimal.html"):
            self.send_error(404)
            print("HTTP status=404 response_body_length=0 connection_completed=1", flush=True)
            return

        fixture_path = os.path.join(self.server.fixture_dir, path.lstrip("/"))
        with open(fixture_path, "rb") as fixture:
            body = fixture.read()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        self.end_headers()
        try:
            self.wfile.write(body)
            self.wfile.flush()
            print("HTTP status=200 response_body_length=%d connection_completed=1" % len(body),
                  flush=True)
        except BrokenPipeError:
            print("HTTP status=200 response_body_length=%d connection_completed=0" % len(body),
                  flush=True)

    def log_message(self, fmt, *args):
        print("http_log " + (fmt % args), flush=True)


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: cp1c0_http_server.py PORT FIXTURE")
    port = int(sys.argv[1])
    fixture_path = os.path.abspath(sys.argv[2])
    server = http.server.HTTPServer(("127.0.0.1", port), FixtureHandler)
    server.fixture_path = fixture_path
    server.fixture_dir = os.path.dirname(fixture_path)
    print("server_ready port=%d fixture=%s" % (port, fixture_path), flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
