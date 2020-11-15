"Rule to copy mathjax subset from node_modules to vendor folder."

_exclude = [
    "mathmaps_ie.js",
]

_include = [
    "es5/tex-chtml.js",
    "es5/input/tex/extensions",
    "es5/output/chtml/fonts/woff-v2",
    "es5/a11y",
    "es5/sre",
]

_unwanted_prefix = "external/npm/node_modules/mathjax/es5/"

def _copy_files(ctx, files):
    cmds = []
    inputs = []
    outputs = []
    for (src, dst) in files:
        inputs.append(src)
        dst = ctx.actions.declare_file(dst)
        outputs.append(dst)
        cmds.append("cp -f {} {}".format(src.path, dst.path))

    shell_fname = ctx.label.name + "-cp.sh"
    shell_file = ctx.actions.declare_file(shell_fname)
    ctx.actions.write(
        output = shell_file,
        content = "#!/bin/bash\nset -e\n" + "\n".join(cmds),
        is_executable = True,
    )
    ctx.actions.run(
        inputs = inputs,
        executable = "bash",
        tools = [shell_file],
        arguments = [shell_file.path],
        outputs = outputs,
        mnemonic = "CopyFile",
        use_default_shell_env = True,
    )

    return [DefaultInfo(files = depset(outputs))]

def _copy_mathjax_impl(ctx):
    wanted = []
    for f in ctx.attr.mathjax.files.to_list():
        path = f.path
        want = True
        for substr in _exclude:
            if substr in path:
                want = False
                continue
        if not want:
            continue

        for substr in _include:
            if substr in path:
                output = path.replace(_unwanted_prefix, "")
                wanted.append((f, output))

    return _copy_files(ctx, wanted)

copy_mathjax = rule(
    implementation = _copy_mathjax_impl,
    attrs = {
        "mathjax": attr.label(default = "@npm//mathjax:mathjax__files"),
    },
)
