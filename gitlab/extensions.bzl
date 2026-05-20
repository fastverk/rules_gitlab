"""Module extension: pin upstream GitLab JSON Schemas as Bazel repos.

The canonical schema lives in the GitLab repo itself at
`gitlab-org/gitlab-foss` under
`app/assets/javascripts/editor/schema/ci.json`. SchemaStore mirrors
it but the URL below is what schemastore's catalog points at — we
go to the source.

Pinning by sha256 keeps the build reproducible across upstream
GitLab releases. Refresh procedure:

    curl -fL "<URL>" -o /tmp/ci.json
    shasum -a 256 /tmp/ci.json
    # paste into _CI_SCHEMA_SHA256 below

When this rule lifts to a standalone `rules_gitlab` module the
extension keeps the same shape; only the consumer's `use_extension(...)`
target name changes.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

_CI_SCHEMA_URL = "https://gitlab.com/gitlab-org/gitlab-foss/-/raw/master/app/assets/javascripts/editor/schema/ci.json"
_CI_SCHEMA_SHA256 = "1e4a59db14999771c45e4b0ab646d663e95607698aa8940f7afed82a9a0d5054"

def _gitlab_schemas_impl(_mctx):
    http_file(
        name = "gitlab_ci_schema",
        urls = [_CI_SCHEMA_URL],
        sha256 = _CI_SCHEMA_SHA256,
        downloaded_file_path = "gitlab-ci.schema.json",
    )

gitlab_schemas = module_extension(implementation = _gitlab_schemas_impl)
