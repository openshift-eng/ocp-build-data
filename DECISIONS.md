# DECISIONS.md — ACM 2.13 ocp-build-data Branch

Product decisions and rationale for the `acm-2.13` branch configuration.
Created as part of JIRA ticket [HYPBLD-883](https://redhat.atlassian.net/browse/HYPBLD-883).

## Product Identity

- **Decision**: `product: rhacm2`, `name: acm-2.13`, `csv_namespace: open-cluster-management`
- **Rationale**: Matches ART naming conventions (short lowercase names like `mta`, `aap`). Requires a corresponding entry in `PRODUCT_NAMESPACE_MAP` in art-tools (PR pending).
- **Revisit**: When the art-tools PR is submitted and merged.

## Version (z-stream)

- **Decision**: `version: 2.13.14`
- **Rationale**: ACM 2.13 is already shipping at **2.13.13** (paired with MCE **2.8**). ART `group.yml` `version` is the next shipped z — same rule as operating ACM branches (e.g. acm-2.14 at `2.14.7` after catalog head `2.14.6`). Starting at `2.13.0` or `2.13.13` would produce an OLM/build version at or behind the catalog head.
- **Note**: MCH `release-2.13` CSV currently carries `2.13.0`; CSV/`OPERATOR_VERSION` bumps happen via MCH `bundle/art.yaml` at cutover (`search: "2.13.0"` → `replace: "2.13.14"`), not automatically from this field alone.
- **Revisit**: Confirm 2.13.14 is still the next z at cutover.

## OCP Version Alignment

- **Decision**: `MAJOR: 4`, `MINOR: 18` (OCP 4.18 infrastructure)
- **Rationale**: ACM 2.13 aligns with OCP 4.18 per the product version alignment table. The distgit branch `rhaos-4.18-rhel-9` is shared Brew infrastructure tied to OCP releases. All layered products use OCP version numbers for MAJOR.MINOR.
- **Source**: ACM/MCE version → OCP branch alignment (local ART research notes); same ±2 catalog window pattern used for acm-2.14/acm-2.15/acm-2.16.
- **Revisit**: Confirm with ACM product lead before opening the ocp-build-data PR.

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["4.16", "4.17", "4.18", "4.19"]`
- **Rationale**: Taken from local `acm-redhat-operators-config.yaml` (`v2.13` catalogs: ocp-4.16 through ocp-4.19). acm-2.14 was not ready as a reference stream.
- **Source**: `~/ghRepo/release/tools/konflux/catalog/example-catalog-repo-config/catalog-branch/config/acm-redhat-operators-config.yaml`
- **Revisit**: Confirm against the live `acm-mce-operator-catalogs` config before opening the PR.

## RHEL Version and Repos Configuration

- **Decision**: RHEL 9.7, old-style inline repos in `group.yml`
- **Rationale**: Carried forward from acm-2.16 ART branch (`ubi9/ubi-minimal:9.7`). Old-style inline repos used because no layered product has adopted new-style `repos/` folder yet.
- **Revisit**: Confirm with ART lead that 9.7 remains correct for the 4.18 brew stream.

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
- **Source of truth**: Cross-checked against stone `crt-redhat-acm-acm-2-13-rpa-{stage,prod}` / bundle RPAs and ART `acm-advisory-{stage,prod}-2-13` after bootstrap.
- **Rationale**: ART sets the `name` label on built container images from the `name` field in ocp-build-data. During stage release, Konflux validates this label against the registered delivery repo. A mismatch causes `LabelValidationError`.
- **Cross-check result (HYPBLD-883 staging)**: Delivery-repo set now matches stone ACM 2.13 exactly (44 operand images + `acm-operator-bundle` via `multiclusterhub-operator.yml` overrides). Removed acm-2.16-only carryovers that are not in stone 2.13: `mtv-integrations-rhel9`, `multicluster-role-assignment-rhel9`, `obo-prometheus-rhel9-operator`. External `volsync-rhel9` is not an ocp-build-data image (bundle `art.yaml` / stage-only ART note); stone 2.13 RPAs do not list it either.
- **Lesson**: Never assume a naming pattern — always cross-reference against the Konflux ReleasePlanAdmission for the product version.

## RHEL 8 Builders

- **Decision**: `acm-cli` and `multicluster-operators-subscription` include both `rhel-9-golang` and `rhel-8-golang` builders
- **Rationale**: Product requirement — ACM customers run on both RHEL 8 and RHEL 9 clusters. Pattern carried from acm-2.16 scaffold.

## Console Node.js Version

- **Decision**: `rhel-9-nodejs-24` stream (Node.js 24), carried from acm-2.16 scaffold
- **Rationale**: Scaffold inherits streams from acm-2.16. Confirm against the actual `release-2.13` console Containerfile before builds.
- **Revisit**: If release-2.13 still builds with an older Node stream, update `streams.yml` / `images/console.yml` accordingly.

## ose-cli Stream

- **Decision**: `ose-cli` pin `registry.redhat.io/openshift4/ose-cli-rhel9:v4.18`
- **Rationale**: Aligns with ACM 2.13 ↔ OCP 4.18 infrastructure (same adjustment applied on acm-2.14 → v4.19).

## Bundle Component

- **Decision**: Bundle handled via `images/multiclusterhub-operator.yml` konflux bundle overrides (`acm-2-13-acm-operator-bundle`) plus operator-repo `bundle/` ART scaffolding.
- **Rationale**: Matches current acm-2.16 ART branch layout used as the scaffold source.

## Dependents (MCE→ACM ordering)

- **Decision**: No cross-product `dependents:` between MCE and ACM branches.
- **Rationale**: The `dependents` field only resolves within the same ocp-build-data branch. MCE and ACM are separate branches. OLM handles install-time ordering via `spec.dependencies` in the bundle CSV.

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
