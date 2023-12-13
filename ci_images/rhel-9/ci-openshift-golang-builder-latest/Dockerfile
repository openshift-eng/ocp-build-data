FROM replaced-by-golang-stream
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

ADD inject-art-repos.sh
RUN chmod +x /inject-art-repos.sh
RUN rm -f /etc/yum.repos.d/*
ADD localdev.repo /etc/yum.repos.d
ONBUILD RUN inject-art-repos.sh

# Some image building tools don't create a missing WORKDIR
RUN mkdir -p /go/src/github.com/openshift/origin
WORKDIR /go/src/github.com/openshift/origin
