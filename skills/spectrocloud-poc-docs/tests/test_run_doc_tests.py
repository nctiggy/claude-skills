"""Integration tests for scripts/run_doc_tests.py using the MOCK adapter only.

These never touch real infrastructure: the mock adapter executes every host
role locally and reports fake credentials (which double as masking test data).
"""

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SKILL = Path(__file__).resolve().parents[1]
RUNNER = SKILL / "scripts" / "run_doc_tests.py"
MOCK = SKILL / "scripts" / "adapters" / "mock" / "mock-adapter.sh"
FIXTURES = Path(__file__).resolve().parent / "fixtures"
MOCK_SECRET = "mock-palette-api-key-000000"


def run_suite(fixture: str, *extra, env_extra=None):
    tmp = tempfile.TemporaryDirectory()
    report_dir = Path(tmp.name) / "report"
    state_dir = Path(tmp.name) / "state"
    env = {"PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
           "HOME": str(Path.home()),
           "MOCK_STATE_DIR": str(state_dir)}
    if env_extra:
        env.update(env_extra)
    proc = subprocess.run(
        [sys.executable, str(RUNNER),
         "--suite", str(FIXTURES / fixture / "poc-test-suite.yaml"),
         "--adapter", str(MOCK),
         "--report-dir", str(report_dir), *extra],
        capture_output=True, text=True, env=env, timeout=300)
    report = None
    report_file = report_dir / "report.json"
    if report_file.exists():
        report = json.loads(report_file.read_text())
    return proc, report, report_dir, state_dir, tmp


class HappyPathTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        (cls.proc, cls.report, cls.report_dir,
         cls.state_dir, cls._tmp) = run_suite("runner_site")

    @classmethod
    def tearDownClass(cls):
        cls._tmp.cleanup()

    def status_of(self, block_id):
        return next(b for b in self.report["blocks"] if b["id"] == block_id)["status"]

    def test_suite_passes(self):
        self.assertEqual(self.proc.returncode, 0, self.proc.stderr + self.proc.stdout)
        self.assertEqual(self.report["result"], "PASSED")

    def test_capture_flows_into_file_block(self):
        config = (self.report_dir / "config.yaml").read_text()
        self.assertIn("greeting: hello-mock", config)

    def test_assert_until_and_needs_pass(self):
        self.assertEqual(self.status_of("check-config"), "PASSED")

    def test_when_gated_block_skipped(self):
        self.assertEqual(self.status_of("gpu-only"), "SKIPPED")

    def test_block_level_retry_recovers(self):
        self.assertEqual(self.status_of("retry-block"), "PASSED")
        # last attempt's stdout is what the report keeps
        self.assertIn("second attempt passes",
                      (self.report_dir / "retry-block.stdout").read_text())

    def test_teardown_ran(self):
        self.assertTrue((self.state_dir / "teardown.marker").exists())
        self.assertTrue(self.report["teardown"]["ran"])

    def test_secret_masked_everywhere(self):
        stdout_file = (self.report_dir / "echo-secret.stdout").read_text()
        self.assertNotIn(MOCK_SECRET, stdout_file)
        self.assertIn("*****", stdout_file)
        self.assertNotIn(MOCK_SECRET, json.dumps(self.report))
        self.assertNotIn(MOCK_SECRET, self.proc.stdout)

    def test_markdown_report_written(self):
        md = (self.report_dir / "report.md").read_text()
        self.assertIn("PASSED", md)
        self.assertIn("emit-value", md)


class FailurePathTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        (cls.proc, cls.report, cls.report_dir,
         cls.state_dir, cls._tmp) = run_suite("runner_fail")

    @classmethod
    def tearDownClass(cls):
        cls._tmp.cleanup()

    def status_of(self, block_id):
        return next(b for b in self.report["blocks"] if b["id"] == block_id)["status"]

    def test_suite_fails_with_exit_1(self):
        self.assertEqual(self.proc.returncode, 1)
        self.assertEqual(self.report["result"], "FAILED")

    def test_failure_localised_and_rest_skipped(self):
        self.assertEqual(self.status_of("passes-first"), "PASSED")
        self.assertEqual(self.status_of("fails-assert"), "FAILED")
        self.assertEqual(self.status_of("never-reached"), "SKIPPED")

    def test_teardown_still_ran_on_failure(self):
        self.assertTrue((self.state_dir / "teardown.marker").exists())


class DryRunTests(unittest.TestCase):
    def test_dry_run_calls_no_adapter(self):
        proc, report, report_dir, state_dir, tmp = run_suite("runner_site", "--dry-run")
        try:
            self.assertEqual(proc.returncode, 0, proc.stderr)
            self.assertIn("dry-run: no adapter calls made", proc.stdout)
            self.assertFalse(state_dir.exists(),
                             "dry-run must not invoke adapter setup/teardown")
            self.assertIsNone(report, "dry-run must not write a report")
        finally:
            tmp.cleanup()


class AdapterFailureTests(unittest.TestCase):
    def test_setup_failure_is_fatal_but_teardown_runs(self):
        proc, report, report_dir, state_dir, tmp = run_suite(
            "runner_site", env_extra={"MOCK_FAIL_SETUP": "1"})
        try:
            self.assertEqual(proc.returncode, 1)
            self.assertEqual(report["result"], "FAILED")
            self.assertTrue((state_dir / "teardown.marker").exists())
        finally:
            tmp.cleanup()

    def test_t1_gate_blocks_bad_suite(self):
        with tempfile.TemporaryDirectory() as tmp:
            site = Path(tmp)
            (site / "docs").mkdir()
            (site / "docs" / "bad.md").write_text(
                "<!-- poc-test\nid: x\nhost: nowhere\n-->\n\n```bash\necho hi\n```\n")
            (site / "poc-test-suite.yaml").write_text(
                "suite: bad\npages: [docs/bad.md]\n"
                "adapter_requirements:\n  hosts: [node]\n  env: []\n")
            proc = subprocess.run(
                [sys.executable, str(RUNNER), "--suite",
                 str(site / "poc-test-suite.yaml"), "--adapter", str(MOCK)],
                capture_output=True, text=True, timeout=60)
            self.assertEqual(proc.returncode, 2)
            self.assertIn("T1-ERROR", proc.stderr)


if __name__ == "__main__":
    unittest.main()
