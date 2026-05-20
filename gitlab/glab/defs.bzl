"""`glab_toolchain` rule — pairs an executable target with the
`GlabToolchainInfo` provider so `gitlab_ci_lint` (and future
gitlab-API rules) can resolve it via Bazel toolchain machinery.

Most users won't author `glab_toolchain` directly — they'll accept
the default toolchain registered by rules_gitlab (PATH-based), or
register one that wires a hermetically-fetched `glab` binary.
"""

load(":toolchain_type.bzl", "GlabToolchainInfo")

def _glab_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        glab_info = GlabToolchainInfo(
            glab = ctx.attr.glab.files_to_run,
            default_runfiles = ctx.attr.glab[DefaultInfo].default_runfiles,
        ),
    )]

glab_toolchain = rule(
    implementation = _glab_toolchain_impl,
    doc = "Register a target as the glab CLI for rules_gitlab's runnable rules. Pair with a `toolchain(...)` declaration pointing at `@rules_gitlab//gitlab/glab:toolchain_type`.",
    attrs = {
        "glab": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            doc = "Executable target whose entry point is the `glab` CLI. Can be a thin `sh_binary` over system `glab` (the default), or a hermetically-fetched binary (rules_multitool, http_file, etc.).",
        ),
    },
)
