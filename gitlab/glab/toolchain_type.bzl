"""Toolchain type + info provider for the `glab` CLI consumed by
`gitlab_ci_lint` (and future `gitlab_*` API / deploy rules).

Indirected via a toolchain so consumers who want a hermetic GitLab
CLI story (multitool-fetched glab, an http_file-pinned archive, a
sidecar container) can register their own toolchain and have
the user-facing rules pick it up — no changes to the rules
themselves.

The default toolchain registered by rules_gitlab
(`@rules_gitlab//gitlab/glab:default_glab_toolchain`) shells out
to whatever `glab` is on the user's PATH. This is the friendliest
default for local dev + CI runners that already have `glab`
installed. `glab` itself requires up-front auth
(`glab auth login`) to whichever GitLab instance is in scope;
that lives in the user's `~/.config/glab-cli/`.
"""

GlabToolchainInfo = provider(
    doc = "Carries the `glab` CLI binary used by rules_gitlab's runnable rules.",
    fields = {
        "glab": "FilesToRunProvider — its `.executable` is the glab CLI entry point.",
        "default_runfiles": "Runfiles needed to invoke `glab` at runtime (the wrapping `sh_binary`'s deps, plus any hermetic-binary auxiliary files).",
    },
)

GLAB_TOOLCHAIN_TYPE = "@rules_gitlab//gitlab/glab:toolchain_type"
