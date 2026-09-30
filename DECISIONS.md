# DECISIONS.md — MCE 2.10 ocp-build-data Branch

Product decisions for the `mce-2.10` branch (HYPBLD-888).
Scaffolded from `mce-2.11` with `art-migration.sh branch-setup`, then patched.
`mce-2.17` and `mce-5.0` were references only. Standard Konflux 2.10
(`crt-redhat-acm-tenant`) is the component and branch authority. Answers
marked Gus are from the HYPBLD-888 spec.

## Product Identity

- **Decision**: `product: multicluster-engine`, `name: mce-2.10`, `csv_namespace: multicluster-engine`
- **Rationale**: Same as mce-2.11 / mce-2.17 / mce-5.0. The tool rewrote `name:`.

## OCP Version Alignment

- **Decision**: `MAJOR: 4`, `MINOR: 20` (distgit template `rhaos-{MAJOR}.{MINOR}-rhel-9`, which expands to `rhaos-4.20-rhel-9`)
- **Rationale**: Konflux 2.10 and Gus (A2) align MCE 2.10 with OCP 4.20. Earlier notes that said 4.21 were mistaken. `OCP_RELEASE_NOTES_VERSION` is `4.20`. `ose-cli` is `v4.20`.
- **Distgit**: Konflux rebase does not clone that branch. Doozer still reads `-rhel-9` from the template to select RHEL 9. `rhaos` is the historical OpenShift dist-git prefix, not an ACM product name. No Brew dist-git branch is created by this change.
- **Tool patch**: `branch-setup` set MAJOR/MINOR from the product version (`2`/`10`). Corrected to OCP 4.20.

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["4.17", "4.18", "4.19", "4.20", "4.21", "4.22"]`
- **Rationale**: Gus (A1). For 2.x, catalogs are published N-3 through N+1, and 2.10's publish range is 4.17–4.22. That is wider than the supported hub window.

## group.yml version

- **Decision**: `version: 2.10.8`
- **Rationale**: Gus (A4). Konflux is releasing 2.10.7 now; ART should build the next z-stream, 2.10.8. ReleasePlan synopsis uses `v2.10.8` as well.
- **Tool patch**: tool wrote `2.10.0`.

## Git Source Branches

- **Decision**:
  - `stolostron/*` → `backplane-2.10` (includes `kube-rbac-proxy`; Konflux `release-2.15` is the same commit today)
  - `openshift/hypershift`, `cluster-api-provider-kubevirt` → `release-4.20`
  - `cluster-api-provider-agent` → `release-ocm-2.15`
  - `hive` → `master`
  - `base-rhel9` → `openshift-base-rhel9`
  - `image-based-install-operator` → `backplane-2.10`
- **Rationale**: Matches Konflux MCE 2.10 operand revisions. OCP-versioned branches are 4.20, not 4.21 (Gus A2).
- **Tool patch**: bumped `backplane-2.11` → `backplane-2.10` only. Left `release-4.21`, `release-ocm-2.16`, `master`, and `openshift-base-rhel9` unchanged.

## Image scope

31 operand configs carried from mce-2.11, minus two images that Konflux 2.10 does not build, plus one image removed after 2.10. Bundle stays out of `images/*.yml` (same as 2.11/2.17/5.0). `base-rhel9` is included.

Dropped (new in 2.11; Konflux 2.10 deletes them):

- `azure-service-operator`
- `cluster-api-provider-azure`

Not copied from 2.17/5.0: `maestro`, `cluster-permission`, `cloudevents-conductor`, `assisted-*`.

### cluster-proxy-addon

Present in Konflux 2.10 and removed in 2.11, so there is no ART image config to copy.

| Component | Upstream repo | Dockerfile | Branch |
|-----------|---------------|------------|--------|
| cluster-proxy-addon | [stolostron/cluster-proxy-addon](https://github.com/stolostron/cluster-proxy-addon) | `Dockerfile.rhtap` | `backplane-2.10` |

- **Decision**: `distgit.component: mce-cluster-proxy-addon-container`, delivery `multicluster-engine/cluster-proxy-addon-rhel9`, builder `rhel-9-golang` (Dockerfile `FROM` is `golang-builder-v1.26`, `go.mod` is 1.26.0), final parent `base-rhel9`.
- **Rationale**: Same shape as `cluster-proxy.yml`. Prod repo matches the existing Konflux 2.10 RPA (`registry.redhat.io/multicluster-engine/cluster-proxy-addon-rhel9`).

## Console Dockerfile

- **Decision**: `Containerfile.mce.konflux` with two `rhel-9-nodejs-24` parents
- **Rationale**: Matches Konflux 2.10 and ART 2.11. Not 2.17's `Containerfile.mce`.

## Streams

- **Go**: keep mce-2.11's mix. Floating `rhel-9-golang` is `golang-builder-v1.26-rhel9`. Per-image `rhel-9-golang-1.25` builders were not retargeted to 1.26.
- **nodejs**: `ubi9/nodejs-24-minimal:latest` (bootstrap choice; 2.11 pins a digest).
- **ubi-minimal**: `registry.redhat.io/ubi9/ubi-minimal:latest`, not PQC (Gus A3). PQC stays 5.0+.
- **ose-cli**: `v4.20`.

## group.yml extras from 2.11

- **Decision**: Keep `cachi2.lockfile.backend`, `mr_approvers`, and per-image `jira:` blocks. `OCP_RELEASE_NOTES_VERSION` is `4.20`.

## Owners

- **Decision**: `acm-cicd@redhat.com` (same bootstrap as 2.11).

## Operator bundle files

Not part of this ocp-build-data change. `backplane-2.10` does not yet have `bundle/image-references`, `bundle/mce-operator.package.yaml`, or `bundle/art.yaml`. Gus (A6): follow 2.11 and replace the community CSV with the product CSV. That is a later `stolostron/backplane-operator` pull request. The 2.10 manifest also differs from 2.11 `image-references` (includes `cluster-proxy-addon-rhel9`, omits azure-service-operator and cluster-api-provider-azure, external Postgres key is `postgresql_12`).

## Konflux

- **Decision**: `network_mode: hermetic`, `cachi2.enabled: true` with `rpm-lockfile-prototype` (carried from 2.11).

## Tool patch report (art-migration branch-setup mce 2.11 2.10)

Command:

```
./art-migration.sh branch-setup mce 2.11 2.10 \
  --ocp-target-versions "4.17,4.18,4.19,4.20,4.21,4.22" \
  --rhel-stream "registry.redhat.io/ubi9/ubi-minimal:latest" \
  --golang-version "1.26"
```

What the tool got right:

- Created `mce-2.10` from `origin/mce-2.11`
- `name: mce-2.10`
- `GO_LATEST`/`GO_EXTRA` 1.26
- `OCP_TARGET_VERSIONS` values (collapsed to one line; reformatted)
- `backplane-2.11` → `backplane-2.10` on stolostron image configs, including `kube-rbac-proxy`
- `rhel9.image` → `ubi-minimal:latest`
- Did not touch hive `master` or `openshift-base-rhel9`

What was patched after (backward / OCP-4.20-aligned product):

1. `vars.MAJOR`/`MINOR` `2`/`10` → `4`/`20` (tool assumes product version == OCP version)
2. `version: 2.10.0` → `2.10.8`
3. `OCP_RELEASE_NOTES_VERSION` `4.21` → `4.20` (not rewritten)
4. `release-4.21` → `release-4.20` on hypershift-cli, hypershift-release, cluster-api-provider-kubevirt
5. `release-ocm-2.16` → `release-ocm-2.15` on cluster-api-provider-agent
6. Removed azure-service-operator and cluster-api-provider-azure (tool does not drop components)
7. Added cluster-proxy-addon (tool does not add components)
8. nodejs digest → `:latest`; ose-cli `v4.21` → `v4.20`
9. Restored `streams.yml` `---` / blank-line formatting lost by the PyYAML fallback (no ruamel.yaml)

`base-rhel9.yml` has no `dependents:` entry. That matches 2.11 (base image, not an operand).

Suggested tool improvements (same class as the 2.11 → 2.17 run, plus a backward jump):

- Do not derive `vars.MAJOR`/`MINOR` from the product version for layered products; take an `--ocp-major-minor 4.20` flag.
- Bump or retarget OCP-aligned `release-X.Y` and `release-ocm-X.Y` separately from product `backplane-` versions. A backward jump must be able to move `release-4.21` to `release-4.20`.
- Support `--drop-images` and `--add-images` so a scaffold can remove components that do not exist on the older release and add ones that were removed later.
- Optional `--version` for `group.yml` z-stream instead of always `{new}.0`.
- Preserve `streams.yml` comments (`ruamel.yaml`) and do not collapse `OCP_TARGET_VERSIONS` formatting unless asked.
- Rewrite `OCP_RELEASE_NOTES_VERSION` when `--ocp-major-minor` is set.
