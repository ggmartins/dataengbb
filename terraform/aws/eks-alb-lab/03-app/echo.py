import json
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        data = {"status": "ok"} if self.path == "/healthz" else {
            "pod": socket.gethostname(),
            "path": self.path,
            "headers": dict(self.headers),
        }
        body = (json.dumps(data, indent=2) + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
