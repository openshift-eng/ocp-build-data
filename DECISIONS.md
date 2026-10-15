# DECISIONS.md — MCE 2.6 ocp-build-data Branch

Product decisions for the `mce-2.6` branch (HYPBLD-880).
Scaffolded from openshift-eng `mce-2.8` (`1cbbdf1`) with `art-migration.sh branch-setup`, then patched.
`mce-2.9`, `mce-2.10`, `mce-2.11`, `mce-2.17`, and `mce-5.0` were references only. Standard Konflux 2.6
(`crt-redhat-acm-tenant`) is the component authority, except the five assisted
images, which Konflux 2.6 does not build and this branch builds the same way 2.8 does.
Answers marked A1–A3 are from the HYPBLD-880 spec.

## Product Identity

- **Decision**: `product: multicluster-engine`, `name: mce-2.6`, `csv_namespace: multicluster-engine`
- **Rationale**: Same as mce-2.8 through mce-5.0. The tool rewrote `name:`.

## OCP Version Alignment

- **Decision**: `MAJOR: 4`, `MINOR: 16` (distgit template `rhaos-{MAJOR}.{MINOR}-rhel-9`, which expands to `rhaos-4.16-rhel-9`)
- **Rationale**: Konflux 2.6 `openshift-branch-patch.yaml` sets the OpenShift git revision to `release-4.16`. A1 confirmed that alignment. `OCP_RELEASE_NOTES_VERSION` is `4.16`. `ose-cli` is `v4.16`.
- **Tool patch**: `branch-setup` set MAJOR/MINOR from the product version (`2`/`6`). Corrected to OCP 4.16.

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["4.12", "4.13", "4.14", "4.15", "4.16", "4.17"]`
- **Rationale**: A1. 4.16 is the associated release and 4.12–4.17 is the supported hub range. 4.12 is a required support exception for MCE 2.6, not a formula error. `olm.maxOpenShiftVersion` on the product CSV is `4.17`.

## group.yml version

- **Decision**: `version: 2.6.17`
- **Rationale**: Next unreleased z-stream. ReleasePlan synopsis uses `v2.6.17`.
- **Tool patch**: tool wrote `2.6.0`.

## Git Source Branches

- **Decision**:
  - `stolostron/*` → `backplane-2.6` (includes `kube-rbac-proxy` and `image-based-install-operator`)
  - `openshift/hypershift`, `cluster-api-provider-kubevirt` → `release-4.16`
  - `cluster-api-provider-agent` → `release-ocm-2.11`
  - five assisted repos → `release-ocm-2.11`
  - `hive` → `master`
  - `base-rhel9` → `openshift-base-rhel9`
  - `console-mce` → `backplane-2.6`, dockerfile `Containerfile.mce.konflux` (2.6 does not override that shared base)
- **Rationale**: Spec branch map. `hypershift-branch-patch.yaml` contains `hypershift-release-416` and is not applied; the live revision is `release-4.16`.
- **Tool patch**: bumped `backplane-2.8` → `backplane-2.6` only. Left `release-4.18`, `release-ocm-2.13`, `master`, and `openshift-base-rhel9` unchanged.

## Image scope

33 configs: the same names as ART 2.8 (operand names, five assisted images, and `base-rhel9`). Nothing was dropped and nothing 2.6-only was added. Bundle stays out of `images/*.yml`.

The four rhel8 assisted Dockerfiles on `release-ocm-2.11` are ubi8. Their delivery names, distgit branch suffix, builders, and runtimes are rhel8. `assisted-service-9` stays on `Dockerfile.assisted-service-rhel9-mce` and `base-rhel9`.

| Component | Dockerfile | Branch | Builder | Runtime |
|-----------|------------|--------|---------|---------|
| assisted-image-service | `Dockerfile.image-service-mce` | `release-ocm-2.11` | `ubi8/go-toolset:1.25` | `ubi8/ubi:8.10` |
| assisted-installer | `Dockerfile.assisted-installer-mce` | `release-ocm-2.11` | `ubi8/go-toolset:1.26` | `ubi8/ubi:8.10` |
| assisted-installer-agent | `Dockerfile.assisted_installer_agent-mce` | `release-ocm-2.11` | `ubi8/go-toolset:1.26` | `ubi8/ubi:8.10` |
| assisted-installer-controller | `Dockerfile.assisted-installer-controller-mce` | `release-ocm-2.11` | `ubi8/go-toolset:1.26` | `ubi8/ubi:8.10` |
| assisted-service-9 | `Dockerfile.assisted-service-rhel9-mce` | `release-ocm-2.11` | `rhel-9-golang-1.26` | `base-rhel9` |

`assisted-image-service` has two `FROM` lines and no packages stage, so there is no extra `base-rhel9` parent and no 2.14 gzip/tar change. `assisted-installer-controller` installs `openshift-clients` with `dnf` on ubi8, so it uses `rhocp-4.16-rhel8-rpms` instead of 2.8's `rhocp-4.17-rhel9-rpms` pin. `assisted-service-9` still installs `openshift-clients` on rhel9 and keeps `rhocp-4.17-rhel9-rpms`.

Not copied from 2.9 and up: `maestro`, `cluster-permission`, `cloudevents-conductor`, PQC ubi-minimal.

## Streams

- **Go**: floating `rhel-9-golang` stays `golang-builder-v1.26-rhel9`. A3: the backplane-2.6 stolostron Dockerfiles use that tag, so `--golang-version 1.26` does not retarget them. Per-image changes from the 2.8 mix:
  - four rhel8 assisted images: `ubi8-go-toolset-1.25` or `ubi8-go-toolset-1.26`, runtime stream `ubi8` (`ubi8/ubi:8.10`). Not `rhel-9-golang` and not `base-rhel9`
  - `cluster-api-provider-agent`: `rhel-9-golang-1.25` → `rhel-9-golang-1.24` (`rhel_9_1.24` on `release-ocm-2.11`)
  - `hypershift-cli`: `rhel-9-golang-1.26` → `rhel-9-golang-1.24` (`rhel_9_golang_1.24` on `release-4.16`)
  - `hypershift-release`: `rhel-9-golang-1.22` → `ubi9-go-toolset-9.5` (`ubi9/go-toolset:9.5-1739267472`). `Containerfile.operator` already has `COPY . .`, so the 2.9 `--chown=default` replace is not applied
  - `cluster-api-provider-kubevirt` stays `rhel-9-golang-1.23`
  - `image-based-install-operator` stays `rhel-9-golang-1.25` (`golang-builder-v1.25-rhel9`)
  - `kube-rbac-proxy` stays `rhel-9-golang-1.25`
  - hive stays `rhel-8-golang-1.26` plus `rhel-9-golang-1.26`. Its Dockerfile default base is `ubi-minimal-pqc`; the member is still `base-rhel9`, and the `rhel9` stream is standard `ubi-minimal:latest`
- **1.22 stream**: removed. Nothing on this branch references it after the hypershift-release retarget.
- **nodejs**: `ubi9/nodejs-24-minimal:latest`
- **ubi-minimal**: `registry.redhat.io/ubi9/ubi-minimal:latest`, not PQC
- **ose-cli**: `v4.16`

## group.yml extras from 2.8

- **Decision**: Keep `cachi2.lockfile.backend`, `mr_approvers`, and per-image `jira:` blocks. `OCP_RELEASE_NOTES_VERSION` is `4.16`. Added `rhel-8-baseos-rpms`, `rhel-8-appstream-rpms`, and `rhocp-4.16-rhel8-rpms` for the ubi8 assisted images.

## Owners

- **Decision**: unchanged from openshift-eng `mce-2.8`, including the `adobes1` OWNERS update (`1cbbdf1`). The scaffold commit is rebased onto that commit. The fork tip (`e138708`) was one OWNERS commit behind.

## Operator bundle files

Separate `stolostron/backplane-operator` pull request branched from `backplane-2.6`. The product CSV is the community `backplane-2.6` CSV transformed in place. The merged 2.8 product CSV is only the metadata template. CRDs are not copied across.

- package channel `stable-2.6`, `currentCSV: multicluster-engine.v2.6.0`
- annotation channels `stable-2.6` (the package file does not set those)
- CSV name, `spec.version`, `OPERATOR_VERSION`, and `olm.skipRange` use `2.6.17` (`>=2.5.0 <2.6.17`)
- `art.yaml` updates search and replace `2.6.17`
- `olm.maxOpenShiftVersion` is `4.17`
- include `assisted_service_8`, the five assisted keys, `cluster_api` (chart key for ose-cluster-api), and `postgresql_12`
- leave out `cluster_api_provider_aws`, Azure, `postgresql_13`, `ip_address_manager`, and the 2.8 ose-aws / ose-baremetal external images
- OSE replace tag is `v4.16`
- `postgresql-12` replace is `registry.redhat.io/rhel8/postgresql-12:1-1789954358`
- `assisted-service-el8` replace is the digest in `stolostron/mce-operator-bundle` `backplane-2.6` `config/mce-manifest-gen-config.json` (`sha256:4f94b0e0…`)
- four assisted image-references tags are the rhel8 delivery names

Merge that pull request after this `mce-2.6` branch contains the five assisted image configs.

## Konflux

- **Decision**: `network_mode: hermetic`, `cachi2.enabled: true` with `rpm-lockfile-prototype` (carried from 2.8).

## aos-cd-jobs group lists

Upstream `pipeline-scripts/commonlib.groovy` on `master` has an empty `nonOCPGroups`. `schedule-layered-products-scan` requires `--group`, and the Jenkins job still builds those flags from `nonOCPGroups`, so an empty list does not schedule a scan. Sibling MCE versions already live in `LPClusterGroups` (image-health unions both lists). `mce-2.6` is added to `nonOCPGroups` so the scan job receives `--group=mce-2.6`, and inserted immediately before `mce-2.8` in `LPClusterGroups` so the version-ordered sibling list and image-health include it.

## Tide branch inclusion (openshift/release)

- **Decision**: Add `mce-2.6` to `tide.queries[].includedBranches`. String sort places it after `mce-2.17` and before `mce-2.8`. The commit is signed with `git commit -S`. DCO `Signed-off-by` is a different check.

## Tool patch report (art-migration branch-setup mce 2.8 2.6)

Command:

```
./art-migration.sh branch-setup mce 2.8 2.6 \
  --ocp-target-versions "4.12,4.13,4.14,4.15,4.16,4.17" \
  --rhel-stream "registry.redhat.io/ubi9/ubi-minimal:latest" \
  --golang-version "1.26"
```

The tool checks out `origin/mce-2.8`. On this machine `origin` is the smithbw88 fork (`e138708`). openshift-eng `mce-2.8` (`1cbbdf1`) is that commit plus the OWNERS update. The scaffold commit was rebased onto `upstream/mce-2.8`. Upstream tracking of `origin/mce-2.8` was unset before pushing `HEAD:mce-2.6`.

`release-bootstrap mce 2.6 2.8` copied the four MCE 2.8 ART RPAs and five tenant ReleasePlans. It rewrote hyphenated `2-8` names and RPA `product_version` / `v2.8` tags to `2.6` / `v2.6`. It did not rewrite the dotted synopsis inside tenant ReleasePlans (`v2.8.13` left in place), appended every new kustomization entry after the 2.8 stage block, and did not edit `acm-base-images-silent-prod-rhel9.yaml`.

What the tool got right:

- Created `mce-2.6` from the mce-2.8 tree
- `name: mce-2.6`
- `GO_LATEST`/`GO_EXTRA` stayed `1.26`
- `OCP_TARGET_VERSIONS` values (collapsed to one line; reformatted)
- `backplane-2.8` → `backplane-2.6` on stolostron image configs, including `kube-rbac-proxy`, `image-based-install-operator`, and `console-mce`
- `rhel9.image` stayed `ubi-minimal:latest` (ruamel.yaml dropped the leading `---`; restored)
- Did not touch hive `master` or `openshift-base-rhel9`
- KRD component lists, application `mce-2-6`, and FBC application `fbc-mce-2-6`

What was patched after:

1. `vars.MAJOR`/`MINOR` `2`/`6` → `4`/`16`
2. `version: 2.6.0` → `2.6.17`
3. `OCP_RELEASE_NOTES_VERSION` `4.18` → `4.16`
4. `release-4.18` → `release-4.16` on hypershift-cli, hypershift-release, cluster-api-provider-kubevirt
5. `release-ocm-2.13` → `release-ocm-2.11` on cluster-api-provider-agent and the five assisted images
6. ose-cli `v4.18` → `v4.16`
7. Four assisted images retargeted to ubi8 builders, `ubi8` runtime, rhel8 delivery names, and `rhaos-{MAJOR}.{MINOR}-rhel-8`
8. Builder streams retargeted for capi-agent (1.24), hypershift-cli (1.24), and hypershift-release (go-toolset 9.5). Removed unused `rhel-9-golang-1.22`
9. Added rhel8 baseos, appstream, and rhocp-4.16 repos
10. KRD synopsis `v2.8.13` → `v2.6.17`, solution URL ACM `2.13` → `2.11`
11. KRD kustomization: 2.6 section placed before 2.8; base-silent entry placed with the other base ReleasePlans
12. `mce-2-6-base-rhel9` added to `acm-base-images-silent-prod-rhel9.yaml`
13. Advisory RPA delivery URLs for the four assisted images changed from rhel9 to rhel8
14. Rebased the KRD branch onto `origin/main` before push

`base-rhel9.yml` has no `dependents:` entry. That matches 2.8 (base image, not an operand).

Suggested tool improvements (same class as the 2.8 → 2.6 backward jump):

- Do not derive `vars.MAJOR`/`MINOR` from the product version for layered products; take an `--ocp-major-minor 4.16` flag.
- Bump or retarget OCP-aligned `release-X.Y` and `release-ocm-X.Y` separately from product `backplane-` versions. A backward jump must be able to move `release-4.18` to `release-4.16` and `release-ocm-2.13` to `release-ocm-2.11`.
- Optional `--version` for `group.yml` z-stream instead of always `{new}.0`.
- Preserve `streams.yml` `---` and do not collapse `OCP_TARGET_VERSIONS` formatting unless asked.
- Rewrite `OCP_RELEASE_NOTES_VERSION` and `ose-cli` tags when `--ocp-major-minor` is set.
- Do not set the new branch's upstream to `origin/<current>` when the landing branch is a new `<product>-<version>` branch.
- When `origin/<current>` is behind `openshift-eng/<current>`, scaffold from the openshift-eng commit.
- `release-bootstrap` should rewrite dotted synopsis versions inside tenant ReleasePlans, insert the new kustomization block before the source version when the new version sorts first, and add the shared `base-rhel9` component to `acm-base-images-silent-prod-rhel9.yaml`.
- Emit a follow-up change for `openshift/release` Tide `includedBranches` and for `aos-cd-jobs` `nonOCPGroups`.
