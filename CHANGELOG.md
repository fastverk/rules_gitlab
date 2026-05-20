# Changelog

All notable changes to rules_gitlab. The format is loosely
[Keep a Changelog](https://keepachangelog.com/) — version headers
mirror the published bazel-registry entries.

## 0.1.0 — initial release

Lifted from `savvi/gitlab/` after the rules stabilized against
real-world `.gitlab-ci.yml` files (selectsmart-engine, savvi-ops).

- **`gitlab_ci_validate(name, src)`** — build-action rule. Pins
  the official GitLab CI JSON Schema (the file
  `gitlab-org/gitlab-foss/.../editor/schema/ci.json` that
  GitLab's web editor uses) via the `gitlab_schemas` module
  extension and validates `.gitlab-ci.yml` files against it
  using `check-jsonschema` (brought in via the internal
  `@rules_gitlab_tooling` pip hub backed by `rules_uv`).
  Hermetic; no network or auth at build time. Skips the
  `format: regex` check because GitLab accepts slash-delimited
  regex literals (e.g. `/^TOTAL.../`) the schema doesn't.
- **`gitlab_ci_lint(name, src, host, repo)`** — `bazel run`-able
  target wrapping `glab ci lint <src>`. Hits the GitLab API for
  full pipeline validation including `include:` resolution and
  semantic checks. Indirected via a `glab` toolchain
  (`//gitlab/glab:toolchain_type`); the default toolchain
  shells out to system `glab` on PATH.
- Smoke test under `examples/smoke/` with a minimal valid
  fixture validated on every CI run.
