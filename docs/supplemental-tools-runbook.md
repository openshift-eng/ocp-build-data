# Supplemental-Tools Build & Release Runbook

This runbook documents the build, release, and verification process for the
`supplemental-tools` group in ocp-build-data. It also covers how to onboard
new images into the group.

Based on the post-mortem from ART-18321 (block-copyfail).

## Overview

The `supplemental-tools` group contains standalone images that are released
independently from the main OCP payload. These images:

- Are **not** part of the OCP payload (`for_payload: false`, `for_release: false`)
- Are built via Konflux with hermetic/cachi2 builds
- Are released to `registry.redhat.io` through the Konflux release pipeline
- Support 4 architectures: x86_64, aarch64, s390x, ppc64le

### Current Images

| Image | Delivery Repo | Source |
|-------|---------------|--------|
| block-copyfail | `openshift4/ose-block-copyfail-rhel9` | [openshift/block-copyfail](https://github.com/openshift/block-copyfail) |

### Group Configuration

- **Branch**: `supplemental-tools` in `ocp-build-data`
- **Product**: `supplemental-tools`
- **Version**: `1.0.0` (group-level; individual images version independently)
- **Konflux tenant**: `ocp-art-tenant/supplemental-tools`

## Prerequisites

- Access to the ART Jenkins instance
- `elliott` CLI installed and configured
- Access to the Konflux cluster (`ocp-art-tenant` namespace)
- `oc` CLI authenticated to the Konflux cluster
- Jira access for tracking bugs/CVEs

## Step 1: Build

Builds are triggered via the **`build/layered-products`** Jenkins job.

```
# Jenkins job: build/layered-products
# Parameters:
#   --group=supplemental-tools
```

1. Navigate to the `build/layered-products` Jenkins job
2. Click "Build with Parameters"
3. Set `--group=supplemental-tools`
4. Trigger the build
5. Monitor the build logs for completion

The build will:
- Resolve the source from `git@github.com:openshift-priv/block-copyfail.git` (branch: `main`)
- Use `rhel9-custom` (ubi9:latest) as the builder and `openshift-enterprise-base-rhel9` as the base
- Build for all 4 architectures via Konflux hermetic mode
- Push to the Konflux image repo: `quay.io/redhat-user-workloads/ocp-art-tenant/supplemental-tools`

## Step 2: Create a Snapshot

After a successful build, create a snapshot using `elliott`:

```bash
elliott -g supplemental-tools snapshot new --apply
```

This creates a Konflux `Snapshot` resource in the `ocp-art-tenant` namespace
that references the built images.

## Step 3: Release

Apply a `Release` custom resource to the Konflux cluster that references the
snapshot and the appropriate `ReleasePlan`.

```bash
# Apply the Release CR to trigger the release pipeline
oc apply -f <release-cr.yaml> -n ocp-art-tenant
```

> **Note**: The exact Release CR template and ReleasePlan name are
> environment-specific. Consult the team for the current values or check
> the `konflux-release-data` repository for the `ocp-art-tenant` namespace
> configuration.

The release pipeline will:
- Sign the images
- Push to the delivery repo on `registry.redhat.io`
- Apply any necessary errata metadata

## Step 4: Verify

Confirm the image appears on `registry.redhat.io`:

```bash
# Check that the image is available
skopeo inspect docker://registry.redhat.io/openshift4/ose-block-copyfail-rhel9:latest

# Verify all architectures are present
skopeo inspect --raw docker://registry.redhat.io/openshift4/ose-block-copyfail-rhel9:latest | jq '.manifests[].platform'
```

Expected architectures: `amd64`, `arm64`, `s390x`, `ppc64le`.

## Onboarding a New Image

To add a new image to the supplemental-tools group:

### 1. Create the image config

Add a YAML file under `images/` on the `supplemental-tools` branch of
`ocp-build-data`. Use `images/block-copyfail.yml` as a template:

```yaml
content:
  source:
    path: .
    dockerfile: Dockerfile
    git:
      allow_unprotected_branch: true
      branch:
        target: main  # or the appropriate branch
      url: git@github.com:openshift-priv/<new-image>.git
      web: https://github.com/openshift/<new-image>
distgit:
  branch: rhaos-{MAJOR}.{MINOR}-rhel-9
  component: <new-image>-container
delivery:
  repo_name: <new-image>
  delivery_repo_names:
  - openshift4/ose-<new-image>-rhel9
for_payload: false
for_release: false
enabled_repos:
- rhel-9-baseos-rpms
- rhel-9-appstream-rpms
- rhel-9-codeready-builder-rpms
from:
  builder:
  - stream: rhel9-custom
  stream: openshift-enterprise-base-rhel9
name: openshift4/ose-<new-image>-rhel9
owners:
- <owner-email>@redhat.com
konflux:
  image_repo: quay.io/redhat-user-workloads/ocp-art-tenant/supplemental-tools
  cachi2:
    lockfile:
      backend: rpm-lockfile-prototype
```

### 2. Add public upstream mapping

If the image source has a private/public fork pair, add the mapping to
`group.yml` under `public_upstreams`:

```yaml
public_upstreams:
- private: "https://github.com/openshift-priv/<new-image>"
  public:  "https://github.com/openshift/<new-image>"
```

### 3. Set up the delivery repo

Ensure the delivery repo (e.g., `openshift4/ose-<new-image>-rhel9`) is
created on `registry.redhat.io`. This typically requires a request to the
container registry team.

### 4. Test the build

Run a build via the `build/layered-products` Jenkins job and verify the
new image builds successfully.

### 5. Update the release configuration

If needed, update the Konflux `ReleasePlan` in `konflux-release-data` to
include the new image component.

## Troubleshooting

### Build fails with cachi2 lockfile errors

The group uses `rpm-lockfile-prototype` as the cachi2 lockfile backend.
If the lockfile is out of date, regenerate it in the source repo.

### Image not appearing on registry.redhat.io

1. Check the Release CR status: `oc get release -n ocp-art-tenant`
2. Check the release pipeline logs in the Konflux UI
3. Verify the delivery repo exists and is configured correctly
4. Check for signing failures in the pipeline logs

### Architecture mismatch

The group builds for 4 architectures. If an architecture is missing:
1. Check the Konflux pipeline for arch-specific failures
2. Verify the base images support the target architecture
3. Check `group.yml` `arches` and `konflux.arches` lists

## References

- [block-copyfail source](https://github.com/openshift/block-copyfail)
- [ocp-build-data supplemental-tools branch](https://github.com/openshift-eng/ocp-build-data/tree/supplemental-tools)
- Post-mortem: ART-18321
- Tracking ticket: ART-18775
