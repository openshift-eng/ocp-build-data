# DECISIONS.md — MCE 5.0 ocp-build-data Branch

Product decisions and rationale for the `mce-5.0` branch configuration.
Derived from `mce-2.11` (HYPBLD-844) and `acm-5.0` (eemurphy PR #12366).
Created as part of JIRA ticket [HYPBLD-862](https://redhat.atlassian.net/browse/HYPBLD-862).

## Product Identity

- **Decision**: `product: multicluster-engine`, `name: mce-5.0`, `csv_namespace: multicluster-engine`
- **Rationale**: Continues MCE 2.x naming pattern with 5.0 product versioning aligned to OCP 5.x.

## OCP Version Alignment

- **Decision**: `MAJOR: 5`, `MINOR: 0` (OCP 5.0 infrastructure)
- **Rationale**: MCE 5.0 aligns with OCP 5.0; distgit branch `rhaos-5.0-rhel-9`.

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["5.0", "5.1"]`
- **Rationale**: From MCE operator bundle `com.redhat.openshift.versions="v5.0-v5.1"`.

## Git Source Branches

- **Decision**: `backplane-5.0` for stolostron/MCE components; `release-5.0` for openshift org repos (hypershift, capi-kubevirt)
- **Rationale**: Matches Konflux `.tekton` configs on `backplane-5.0` branches in upstream repos.

## New Components (vs mce-2.11)

Added for MCE 5.0 per component migration map:

| Component | Upstream repo | Dockerfile | Notes |
|-----------|---------------|------------|-------|
| cluster-permission | [stolostron/cluster-permission](https://github.com/stolostron/cluster-permission) | `Dockerfile.rhtap` | Moved from ACM to MCE (same container/repo) |
| maestro | [stolostron/maestro](https://github.com/stolostron/maestro) | `Dockerfile.rhtap` | New since MCE 2.17; present in 5.0, removed in 5.1 |
| cloudevents-conductor | [stolostron/cloudevents-conductor](https://github.com/stolostron/cloudevents-conductor) | `Dockerfile.rhtap` | New since MCE 2.17; present in 5.0, removed in 5.1 |

## Image scope

27 components on `backplane-5.0` (24 carried forward from mce-2.11 + 3 new).
`cluster-proxy-addon` remains excluded (removed in MCE 2.11).

## Console Dockerfile

- **Decision**: `Containerfile.mce` (not `Containerfile.mce.konflux`)
- **Rationale**: Parallel to ACM 5.0 change from `Containerfile.acm.konflux` → `Containerfile.acm`.

## Console Parent Image Count

- **Decision**: `console-mce.yml` defines 3 builder entries: `rhel9-ubi`, `rhel-9-nodejs-24`, and final `rhel-9-nodejs-24`
- **Rationale**: The upstream `Containerfile.mce` has a `FROM registry.redhat.io/ubi9/ubi:latest AS crypto-policy` stage plus two `FROM ${NODE_BASE}` entries (build-base + final). Doozer counts non-stage FROM directives and must match `ocp-build-data`. The `rhel9-ubi` stream was added to `streams.yml` for this purpose.
- **Issue**: Initial builds failed with "expected 2 parent images, but found 3" until the third builder was added.

## Hypershift-cli PQC Parent Image

- **Decision**: `hypershift-cli.yml` includes `rhel9` as a second builder entry
- **Rationale**: The `release-5.0` `Containerfile.cli` added a `FROM ubi-minimal-pqc AS policy` stage, increasing non-stage FROM directives from 2 to 3. Same pattern as console fix.

## PQC Base Images

- **Decision**: `streams.yml` defines `rhel9` stream as `registry.redhat.io/ubi9/ubi-minimal-pqc:latest`; upstream stolostron Dockerfiles migrated from `ubi-minimal` to `ubi-minimal-pqc`
- **Rationale**: 5.0 is the first release to adopt Post-Quantum Cryptography images. Both the `streams.yml` stream definition and the upstream Dockerfiles were updated.
- **Scope**: Only applies to 5.0+. Earlier releases (2.11, 2.17) use standard `ubi-minimal`.

## Stream: rhel9-ubi

- **Decision**: Added `rhel9-ubi` stream (`registry.redhat.io/ubi9/ubi:latest`) to `streams.yml`
- **Rationale**: Needed for the console `crypto-policy` stage which uses the full UBI 9 image (not ubi-minimal). Named `rhel9-ubi` per developer preference (Ashwin).
- **Note**: Original name was `rhel-9-ubi`; renamed to `rhel9-ubi` at developer request.

## Bundle Component

- **Decision**: MCE operator bundle excluded from `images/*.yml`
- **Rationale**: Same as mce-2.11 and acm-5.0 — defer bundle complexity until individual images build.

## Stage-only Components in KRD RPAs

- **Decision**: `mce-operator-bundle` is in the stage RPA but not the prod RPA
- **Rationale**: The bundle is released to prod through the separate FBC (file-based catalog) pipeline, not the advisory pipeline.

## External Images in backplane-operator art.yaml

- **Decision**: `assisted-*` images (5 total) and `ose-cluster-api-*` images (2 total) use placeholder digests/tags from MCE 2.11
- **Rationale**: These are external images not built by MCE. The 5.0 digests were stale/nonexistent at initial build time. MCE 2.11 digests were used as temporary placeholders with `TODO` comments.
- **Revisit**: Replace with actual 5.0 digests once the assisted-installer and OCP 5.0 teams publish them.

## azure-service-operator Dockerfile Modifications

- **Decision**: `ocp-build-data` config includes `modifications:` to rewrite `COPY ./ ./` → `COPY v2/ ./` and `COPY stolostron/crds ./crds` → `COPY v2/stolostron/crds ./crds`
- **Rationale**: The Go module lives in the `v2/` subdirectory. The ART Dockerfile uses `COPY ./ ./` generically, but doozer needs to scope it to `v2/`.
- **Issue**: The upstream `.dockerignore` excludes `v2/` from the Docker build context, conflicting with the `COPY v2/ ./` rewrite. Fixed by removing `v2` from `.dockerignore` upstream ([PR #536](https://github.com/stolostron/azure-service-operator/pull/536)).

## CSV Feature Annotations (verify-conforma)

- **Decision**: `backplane-operator` CSV requires all 10 `features.operators.openshift.io/*` annotations
- **Rationale**: The 5.0 CSV was regenerated from operator-sdk scaffolding and lost these annotations. `verify-conforma`'s `olm.feature_annotations_format` policy blocks stage releases without them.
- **Fix**: [PR #4000](https://github.com/stolostron/backplane-operator/pull/4000) — added annotations matching MCE 2.11 values.

## CSV relatedImages and OPERAND_IMAGE_* Environment Variables

- **Decision**: The operator CSV must include `relatedImages` section and `OPERAND_IMAGE_*` env vars
- **Rationale**: Required for disconnected/air-gapped mirroring support. The 5.0 CSV initially lacked both because it was regenerated from scaffolding.
- **Note**: Developer Alec's [PR #4730](https://github.com/stolostron/multiclusterhub-operator/pull/4730) (ACM equivalent) was the authoritative fix; our initial PR #4731 contained extra entries for images no longer in 5.0.

## aos-cd-jobs Pipeline Activation

- **Decision**: `"mce-5.0"` must be added to `nonOCPGroups` in `aos-cd-jobs/pipeline-scripts/commonlib.groovy`
- **Rationale**: The ART build pipeline only triggers for groups listed in `nonOCPGroups`. Without this entry, MCE 5.0 builds won't run.
- **Reference**: [aos-cd-jobs PR](https://github.com/openshift-eng/aos-cd-jobs/pull/4793) (ACM 5.0 was the model).

## KRD build-manifests.sh

- **Decision**: After editing KRD tenant configs, must run `tenants-config/build-manifests.sh` with kustomize v5.7.1
- **Rationale**: The Gitlab CI rejects MRs where `auto-generated/` content doesn't match the kustomization sources. This script regenerates those files.
- **Lesson**: First MR attempt failed until this step was discovered.

## DCO Signoff

- **Decision**: All commits to `stolostron/*` repos require `git commit --signoff`
- **Rationale**: stolostron repos enforce the Developer Certificate of Origin (DCO) check. PRs without signed-off commits fail the `dco` CI check.
- **Lesson**: Multiple PRs had to be amended and force-pushed to add signoffs.
