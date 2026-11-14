# ocp-build-data

Welcome to the OpenShift ocp-build-data repo, managed by ART. This
repository is the source of truth for all RPMs and images built for any
OpenShift Container Platform release.  

You can find the mapping of product component to Jira in [product.yml](product.yml).

You can find release specific build metadata in the `openshift-4.x` branches
of this repository. For example, OCP 4.10 data lives in the
[`openshift-4.10`](https://github.com/openshift/ocp-build-data/tree/openshift-4.10)
branch. (EOL branches are eventually converted to tags of the same name.)

There are a number of other branches for various purposes, for instance
sources for base images, golang-builder specs, or 
[`misc-sync`](https://github.com/openshift/ocp-build-data/tree/sync-misc)
which is referred to by an ART service that mirrors images once a day to
`registry.reg-aws`.

# Freezing build automation

The master switch lives in [config/automation.yml](config/automation.yml) on
`main`. Set `freeze_automation: true` there to freeze all groups using Pyartcd's
freeze checks, regardless of their group settings or manual-run exceptions.
Set it back to `false` to restore each group's existing `freeze_automation`
policy. The switch defaults to `false`.

Pyartcd reads this setting from the canonical repository's `main` branch even
when a job uses a different build-data branch, ref, or fork. This requires the
corresponding global-freeze support in `art-tools`; it does not cancel builds
already running or affect commands that do not use Pyartcd freeze checks.

# Contributing

All changes to this repo must be submitted as pull requests against
the appropriate branch for the version of OCP targeted by your
change. If you are unsure, please slack @release-artists in #forum-ocp-art.

# Documentation

For examples with extensive comment documentation of the config data
yaml files, see the
[examples](https://github.com/openshift/ocp-build-data/tree/master/example)
directory.

To onboard your image or rpm with OCP, please check out our
[SOP document on The Source](https://source.redhat.com/groups/public/atomicopenshift/atomicopenshift_wiki/guidelines_for_requesting_new_content_managed_by_ocp_art).
