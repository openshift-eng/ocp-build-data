# DECISIONS.md — ACM 2.11 ocp-build-data Branch

Product decisions and rationale for the `acm-2.11` branch configuration.
Created as part of JIRA ticket [HYPBLD-879](https://redhat.atlassian.net/browse/HYPBLD-879).

## Product Identity

- **Decision**: `product: rhacm2`, `name: acm-2.11`, `csv_namespace: open-cluster-management`
- **Rationale**: Matches ART naming conventions (short lowercase names like `mta`, `aap`). Requires a corresponding entry in `PRODUCT_NAMESPACE_MAP` in art-tools (PR pending).
- **Revisit**: When the art-tools PR is submitted and merged.

## Version (z-stream)

- **Decision**: `version: 2.11.14`
- **Rationale**: ACM 2.11 is already shipping at **2.11.13** (paired with MCE **2.6**, not yet ART-onboarded). ART `group.yml` `version` is the next z-stream under preparation.
- **Revisit**: Bump with each z-stream cut.

## OCP Version Alignment

- **Decision**: `MAJOR: 4`, `MINOR: 16` (OCP 4.16 infrastructure)
- **Rationale**: ACM 2.11 aligns with OCP 4.16 per the product version alignment table (`ACM Konflux Infrastructure.md`: ACM 2.11 → MCE 2.6 → `release-4.16`). The distgit branch `rhaos-4.16-rhel-9` is shared Brew infrastructure tied to OCP releases. Derived as second-highest of `OCP_TARGET_VERSIONS` (art-migration branch-setup convention).
- **Source**: Local ART research notes; catalog config v2.11 window.
- **Revisit**: Confirm with ACM product lead before opening the ocp-build-data PR.

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["4.12", "4.14", "4.15", "4.16", "4.17"]`
- **Rationale**: Product confirmed OCP **4.12** must remain (support exception). **4.13** is dropped as no longer supported. Remaining window is 4.14–4.17. acm-2.12 is sunset and must not be used as a reference.
- **Source**: Gus Parvin / Disaiah Bennett guidance (OCP 4.12 support exception for ACM 2.11 / MCE 2.6 pairing).
- **Revisit**: Confirm against the live `acm-mce-operator-catalogs` config before opening the PR.

## RHEL Version and Repos Configuration

- **Decision**: RHEL 9.7, old-style inline repos in `group.yml`
- **Rationale**: Carried forward from acm-2.16 ART branch (`ubi9/ubi-minimal:9.7`). Old-style inline repos used because no layered product has adopted new-style `repos/` folder yet.
- **Revisit**: Confirm with ART lead that 9.7 remains correct for the 4.16 brew stream.

## Network Mode

- **Decision**: `network_mode: hermetic`
- **Rationale**: Carried forward from acm-2.16 ART branch (hermetic already enabled there). Confirm with ART lead.
- **Revisit**: If initial builds fail hermetic resolution, temporarily open network mode then re-enable hermetic.

## Git Source URLs

- **Decision**: Use `git@github.com:openshift-priv/stolostron-<repo>.git` with `public_upstreams` mapping to `stolostron`
- **Rationale**: ART builds use `openshift-priv` mirrors for hermetic source resolution. The `public_upstreams` section maps `openshift-priv` -> `stolostron` so ART can locate public sources for advisories and CVE tracking.

## Distgit Component Naming

- **Decision**: `acm-<component>-container` pattern for all ACM components
- **Rationale**: Consistent with other layered products (`mta-*-container`, `ose-*-container`). Internal build infrastructure naming decided by HCM Build team.

## Delivery Repo Names

- **Decision**: `name` and `delivery_repo_names` must exactly match the delivery repo name registered in the Konflux product registry (ReleasePlanAdmission).
- **Source of truth**: Cross-checked against stone `crt-redhat-acm-acm-2-11-rpa-{stage,prod}` / bundle RPAs and ART `acm-advisory-{stage,prod}-2-11` after bootstrap.
- **Rationale**: ART sets the `name` label on built container images from the `name` field in ocp-build-data. During stage release, Konflux validates this label against the registered delivery repo. A mismatch causes `LabelValidationError`.
- **Cross-check result (HYPBLD-879 staging)**: Delivery-repo set matches stone ACM 2.11 exactly (41 operand images + `acm-operator-bundle` via `multiclusterhub-operator.yml` overrides). Removed acm-2.16-only carryovers absent from stone 2.11: `acm-cli`, `siteconfig`, `multicluster-observability-addon`, `mtv-integrations`, `multicluster-role-assignment`, `obo-prometheus-operator`. External `volsync-rhel9` is not an ocp-build-data image (bundle `art.yaml`); stone 2.11 RPAs do not list it either, so it was dropped from the ART stage advisory mapping. Re-verified after that konflux trim: every stone delivery repo still pairs 1:1 with an `images/*.yml` `name`/`delivery_repo_names` entry on `release-2.11`; no additional ocp-build-data deletions or renames were required.
- **Lesson**: Never assume a naming pattern — always cross-reference against the Konflux ReleasePlanAdmission for the product version.

## RHEL 8 Builders

- **Decision**: `multicluster-operators-subscription` includes both `rhel-9-golang` and `rhel-8-golang` builders
- **Rationale**: Product requirement — ACM customers run on both RHEL 8 and RHEL 9 clusters. Pattern carried from acm-2.16 scaffold. (`acm-cli` is not part of the ACM 2.11 image set.)

## Console Node.js Version

- **Decision**: `rhel-9-nodejs-24` stream (Node.js 24), carried from acm-2.16 scaffold
- **Rationale**: Scaffold inherits streams from acm-2.16. Confirm against the actual `release-2.11` console Containerfile before builds.
- **Revisit**: If release-2.11 still builds with an older Node stream, update `streams.yml` / `images/console.yml` accordingly.

## ose-cli Stream

- **Decision**: `ose-cli` pin `registry.redhat.io/openshift4/ose-cli-rhel9:v4.16`
- **Rationale**: Aligns with ACM 2.11 ↔ OCP 4.16 infrastructure (same adjustment applied on acm-2.13 → v4.18 / acm-2.14 → v4.19).

## Bundle Component

- **Decision**: Bundle handled via `images/multiclusterhub-operator.yml` konflux bundle overrides (`acm-2-11-acm-operator-bundle`) plus operator-repo `bundle/` ART scaffolding.
- **Rationale**: Matches current acm-2.16 ART branch layout used as the scaffold source.
- **Package / CSV identity**: `update-csv.name` is `advanced-cluster-management` (with `bundle_delivery_repo_name: rhacm2/acm-operator-bundle`). Confirmed against stone/FBC `allowedPackages: [advanced-cluster-management]` and the operator-repo ART bundle packaging after the HYPBLD-879 product bug-fix pass. No further ocp-build-data image-set changes were required by the konflux advisory trim (volsync was never an ocp-build-data image).

## Dependents (MCE→ACM ordering)

- **Decision**: No cross-product `dependents:` between MCE and ACM branches.
- **Rationale**: The `dependents` field only resolves within the same ocp-build-data branch. MCE (`mce-2.6`) and ACM (`acm-2.11`) are separate branches. OLM handles install-time ordering via `spec.dependencies` in the bundle CSV. Current Z-stream pairing: ACM 2.11.13 / MCE 2.6.15.

## Owners

- **Decision**: `acm-cicd@redhat.com` as temporary owner for all images
- **Rationale**: HCM Build team DL used during bootstrap. ACM org should designate permanent owners.
- **Revisit**: When ACM team provides long-term ownership contacts.

## MR Approvers

- **Decision**: Omitted from `group.yml`
- **Rationale**: Optional field. Can be added later if ACM wants QE/DOCS sign-off on FBC release MRs.

## Base RHEL 9 Image

- **Decision**: Keep `images/base-rhel9.yml` as a layered base image on top of `ubi-minimal` (`name: art-core/base-rhel9`)
- **Rationale**: Carried from acm-2.16. Shared ART infrastructure image; not an ACM product image; `for_release: false`.
