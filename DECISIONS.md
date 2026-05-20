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

- **Decision**: `git@github.com:openshift-priv/stolostron-{repo}.git` midstream naming (same pattern as ACM PR #10635)
- **Rationale**: Ashwin verified openshift-priv mirrors exist for stolostron repos.

## Distgit and Delivery Naming

- **Decision**: `mce-{component}-container` distgit; `multicluster-engine/{component}-rhel9` delivery/name
- **Rationale**: Parallel to ACM's `acm-*` / `rhacm2/*-rhel9`; `multicluster-engine` matches OLM `csv_namespace`.

## Dockerfiles

- **Decision**: Use existing Konflux/RHTAP Dockerfiles per repo (not `Dockerfile.art`)
- **Rationale**: Per ACM onboarding thread — `Dockerfile.art` does not exist in stolostron repos; paths vary (`Dockerfile.rhtap`, `build/Dockerfile.rhtap`, `cmd/Dockerfile.rhtap`, etc.).

## Branch Target

- **Decision**: `branch.target: backplane-2.11` for all images
- **Rationale**: MCE 2.11 release branch. Some repos do not have `backplane-2.11` yet; dockerfile paths were discovered on the latest available `backplane-*` branch (documented per image in PR description).

## Components Not Yet in images/

- **Deferred**: `console-mce` (no `stolostron/console-mce` repo), `discovery-operator`, `multicloud-manager`, `cluster-api-provider-agent`, `cluster-api-provider-kubevirt`, `hypershift-operator` (no matching stolostron repo or no `backplane-2.11` branch yet)
- **Revisit**: Add when repos/branches exist and delivery names are confirmed.

## Bundle Component

- **Decision**: MCE operator bundle excluded from `images/*.yml`
- **Rationale**: Same as ACM — defer bundle complexity until individual images build.

## Owners

- **Decision**: `acm-cicd@redhat.com` for all images (bootstrap)
- **Revisit**: MCE team to designate permanent owners.

## Konflux

- **Decision**: `network_mode: hermetic`, `cachi2.enabled: true`, `sast.enabled: true`
- **Rationale**: Aligned with merged skeleton and ACM PR after Ashwin review.
