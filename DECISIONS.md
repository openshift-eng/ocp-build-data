# DECISIONS.md — MCE 2.11 ocp-build-data Branch

Product decisions and rationale for the `mce-2.11` branch configuration.
Created as part of JIRA ticket [HYPBLD-844](https://redhat.atlassian.net/browse/HYPBLD-844).

## Product Identity

- **Decision**: `product: mce`, `name: mce-2.11`, `csv_namespace: multicluster-engine`
- **Rationale**: Matches ART naming for layered products (parallel to Brian's `acm` / `acm-2.16`). Requires `CPE_PRODUCT_NAME_MAPPING` in art-tools (separate PR).

## OCP Version Alignment

- **Decision**: `MAJOR: 4`, `MINOR: 21` (OCP 4.21 infrastructure)
- **Rationale**: MCE 2.11 aligns with OCP 4.21; distgit branch `rhaos-4.21-rhel-9`.

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["4.18", "4.19", "4.20", "4.21", "4.22"]`
- **Rationale**: From MCE operator catalog channels.

## Git Source URLs

- **Decision**: Midstream mirrors under `openshift-priv`:
  - `stolostron/*` → `git@github.com:openshift-priv/stolostron-{repo}.git`
  - `openshift/*` → `git@github.com:openshift-priv/{repo}.git`
- **Rationale**: Same pattern as ACM PR #10635 (stolostron) and OCP `openshift-4.21` images (openshift org).

## Distgit and Delivery Naming

- **Decision**: `mce-{component}-container` distgit; `multicluster-engine/{component}-rhel9` delivery/name
- **Rationale**: Parallel to ACM's `acm-*` / `rhacm2/*-rhel9`; `multicluster-engine` matches OLM `csv_namespace`.

## Dockerfiles

- **Decision**: Use existing Konflux/RHTAP Dockerfiles per repo (not `Dockerfile.art`)
- **Rationale**: Per ACM onboarding thread — `Dockerfile.art` does not exist; paths vary by component.

## Image scope (HYPBLD-844 Jira stolostron checklist)

24 components on `backplane-2.11`. Excluded from 2.11: `cloudevents-conductor`, `cluster-permission`, `maestro`.

| Component | Upstream repo | Dockerfile |
|-----------|---------------|------------|
| addon-manager | [stolostron/ocm](https://github.com/stolostron/ocm) | `build/Dockerfile.addon.rhtap` |
| azure-service-operator | [stolostron/azure-service-operator](https://github.com/stolostron/azure-service-operator) | `stolostron/Dockerfile.stolostron` |
| backplane-must-gather | [stolostron/backplane-must-gather](https://github.com/stolostron/backplane-must-gather) | `build/Dockerfile.rhtap` |
| backplane-operator | [stolostron/backplane-operator](https://github.com/stolostron/backplane-operator) | `build/Dockerfile.rhtap` |
| cluster-api-provider-aws | [stolostron/cluster-api-provider-aws](https://github.com/stolostron/cluster-api-provider-aws) | `stolostron/Dockerfile.stolostron` |
| cluster-api-provider-azure | [stolostron/cluster-api-provider-azure](https://github.com/stolostron/cluster-api-provider-azure) | `stolostron/Dockerfile.stolostron` |
| cluster-api-webhook-config | [stolostron/cluster-api-installer](https://github.com/stolostron/cluster-api-installer) | `mce-capi-webhook-config/Dockerfile` |
| cluster-curator-controller | [stolostron/cluster-curator-controller](https://github.com/stolostron/cluster-curator-controller) | `Dockerfile.rhtap` |
| cluster-image-set-controller | [stolostron/cluster-image-set-controller](https://github.com/stolostron/cluster-image-set-controller) | `Dockerfile.rhtap` |
| cluster-proxy | [stolostron/cluster-proxy](https://github.com/stolostron/cluster-proxy) | `cmd/Dockerfile.rhtap` |
| clusterclaims-controller | [stolostron/clusterclaims-controller](https://github.com/stolostron/clusterclaims-controller) | `Dockerfile.rhtap` |
| clusterlifecycle-state-metrics | [stolostron/clusterlifecycle-state-metrics](https://github.com/stolostron/clusterlifecycle-state-metrics) | `build/Dockerfile.rhtap` |
| console-mce | [stolostron/console](https://github.com/stolostron/console) | `Containerfile.mce.konflux` |
| discovery-operator | [stolostron/discovery](https://github.com/stolostron/discovery) | `build/Dockerfile.rhtap` |
| hypershift-addon-operator | [stolostron/hypershift-addon-operator](https://github.com/stolostron/hypershift-addon-operator) | `Dockerfile.rhtap` |
| kube-rbac-proxy | [stolostron/kube-rbac-proxy](https://github.com/stolostron/kube-rbac-proxy) | `Containerfile.operator` |
| managed-serviceaccount | [stolostron/managed-serviceaccount](https://github.com/stolostron/managed-serviceaccount) | `Dockerfile.rhtap` |
| managedcluster-import-controller-addon | [stolostron/managedcluster-import-controller](https://github.com/stolostron/managedcluster-import-controller) | `build/Dockerfile.rhtap` |
| multicloud-manager | [stolostron/multicloud-operators-foundation](https://github.com/stolostron/multicloud-operators-foundation) | `Dockerfile.rhtap` |
| placement | [stolostron/ocm](https://github.com/stolostron/ocm) | `build/Dockerfile.placement.rhtap` |
| provider-credential-controller | [stolostron/provider-credential-controller](https://github.com/stolostron/provider-credential-controller) | `Dockerfile.rhtap` |
| registration | [stolostron/ocm](https://github.com/stolostron/ocm) | `build/Dockerfile.registration.rhtap` |
| registration-operator | [stolostron/ocm](https://github.com/stolostron/ocm) | `build/Dockerfile.registration-operator.rhtap` |
| work | [stolostron/ocm](https://github.com/stolostron/ocm) | `build/Dockerfile.work.rhtap` |

## Bundle Component

- **Decision**: MCE operator bundle excluded from `images/*.yml`
- **Rationale**: Same as ACM — defer bundle complexity until individual images build.

## Owners

- **Decision**: `acm-cicd@redhat.com` for all images (bootstrap)
- **Revisit**: MCE team to designate permanent owners.

## Konflux

- **Decision**: `network_mode: hermetic`, `cachi2.enabled: true`, `sast.enabled: true`
- **Rationale**: Aligned with merged skeleton and ACM PR after Ashwin review.
