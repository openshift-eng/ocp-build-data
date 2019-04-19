RHCOS Declarative Pipeline
==

This is an example RHCOS Upshift configuration pipeline. The purpose
is to describe a pipeline in YAML and have the configuration under
revision control.

No DevOps
==

The [RHCOS Pipeline and Configuration](https://gitlab.cee.redhat.com) is incredibly powerful.
However, in that power, the Pipeline exposes many knobs and toggles that help developers
but get in the way those who are trying operate the pipeline.

Why?
==

The RHCOS Pipeline supports two modes: declarative and imperative. Under the
declarative mode (which this repo enables), ALL options are exposed in YAML.
More importantly there are simply NO runtime options or calculated option.

Under the imperative, or developer mode, runtime options are supported for
in the form of YAML, Jenkins Parameters and Upshift environment variables.
If you are not a developer and hacking on RHCOS, then imperative mode offers
too many options that likely is not what you want.

GitOps
==

Declarative mode allows any who choses it, to describe their pipeline in
YAML. Since the YAML is checked into a Git repo, you have have the ability
to develop a PR processes and use GitOps.

Deployment:
==

You will need to follow all the setup process for the Upshift tenant. You will
still need to maintain the CoreOS Assembler build configuration and Jenkins,
perferrably from the [redhat-coreos repositroy](https://gitlab.cee.redhat.com).

Then:
1. Fork this repo
1. Edit `jobspec.yaml`
1. Run `make publish`

Best Practices
==

1. Use explicit tags/hashes in `jobspec.yaml` when possible. This is especially true for production systems.
1. If you are delivering production assests, have one job that tracks `master` for `redhat-cores`. This can let you know if a breaking change is introduced.
1. Before updating your production pipeline, check the values against a non-production job.
1. Develop a GitOps strategy for maintaining your branches.
