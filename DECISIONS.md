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

`cluster-proxy-addon` remains excluded. `assisted-*` is deferred (Gus: fine to start without them). They stay in `bundle/image-references` as **external** images (see art.yaml below), not as `images/*.yml`.

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

## Operator bundle files (backplane-2.17)

`backplane-operator.yml` already had `update-csv` pointing at `bundle`. Community `backplane-2.17` shipped none of the three ART files (`image-references`, `*package.yaml`, `art.yaml`). Each was added only after the corresponding ART job failed. See the appendix for job IDs.

### `bundle/mce-operator.package.yaml`

- **Decision**: `packageName: multicluster-engine`, channel `stable-2.17`, `currentCSV: multicluster-engine.v2.17.0`, `defaultChannel: stable-2.17`
- **Rationale**: Same shape as 2.11 (`stable-2.11` / `v2.11.0`). Community annotations still say channel `stable` / CSV `v0.0.1`; doozer reads `*package.yaml` for bundle labels, not those annotations.
- **Fix:** [stolostron/backplane-operator#4045](https://github.com/stolostron/backplane-operator/pull/4045)

### External images in `bundle/art.yaml`

Nine `image-references` names are not ART-built on `mce-2.17`. Doozer requires each as `external-images[].name` **exactly matching** the `image-references` tag name (the skip is name-only; `search`/`replace` without `name:` does not skip).

| name (must match image-references) | replace |
|------------------------------------|---------|
| `assisted-image-service-rhel9` | 2.11 digest placeholder on `registry.redhat.io/multicluster-engine/…` |
| `assisted-installer-rhel9` | same |
| `assisted-installer-agent-rhel9` | same |
| `assisted-installer-controller-rhel9` | same |
| `assisted-service-9-rhel9` | same |
| `ose-cluster-api` | `registry.redhat.io/openshift4/ose-cluster-api-rhel9:v4.22` |
| `ose-baremetal-cluster-api-controllers` | `registry.redhat.io/openshift4/ose-baremetal-cluster-api-controllers-rhel9:v4.22` |
| `postgresql-15` | 5.0 sha256 pin on `registry.redhat.io/rhel9/postgresql-15` |
| `postgresql-16` | 5.0 sha256 pin on `registry.redhat.io/rhel9/postgresql-16` |

- **Rationale**: 2.17 `image-references` was copied from 5.0, so assisted names are `*-rhel9` (2.11 art.yaml used un-suffixed names) and postgres is 15/16 (2.11 had `postgresql-13`). OSE tags follow A1 (OCP **4.22**), not 2.11’s `v4.21` or 5.0’s `openshift5` stage tags.
- **Revisit**: Replace 2.11 assisted digests when assisted-installer publishes 2.17 images.
- **Fix:** [stolostron/backplane-operator compare](https://github.com/stolostron/backplane-operator/compare/backplane-2.17...HYPBLD-873-bundle-art-yaml?expand=1)

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
- Treat missing operator `bundle/image-references` as a **pre-build** check whenever `update-csv` is set. `branch-setup` neither copies the file nor warns; `run` lists `bundle-image-references` as remaining work **after** merge, but the first layered-products rebase already needs it. The file uses `:latest` placeholders — it does not wait on real pullspecs.
- For non-sequential jumps, do not only copy `image-references` from `--current-version`. Merge in delivery names that exist on a reference branch / in the new image set (2.17 needed `cloudevents-conductor`, `cluster-permission`, `maestro` from 5.0; a 2.11 copy would have missed them).
- Make `bundle-cross-check` bidirectional: flag ART-built delivery names absent from `image-references`, not only names in the file that lack an `images/*.yml` or `art.yaml` mapping.
- Carry the **whole ART bundle trio** onto the new operator branch as soon as it exists, not after first image/bundle jobs: `bundle/image-references`, `bundle/*package.yaml`, and `bundle/art.yaml`. `bundle-image-references` copies only the first; 2.17 then failed olm_bundle on the other two in sequence.
- When copying `art.yaml`, rewrite `external-images[].name` to the **new** `image-references` tag names (2.11 `assisted-image-service` vs 5.0/2.17 `assisted-image-service-rhel9`). Doozer’s skip is `name in external_image_names`; `search`/`replace` without `name:` does not skip. Align OSE `replace` tags to the product’s OCP minor (2.17 → `v4.22`), not the source branch’s.
- After any operator-repo bundle-file PR, rebuild the **operator image** first. `olm_bundle_konflux` clones `operator_build.rebase_commitish`; re-running the bundle job against the previous NVR will not see the new files.

## Appendix: first ART builds (not ocp-build-data decisions)

Recorded here so the next non-sequential jump does not treat “tool ran + YAML patched” as “builds are green.”

Two classes of first-build failure showed up on `mce-2-17`:

1. **Operand git** (ASO, MSA) — outside a typical ART migration. `art-migration` does not inspect upstream `.dockerignore`, Docker `COPY` vs context, or whether `go mod vendor` matches the git tree under hermeto STRICT.
2. **Operator bundle mapping** (`image-references`, `*package.yaml`, `art.yaml`) — **in** the tool’s stated scope, but `bundle-image-references` only copies one of three files, is sequenced after first rebase, and a 2.11 copy is incomplete for a non-sequential jump. Nothing in `ocp-build-data` needed to change.

### azure-service-operator — `.dockerignore` vs ART `COPY v2/`

- **Symptom:** `go: no modules specified (see 'go help mod download')` in `build-images` after `COPY v2/ ./`.
- **Cause:** `backplane-2.17` `.dockerignore` listed `v2` (only `!v2/boilerplate.go.txt` excepted), so `v2/go.mod` never entered the build context. ART’s Dockerfile replace (`COPY ./ ./` → `COPY v2/ ./`) applied; dockerignore still stripped the module.
- **2.11 / 5.0:** 2.11 never excluded `v2`. 5.0 already has a comment that ART/Konflux needs `v2/` in context.
- **Fix:** operand PR, not image YAML. [stolostron/azure-service-operator#566](https://github.com/stolostron/azure-service-operator/pull/566)
- **Playbook:** after scaffold, diff operand `.dockerignore` on the new `backplane-*` branch against both the previous ART version **and** a later reference (here 5.0). Check that every ART `COPY` path is still in the Docker context.

### managed-serviceaccount — gitignored file that `go mod vendor` copies

- **Symptom:** hermeto STRICT prefetch: `vendor directory changed after vendoring: A vendor/github.com/santhosh-tekuri/jsonschema/v6/.swp`
- **Cause:** `github.com/santhosh-tekuri/jsonschema/v6` **v6.0.2** ships a vim `.swp`. `go mod vendor` copies it; MSA `.gitignore` has `*.swp`, so the committed `vendor/` does not match. Fails in **prefetch** on the cloned git tree; Dockerfile/image YAML cannot fix it.
- **2.11 / 5.0:** neither branch tracks that `.swp` either. 2.11 uses `v6.0.3-0.20260305…`, 5.0 uses `v6.0.3`. They may share the latent bug on a rebuild; 2.17 is pinned to v6.0.2, which definitely contains the file.
- **Fix:** operand PR (`git add --force` the vendored file / gitignore exception). [stolostron/managed-serviceaccount#610](https://github.com/stolostron/managed-serviceaccount/pull/610)
- **Playbook:** first hermetic prefetch failures that mention `vendor directory changed` are operand content (gitignore vs `go mod vendor`), not ART config. Do not paper over them by disabling hermetic/cachi2.

### backplane-operator — missing `bundle/image-references` (layered-products 19398)

- **Symptom:** doozer Konflux rebase: `FileNotFoundError: backplane-operator: image-references file not found` under `bundle/manifests/`, `bundle/`, or `manifests/`. Operator excluded from the build. Hive `subscription-manager` lockfile lines in the same job were warnings; the later Jenkins `FlowNode 92` crash was durability, not the root cause.
- **Cause:** `backplane-2.17` never had `bundle/image-references` (or `bundle/art.yaml`). `backplane-operator.yml` already had `update-csv` pointing at `bundle`, so rebase requires that file on the **first** operator build. `art-migration.sh bundle-image-references` copies it from the current version’s operator branch, but (a) `branch-setup` does not run it, (b) `run` lists it after merge as remaining work, and (c) a verbatim copy from `backplane-2.11` would still miss the three 2.17-only images.
- **2.11 / 5.0:** both branches have the file. 5.0 also lists `cloudevents-conductor-rhel9`, `cluster-permission-rhel9`, `maestro-rhel9`.
- **Fix:** operand PR, not image YAML. Copied the 5.0 mapping onto `backplane-2.17` (placeholders stay `:latest`). Merged as [stolostron/backplane-operator#4035](https://github.com/stolostron/backplane-operator/pull/4035). Job 19493 then built the operator and triggered `olm_bundle_konflux`.
- **Playbook:** as soon as the new operator branch exists, ensure `bundle/image-references` covers every ART-built delivery name **plus** externals. Do not wait for pullspecs. For a non-sequential jump, start from current_version then merge names from the reference branch / new image set; `bundle-cross-check` only catches extras in the file, not missing ART images.

### backplane-operator — missing `bundle/*package.yaml` (olm_bundle_konflux 35280)

- **Symptom:** `IndexError: list index out of range` at `konflux_olm_bundler.py` `_rebase_dir`: `glob.glob(.../*package.yaml')[0]`. Job lasted ~58s; no bundle NVR.
- **Cause:** `backplane-2.17` had no `bundle/*package.yaml`. Doozer uses that file for `packageName`, channel, and `currentCSV` (community `annotations.yaml` still says channel `stable` / CSV `v0.0.1`). `art-migration` has no command that copies this file.
- **2.11 / 5.0:** `bundle/mce-operator.package.yaml` with `stable-2.11` / `v2.11.0` and `stable-5.0` / `v5.0.0`.
- **Fix:** operand PR. [stolostron/backplane-operator#4045](https://github.com/stolostron/backplane-operator/pull/4045)
- **Playbook:** after `image-references`, add `*package.yaml` before the first `olm_bundle_konflux`. Channel/CSV follow `{product}-{version}` / `v{version}.0`, not the community `stable` / `0.0.1` CSV. Rebuild the operator image so the bundle job sees the new commit.

### backplane-operator — missing `bundle/art.yaml` (olm_bundle_konflux 35306 / 35339)

- **Symptom:** `ValueError: Unable to find assisted-image-service-rhel9 in name_in_bundle_map for backplane-operator`.
- **Cause:** 5.0-based `image-references` lists nine names that `mce-2.17` does not build. Without `art.yaml` `external-images[].name`, the Konflux bundler tries to resolve them from the ART DB. `art-migration` does not copy `art.yaml`.
- **2.11 / 5.0:** 2.11 `art.yaml` declares assisted (unsuffixed names) + ose `v4.21` + `postgresql-13`. 5.0 declares ose (stage `openshift5`) + `postgresql-15`/`16` and **omits** assisted even though 5.0 `image-references` lists them.
- **Fix:** operand PR, not image YAML. `name:` must match 2.17 `image-references` (`assisted-*-rhel9`, not 2.11’s unsuffixed names). OSE `replace` is `openshift4` `v4.22`. Assisted digests are 2.11 placeholders; postgres pins match 5.0. [stolostron/backplane-operator compare](https://github.com/stolostron/backplane-operator/compare/backplane-2.17...HYPBLD-873-bundle-art-yaml?expand=1)
- **Playbook:** for every `image-references` name with no `images/*.yml`, require an `external-images` entry whose `name` equals that tag. After merge, rebuild **backplane-operator** then bundle; do not re-run `olm_bundle_konflux` against the previous operator NVR (`rebase_commitish` will not include `art.yaml`).
