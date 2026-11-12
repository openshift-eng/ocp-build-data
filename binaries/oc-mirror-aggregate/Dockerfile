# Doozer replaces each oc-mirror-source placeholder with a per-architecture digest
# from images/oc-mirror.yml. Release automation must select and verify the source NVR.
# Foreign-architecture stages only supply files; no source binaries are executed.
FROM --platform=linux/amd64 oc-mirror-source AS amd64
FROM --platform=linux/arm64 oc-mirror-source AS arm64
FROM --platform=linux/ppc64le oc-mirror-source AS ppc64le
FROM --platform=linux/s390x oc-mirror-source AS s390x

FROM registry.redhat.io/ubi9-minimal:latest
COPY --from=amd64 /releases/ /releases/
COPY --from=arm64 /releases/ /releases/
COPY --from=ppc64le /releases/ /releases/
COPY --from=s390x /releases/ /releases/

LABEL summary="oc-mirror binaries transport image" \
      description="Collects the existing oc-mirror RHEL 8 and RHEL 9 tarballs for all four architectures under /releases/ for CDN publication." \
      io.k8s.display-name="oc-mirror binaries transport image"
