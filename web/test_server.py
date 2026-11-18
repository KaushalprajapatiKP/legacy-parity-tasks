"""API tests for the sample page. Run: python3 -m unittest web/test_server.py (Python 3.11+)."""
import json
import sys
import threading
import unittest
import urllib.error
import urllib.request
from http.server import HTTPServer
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import server  # noqa: E402

EXPECTED = {"cobol-production-parity", "fortran-solver-parity", "legacy-store-migration"}


class APITest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.httpd = HTTPServer(("127.0.0.1", 0), server.Handler)
        cls.base = f"http://127.0.0.1:{cls.httpd.server_port}"
        threading.Thread(target=cls.httpd.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.httpd.shutdown()

    def get(self, path):
        with urllib.request.urlopen(self.base + path) as r:
            return r.status, r.read()

    def test_list(self):
        status, body = self.get("/api/tasks")
        self.assertEqual(status, 200)
        tasks = json.loads(body)
        self.assertEqual({t["id"] for t in tasks}, EXPECTED)
        for t in tasks:
            self.assertTrue(t["title"])
            self.assertEqual(t["difficulty"], "hard")
            self.assertIn(t["agent_run"]["reward"], (0.0, 1.0))

    def test_detail(self):
        for slug in EXPECTED:
            status, body = self.get("/api/tasks/" + slug)
            self.assertEqual(status, 200)
            t = json.loads(body)
            self.assertGreater(len(t["statement"]), 200)
            self.assertTrue(t["difficulty_explanation"])
            self.assertGreaterEqual(len(t["validation"]), 4)
            self.assertGreaterEqual(t["agent_run"]["tool_calls"], 50)

    def test_unknown_and_traversal(self):
        for path in ("/api/tasks/nope", "/api/tasks/..%2F..%2Fetc", "/api/tasks/.."):
            with self.assertRaises(urllib.error.HTTPError) as cm:
                self.get(path)
            self.assertEqual(cm.exception.code, 404)

    def test_frontend(self):
        status, body = self.get("/")
        self.assertEqual(status, 200)
        self.assertIn(b"app.js", body)


if __name__ == "__main__":
    unittest.main()
