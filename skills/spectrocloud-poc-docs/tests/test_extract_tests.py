"""Unit tests for scripts/extract_tests.py (annotation parsing + T1 lint)."""

import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

SKILL = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SKILL / "scripts"))

import extract_tests as et  # noqa: E402

FIXTURES = Path(__file__).resolve().parent / "fixtures"


def write_page(tmp: Path, text: str) -> Path:
    page = tmp / "page.md"
    page.write_text(textwrap.dedent(text))
    return page


def mini_suite(tmp: Path, hosts=("node",), env=("PALETTE_API_KEY",),
               vars_=None, required=None) -> et.Suite:
    return et.Suite(name="t", path=tmp / "suite.yaml", pages=["page.md"],
                    hosts=list(hosts), env_keys=list(env),
                    vars=dict(vars_ or {}), required_vars=list(required or []),
                    teardown="always")


class ParseTests(unittest.TestCase):
    def test_parses_fixture_suite_in_order(self):
        suite = et.load_suite(FIXTURES / "runner_site" / "poc-test-suite.yaml")
        blocks = et.suite_blocks(suite)
        self.assertEqual([b.id for b in blocks],
                         ["emit-value", "write-config", "check-config",
                          "echo-secret", "retry-block", "gpu-only"])
        self.assertEqual(blocks[0].capture, {"GREETING": "tail -n1"})
        self.assertEqual(blocks[1].file, "$POC_ARTIFACTS/config.yaml")
        self.assertEqual(blocks[1].lang, "yaml")
        self.assertEqual(blocks[2].retry, {"attempts": 3, "delay": 1})
        self.assertEqual(blocks[4].retry, {"attempts": 3, "delay": 1})
        self.assertEqual(blocks[5].when, "GPU_PRESENT")
        self.assertEqual(et.lint(suite, blocks), [])

    def test_indented_annotation_inside_tab(self):
        with tempfile.TemporaryDirectory() as tmp:
            page = write_page(Path(tmp), """\
                # Page

                === "API"

                    <!-- poc-test
                    id: tabbed-block
                    host: local
                    -->

                    ```bash
                    echo tabbed
                    ```
                """)
            blocks = et.parse_page(page)
            self.assertEqual(len(blocks), 1)
            self.assertEqual(blocks[0].id, "tabbed-block")
            self.assertEqual(blocks[0].code, "echo tabbed\n")

    def test_unclosed_annotation_raises(self):
        with tempfile.TemporaryDirectory() as tmp:
            page = write_page(Path(tmp), """\
                <!-- poc-test
                id: broken
                host: local
                """)
            with self.assertRaises(et.ParseError):
                et.parse_page(page)

    def test_annotation_without_block_raises(self):
        with tempfile.TemporaryDirectory() as tmp:
            page = write_page(Path(tmp), """\
                <!-- poc-test
                id: no-block
                host: local
                -->

                Just prose, no fence.
                """)
            with self.assertRaises(et.ParseError):
                et.parse_page(page)


class LintTests(unittest.TestCase):
    def lint_of(self, text, **suite_kw):
        with tempfile.TemporaryDirectory() as tmp:
            page = write_page(Path(tmp), text)
            blocks = et.parse_page(page, "page.md")
            return et.lint(mini_suite(Path(tmp), **suite_kw), blocks)

    def test_duplicate_id(self):
        errors = self.lint_of("""\
            <!-- poc-test
            id: twice
            host: local
            -->

            ```bash
            echo a
            ```

            <!-- poc-test
            id: twice
            host: local
            -->

            ```bash
            echo b
            ```
            """)
        self.assertTrue(any("duplicate id" in e for e in errors), errors)

    def test_unknown_host(self):
        errors = self.lint_of("""\
            <!-- poc-test
            id: x
            host: mystery-box
            -->

            ```bash
            echo hi
            ```
            """)
        self.assertTrue(any("not in adapter_requirements.hosts" in e for e in errors), errors)

    def test_needs_must_reference_earlier_id(self):
        errors = self.lint_of("""\
            <!-- poc-test
            id: x
            host: local
            needs: [ghost]
            -->

            ```bash
            echo hi
            ```
            """)
        self.assertTrue(any("ghost" in e for e in errors), errors)

    def test_unresolvable_var(self):
        errors = self.lint_of("""\
            <!-- poc-test
            id: x
            host: local
            assert: test -n "$NOT_DEFINED_ANYWHERE"
            -->

            ```bash
            echo hi
            ```
            """)
        self.assertTrue(any("NOT_DEFINED_ANYWHERE" in e for e in errors), errors)

    def test_var_from_capture_env_and_auto_resolve(self):
        errors = self.lint_of("""\
            <!-- poc-test
            id: a
            host: node
            capture:
              THING: "tail -n1"
            -->

            ```bash
            echo v
            ```

            <!-- poc-test
            id: b
            host: local
            needs: [a]
            assert: test -n "$THING" && test -n "$PALETTE_API_KEY" && test -n "$POC_HOST_NODE_ADDR"
            -->

            ```bash
            echo ok
            ```
            """)
        self.assertEqual(errors, [])

    def test_yaml_block_without_file_is_error(self):
        errors = self.lint_of("""\
            <!-- poc-test
            id: x
            host: local
            -->

            ```yaml
            key: value
            ```
            """)
        self.assertTrue(any("not executable" in e for e in errors), errors)

    def test_unknown_annotation_key(self):
        errors = self.lint_of("""\
            <!-- poc-test
            id: x
            host: local
            tymeout: 5
            -->

            ```bash
            echo hi
            ```
            """)
        self.assertTrue(any("unknown annotation key" in e for e in errors), errors)

    def test_retry_without_until_is_block_level_retry(self):
        errors = self.lint_of("""\
            <!-- poc-test
            id: x
            host: local
            retry:
              attempts: 5
              delay: 2
            -->

            ```bash
            echo hi
            ```
            """)
        self.assertEqual(errors, [])

    def test_retry_on_file_block_is_error(self):
        errors = self.lint_of("""\
            <!-- poc-test
            id: x
            host: local
            file: out.txt
            retry:
              attempts: 5
              delay: 2
            -->

            ```yaml
            key: value
            ```
            """)
        self.assertTrue(any("meaningless" in e for e in errors), errors)


if __name__ == "__main__":
    unittest.main()
