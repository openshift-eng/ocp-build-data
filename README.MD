There are a few tests for bring your own RHEL OpenShift 4 tests
that spin up clusters in AWS and require access to RHEL yum respos.

e.g. https://github.com/openshift/release/blob/6d07d25eafcf72f97ade491db42aceb5ae334c8f/cluster/test-deploy/aws-4.0/vars.yaml#L10

This group is specially designed to allow sync a bare minimum of repos
out to the mirrors for this test using doozer reposync.