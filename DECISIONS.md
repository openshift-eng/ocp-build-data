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

- **Decision**: Use `git@github.com:openshift-priv/stolostron-<repo>.git` with `public_upstreams` mapping to `stolostron`
- **Rationale**: ART builds use `openshift-priv` mirrors for hermetic source resolution. The `public_upstreams` section maps `openshift-priv` -> `stolostron` so ART can locate public sources for advisories and CVE tracking.
- **Updated**: Originally omitted `public_upstreams`; added after enabling hermetic builds.

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

## Base RHEL 9 Image (Part 5)

- **Decision**: Introduce `images/base-rhel9.yml` as a layered base image on top of `ubi-minimal`
- **Rationale**: RPMs available through ART's enabled repositories are shipped sooner than RHEL. Without a managed base image that runs `yum update`, ACM would be stuck in rebuild loops waiting for RHEL updates. This pattern is standard across all ART-managed layered products (OCP, logging-6.5, MTA 8.1, OADP 1.6).
- **Source**: Developer request (Ashwin), reference PR openshift-eng/ocp-build-data#11595

### base-rhel9 Image Name

- **Decision**: `name: art-core/base-rhel9` (not `rhacm2/base-rhel9`)
- **Rationale**: This is a shared ART infrastructure image, not an ACM product image. The `art-core/` namespace is used by all layered products for this same base image (logging-6.5, MTA 8.1). It is not shipped to customers and has `for_release: false`.

### base-rhel9 Source Branch

- **Decision**: Source from `openshift-base-rhel9` branch of `ocp-build-data` (shared across all products)
- **Rationale**: The Dockerfile, `microdnf-wrapper.sh`, and `ubi.repo` on this branch are maintained by ART and shared by all layered products. No ACM-specific fork needed.

### public_upstreams Override for ocp-build-data

- **Decision**: Added specific `public_upstreams` entry mapping `openshift-priv/ocp-build-data` -> `openshift-eng/ocp-build-data`
- **Rationale**: ACM's generic mapping (`openshift-priv` -> `stolostron`) does not apply to the `ocp-build-data` repo, which lives under `openshift-eng`. Without this override, ART's source resolver would look for a non-existent `stolostron/ocp-build-data`. Same issue addressed in MTA 8.1 PR#11595 (commit "Fix public_upstreams mapping").

### Runtime Base Image Replacement

- **Decision**: All 47 component configs changed from `from: stream: rhel9` to `from: member: base-rhel9`
- **Rationale**: Per developer guidance (A3): "Any job that uses the existing ubi-minimal image should be replaced: stream: rhel9 -> member: base-rhel9." This ensures all ACM images layer on the managed base, receiving timely RPM updates. Builder entries using `stream: rhel9` (only `multiclusterhub-operator`) also changed.
- **Exception**: `base-rhel9.yml` itself retains `from: stream: rhel9` since it IS the layer on top of ubi-minimal.

### base-rhel9 Lockfile RPMs

- **Decision**: `konflux.cachi2.lockfile.rpms: [findutils]` with `inspect_parent: false`
- **Rationale**: Matches logging-6.5 configuration. The shared Dockerfile uses `find` implicitly, and `inspect_parent: false` is correct for a base image (no parent lockfile to inherit). The `findutils` RPM ensures hermetic builds can resolve this dependency.

### base-rhel9 Ownership

- **Decision**: `owners: [aos-team-art@redhat.com]` (ART team, not ACM team)
- **Rationale**: This is an ART-maintained infrastructure image shared across products. Matches the pattern in logging-6.5 and other layered products.
