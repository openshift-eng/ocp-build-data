# ocp-build-data

Welcome to the OpenShift ocp-build-data repo, managed by ART.  This
repository is the source of truth for all images built for any
OpenShift Container Platform release.  However, you will not find any
data in the `master` branch as all data lives in branches specific to
each version of OCP. For example, OCP 4.3 data lives in the
[`openshift-4.3`](https://github.com/openshift/ocp-build-data/tree/openshift-4.3)
branch.

If your images are in dist-git, then ART has a service that can mirror
your images once a day to `registry.reg-aws`. The
[`misc-sync`](https://github.com/openshift/ocp-build-data/tree/sync-misc)
branch contains the configuration information. Specify the branch you
build out of in dist-git and the `<repo>/<name>` of your image
there. This is for software outside OpenShift that must be tested with
OpenShift.

# Contributing

All changes to this repo must be submitted as pull requests against
the appropriate branch for the version of OCP targeted by your
change. If you are unsure, please contact
[aos-team-art@redhat.com](mailto:aos-team-art@redhat.com).

# Documentation

For examples with extensive comment documentation of the config data
yaml files, see the
[examples](https://github.com/openshift/ocp-build-data/tree/master/example)
directory.

For the full documentation on how to build your image or rpm with OCP,
please check out our
[SOP document on Mojo](https://mojo.redhat.com/docs/DOC-1179058).
