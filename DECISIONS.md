# DECISIONS.md — MCE 5.1 ocp-build-data Branch

Product decisions and rationale for the `mce-5.1` branch configuration.
Scaffolded from `mce-5.0` by `art-migration` `branch-setup`, then corrected
where that copy-forward does not match the 5.1 sources.
Created as part of JIRA ticket [HYPBLD-894](https://redhat.atlassian.net/browse/HYPBLD-894).

## Product Identity

- **Decision**: `product: multicluster-engine`, `name: mce-5.1`, `csv_namespace: multicluster-engine`, `version: 5.1.0`, `MAJOR: 5`, `MINOR: 1`
- **Rationale**: MCE 5.1 tracks `release-5.1`. Distgit branch pattern remains `rhaos-{MAJOR}.{MINOR}-rhel-9`.

## OCP Target Versions

- **Decision**: `OCP_TARGET_VERSIONS: ["4.22", "4.23", "5.0", "5.1", "5.2"]`
- **Rationale**: 5.1 is the associated release. The supported hub range is the list above, from `acm-mce-operator-catalogs` `config/mce-redhat-operators-config.yaml` on `mce-redhat-operators`. This is not the 5.0 tool invocation's target list.

## Git Source Branches

- **Decision**:
  - stolostron images, including `image-based-install-operator`, `cluster-api-provider-agent`, and the five `assisted-*` repos: `backplane-5.1`
  - `hypershift-cli`, `hypershift-release`, `cluster-api-provider-kubevirt`: `release-5.1`
  - `hive`: `master`
  - `kube-rbac-proxy`: `backplane-5.1`
  - `base-rhel9`: `openshift-base-rhel9`
- **Rationale**: Matches the 5.0 ART branch map, moved forward one y-stream. Konflux 5.1 still pins some of these to `main` or `master` until release cut; ART builds the release branches, as 5.0 did. `branch-setup` rewrites `images/*.yml` only, so the `assisted-*.yaml` targets were bumped by hand.

## Removed Components

- **Decision**: Drop `maestro` and `cloudevents-conductor`. Leave `cluster-proxy-addon` out.
- **Rationale**: Konflux `mce/5.1/operands/component-removal.yaml` deletes maestro and cloudevents-conductor. `cluster-proxy-addon` was already absent from ART 5.0. No components are added in 5.1. The shared Konflux base images that ART 5.0 already omitted (`cluster-api`, `cluster-api-aws-controller`, `apiserver-network-proxy`, `aws-encryption-provider`, `postgresql-12-centos7`, discovery test images) stay omitted.

## PQC Base Images and Go

- **Decision**: Keep the 5.0 streams. `rhel9` is `registry.redhat.io/ubi9/ubi-minimal-pqc:latest`. `rhel-9-golang` and `GO_LATEST` stay on Go 1.26. `ose-cli` stays `registry.redhat.io/openshift4/ose-cli-rhel9:v4.22` until `openshift5/ose-cli-rhel9:v5.0` is published.
- **Rationale**: 5.1 Dockerfiles that name a Go builder name `rhel_9_golang_1.26`. Do not switch any image back to standard `ubi-minimal`.

## Console Parents

- **Decision**: `console-mce.yml` builders are `rhel-9-nodejs-24` then `rhel-9-golang`, and the final stage is stream `rhel9`. The `rhel9-ubi` stream is removed.
- **Rationale**: `backplane-5.1` `Containerfile.mce` no longer has the 5.0 `ubi9/ubi` crypto-policy stage. Its three non-stage parents are `nodejs-24-minimal`, `golang-builder` 1.26, and `ubi-minimal-pqc`, in that order. `FROM build-base` is a same-stage reference and is not a fourth parent.

## Hypershift-cli Parents

- **Decision**: Keep the 5.0 parent list: builder `rhel-9-golang`, builder `rhel9`, final stream `rhel-9-nginx-124`. Do not use `member: base-rhel9`.
- **Rationale**: `release-5.1` `Containerfile.cli` has those three parents: the Go 1.26 builder, `ubi-minimal-pqc` as the policy stage, and `nginx-124` as the final stage.

## Must-gather Parents

- **Decision**: Builders `ose-cli` and `rhel-9-golang`, final stream `rhel9` (not `member: base-rhel9`).
- **Rationale**: `backplane-5.1` `build/Dockerfile.rhtap` has those three parents, and the final stage is `ubi-minimal-pqc`. The go-toolset stage still has `COPY --chown=default`. ART replaces that stage with `openshift/golang-builder`, which has no user `default`, so the upstream Dockerfile needs `USER 0` before `COPY`. That edit is on `backplane-must-gather`, not in this image config. The 5.0 Dockerfile already has the fix; `backplane-5.1` does not.

## Backplane-operator Parents

- **Decision**: Keep builder `rhel9`, builder `rhel-9-golang-1.26`, and final `member: base-rhel9`.
- **Rationale**: `backplane-5.1` `build/Dockerfile.rhtap` still has three non-stage `FROM` lines (cloner, Go 1.26 builder, `ubi-minimal-pqc`). The cloner line in git names standard `ubi-minimal`; Doozer substitutes the `rhel9` PQC stream for that parent.

## Assisted Images

- **Decision**: The five assisted images stay in the ART image set and stay out of `bundle/art.yaml` `external-images`.
- **Rationale**: ART 5.0 builds them and Konflux 5.1 still has them. Doozer fills those references from the ART builds. `postgresql_16` is an external digest pin. `ip_address_manager` is a chart key, not an image pin. The baremetal OSE image is an external pin.

## External OSE Images

- **Decision**: Pin both OSE images on the stage registry at the 5.1 tags: `registry.stage.redhat.io/openshift5/ose-cluster-api-rhel9:v5.1` and `registry.stage.redhat.io/openshift5/ose-baremetal-cluster-api-controllers-rhel9:v5.1`.
- **Rationale**: Same registry and `openshift5` namespace as the 5.0 stage pins, with the tag bumped to `v5.1`, until OCP 5 is published on the production registry.

## Bundle Metadata

- **Decision**: Package channel and `defaultChannel` are `stable-5.1`, `currentCSV` is `multicluster-engine.v5.1.0`. `bundle/metadata/annotations.yaml` channels and the default channel are also `stable-5.1`. `OPERATOR_VERSION` is `5.1.0`. `olm.maxOpenShiftVersion` is `5.2`. `olm.skipRange` is `>=2.17.0-0 <5.1.0`. The `art.yaml` updates entry searches `5.1.0` and replaces `5.1.0`.
- **Rationale**: The package file does not set the annotation channels. The updates block exists so the FBC build can move the channel head. The community CSV on `backplane-5.1` is still `multicluster-engine.v0.0.1`; product metadata is applied in place and the 5.1 CRDs are kept. `relatedImages` and `OPERAND_IMAGE_*` follow the 5.1 chart keys plus the operator images ART still builds, without `maestro`, `cloudevents_conductor`, or `postgresql_15`.

## Operator Bundle in Advisory RPAs

- **Decision**: `mce-operator-bundle` is in both the stage and prod advisory RPAs.
- **Rationale**: Live ART 2.9 through 5.0 put it in both. Prod delivery of the catalog still also goes through the FBC pipeline. The FBC stage ReleasePlan is `mce-advisory-stage-auto-5-1`, admitting through `mce-advisory-stage-5-1`.

## Scan Schedule

- **Decision**: `--group=mce-5.1` is added immediately after `--group=mce-5.0` in the layered-products scan schedule.
- **Rationale**: That schedule now lives in GitLab `art-config` (`argocd/project/art-acm-tenant/18_pipeline-schedule-layered-products-scan.yaml`) after ART-24826 moved the Argo CD config out of `art-tools`. `aos-cd-jobs` `nonOCPGroups` is not the scan source. The same art-config FBC release pipeline allowlist includes `mce-5.1` next to `mce-5.0`, or `release-from-fbc` rejects the group.

## What branch-setup did not get right

- It rewrites only `images/*.yml`, so `assisted-*.yaml` stayed on `backplane-5.0` until patched.
- It copied `maestro` and `cloudevents-conductor` forward.
- It kept the 5.0 console parents (`rhel9-ubi` plus two Node streams) and the must-gather `member: base-rhel9` final stage.
- `ruamel` dropped the leading `---` in `streams.yml`; that marker was restored. `rhel9.image` was already the PQC pullspec, so the `--rhel-stream` write did not change the image.
- It collapsed `OCP_TARGET_VERSIONS` onto one line and left the 5.0 version comment in place. The list is `4.22, 4.23, 5.0, 5.1, 5.2`, restored as a multi-line array.
- It does not edit Konflux release data, `backplane-operator`, Tide, or `art-tools`.
