"""Module extension: pin upstream GitLab JSON Schemas as Bazel repos.

The canonical schema lives in the GitLab repo itself at
`gitlab-org/gitlab-foss` under
`app/assets/javascripts/editor/schema/ci.json`. SchemaStore mirrors
it but the URL below is what schemastore's catalog points at — we
go to the source.

Pinning by release TAG + sha256 keeps the build reproducible. The URL
MUST use a tag (e.g. `v18.11.5`), never `master` — `master` moves and
its content changes break the sha256 pin. Refresh procedure:

    TAG=v18.11.5  # bump to a newer gitlab-foss release tag
    curl -fL "https://gitlab.com/gitlab-org/gitlab-foss/-/raw/$TAG/app/assets/javascripts/editor/schema/ci.json" -o /tmp/ci.json
    shasum -a 256 /tmp/ci.json   # paste into _CI_SCHEMA_SHA256; set _CI_SCHEMA_TAG

When this rule lifts to a standalone `rules_gitlab` module the
extension keeps the same shape; only the consumer's `use_extension(...)`
target name changes.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

# Pin to an immutable release TAG, never `master` — `master` is a moving ref
# whose content changes silently break the sha256 pin (the build then fails to
# fetch). Bump _CI_SCHEMA_TAG + _CI_SCHEMA_SHA256 together to refresh.
_CI_SCHEMA_TAG = "v18.11.5"
_CI_SCHEMA_URL = "https://gitlab.com/gitlab-org/gitlab-foss/-/raw/{}/app/assets/javascripts/editor/schema/ci.json".format(_CI_SCHEMA_TAG)
_CI_SCHEMA_SHA256 = "fe7dcbabd9e0b441b59395a335d5cd480a770b90d9707f2511969a1564066a53"

def _gitlab_schemas_impl(_mctx):
    http_file(
        name = "gitlab_ci_schema",
        urls = [_CI_SCHEMA_URL],
        sha256 = _CI_SCHEMA_SHA256,
        downloaded_file_path = "gitlab-ci.schema.json",
    )

gitlab_schemas = module_extension(implementation = _gitlab_schemas_impl)
