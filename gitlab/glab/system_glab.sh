#!/usr/bin/env bash
# Default glab CLI wrapper for savvi's gitlab rules. Shells out to
# whatever `glab` is on PATH. Swap by registering an alternate
# toolchain for `@savvi//gitlab/glab:toolchain_type`.
set -euo pipefail

if ! command -v glab >/dev/null 2>&1; then
    echo "savvi/gitlab: default glab toolchain expected \`glab\` on PATH but none found." >&2
    echo "  Install via https://gitlab.com/gitlab-org/cli (brew install glab on macOS)," >&2
    echo "  then \`glab auth login\` to your gitlab.savvifi.com instance." >&2
    exit 127
fi

exec glab "$@"
