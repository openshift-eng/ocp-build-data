# DECISIONS.md — ACM 2.14 ocp-build-data Branch

Product decisions and rationale for the `acm-2.14` branch configuration.
Created as part of JIRA ticket [HYPBLD-885](https://redhat.atlassian.net/browse/HYPBLD-885).

Aligned with lessons from the operating `acm-2.15` ART branch after reopen onto
`openshift-eng/acm-2.14` (which was cut from 2.15 content).

## Product Identity

- **Decision**: `product: rhacm2`, `name: acm-2.14`, `csv_namespace: open-cluster-management`
- **Rationale**: For a layered product, ART's `name` label and Konflux (`name` == repository) require `product` to be the registry namespace. ACM ships `registry.redhat.io/rhacm2/…`. art-tools already maps `rhacm2` (`PRODUCT_NAMESPACE_MAP` → `art-acm-tenant`, `CPE_PRODUCT_NAME_MAPPING` → `acm`).
- **Not this field**: a short product slug like `acm`.

## Version (z-stream)

- **Decision**: `version: 2.14.7`
- **Rationale**: ACM 2.14 is already shipping at **2.14.6** (paired with MCE **2.9.8**). ART `group.yml` `version` is the next shipped z — same rule as operating 2.15 (`2.15.9` after catalog head `2.15.8`). Starting at `2.14.0` or `2.14.6` would produce an OLM/build version at or behind the catalog head.
- **Note**: MCH `release-2.14` source/`art.yaml` still carry `2.14.0` placeholders; CSV/`OPERATOR_VERSION` bumps happen via MCH `bundle/art.yaml` at cutover, not automatically from this field alone.
- **Revisit**: Confirm 2.14.7 is still the next z at cutover.

## OCP Version Alignment

- **Decision**: `MAJOR: 4`, `MINOR: 19` (OCP 4.19 infrastructure). `streams.yml` `ose-cli` is `ose-cli-rhel9:v4.19`. Distgit/Brew expand to `rhaos-4.19-rhel-9`.
- **Rationale**: `vars.MAJOR` / `MINOR` are the **OpenShift Aligned Version** for this ACM y-stream, not the ACM version and not the catalog window. Layered products reuse an OCP `rhaos-*` line. Staircase with operating branches: ACM 2.14→4.19, 2.15→4.20, 2.16→4.21.
- **Not this field**: `OCP_TARGET_VERSIONS` (install/catalog window).

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["4.16", "4.17", "4.18", "4.19", "4.20"]`
- **Rationale**: Catalog/FBC window for ACM 2.14 (one step behind operating 2.15’s 4.17–4.21). Originally derived from `acm-redhat-operators-config.yaml` / catalog config for 2.14.
- **Revisit**: If catalog targets change, or if ART wants this list trimmed to the lifecycle "Supported OpenShift versions" column only.

## RHEL Version and Repos Configuration

- **Decision**: Inline pulp URLs `rhel9/9.7` with `rhel-9-*` repo names. `streams.yml` `rhel9` is `registry.redhat.io/ubi9/ubi-minimal:9.7` (pinned minor, not `:latest`).
- **Rationale**: RHEL major must stay aligned across distgit, repos, builders, and UBI. Same pinned UBI pullspec pattern as operating 2.15 / 2.16.
- **Revisit**: If ART requests migration to the `repos/` folder pattern.

## Network Mode

- **Decision**: `network_mode: hermetic` with group-level `cachi2.enabled: true` (no `cachi2.lockfile.backend`).
- **Rationale**: Matches operating 2.15 / 2.16. Do not regress to `open`. The bootstrap `rpm-lockfile-prototype` backend was removed to match 2.15.
- **Revisit**: Individual 2.14 Dockerfiles that still `go mod vendor`, `git submodule update`, or `GOTOOLCHAIN=auto` may fail hermetic until those repos match later y-streams.

## Git Source URLs

- **Decision**: Use `git@github.com:openshift-priv/stolostron-<repo>.git` with `public_upstreams` mapping `openshift-priv` → `stolostron`, plus an override for `ocp-build-data` → `openshift-eng/ocp-build-data`.
- **Rationale**: ART builds from `openshift-priv` mirrors. The generic stolostron mapping does not apply to the shared `base-rhel9` source repo.

## Distgit Component Naming

- **Decision**: `acm-<component>-container` pattern for ACM components
- **Rationale**: Consistent with other layered products (`mta-*-container`, `ose-*-container`). Internal build infrastructure naming decided by HCM Build team.

## Jira components

- **Decision**: No `jira:` block on image YAML. Lookups fall back to `product.yml` on `main`.
- **Rationale**: Same as operating `acm-2.15` / `acm-5.0` / `mce-5.0`. Distgit → Jira mappings are maintained once on `main`, generated from [stolostron/acm-config](https://github.com/stolostron/acm-config). Copying them onto every y-stream duplicates that source of truth.
- **Revisit**: Confirm `main` `product.yml` covers all ACM 2.14 distgit components (e.g. cluster-permission) before relying on fallback alone.

## Delivery Repo Names

- **Decision**: `name` and `delivery_repo_names` must exactly match the delivery repo registered for this y-stream.
- **Source of truth for 2.14**: `konflux-release-data` `crt-redhat-acm-acm-2-14-rpa-stage.yaml` (when present). Use operating 2.15 / 2.16 RPAs only as naming references, not as the 2.14 allow-list.
- **Rationale**: ART sets the `name` label from ocp-build-data. Stage release validates that label against the registered delivery repo. A mismatch causes `LabelValidationError`.
- **Naming patterns** (not uniform — look up per component):
  - Some have `acm-` prefix: `acm-cluster-permission-rhel9`, `acm-grafana-rhel9`, `acm-must-gather-rhel9`, etc.
  - Some have `-rhel9-operator` suffix (not `-operator-rhel9`): `endpoint-monitoring-rhel9-operator`, `observatorium-rhel9-operator`
  - Some differ from the ocp-build-data filename: `prometheus-operator.yml` → `acm-prometheus-rhel9`, `search-v2-operator.yml` → `acm-search-v2-rhel9`

## Image set vs operating 2.15

- **Decision**: Same image YAML set as operating 2.15 except:
  - No `images/mtv-integrations.yml` — no `release-2.14` on `stolostron/mtv-integrations` (first appears at 2.15).
  - No `images/multicluster-role-assignment.yml` — no `release-2.14` (first appears at 2.15).
  - `acm-cli.yml` cachito gomod paths are `.`, `external/policy-cli`, `external/policy-generator-plugin` only. `external/allowlist-migration-mcoa` does not exist on `acm-cli` `release-2.14`.

## RHEL 8 Builders

- **Decision**: Only `multicluster-operators-subscription` has both `rhel-9-golang` and `rhel-8-golang` builders. `acm-cli` is rhel-9 golang only.
- **Rationale**: Matches `release-2.14` / operating 2.15 Dockerfiles. Subscription still builds a RHEL 8 policy-generator binary; acm-cli has a single golang-builder FROM.

## Console Node.js Version

- **Decision**: `rhel-9-nodejs-24` stream (Node.js 24). Console runtime stays on that stream (not `member: base-rhel9`).
- **Rationale**: `stolostron/console` `release-2.14` `Containerfile.acm.konflux` is two `FROM registry.redhat.io/ubi9/nodejs-24-minimal:latest` stages. Earlier bootstrap notes about Node 20 were stale.

## Bundle / `update-csv`

- **Decision**: Enable `update-csv` on `multiclusterhub-operator.yml` with `name: multiclusterhub-operator` (not `advanced-cluster-management`). Keep `bundle_name_override: acm-operator-bundle` and Konflux `bundle_name_override: acm-2-14-acm-operator-bundle`.
- **Rationale**: On `release-2.14`, the CSV file, package annotation, and `bundle/art.yaml` still use `multiclusterhub-operator`. Operating 2.15 renamed the package to `advanced-cluster-management`; that rename must not be copied onto 2.14.
- **Revisit**: If/when MCH `release-2.14` adopts the `advanced-cluster-management` CSV name, update `update-csv.name` to match.

## Dependents

- **Decision**: Operand images keep `dependents: [multiclusterhub-operator]` (intra-branch). This does **not** express MCE → ACM ordering.
- **Rationale**: `dependents` only resolves within the same ocp-build-data branch. OLM handles install-time ordering via CSV `spec.dependencies`.

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
- **Runtime replacement**: Images whose Dockerfile final `FROM` is ubi-minimal use `from.member: base-rhel9`. Exceptions: `console.yml` (nodejs-24 runtime) and `base-rhel9.yml` itself (`from.stream: rhel9`).
