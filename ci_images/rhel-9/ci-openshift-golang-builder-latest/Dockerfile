FROM registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.20-openshift-4.16
# See images/ci-openshift-golang-builder-latest.yml

# Turn off information for CI environment. This is usually just noise for upstream
# engineers and can complicate debug. When issues arise, have repos export
# GO_COMPLIANCE_INFO=1 or GO_COMPLIANCE_DEBUG=1 before running go.
ENV GO_COMPLIANCE_INFO=0

ENV GOARM=5 \
    LOGNAME=deadbeef \
    GOCACHE=/go/.cache \
    GOPATH=/go \
    LOGNAME=deadbeef
ENV PATH=$PATH:$GOPATH/bin

# make go related directories writeable since builds in CI will run as non-root.
RUN mkdir -p $GOPATH && \
    chmod g+xw -R $GOPATH && \
    chmod g+xw -R $(go env GOROOT)

# Some image building tools don't create a missing WORKDIR
RUN mkdir -p /go/src/github.com/openshift/origin
WORKDIR /go/src/github.com/openshift/origin
