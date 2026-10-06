# DECISIONS.md — MCE 2.9 ocp-build-data Branch

Product decisions for the `mce-2.9` branch (HYPBLD-886).
Scaffolded from merged `mce-2.10` (`75fdf09`, including assisted images from #13473 and the OCP 4.22 removal from #13505) with `art-migration.sh branch-setup`, then patched.
`mce-2.11`, `mce-2.17`, and `mce-5.0` were references only. Standard Konflux 2.9
(`crt-redhat-acm-tenant`) is the component authority, except the five assisted
images, which 2.10 ART builds and this branch builds too. Answers marked Gus
are from the HYPBLD-886 spec.

## Product Identity

- **Decision**: `product: multicluster-engine`, `name: mce-2.9`, `csv_namespace: multicluster-engine`
- **Rationale**: Same as mce-2.10 / mce-2.11 / mce-2.17 / mce-5.0. The tool rewrote `name:`.

## OCP Version Alignment

- **Decision**: `MAJOR: 4`, `MINOR: 19` (distgit template `rhaos-{MAJOR}.{MINOR}-rhel-9`, which expands to `rhaos-4.19-rhel-9`)
- **Rationale**: Konflux 2.9 sets the OpenShift git revision to `release-4.19`. Gus (A1) confirmed that alignment. `OCP_RELEASE_NOTES_VERSION` is `4.19`. `ose-cli` is `v4.19`.
- **Tool patch**: `branch-setup` set MAJOR/MINOR from the product version (`2`/`9`). Corrected to OCP 4.19.

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["4.16", "4.17", "4.18", "4.19", "4.20"]`
- **Rationale**: Gus (A1). For 2.x, catalogs are published N-3 through N+1. MCE 2.9's publish range is 4.16–4.20, confirmed by the mce-redhat-operators catalog config. `olm.maxOpenShiftVersion` on the product CSV is `4.20`.

## group.yml version

- **Decision**: `version: 2.9.9`
- **Rationale**: Next unreleased z-stream. Konflux stage/prod text is still `v2.9.8`. ReleasePlan synopsis uses `v2.9.9`.
- **Tool patch**: tool wrote `2.9.0`.

## Git Source Branches

- **Decision**:
  - `stolostron/*` → `backplane-2.9` (includes `kube-rbac-proxy`; Konflux `release-2.14` is the same commit `8cd9bad`)
  - `openshift/hypershift`, `cluster-api-provider-kubevirt` → `release-4.19`
  - `cluster-api-provider-agent` → `release-ocm-2.14`
  - `assisted-service`, `assisted-image-service`, `assisted-installer`, `assisted-installer-agent` → `release-ocm-2.14`
  - `hive` → `master`
  - `base-rhel9` → `openshift-base-rhel9`
  - `image-based-install-operator` → `backplane-2.9`
- **Rationale**: Same mapping as mce-2.10, one release earlier. Assisted repositories have no `backplane-2.9` branch. `release-ocm-2.14` is the ACM 2.14 branch, the same mapping already used for `cluster-api-provider-agent`. The `*-mce` Dockerfiles exist on `release-ocm-2.14`.
- **Tool patch**: bumped `backplane-2.10` → `backplane-2.9` only. Left `release-4.20`, `release-ocm-2.15`, `master`, and `openshift-base-rhel9` unchanged.

## Image scope

36 configs: the merged mce-2.10 set, minus `cluster-api-provider-aws`. Bundle stays out of `images/*.yml`. `base-rhel9` is included.

Dropped (present on mce-2.10, deleted by Konflux 2.9 `component-removal.yaml`):

- `cluster-api-provider-aws`

Kept from the merged mce-2.10 assisted addition. Konflux 2.9's operand kustomization does not build these five; ART does, so Doozer can substitute them instead of treating them as external images:

| Component | Upstream repo | Dockerfile | Branch |
|-----------|---------------|------------|--------|
| assisted-image-service | [openshift/assisted-image-service](https://github.com/openshift/assisted-image-service) | `Dockerfile.image-service-mce` | `release-ocm-2.14` |
| assisted-installer | [openshift/assisted-installer](https://github.com/openshift/assisted-installer) | `Dockerfile.assisted-installer-mce` | `release-ocm-2.14` |
| assisted-installer-agent | [openshift/assisted-installer-agent](https://github.com/openshift/assisted-installer-agent) | `Dockerfile.assisted_installer_agent-mce` | `release-ocm-2.14` |
| assisted-installer-controller | [openshift/assisted-installer](https://github.com/openshift/assisted-installer) | `Dockerfile.assisted-installer-controller-mce` | `release-ocm-2.14` |
| assisted-service-9 | [openshift/assisted-service](https://github.com/openshift/assisted-service) | `Dockerfile.assisted-service-rhel9-mce` | `release-ocm-2.14` |

`assisted-service-9` keeps `rhocp-4.17-rhel9-rpms` and the assisted `public_upstreams` entries. mce-5.0 and mce-2.10 both pin that repo for this image.

`cluster-proxy-addon` stays. It is in Konflux 2.9 and in mce-2.10 ART.

Not copied from 2.17/5.0: `maestro`, `cluster-permission`, `cloudevents-conductor`.

The AWS chart on `backplane-2.9` still deploys `ose_aws_cluster_api_controllers_rhel9`. That image is external in `bundle/art.yaml`, not an `images/*.yml`.

## Console Dockerfile

- **Decision**: `Containerfile.mce.konflux` with two `rhel-9-nodejs-24` parents
- **Rationale**: Matches Konflux 2.9 and ART 2.10. Not 2.17's `Containerfile.mce`.

## image-based-install-operator

- **Decision**: `Dockerfile.konflux`
- **Rationale**: Same as mce-2.10 ART. The repository `Dockerfile` points at `registry.ci.openshift.org` 4.21 builders.

## Streams

- **Go**: keep mce-2.10's mix. Floating `rhel-9-golang` is `golang-builder-v1.26-rhel9`. Per-image `rhel-9-golang-1.25` builders were not retargeted. Gus (A3): leave images on their current builder minor when it is an ART golang builder. No operand Go bumps in this pass.
- **nodejs**: `ubi9/nodejs-24-minimal:latest`
- **ubi-minimal**: `registry.redhat.io/ubi9/ubi-minimal:latest`, not PQC. PQC stays 5.0+.
- **ose-cli**: `v4.19`.

## group.yml extras from 2.10

- **Decision**: Keep `cachi2.lockfile.backend`, `mr_approvers`, and per-image `jira:` blocks. `OCP_RELEASE_NOTES_VERSION` is `4.19`.

## Owners

- **Decision**: `acm-cicd@redhat.com` (same bootstrap as 2.10).

## Operator bundle files

Separate `stolostron/backplane-operator` pull request on `backplane-2.9` (one PR, no `/hold`). `backplane-2.9` had none of the ART bundle trio. The product CSV follows the merged mce-2.10 template (#4088) with these 2.9 differences:

- package channel `stable-2.9`, `currentCSV: multicluster-engine.v2.9.0`
- CSV name, `spec.version`, `OPERATOR_VERSION`, and `olm.skipRange` use `2.9.9` (`>=2.8.0 <2.9.9`)
- `art.yaml` updates search and replace `2.9.9`
- `olm.maxOpenShiftVersion` is `4.20`
- annotation channels `stable-2.9`
- drop `cluster_api_provider_aws_rhel9`
- add the five assisted images, `assisted_service_8`, and `ose_aws_cluster_api_controllers_rhel9`
- OSE replace tags are `v4.19`
- `assisted-service-el8` replace is the digest in `stolostron/mce-operator-bundle` `backplane-2.9` `config/mce-manifest-gen-config.json`
- `postgresql-12` replace stays `registry.redhat.io/rhel8/postgresql-12:latest`

Merge that pull request after this `mce-2.9` branch contains the five assisted image configs.

## Konflux

- **Decision**: `network_mode: hermetic`, `cachi2.enabled: true` with `rpm-lockfile-prototype` (carried from 2.10).

## Tide branch inclusion (openshift/release)

- **Decision**: Add `mce-2.9` to `tide.queries[].includedBranches` in [openshift/release `core-services/prow/02_config/openshift-eng/ocp-build-data/_prowconfig.yaml`](https://github.com/openshift/release/blob/master/core-services/prow/02_config/openshift-eng/ocp-build-data/_prowconfig.yaml), immediately before `mce-2.10`. `branch-protection` stays `unmanaged: true`.
- **Rationale**: Tide only merges ocp-build-data pull requests whose target branch is listed there. Pattern is [#86320](https://github.com/openshift/release/pull/86320). Open that pull request from a fork of `openshift/release`. `branch-setup` does not edit this file.
- **Follow-up for later migrations**: Repeat this for every new `<product>-<version>` branch. The list already has `mce-2.10`, `mce-2.11`, `mce-2.17`, and `mce-5.0`.

## Tool patch report (art-migration branch-setup mce 2.10 2.9)

Command:

```
./art-migration.sh branch-setup mce 2.10 2.9 \
  --ocp-target-versions "4.16,4.17,4.18,4.19,4.20" \
  --rhel-stream "registry.redhat.io/ubi9/ubi-minimal:latest" \
  --golang-version "1.26"
```

The checkout used for the tool had `origin` pointing at `openshift-eng/ocp-build-data`, because the `smithbw88` fork's `mce-2.10` was still the pre-merge scaffold (`3f50f53`) and is not an ancestor of upstream `mce-2.10`.

What the tool got right:

- Created `mce-2.9` from `origin/mce-2.10` (`75fdf09`)
- `name: mce-2.9`
- `GO_LATEST`/`GO_EXTRA` stayed `1.26`
- `OCP_TARGET_VERSIONS` values (collapsed to one line; reformatted)
- `backplane-2.10` → `backplane-2.9` on stolostron image configs, including `kube-rbac-proxy`
- `rhel9.image` stayed `ubi-minimal:latest`
- Did not touch hive `master`, `openshift-base-rhel9`, or per-image Go builders

What was patched after (backward / OCP-4.19-aligned product):

1. `vars.MAJOR`/`MINOR` `2`/`9` → `4`/`19` (tool assumes product version == OCP version)
2. `version: 2.9.0` → `2.9.9`
3. `OCP_RELEASE_NOTES_VERSION` `4.20` → `4.19` (not rewritten)
4. `release-4.20` → `release-4.19` on hypershift-cli, hypershift-release, cluster-api-provider-kubevirt
5. `release-ocm-2.15` → `release-ocm-2.14` on cluster-api-provider-agent and the five assisted images
6. Removed cluster-api-provider-aws (tool does not drop components)
7. ose-cli `v4.20` → `v4.19`
8. Restored `streams.yml` `---` / blank-line formatting lost by the PyYAML fallback (no ruamel.yaml)
9. `branch-setup` set upstream to `origin/mce-2.10`. Unset before pushing `HEAD:mce-2.9`.

`base-rhel9.yml` has no `dependents:` entry. That matches 2.10 (base image, not an operand).

Suggested tool improvements (same class as the 2.11 → 2.10 run):

- Do not derive `vars.MAJOR`/`MINOR` from the product version for layered products; take an `--ocp-major-minor 4.19` flag.
- Bump or retarget OCP-aligned `release-X.Y` and `release-ocm-X.Y` separately from product `backplane-` versions. A backward jump must be able to move `release-4.20` to `release-4.19` and `release-ocm-2.15` to `release-ocm-2.14`.
- Support `--drop-images` so a scaffold can remove components that do not exist on the older release.
- Optional `--version` for `group.yml` z-stream instead of always `{new}.0`.
- Preserve `streams.yml` comments (`ruamel.yaml`) and do not collapse `OCP_TARGET_VERSIONS` formatting unless asked.
- Rewrite `OCP_RELEASE_NOTES_VERSION` and `ose-cli` tags when `--ocp-major-minor` is set.
- Do not set the new branch's upstream to `origin/<current>` when the landing branch is a new `<product>-<version>` branch.
- Emit a follow-up change for `openshift/release` `core-services/prow/02_config/openshift-eng/ocp-build-data/_prowconfig.yaml`: add the new branch to `tide.queries[].includedBranches`. Without that entry, Tide will not merge pull requests that target the new branch. See openshift/release#86320.
