# ART-22737: transport image that carries the openshift-install tarballs under /releases/ for the
# Konflux push-artifacts-to-cdn pipeline. The binaries are copied from the release's installer,
# installer-artifacts and baremetal-installer images and get the release pullspec, version and
# architecture injected the way `oc adm release extract` does (inject.py, package.sh). Nothing is
# compiled. Only the native packer stage runs commands; the foreign-arch stages are only read through
# COPY --from, so their binaries are plain files.
# Doozer rewrites every FROM at rebase time from from.builder (per-arch digests of the members
# ose-installer, ose-installer-artifacts and ose-baremetal-installer) and from.stream (rhel9). The
# literal digests below are the 4.22.18 images, only for local validation builds.
# The build args are set by the binaries-cdn-release job from the promoted release payloads.

FROM --platform=linux/amd64 quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:ac852ceb358abe9c7dc62412fd1c7e37dece2291624b8464f030fb89c1681268 AS inst_amd64
FROM --platform=linux/arm64 quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:941589e9bd111fdc31faa9ef9c64e0f7c7ec2fe27c09db58138871db21bd9023 AS inst_arm64
FROM --platform=linux/ppc64le quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:bbe45a8a6ff0c374fc809724d9e79e8d6153c3b3e019f96c6d7b6eed78092b8a AS inst_ppc64le
FROM --platform=linux/s390x quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:8d9e1a90d52f190b995a6e872d37b50bac7f18f184496b95a7ea696291b44091 AS inst_s390x
FROM --platform=linux/amd64 quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:1860f517a133f1006f4f2325589e84189ff455f70e7543acbae26c03f91c81c1 AS art_amd64
FROM --platform=linux/arm64 quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:55b1300d3533dd74baa3a6ba694805b01758887152d57c78fac22822a00995be AS art_arm64
FROM --platform=linux/ppc64le quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:9fbd5332b91f212c9641f568c70873e96567f3b3604f91ef0c5ff057331da371 AS art_ppc64le
FROM --platform=linux/s390x quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:eb3fd49cacba70b20ff476250188c135a4f0a2a50e6e5a8616b22449e16644e0 AS art_s390x
FROM --platform=linux/amd64 quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:f7e614af36d0b04e2da4f8d1a01c8c9da224405c606807069f9dc1f4ce6d93d7 AS bm_amd64
FROM --platform=linux/arm64 quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:6397dea4cec93f3ff38a4744c18813baf8ed9a9fed44ba4b061b633f388d622a AS bm_arm64
FROM --platform=linux/ppc64le quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:0616f7f6e1530ac4ff0c27d853add418f31acb302f0f767b92ae2847adf897d2 AS bm_ppc64le
FROM --platform=linux/s390x quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:bf4d8b863386a90434c6597b20b17877706a53cc53fea25024524d340402a921 AS bm_s390x

FROM art_amd64 AS packer
USER 0
COPY --from=inst_amd64 /usr/bin/openshift-install /in/amd64/installer/
COPY --from=inst_arm64 /usr/bin/openshift-install /in/arm64/installer/
COPY --from=inst_ppc64le /usr/bin/openshift-install /in/ppc64le/installer/
COPY --from=inst_s390x /usr/bin/openshift-install /in/s390x/installer/
COPY --from=art_arm64 /usr/share/openshift/ /in/arm64/artifacts/
COPY --from=art_ppc64le /usr/share/openshift/ /in/ppc64le/artifacts/
COPY --from=art_s390x /usr/share/openshift/ /in/s390x/artifacts/
COPY --from=bm_amd64 /usr/bin/openshift-install /in/amd64/baremetal/
COPY --from=bm_arm64 /usr/bin/openshift-install /in/arm64/baremetal/
COPY --from=bm_ppc64le /usr/bin/openshift-install /in/ppc64le/baremetal/
COPY --from=bm_s390x /usr/bin/openshift-install /in/s390x/baremetal/
COPY inject.py package.sh README.md /work/
ARG RELEASE_VERSION
ARG RELEASE_REPO=quay.io/openshift-release-dev/ocp-release
ARG DIGEST_X86_64
ARG DIGEST_AARCH64
ARG DIGEST_PPC64LE
ARG DIGEST_S390X
ARG DIGEST_MULTI
ARG FIPS_BIN=openshift-install-fips
ARG EXPECTED_TARBALLS=44
ARG REQUIRED_MARKERS=image,version,arch
RUN ln -s /usr/share/openshift /in/amd64/artifacts && bash /work/package.sh

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
COPY --from=packer /releases/ /releases/
ENTRYPOINT ["sh", "-c", "echo 'openshift-install binaries container; not runnable' && exit 1"]
CMD []
LABEL summary="OpenShift installer binaries container" \
      description="Transport image carrying the openshift-install binaries tarballs under /releases for the CDN. Not a runtime image." \
      io.k8s.display-name="OpenShift installer binaries container" \
      io.k8s.description="Transport image carrying the openshift-install binaries tarballs under /releases for the CDN. Not a runtime image." \
      io.openshift.tags="openshift,installer,binaries"
