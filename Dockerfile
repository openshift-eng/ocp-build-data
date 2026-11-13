# Doozer replaces each oc-mirror-source placeholder with a per-architecture digest
# from images/oc-mirror.yml. Release automation must select and verify the source NVR.
# Foreign-architecture stages only supply files; no source binaries are executed.
FROM --platform=linux/amd64 quay.io/redhat-user-workloads/ocp-art-tenant/art-images@sha256:851a9c4179298357e5e17e1e958b17e8e92260e2e9d065cc9c4295690f44e519 AS amd64

# Start Konflux-specific steps
ENV ART_BUILD_ENGINE=konflux
ENV ART_BUILD_DEPS_METHOD=cachi2
ENV ART_BUILD_NETWORK=hermetic
ENV ART_BUILD_DEPS_MODE=default
# End Konflux-specific steps
ENV __doozer=update BUILD_RELEASE=202611130130.p2.g743b814.assembly.stream.el9 BUILD_VERSION=v2.0.0 OS_GIT_MAJOR=2 OS_GIT_MINOR=0 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=2.0.0-202611130130.p2.g743b814.assembly.stream.el9 SOURCE_GIT_TREE_STATE=clean __doozer_group=oc-mirror-2.0 __doozer_key=oc-mirror-aggregate __doozer_uuid_tag=oc-mirror-2-0-binaries-v2.0.0-20261113.013038 __doozer_version=v2.0.0 
ENV __doozer=merge OS_GIT_COMMIT=743b814 OS_GIT_VERSION=2.0.0-202611130130.p2.g743b814.assembly.stream.el9-743b814 SOURCE_DATE_EPOCH=1794515379 SOURCE_GIT_COMMIT=743b81466953ea48b11ba4c1b9c5e5db8ca98678 SOURCE_GIT_TAG=743b814 SOURCE_GIT_URL=https://github.com/openshift-eng/ocp-build-data 
FROM --platform=linux/arm64 quay.io/redhat-user-workloads/ocp-art-tenant/art-images@sha256:f12c574f954962a70b78dc171f657ac7940c4471a2dfe6faf72ac59904ad4030 AS arm64

# Start Konflux-specific steps
ENV ART_BUILD_ENGINE=konflux
ENV ART_BUILD_DEPS_METHOD=cachi2
ENV ART_BUILD_NETWORK=hermetic
ENV ART_BUILD_DEPS_MODE=default
# End Konflux-specific steps
ENV __doozer=update BUILD_RELEASE=202611130130.p2.g743b814.assembly.stream.el9 BUILD_VERSION=v2.0.0 OS_GIT_MAJOR=2 OS_GIT_MINOR=0 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=2.0.0-202611130130.p2.g743b814.assembly.stream.el9 SOURCE_GIT_TREE_STATE=clean __doozer_group=oc-mirror-2.0 __doozer_key=oc-mirror-aggregate __doozer_uuid_tag=oc-mirror-2-0-binaries-v2.0.0-20261113.013038 __doozer_version=v2.0.0 
ENV __doozer=merge OS_GIT_COMMIT=743b814 OS_GIT_VERSION=2.0.0-202611130130.p2.g743b814.assembly.stream.el9-743b814 SOURCE_DATE_EPOCH=1794515379 SOURCE_GIT_COMMIT=743b81466953ea48b11ba4c1b9c5e5db8ca98678 SOURCE_GIT_TAG=743b814 SOURCE_GIT_URL=https://github.com/openshift-eng/ocp-build-data 
FROM --platform=linux/ppc64le quay.io/redhat-user-workloads/ocp-art-tenant/art-images@sha256:a00a7467510b2d4cb210f5abdbcfe79e5ab99098b44cfa619f41bbd63e6fadff AS ppc64le

# Start Konflux-specific steps
ENV ART_BUILD_ENGINE=konflux
ENV ART_BUILD_DEPS_METHOD=cachi2
ENV ART_BUILD_NETWORK=hermetic
ENV ART_BUILD_DEPS_MODE=default
# End Konflux-specific steps
ENV __doozer=update BUILD_RELEASE=202611130130.p2.g743b814.assembly.stream.el9 BUILD_VERSION=v2.0.0 OS_GIT_MAJOR=2 OS_GIT_MINOR=0 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=2.0.0-202611130130.p2.g743b814.assembly.stream.el9 SOURCE_GIT_TREE_STATE=clean __doozer_group=oc-mirror-2.0 __doozer_key=oc-mirror-aggregate __doozer_uuid_tag=oc-mirror-2-0-binaries-v2.0.0-20261113.013038 __doozer_version=v2.0.0 
ENV __doozer=merge OS_GIT_COMMIT=743b814 OS_GIT_VERSION=2.0.0-202611130130.p2.g743b814.assembly.stream.el9-743b814 SOURCE_DATE_EPOCH=1794515379 SOURCE_GIT_COMMIT=743b81466953ea48b11ba4c1b9c5e5db8ca98678 SOURCE_GIT_TAG=743b814 SOURCE_GIT_URL=https://github.com/openshift-eng/ocp-build-data 
FROM --platform=linux/s390x quay.io/redhat-user-workloads/ocp-art-tenant/art-images@sha256:b54f9ead49d4d69aab77d8b3a924afa491d6f108f51e0e4635556e70b830a1ec AS s390x

