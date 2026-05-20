"""Entry point for the `gitlab_ci_validate` Bazel rule.

A thin wrapper around `check-jsonschema` (a pip dep brought in via
the `@savvi_tooling` hub) that:

  1. Loads the pinned GitLab CI JSON Schema (passed via argv).
  2. Validates a single `.gitlab-ci.yml` against it.
  3. On success, writes a single-line stamp file so Bazel knows the
     check ran cleanly (caching keys on the file's mtime/content).

Errors are printed to stderr with file:line context. Exit code is
the check-jsonschema runner's exit code — non-zero for any
violation.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from check_jsonschema.cli import main as check_jsonschema_main


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--schema", required=True, type=Path)
    ap.add_argument("--src", required=True, type=Path)
    ap.add_argument(
        "--stamp",
        required=True,
        type=Path,
        help="Path the rule expects the check to write on success.",
    )
    args = ap.parse_args(argv)

    # check-jsonschema's `main` is a click entry point — calls
    # sys.exit() at the end. Pre-build its argv so it exits with
    # the right code; we catch SystemExit to write the stamp.
    check_argv = [
        "--schemafile",
        str(args.schema),
        # GitLab's .gitlab-ci.yml uses Perl-style slash-delimited
        # regex literals for fields like `coverage:` (e.g.
        # `/^TOTAL\s+\d+/`). GitLab's runtime parser strips the
        # leading/trailing `/`s before compiling, but the JSON
        # Schema declares those fields with `format: regex` and
        # check-jsonschema's strict format validator rejects the
        # wrapped form. Skip just the regex format check —
        # everything else (`uri`, `date-time`, structural) stays on.
        "--disable-formats",
        "regex",
        "--verbose",
        str(args.src),
    ]
    try:
        check_jsonschema_main(check_argv)
        rc = 0
    except SystemExit as e:
        # click main() raises SystemExit(0) on success; non-zero on
        # validation failure.
        rc = int(e.code) if e.code is not None else 0
    if rc == 0:
        args.stamp.write_text(
            f"gitlab_ci_validate: OK\nschema={args.schema}\nsrc={args.src}\n",
        )
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
