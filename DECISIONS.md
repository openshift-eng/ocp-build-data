# DECISIONS.md — ACM 2.15 ocp-build-data Branch

Product decisions and rationale for the `acm-2.15` branch configuration.

Scaffolded from `acm-2.16` (the ART config landed under [HYPBLD-847](https://redhat.atlassian.net/browse/HYPBLD-847)) and then adjusted for 2.15 source, catalogs, and the already-shipping z-stream.

## Product Identity

- **Decision**: `product: rhacm2`, `name: acm-2.15`, `csv_namespace: open-cluster-management`
- **Rationale**: For a layered product, ART's `name` label and Konflux (`name` == repository) require `product` to be the registry namespace. ACM ships `registry.redhat.io/rhacm2/…`. art-tools already maps `rhacm2` (`PRODUCT_NAMESPACE_MAP` → `art-acm-tenant`, `CPE_PRODUCT_NAME_MAPPING` → `acm`).
- **Not this field**: a short product slug like `acm`. That was the original 2.16 bootstrap draft; `group.yml` on 2.16 is already `rhacm2`.

## Version (z-stream)

- **Decision**: `version: 2.15.9`
- **Rationale**: ACM 2.15 is already in production at **2.15.8** (`advanced-cluster-management.v2.15.8`; existing `crt-redhat-acm` RPA tags `v2.15` / `v2.15.8`). ART `group.yml` `version` is the next shipped z. Starting at 2.15.0 or 2.15.8 would produce an OLM version at or behind the catalog head.
- **Revisit**: Confirm 2.15.9 is still the next z at cutover.

## OCP Version Alignment

- **Decision**: `MAJOR: 4`, `MINOR: 20` (OCP 4.20 infrastructure). `streams.yml` `ose-cli` is `ose-cli-rhel9:v4.20`. Distgit/Brew expand to `rhaos-4.20-rhel-9`.
- **Rationale**: `vars.MAJOR` / `MINOR` are the **OpenShift Aligned Version** for this ACM y-stream, not the ACM version and not the catalog window. Layered products reuse an OCP `rhaos-*` line. ACM and MCE are Platform Aligned operators: support dates follow that one OCP minor, even though the operator still installs on other OCP versions.
- **Source**: [OpenShift Operator Life Cycles](https://access.redhat.com/support/policy/updates/openshift_operators) → Platform Aligned → expand ACM / MCE rows. ACM **2.15** OpenShift Aligned Version is **4.20** (MCE **2.10** is the same). ACM 2.16 is 4.21; `branch-setup` first wrote 2/15 then 4.21 — both were wrong for this field.
- **Not this field**: the "Supported OpenShift versions" column on that page, the [2.15 Support Matrix](https://access.redhat.com/articles/7133095) hub list, and `OCP_TARGET_VERSIONS`. Those are the install/catalog window (includes 4.21 as the extra next OCP). 4.21 is compatible, not the aligned line.

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["4.17", "4.18", "4.19", "4.20", "4.21"]`
- **Rationale**: Catalog/FBC list for ACM 2.15, from `acm-operator-bundle` `release-2.15` Dockerfile annotation `com.redhat.openshift.versions="v4.17-v4.21"`. The lifecycle page lists supported OCP as 4.18–4.21; 4.17 is kept to match the bundle annotation until catalogs or docs drop it.
- **Revisit**: If catalog targets change, or if ART wants this list trimmed to the lifecycle "Supported OpenShift versions" column only.

## RHEL Version and Repos Configuration

- **Decision**: Inline pulp URLs `rhel9/9.7` with `rhel-9-*` repo names. `streams.yml` `rhel9` is `registry.access.redhat.com/ubi9/ubi-minimal:9.7` (pinned minor, not `:latest`).
- **Rationale**: RHEL major (`rhel-9` in distgit, repos, builders, UBI) must stay aligned. Pulp is 9.7; a floating `:latest` UBI that moves to 9.8 would fail RPM install against these repos. 2.15 Konflux `Dockerfile.rhtap` files use the `registry.access.redhat.com` host and `:latest`; ART rewrites `FROM` from this stream, so the pin is the ocp-build-data contract. 2.16 uses `registry.redhat.io/ubi9/ubi-minimal:9.7` — same minor, different host.
- **Revisit**: If ART wants the `registry.redhat.io` host, a 4.20-matched E4S minor, or migration to the `repos/` folder pattern.

## Network Mode

- **Decision**: `network_mode: hermetic` (copied from 2.16)
- **Rationale**: 2.16 already builds hermetic. 2.15 should not regress to `open`. Group-level `cachi2.enabled: true`.
- **Revisit**: Individual 2.15 Dockerfiles that still `go mod vendor`, `git submodule update`, or `GOTOOLCHAIN=auto` may fail hermetic until those repos match 2.16.

## Git Source URLs

- **Decision**: Use `git@github.com:openshift-priv/stolostron-<repo>.git` with `public_upstreams` mapping `openshift-priv` → `stolostron`, plus an override for `ocp-build-data` → `openshift-eng/ocp-build-data`.
- **Rationale**: ART builds from `openshift-priv` mirrors. The generic stolostron mapping does not apply to the shared `base-rhel9` source repo.

## Distgit Component Naming

- **Decision**: `acm-<component>-container` pattern for ACM components
- **Rationale**: Consistent with other layered products (`mta-*-container`, `ose-*-container`). Internal build infrastructure naming decided by HCM Build team.

## Jira components

- **Decision**: No `jira:` block on image YAML. Lookups fall back to `product.yml` on `main`.
- **Rationale**: Same as `acm-5.0` / `mce-5.0`. Distgit → Jira component mappings are maintained once on `main`, generated from [stolostron/acm-config](https://github.com/stolostron/acm-config) via `product/generate_ocp_build_data_product_yml.py`. Copying them onto every y-stream branch duplicates that source of truth (and is what `acm-2.16` still has).
- **Revisit**: `origin/main` `product.yml` has `mce-cluster-permission-container` but not `acm-cluster-permission-container`. Regenerating `product.yml` from acm-config is required before this fallback covers cluster-permission. Until then, Konflux/Jira routing for that image may be empty.

## Delivery Repo Names

- **Decision**: `name` and `delivery_repo_names` must exactly match the delivery repo registered for this y-stream.
- **Source of truth for 2.15**: `konflux-release-data/config/stone-prd-rh01.pg1f.p1/product/ReleasePlanAdmission/crt-redhat-acm/crt-redhat-acm-acm-2-15-rpa-stage.yaml` (pre-ART tenant). The 2.16 ART RPA is a naming reference, not the 2.15 allow-list — it includes `obo-prometheus-rhel9-operator`, which 2.15 does not ship under `rhacm2/`.
- **Rationale**: ART sets the `name` label from ocp-build-data. Stage release validates that label against the registered delivery repo. A mismatch causes `LabelValidationError`.
- **Naming patterns** (not uniform — look up per component):
  - Some have `acm-` prefix: `acm-cluster-permission-rhel9`, `acm-grafana-rhel9`, `acm-must-gather-rhel9`, etc.
  - Some have `-rhel9-operator` suffix (not `-operator-rhel9`): `endpoint-monitoring-rhel9-operator`, `observatorium-rhel9-operator`
  - Some differ from the ocp-build-data filename: `prometheus-operator.yml` → `acm-prometheus-rhel9`, `search-v2-operator.yml` → `acm-search-v2-rhel9`

## Image set vs 2.16

- **Decision**: Same image YAML set as 2.16 except:
  - No `images/obo-prometheus-operator.yml`. 2.15 has no `release-2.15` branch on `stolostron/obo-prometheus-operator`. The shipping 2.15.8 CSV references COO's `cluster-observability-operator/obo-prometheus-rhel9-operator`, not `rhacm2/obo-prometheus-rhel9-operator`. When ART bundles are enabled, that image belongs in `bundle/art.yaml` `external-images` / `image-references`.
  - `acm-cli.yml` cachito gomod paths are `.`, `external/policy-cli`, `external/policy-generator-plugin` only. `external/allowlist-migration-mcoa` does not exist on `acm-cli` `release-2.15`.

## RHEL 8 Builders

- **Decision**: Only `multicluster-operators-subscription` has both `rhel-9-golang` and `rhel-8-golang` builders. `acm-cli` is rhel-9 golang only.
- **Rationale**: Matches `release-2.15` Dockerfiles. Subscription still builds a RHEL 8 policy-generator binary; acm-cli `Dockerfile.rhtap` on 2.15 has a single golang-builder FROM.

## Console Node.js Version

- **Decision**: `rhel-9-nodejs-24` stream (Node.js 24). Console runtime stays on that stream (not `member: base-rhel9`).
- **Rationale**: `stolostron/console` `release-2.15` `Containerfile.acm.konflux` is two `FROM registry.redhat.io/ubi9/nodejs-24-minimal:latest` stages. The 2.16 bootstrap note about Node 20 is stale.

## Bundle / `update-csv`

- **Decision**: Images-first. `update-csv` on `multiclusterhub-operator.yml` is commented until ART bundle metadata exists on `multiclusterhub-operator` `release-2.15`. `bundle_name_override: acm-operator-bundle` and Konflux `bundle_name_override: acm-2-15-acm-operator-bundle` stay so re-enabling is a small uncomment.
- **Rationale**: `update-csv` is the switch that turns on bundle and catalog production. 2.15 MCH still has the operator-sdk CSV (`multiclusterhub-operator.clusterserviceversion.yaml`, `0.0.1`) and no `bundle/art.yaml` / `bundle/image-references`. 2.16 has `advanced-cluster-management.clusterserviceversion.yaml` with `relatedImages`, `OPERAND_IMAGE_*`, and `features.operators.openshift.io/*`. Enabling `update-csv` without those inputs fails Conforma (`olm.feature_annotations_format`, `olm.unmapped_references`) and disconnected install.
- **Revisit**: After the 2.15 MCH ART bundle PR merges, uncomment `update-csv` (and keep `name: advanced-cluster-management` matching that CSV filename).

## Dependents

- **Decision**: Operand images keep `dependents: [multiclusterhub-operator]` (intra-branch). This does **not** express MCE → ACM ordering.
- **Rationale**: `dependents` only resolves within the same ocp-build-data branch. MCE 2.10 and ACM 2.15 are separate groups. OLM handles install-time ordering via CSV `spec.dependencies`.

## Owners

- **Decision**: `acm-cicd@redhat.com` as temporary owner for ACM images; `aos-team-art@redhat.com` for `base-rhel9`
- **Rationale**: HCM Build team DL used during bootstrap. ACM org should designate permanent owners.
- **Revisit**: When ACM team provides long-term ownership contacts.

## MR Approvers

- **Decision**: Omitted from `group.yml`
- **Rationale**: Optional field. Many products (OCP, AAP, Serverless) don't use it. Can be added later if ACM wants QE/DOCS sign-off on FBC release MRs.

## Base RHEL 9 Image

- **Decision**: `images/base-rhel9.yml` as a layered base on top of `ubi-minimal`. `name: art-core/base-rhel9`, `for_release: false`, source branch `openshift-base-rhel9`.
- **Rationale**: RPMs in ART's enabled repos ship sooner than RHEL. A managed base that runs `yum update` avoids rebuild loops waiting on UBI. Shared ART infrastructure, not an ACM product image — same pattern as logging / MTA / OADP.
- **Runtime replacement**: Every image whose Dockerfile final `FROM` is ubi-minimal uses `from.member: base-rhel9` (45 images). Exceptions: `console.yml` (nodejs-24 runtime) and `base-rhel9.yml` itself (`from.stream: rhel9`).
