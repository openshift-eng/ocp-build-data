# DECISIONS.md — MCE 2.8 ocp-build-data Branch

Product decisions for the `mce-2.8` branch (HYPBLD-884).
Scaffolded from merged `mce-2.9` (`2d3d19e`, openshift-eng squash of HYPBLD-886) with `art-migration.sh branch-setup`, then patched.
`mce-2.10`, `mce-2.11`, `mce-2.17`, and `mce-5.0` were references only. Standard Konflux 2.8
(`crt-redhat-acm-tenant`) is the component authority, except the five assisted
images, which 2.9 ART builds and this branch builds too. Answers marked A1–A3
are from the HYPBLD-884 spec.

## Product Identity

- **Decision**: `product: multicluster-engine`, `name: mce-2.8`, `csv_namespace: multicluster-engine`
- **Rationale**: Same as mce-2.9 / mce-2.10 / mce-2.11 / mce-2.17 / mce-5.0. The tool rewrote `name:`.

## OCP Version Alignment

- **Decision**: `MAJOR: 4`, `MINOR: 18` (distgit template `rhaos-{MAJOR}.{MINOR}-rhel-9`, which expands to `rhaos-4.18-rhel-9`)
- **Rationale**: Konflux 2.8 `openshift-branch-patch.yaml` sets the OpenShift git revision to `release-4.18`. A1 confirmed that alignment. `OCP_RELEASE_NOTES_VERSION` is `4.18`. `ose-cli` is `v4.18`.
- **Tool patch**: `branch-setup` set MAJOR/MINOR from the product version (`2`/`8`). Corrected to OCP 4.18.

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["4.15", "4.16", "4.17", "4.18", "4.19"]`
- **Rationale**: A1. For 2.x, catalogs are published N-3 through N+1. MCE 2.8's publish range is 4.15–4.19. `olm.maxOpenShiftVersion` on the product CSV is `4.19`.

## group.yml version

- **Decision**: `version: 2.8.13`
- **Rationale**: Next unreleased z-stream. ReleasePlan synopsis uses `v2.8.13`.
- **Tool patch**: tool wrote `2.8.0`.

## Git Source Branches

- **Decision**:
  - `stolostron/*` → `backplane-2.8` (includes `kube-rbac-proxy` and `image-based-install-operator`)
  - `openshift/hypershift`, `cluster-api-provider-kubevirt` → `release-4.18`
  - `cluster-api-provider-agent` → `release-ocm-2.13`
  - `assisted-service`, `assisted-image-service`, `assisted-installer`, `assisted-installer-agent` → `release-ocm-2.13`
  - `hive` → `master`
  - `base-rhel9` → `openshift-base-rhel9`
  - `console-mce` → `backplane-2.8`, dockerfile `Containerfile.mce.konflux` (2.8 does not override that shared base)
- **Rationale**: Spec branch map. Assisted repositories have no `backplane-2.8` branch. `release-ocm-2.13` is the ACM 2.13 branch. The `*-mce` Dockerfiles exist on `release-ocm-2.13`.
- **Tool patch**: bumped `backplane-2.9` → `backplane-2.8` only. Left `release-4.19`, `release-ocm-2.14`, `master`, and `openshift-base-rhel9` unchanged.

## Image scope

33 configs: the merged mce-2.9 set, minus the three components Konflux 2.8 deletes. Bundle stays out of `images/*.yml`. `base-rhel9` is included. `cluster-proxy-addon` stays. Nothing 2.8-only was added.

Dropped (present on mce-2.9, deleted by Konflux 2.8 `component-removal.yaml`):

- `capoa-bootstrap`
- `capoa-control-plane`
- `cluster-api-webhook-config`

Kept from mce-2.9. Konflux 2.8's operand kustomization does not build these five; ART does, so Doozer can substitute them instead of treating them as external images:

| Component | Upstream repo | Dockerfile | Branch | Go |
|-----------|---------------|------------|--------|----|
| assisted-image-service | [openshift/assisted-image-service](https://github.com/openshift/assisted-image-service) | `Dockerfile.image-service-mce` | `release-ocm-2.13` | 1.26 |
| assisted-installer | [openshift/assisted-installer](https://github.com/openshift/assisted-installer) | `Dockerfile.assisted-installer-mce` | `release-ocm-2.13` | 1.25 |
| assisted-installer-agent | [openshift/assisted-installer-agent](https://github.com/openshift/assisted-installer-agent) | `Dockerfile.assisted_installer_agent-mce` | `release-ocm-2.13` | 1.26 |
| assisted-installer-controller | [openshift/assisted-installer](https://github.com/openshift/assisted-installer) | `Dockerfile.assisted-installer-controller-mce` | `release-ocm-2.13` | 1.25 |
| assisted-service-9 | [openshift/assisted-service](https://github.com/openshift/assisted-service) | `Dockerfile.assisted-service-rhel9-mce` | `release-ocm-2.13` | 1.25 |

`assisted-service-9` and `assisted-installer-controller` keep `rhocp-4.17-rhel9-rpms`, the same pin mce-2.9 carried. Not retargeted to 4.18.

Not copied from 2.17/5.0: `maestro`, `cluster-permission`, `cloudevents-conductor`. PQC ubi-minimal stays 5.0+.

The AWS chart on `backplane-2.8` still deploys `ose_aws_cluster_api_controllers_rhel9`. That image is external in `bundle/art.yaml`, not an `images/*.yml`. `cluster-api-provider-aws` is not an ART image on 2.8.

`Dockerfile.image-service-mce` on `release-ocm-2.13` installs `cpio` and `squashfs-tools` and does not install `gzip` or `tar`. `release-ocm-2.14` added those in assisted-image-service #1197 because Doozer rewrites `FROM` to minimal `base-rhel9`. That operand change is still required before the first 2.8 assisted-image-service build.

## Console Dockerfile

- **Decision**: `Containerfile.mce.konflux` with two `rhel-9-nodejs-24` parents
- **Rationale**: Matches Konflux 2.8 and ART 2.9. Not 2.17's `Containerfile.mce`.

## image-based-install-operator

- **Decision**: `Dockerfile.konflux`, builder `rhel-9-golang-1.25`
- **Rationale**: Same dockerfile as mce-2.9 ART. The 2.8 dockerfile `FROM` is `golang-builder-v1.25-rhel9`.

## Streams

- **Go**: floating `rhel-9-golang` stays `golang-builder-v1.26-rhel9` because the 2.8 stolostron Dockerfiles use that tag. A3: do not retarget a builder to 1.26 unless that Dockerfile uses it. Per-image changes from the 2.9 mix:
  - `assisted-installer`, `assisted-installer-controller`, `assisted-service-9`: floating 1.26 → `rhel-9-golang-1.25` (`go-toolset:1.25`)
  - `hypershift-cli`: `rhel-9-golang-1.25` → `rhel-9-golang-1.26` (`rhel_9_1.26`)
  - `hypershift-release`: `rhel-9-golang-1.25` → `rhel-9-golang-1.22` (`rhel_9_1.22`)
  - `cluster-api-provider-kubevirt`: `rhel-9-golang-1.25` → `rhel-9-golang-1.23` (`rhel_9_1.23`)
  - left on 1.26: discovery, backplane-operator, managed-serviceaccount, hive, and every image whose Dockerfile `FROM` is `golang-builder-v1.26-rhel9` or `go-toolset:1.26`
  - left on 1.25: `cluster-api-provider-agent`, `kube-rbac-proxy`, `image-based-install-operator`
- **1.22 / 1.23 streams**: added as `registry.redhat.io/openshift/golang-builder:golang-builder-v1.22-rhel9` and `golang-builder-v1.23-rhel9`, the same short-tag form 2.9 uses for 1.25 and 1.26. Registry auth was not available here to confirm those two tags are published.
- **nodejs**: `ubi9/nodejs-24-minimal:latest`
- **ubi-minimal**: `registry.redhat.io/ubi9/ubi-minimal:latest`, not PQC.
- **ose-cli**: `v4.18`.

## group.yml extras from 2.9

- **Decision**: Keep `cachi2.lockfile.backend`, `mr_approvers`, and per-image `jira:` blocks. `OCP_RELEASE_NOTES_VERSION` is `4.18`.

## Owners

- **Decision**: `acm-cicd@redhat.com` (same bootstrap as 2.9).

## Operator bundle files

Separate `stolostron/backplane-operator` pull request on `backplane-2.8`. The product CSV is the community `backplane-2.8` CSV transformed in place. The merged 2.9 product CSV is only the metadata template. CRDs are not copied across.

- package channel `stable-2.8`, `currentCSV: multicluster-engine.v2.8.0`
- annotation channels `stable-2.8` (the package file does not set those)
- CSV name, `spec.version`, `OPERATOR_VERSION`, and `olm.skipRange` use `2.8.13` (`>=2.7.0 <2.8.13`)
- `art.yaml` updates search and replace `2.8.13`
- `olm.maxOpenShiftVersion` is `4.19`
- drop `cluster_api_provider_openshift_assisted_bootstrap`, `cluster_api_provider_openshift_assisted_control_plane`, `mce_capi_webhook_config_rhel9`, `cluster_api_provider_aws_rhel9`, `postgresql_13`, Azure, and `ip_address_manager`
- include `assisted_service_8`, the five assisted keys, `ose_aws_cluster_api_controllers_rhel9`, and `postgresql_12`
- OSE replace tags are `v4.18`
- `assisted-service-el8` replace is the digest in `stolostron/mce-operator-bundle` `backplane-2.8` `config/mce-manifest-gen-config.json`
- `postgresql-12` replace stays `registry.redhat.io/rhel8/postgresql-12:latest`

Merge that pull request after this `mce-2.8` branch contains the five assisted image configs.

## Konflux

- **Decision**: `network_mode: hermetic`, `cachi2.enabled: true` with `rpm-lockfile-prototype` (carried from 2.9).

## Tide branch inclusion (openshift/release)

- **Decision**: Add `mce-2.8` to `tide.queries[].includedBranches` in [openshift/release `core-services/prow/02_config/openshift-eng/ocp-build-data/_prowconfig.yaml`](https://github.com/openshift/release/blob/master/core-services/prow/02_config/openshift-eng/ocp-build-data/_prowconfig.yaml). The list is sorted as plain strings, so `mce-2.8` goes after `mce-2.17` and before `mce-2.9`. `branch-protection` stays `unmanaged: true`. The commit must be signed with a GPG or SSH key GitHub can verify (`git commit -S`); DCO `Signed-off-by` is not that check.
- **Rationale**: Tide only merges ocp-build-data pull requests whose target branch is listed there. Pattern is [#86320](https://github.com/openshift/release/pull/86320).

## Tool patch report (art-migration branch-setup mce 2.9 2.8)

Command:

```
./art-migration.sh branch-setup mce 2.9 2.8 \
  --ocp-target-versions "4.15,4.16,4.17,4.18,4.19" \
  --rhel-stream "registry.redhat.io/ubi9/ubi-minimal:latest" \
  --golang-version "1.26"
```

The tool checks out `origin/mce-2.9`. On this machine `origin` is the smithbw88 fork, whose `mce-2.9` tip (`b768915`) has the same tree as openshift-eng `mce-2.9` (`2d3d19e`, the squash of #13522). The scaffold commit was rebased onto `upstream/mce-2.9` so the new branch's parent is the merged branch, not the pre-squash fork history. Upstream tracking of `origin/mce-2.9` was unset.

What the tool got right:

- Created `mce-2.8` from the mce-2.9 tree
- `name: mce-2.8`
- `GO_LATEST`/`GO_EXTRA` stayed `1.26` (the flag matched the existing floating builder; it did not retarget per-image builders)
- `OCP_TARGET_VERSIONS` values (collapsed to one line; reformatted)
- `backplane-2.9` → `backplane-2.8` on stolostron image configs, including `kube-rbac-proxy` and `image-based-install-operator`
- `rhel9.image` stayed `ubi-minimal:latest`
- Did not touch hive `master` or `openshift-base-rhel9`

What was patched after (backward / OCP-4.18-aligned product):

1. `vars.MAJOR`/`MINOR` `2`/`8` → `4`/`18` (tool assumes product version == OCP version)
2. `version: 2.8.0` → `2.8.13`
3. `OCP_RELEASE_NOTES_VERSION` `4.19` → `4.18` (not rewritten)
4. `release-4.19` → `release-4.18` on hypershift-cli, hypershift-release, cluster-api-provider-kubevirt
5. `release-ocm-2.14` → `release-ocm-2.13` on cluster-api-provider-agent and the five assisted images
6. Removed capoa-bootstrap, capoa-control-plane, and cluster-api-webhook-config (tool does not drop components)
7. ose-cli `v4.19` → `v4.18`
8. Restored `streams.yml` `---` / blank-line formatting lost by the PyYAML fallback (no ruamel.yaml), and added `rhel-9-golang-1.22` and `rhel-9-golang-1.23`
9. Retargeted the five builder streams listed under Streams so they match the 2.8 Dockerfiles
10. `branch-setup` set upstream to `origin/mce-2.9`. Unset before pushing `HEAD:mce-2.8`. Rebased the scaffold commit onto `upstream/mce-2.9`.

`base-rhel9.yml` has no `dependents:` entry. That matches 2.9 (base image, not an operand).

Suggested tool improvements (same class as the 2.10 → 2.9 run):

- Do not derive `vars.MAJOR`/`MINOR` from the product version for layered products; take an `--ocp-major-minor 4.18` flag.
- Bump or retarget OCP-aligned `release-X.Y` and `release-ocm-X.Y` separately from product `backplane-` versions. A backward jump must be able to move `release-4.19` to `release-4.18` and `release-ocm-2.14` to `release-ocm-2.13`.
- Support `--drop-images` so a scaffold can remove components that do not exist on the older release.
- Optional `--version` for `group.yml` z-stream instead of always `{new}.0`.
- Preserve `streams.yml` comments (`ruamel.yaml`) and do not collapse `OCP_TARGET_VERSIONS` formatting unless asked.
- Rewrite `OCP_RELEASE_NOTES_VERSION` and `ose-cli` tags when `--ocp-major-minor` is set.
- Do not set the new branch's upstream to `origin/<current>` when the landing branch is a new `<product>-<version>` branch.
- When `origin/<current>` is a fork tip with the same tree as `openshift-eng/<current>` but a different history, scaffold from the openshift-eng commit.
- Emit a follow-up change for `openshift/release` `core-services/prow/02_config/openshift-eng/ocp-build-data/_prowconfig.yaml`: add the new branch to `tide.queries[].includedBranches`.
