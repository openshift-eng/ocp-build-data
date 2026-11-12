# oc-mirror binaries aggregator

This binaries member copies the existing `/releases/` tarballs from the amd64,
arm64, ppc64le and s390x images of an oc-mirror build into one transport image.
Each architecture supplies a RHEL 8 and a RHEL 9 archive, for eight archives total.
The files are copied without unpacking, renaming or rebuilding them.

The member is named `oc-mirror-aggregate` to distinguish it from the existing
`images/oc-mirror.yml` member. It requires the binaries and cross-platform build
support in art-tools PR #3768. Normal image builds do not load this member.

The committed recipe is reused for every release. Doozer rewrites the source
placeholders to per-architecture digests during rebase. Release orchestration
must pin and verify those parents against the selected source NVR rather than
implicitly selecting the latest stream build.

This recipe does not change the release pipeline. Follow-up work must build the
aggregator in `art-oc-mirror-tenant`, use its NVR for the shipment, and update the
CDN component mapping. Before production, compare all eight archive checksums
with their source images and verify an actual stage release, including EC.
