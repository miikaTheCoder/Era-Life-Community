#!/usr/bin/env python3
"""Serve the Web export locally with the headers required by Godot threads."""

import argparse
import json
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit


# Optional test instrumentation. The exported page stays untouched; only the
# local preview's ?trace=1 page forwards console messages to its retained log.
TRACE_SCRIPT = """<script>
(() => {
    let pending = [];
    const record = (level, args) => pending.push({
        time: new Date().toISOString(), level,
        message: args.map(value => value instanceof Error ? value.stack : String(value)).join(' ')
    });
    for (const level of ['log', 'info', 'warn', 'error']) {
        const original = console[level].bind(console);
        console[level] = (...args) => { original(...args); record(level, args); };
    }
    window.addEventListener('error', event => record('uncaught', [event.error || event.message]));
    window.addEventListener('unhandledrejection', event => record('unhandledrejection', [event.reason]));
    const flush = () => {
        if (pending.length) {
            navigator.sendBeacon('/__diagnostics', JSON.stringify(pending));
            pending = [];
        }
    };
    setInterval(flush, 250);
    window.addEventListener('pagehide', flush);
    record('environment', [navigator.userAgent, 'isolated=' + crossOriginIsolated]);
})();
</script>"""


class WebHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        url = urlsplit(self.path)
        if url.path in ("/", "/index.html") and parse_qs(url.query).get("trace") == ["1"]:
            content = (Path(self.directory) / "index.html").read_text()
            body = content.replace("</head>", TRACE_SCRIPT + "</head>").encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        if self.path != "/__diagnostics" or not 0 < length <= 1024 * 1024:
            self.send_error(400)
            return
        try:
            events = json.loads(self.rfile.read(length))
            if not isinstance(events, list):
                raise ValueError("Expected an event list")
            with self.server.trace_log.open("a") as log:
                for event in events:
                    log.write(json.dumps(event) + "\n")
        except (ValueError, OSError):
            self.send_error(400)
            return
        self.send_response(204)
        self.end_headers()

    def log_message(self, format, *args):
        if self.path != "/__diagnostics":
            super().log_message(format, *args)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8060)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1] / "build/web")
    parser.add_argument("--trace-log", type=Path, default=Path(__file__).resolve().parents[1] / "build/logs/web-browser.jsonl")
    args = parser.parse_args()
    if not (args.root / "index.html").is_file():
        parser.error("Missing index.html. Run bash scripts/build.sh web first.")
    handler = partial(WebHandler, directory=str(args.root.resolve()))
    with ThreadingHTTPServer(("127.0.0.1", args.port), handler) as server:
        args.trace_log.parent.mkdir(parents=True, exist_ok=True)
        server.trace_log = args.trace_log
        print(f"EraLife Web: http://localhost:{args.port}/", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