# Start Konflux-specific steps
ENV ART_BUILD_ENGINE=konflux
ENV ART_BUILD_DEPS_METHOD=cachi2
ENV ART_BUILD_NETWORK=hermetic
ENV ART_BUILD_DEPS_MODE=default
# End Konflux-specific steps
ENV __doozer=update BUILD_RELEASE=202611130130.p2.g743b814.assembly.stream.el9 BUILD_VERSION=v2.0.0 OS_GIT_MAJOR=2 OS_GIT_MINOR=0 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=2.0.0-202611130130.p2.g743b814.assembly.stream.el9 SOURCE_GIT_TREE_STATE=clean __doozer_group=oc-mirror-2.0 __doozer_key=oc-mirror-aggregate __doozer_uuid_tag=oc-mirror-2-0-binaries-v2.0.0-20261113.013038 __doozer_version=v2.0.0 
ENV __doozer=merge OS_GIT_COMMIT=743b814 OS_GIT_VERSION=2.0.0-202611130130.p2.g743b814.assembly.stream.el9-743b814 SOURCE_DATE_EPOCH=1794515379 SOURCE_GIT_COMMIT=743b81466953ea48b11ba4c1b9c5e5db8ca98678 SOURCE_GIT_TAG=743b814 SOURCE_GIT_URL=https://github.com/openshift-eng/ocp-build-data 

FROM registry.redhat.io/ubi9-minimal:latest

# Start Konflux-specific steps
ENV ART_BUILD_ENGINE=konflux
ENV ART_BUILD_DEPS_METHOD=cachi2
ENV ART_BUILD_NETWORK=hermetic
ENV ART_BUILD_DEPS_MODE=default
# End Konflux-specific steps
ENV __doozer=update BUILD_RELEASE=202611130130.p2.g743b814.assembly.stream.el9 BUILD_VERSION=v2.0.0 OS_GIT_MAJOR=2 OS_GIT_MINOR=0 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=2.0.0-202611130130.p2.g743b814.assembly.stream.el9 SOURCE_GIT_TREE_STATE=clean __doozer_group=oc-mirror-2.0 __doozer_key=oc-mirror-aggregate __doozer_uuid_tag=oc-mirror-2-0-binaries-v2.0.0-20261113.013038 __doozer_version=v2.0.0 
ENV __doozer=merge OS_GIT_COMMIT=743b814 OS_GIT_VERSION=2.0.0-202611130130.p2.g743b814.assembly.stream.el9-743b814 SOURCE_DATE_EPOCH=1794515379 SOURCE_GIT_COMMIT=743b81466953ea48b11ba4c1b9c5e5db8ca98678 SOURCE_GIT_TAG=743b814 SOURCE_GIT_URL=https://github.com/openshift-eng/ocp-build-data 
COPY --from=amd64 /releases/ /releases/
COPY --from=arm64 /releases/ /releases/
COPY --from=ppc64le /releases/ /releases/
COPY --from=s390x /releases/ /releases/

LABEL \
        summary="oc-mirror binaries transport image" \
        description="Collects the existing oc-mirror RHEL 8 and RHEL 9 tarballs for all four architectures under /releases/ for CDN publication." \
        io.k8s.display-name="oc-mirror binaries transport image" \
        name="openshift5/oc-mirror-2-0-binaries" \
        vendor="Red Hat, Inc." \
        cpe="cpe:/a:redhat:oc-mirror:2.0::el9" \
        com.redhat.component="oc-mirror-aggregate-binaries-container" \
        io.openshift.maintainer.project="OCPBUGS" \
        io.openshift.maintainer.component="Unknown" \
        version="v2.0.0" \
        release="202611130130.p2.g743b814.assembly.stream.el9" \
        io.openshift.build.commit.id="743b81466953ea48b11ba4c1b9c5e5db8ca98678" \
        io.openshift.build.source-location="https://github.com/openshift-eng/ocp-build-data" \
        io.openshift.build.commit.url="https://github.com/openshift-eng/ocp-build-data/commit/743b81466953ea48b11ba4c1b9c5e5db8ca98678" \
        io.k8s.description="Empty" \
        io.openshift.tags="Empty"

