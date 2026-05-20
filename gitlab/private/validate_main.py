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

import yaml

from check_jsonschema.cli import main as check_jsonschema_main


def _install_gitlab_yaml_tag_tolerance() -> None:
    """Teach PyYAML to ignore GitLab-specific custom YAML tags.

    GitLab CI YAML uses constructs like `!reference [.aws_env, vars]`
    and `!file`, `!base64` — non-standard YAML tags that GitLab's
    server-side parser handles but PyYAML's default loader rejects
    with `ConstructorError: could not determine a constructor for
    the tag '!reference'`.

    We register a generic constructor that returns the underlying
    Python value (string / list / mapping) for any unknown `!tag`,
    effectively making the parser treat them as no-ops. The JSON
    Schema validator then sees the structural shape (lists stay
    lists, etc.) and validates it; it's the trade-off for being
    able to validate real-world GitLab CI files at all.
    """

    def _generic_constructor(loader: yaml.Loader, _suffix: str, node: yaml.Node):
        if isinstance(node, yaml.ScalarNode):
            return loader.construct_scalar(node)
        if isinstance(node, yaml.SequenceNode):
            return loader.construct_sequence(node)
        return loader.construct_mapping(node)

    for loader_cls in (yaml.Loader, yaml.SafeLoader, yaml.FullLoader):
        loader_cls.add_multi_constructor("!", _generic_constructor)
        loader_cls.add_multi_constructor("tag:yaml.org,2002:", _generic_constructor)


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

    _install_gitlab_yaml_tag_tolerance()

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
