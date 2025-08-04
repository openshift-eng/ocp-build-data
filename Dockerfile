# Build the manager binary
FROM registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.22-openshift-4.18 AS builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# Copy the vendor directory
COPY vendor/ vendor/

# Copy the go source
COPY cmd/main.go cmd/main.go
COPY api/ api/
COPY internal/controller/ internal/controller/

# Build
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} go build -a -o manager cmd/main.go

FROM registry.ci.openshift.org/ocp/builder:rhel-9-base-openshift-4.18
WORKDIR /
COPY --from=builder /workspace/manager .
USER 65532:65532

LABEL \
  name="helloworld operator" \
  description="Test operator meant to be to be used to test out Brew/Konflux build/release pipelines. Not to be used in prod." \
  io.k8s.description="Test operator meant to be to be used to test out Brew/Konflux build/release pipelines. Not to be used in prod." \
  summary="Test operator meant to be to be used to test out Brew/Konflux build/release pipelines. Not to be used in prod." \
  io.k8s.display-name="helloworld operator" \

ENTRYPOINT ["/manager"]
