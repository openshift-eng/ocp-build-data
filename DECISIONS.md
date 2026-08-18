# DECISIONS.md — MCE 5.0 ocp-build-data Branch

Product decisions and rationale for the `mce-5.0` branch configuration.
Derived from `mce-2.11` (HYPBLD-844) and `acm-5.0` (eemurphy PR #12366).

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

## Bundle Component

- **Decision**: MCE operator bundle excluded from `images/*.yml`
- **Rationale**: Same as mce-2.11 and acm-5.0 — defer bundle complexity until individual images build.
