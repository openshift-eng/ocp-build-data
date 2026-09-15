# DECISIONS.md — MCE 2.17 ocp-build-data Branch

Product decisions and rationale for the `mce-2.17` branch configuration.
Scaffolded from `mce-2.11` via `art-migration.sh branch-setup`, then patched
for the non-sequential 2.11 → 2.17 jump (HYPBLD-873). `mce-5.0` was used
only as a reference for the three components added in 2.17.

## Product Identity

- **Decision**: `product: multicluster-engine`, `name: mce-2.17`, `csv_namespace: multicluster-engine`
- **Rationale**: Same as mce-2.11 / mce-5.0. Tool correctly rewrote `name:`.

## OCP Version Alignment

- **Decision**: `MAJOR: 4`, `MINOR: 22` (distgit `rhaos-4.22-rhel-9`)
- **Rationale**: MCE 2.17 aligns with OCP 4.22 (HYPBLD-873 A1).
- **Tool patch**: `branch-setup` set MAJOR/MINOR from the *product* version (`2`/`17`). Corrected to OCP 4.22.

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["4.20", "4.21", "4.22", "5.0"]`
- **Rationale**: Hosted/guest window is N-2..N (4.20–4.22). Hub N+1 would be 4.23, which does not exist; CSV `olm.maxOpenShiftVersion` is `5.0` (A2b).

## group.yml version

- **Decision**: `version: 2.17.3`
- **Rationale**: Latest unreleased z-stream so FBCs can build (A10/A11). Konflux 2.17 CSV is currently 2.17.3.
- **Tool patch**: tool wrote `2.17.0`.

## Git Source Branches

- **Decision**:
  - `stolostron/*` → `backplane-2.17`
  - `openshift/hypershift`, `cluster-api-provider-kubevirt` → `release-4.22`
  - `cluster-api-provider-agent` → `release-ocm-2.17`
  - `hive` → `master`
  - `base-rhel9` → `openshift-base-rhel9`
  - `image-based-install-operator` → `backplane-2.17`
- **Rationale**: Matches Konflux MCE 2.17 operand overlays (A9).
- **Tool patch**: bumped `backplane-2.11` → `backplane-2.17` only. Left `release-4.21`, `release-ocm-2.16`, `master`, and `openshift-base-rhel9` unchanged.

## New Components (vs mce-2.11)

Added from `mce-5.0` templates with `backplane-2.17` (A5/A8):

| Component | Upstream repo | Dockerfile |
|-----------|---------------|------------|
| cloudevents-conductor | [stolostron/cloudevents-conductor](https://github.com/stolostron/cloudevents-conductor) | `Dockerfile.rhtap` |
| cluster-permission | [stolostron/cluster-permission](https://github.com/stolostron/cluster-permission) | `Dockerfile.rhtap` |
| maestro | [stolostron/maestro](https://github.com/stolostron/maestro) | `Dockerfile.rhtap` |

`cluster-proxy-addon` remains excluded. `assisted-*` is deferred (Gus: fine to start without them).

## Image scope

36 configs: 33 carried from mce-2.11 + 3 new. Bundle still excluded from `images/*.yml` (same as 2.11/5.0).

## Console Dockerfile

- **Decision**: `Containerfile.mce` with two `rhel-9-nodejs-24` parents; no `rhel9-ubi` crypto-policy stream
- **Rationale**: Matches `backplane-2.17` upstream. 2.11 used `Containerfile.mce.konflux` (2 parents). 5.0 used `Containerfile.mce` with 3 parents. 2.17 is the hybrid (A15b).

## PQC / RHEL base

- **Decision**: `streams.yml` `rhel9` = `registry.redhat.io/ubi9/ubi-minimal:9.8` (not pqc, not `:latest`)
- **Rationale**: A3. PQC is 5.0+ only.

## Other streams

- **Go**: floating `golang-builder-v1.26-rhel9` (already on mce-2.11 after #12657). Per-image `rhel-9-golang-1.25` builders retargeted to `rhel-9-golang` (A4). Hypershift upstream 1.25 upgrade is a separate PR.
- **nodejs**: `ubi9/nodejs-24-minimal:latest` (A16b compromise; ubi-minimal stays version-pinned).
- **ose-cli**: `v4.22` (A16b).

## group.yml extras from 2.11

- **Decision**: Keep `cachi2.lockfile.backend`, `mr_approvers`, `OCP_RELEASE_NOTES_VERSION` (now `4.22`), and per-image `jira:` blocks (A17).

## Owners

- **Decision**: `acm-cicd@redhat.com` (same bootstrap as 2.11).

## Konflux

- **Decision**: `network_mode: hermetic`, `cachi2.enabled: true` with `rpm-lockfile-prototype` (carried from 2.11).

## Tool patch report (art-migration branch-setup mce 2.11 2.17)

Command:

```
./art-migration.sh branch-setup mce 2.11 2.17 \
  --ocp-target-versions "4.20,4.21,4.22,5.0" \
  --rhel-stream "registry.redhat.io/ubi9/ubi-minimal:9.8" \
  --golang-version "1.26"
```

What the tool got right:
- Created `mce-2.17` from `origin/mce-2.11`
- `name: mce-2.17`
- `GO_LATEST`/`GO_EXTRA` 1.26
- `OCP_TARGET_VERSIONS` list (collapsed to one line; reformatted)
- `backplane-2.11` → `backplane-2.17` on stolostron image configs
- `rhel9.image` → ubi-minimal:9.8
- Did not touch hive `master` or `openshift-base-rhel9`

What was patched after (non-sequential / OCP-aligned product):
1. `vars.MAJOR`/`MINOR` `2`/`17` → `4`/`22` (tool assumes product version == OCP version)
2. `version: 2.17.0` → `2.17.3`
3. `OCP_RELEASE_NOTES_VERSION` `4.21` → `4.22` (not rewritten)
4. `release-4.21` → `release-4.22` on hypershift-cli, hypershift-release, cluster-api-provider-kubevirt
5. `release-ocm-2.16` → `release-ocm-2.17` on cluster-api-provider-agent
6. Added images for cloudevents-conductor, cluster-permission, maestro (tool does not add components)
7. `console-mce` dockerfile `Containerfile.mce.konflux` → `Containerfile.mce`
8. nodejs digest → `:latest`; ose-cli `v4.21` → `v4.22`
9. Dropped unused `rhel-9-golang-1.25` stream; retargeted 11 image builders to `rhel-9-golang`
10. Restored `streams.yml` `---` / blank-line formatting lost by the PyYAML fallback (no ruamel.yaml)

Suggested tool improvements:
- Do not derive `vars.MAJOR`/`MINOR` from product version for layered products; take an `--ocp-major-minor 4.22` flag (or read from `--ocp-reference-branch`).
- Bump OCP-aligned `release-X.Y` and `release-ocm-X.Y` targets separately from product `backplane-`/`release-` product versions.
- Support adding image configs that exist on a reference branch (`--add-images-from mce-5.0`).
- Preserve `streams.yml` comments (`ruamel.yaml`) and do not collapse `OCP_TARGET_VERSIONS` formatting unless asked.
- Optional `--version` for `group.yml` z-stream instead of always `{new}.0`.
