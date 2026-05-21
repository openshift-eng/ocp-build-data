# DECISIONS.md — ACM 2.16 ocp-build-data Branch

Product decisions and rationale for the `acm-2.16` branch configuration.
Created as part of JIRA ticket [HYPBLD-847](https://redhat.atlassian.net/browse/HYPBLD-847).

## Product Identity

- **Decision**: `product: acm`, `name: acm-2.16`, `csv_namespace: open-cluster-management`
- **Rationale**: Matches ART naming conventions (short lowercase names like `mta`, `aap`). Requires a corresponding entry in `PRODUCT_NAMESPACE_MAP` in art-tools (PR pending).
- **Revisit**: When the art-tools PR is submitted and merged.

## OCP Version Alignment

- **Decision**: `MAJOR: 4`, `MINOR: 21` (OCP 4.21 infrastructure)
- **Rationale**: ACM 2.16 aligns with OCP 4.21 per the product version alignment table. The distgit branch `rhaos-4.21-rhel-9` is shared Brew infrastructure tied to OCP releases. All layered products use OCP version numbers for MAJOR.MINOR.
- **Source**: `acm-redhat-operators-config.yaml`, ART OLM Bundle docs.

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["4.18", "4.19", "4.20", "4.21", "4.22"]`
- **Rationale**: Derived from `acm-mce-operator-catalogs/config/acm-redhat-operators-config.yaml` which defines ACM 2.16 catalogs.
- **Revisit**: If catalog targets change before GA.

## RHEL Version and Repos Configuration

- **Decision**: RHEL 9.6 E4S, old-style inline repos in `group.yml`
- **Rationale**: E4S matches OCP 4.21 infrastructure. Old-style inline repos used because no layered product has adopted new-style `repos/` folder yet (logging-6.5, mta-8.1, oadp-1.5 all use inline). ART ai-helper tooling does not mandate a specific style.
- **Revisit**: If ART requests migration to `repos/` folder pattern.

## Network Mode

- **Decision**: `network_mode: open` (non-hermetic)
- **Rationale**: Per ART guidance (May 12 meeting): "Get images building non-hermetic first, then hermetic, then tackle bundles."
- **Revisit**: After initial builds succeed, migrate to `network_mode: hermetic`.

## Git Source URLs

- **Decision**: Use `git@github.com:stolostron/<repo>.git` directly (no openshift-priv mirrors)
- **Rationale**: ACM repos are already public under `github.com/stolostron/`. No private mirrors exist. Verified: `grep -r "openshift-priv"` in KRD ACM tenant returns zero hits.
- **Consequence**: `public_upstreams` section omitted from `group.yml`.

## Distgit Component Naming

- **Decision**: `acm-<component>-container` pattern for all ACM components
- **Rationale**: Consistent with other layered products (`mta-*-container`, `ose-*-container`). Internal build infrastructure naming decided by HCM Build team.

## Delivery Repo Names

- **Decision**: `rhacm2/<component>-rhel9` pattern
- **Rationale**: Matches existing ACM images in `registry.redhat.io/rhacm2/` namespace. Confirmed from ACM CSV OPERAND_IMAGE values and KRD ReleasePlanAdmission configs.

## RHEL 8 Builders

- **Decision**: `acm-cli` and `multicluster-operators-subscription` include both `rhel-9-golang` and `rhel-8-golang` builders
- **Rationale**: Product requirement — ACM customers run on both RHEL 8 and RHEL 9 clusters. These components ship binaries for both platforms. ART supports this pattern (see OCP's `egress-router-cni.yml`).

## Console Node.js Version

- **Decision**: `rhel-9-nodejs-20` stream (Node.js 20)
- **Rationale**: The `release-2.16` branch `Containerfile.acm.konflux` uses `nodejs-20-minimal`. Version-specific answers use the release-2.16 branch as the source of truth.

## Bundle Component

- **Decision**: `acm-operator-bundle` excluded from `images/*.yml`
- **Rationale**: Per ART guidance (May 12 meeting): "Don't try to solve bundle complexity upfront." ACM's bundle architecture (separate repos) is incompatible with ART's standard `update-csv` flow.
- **Revisit**: After images are building successfully.

## Dependents (MCE→ACM ordering)

- **Decision**: No `dependents:` field in any image config
- **Rationale**: The `dependents` field only resolves within the same ocp-build-data branch. MCE and ACM are separate branches (`mce-2.11`, `acm-2.16`), so this field cannot express cross-product dependencies. OLM handles install-time ordering via `spec.dependencies` in the bundle CSV.

## Owners

- **Decision**: `acm-cicd@redhat.com` as temporary owner for all images
- **Rationale**: HCM Build team DL used during bootstrap. ACM org should designate permanent owners.
- **Revisit**: When ACM team provides long-term ownership contacts.

## MR Approvers

- **Decision**: Omitted from `group.yml`
- **Rationale**: Optional field. Many products (OCP, AAP, Serverless) don't use it. Can be added later if ACM wants QE/DOCS sign-off on FBC release MRs.
