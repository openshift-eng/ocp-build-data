# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository-Specific Skills System

### Skills Directory
This repository contains specialized skills in `.claude/skills/` for OCP build data workflows:

### Available Skills
- **hermetic-migration** (`hermetic-migration/`) - Orchestrates hermetic migration workflows for OCP components

### Skill Triggers and Mappings
- **Hermetic migration operations** ("hermetic migration", "migrate to hermetic", "hermetic status", "konflux migration") → `.claude/skills/hermetic-migration/SKILL.md`

### Repository Skill Integration
Repository-specific skills enhance the global skills system by providing:
- **OCP-specific knowledge**: Understanding of ocp-build-data structure and conventions
- **Branch context awareness**: Integration with OpenShift version branching patterns  
- **Configuration validation**: OCP build configuration patterns and validation
- **Workflow automation**: Specialized workflows for OCP component management

### Using Repository Skills
When working in this repository, Claude will automatically load and use repository-specific skills alongside global skills. Repository skills take precedence for OCP-specific operations while delegating to global skills for general operations (git, jira, pr creation).

**Skill Loading Priority:**
1. Repository skills (`.claude/skills/`) - OCP-specific operations
2. Global skills (`~/.claude/skills/`) - General development operations
3. Built-in functionality - Basic tool operations

## Repository Overview

**ocp-build-data** is a metadata configuration repository for **OpenShift Container Platform (OCP) build management**. This repository contains YAML-based build configurations that define how OpenShift images and RPM packages are built, versioned, and distributed across multiple architectures.

### Key Characteristics
- **Pure Configuration Repository**: No traditional build system - configurations are consumed by external build systems (Konflux, OSBS)
- **Multi-Branch Architecture**: Each OpenShift version has its own branch containing version-specific build metadata
- **YAML-Based DSL**: All configurations use YAML format with variable templating (`{MAJOR}`, `{MINOR}`, etc.)
- **Multi-Architecture Support**: x86_64, aarch64, ppc64le, s390x
- **Version-Specific Branches**: Versions range from 4.10 through 5.0, each with distinct configurations

## Core Architecture

### Primary Configuration Files
- **`group.yml`**: Global release configuration, build profiles, and default settings
- **`streams.yml`**: Base image definitions and golang builder configurations
- **`releases.yml`**: Release tracking with assemblies, advisories, and RHCOS images
- **`erratatool.yml`**: Integration with Red Hat's errata management system

### Directory Structure
```
images/          # 200+ container image build configurations
rpms/           # RPM package build configurations
ci_images/      # CI/build infrastructure containers
ci_transforms/  # Build transformations and customizations
modifications/  # Custom modification scripts
```

### Configuration Patterns

#### Standard Image Configuration
```yaml
content:
  source:
    git:
      url: git@github.com:openshift-priv/repo.git
      branch:
        target: release-{MAJOR}.{MINOR}
from:
  builder:
  - stream: rhel-9-golang
  member: openshift-enterprise-base-rhel9
konflux:
  network_mode: open  # TARGET: Remove this for hermetic conversion
  cachi2:
    lockfile:
      rpms: [list of required RPMs]
```

#### Variable Templating System
- `{MAJOR}`: Major version (varies by branch: 4 or 5)
- `{MINOR}`: Minor version (varies by branch: 10-23)
- `{GO_LATEST}`: Latest golang version (varies by branch and time)
- `{GO_EXTRA}`: Extra golang version (varies by branch and time)
- `{RHCOS_EL_MAJOR}`: RHCOS major version (8 or 9, depending on branch)

## Branch Types and Architecture

### Branch Structure Overview
This repository uses a complex multi-branch architecture where each branch serves specific purposes in the OpenShift build ecosystem.

#### Product Version Branches
- **Pattern**: `openshift-{MAJOR}.{MINOR}` (e.g., `openshift-4.12`, `openshift-4.20`, `openshift-5.0`)
- **Purpose**: Contains version-specific build metadata and configurations
- **Range**: Currently spans OpenShift 4.10 through 5.0
- **Content**: Each branch has its own `group.yml`, `streams.yml`, and complete image/rpm configurations
- **Variables**: MAJOR, MINOR, GO_LATEST, etc. are branch-specific

#### OpenShift Logging Version Branches
- **Pattern**: `logging-{VERSION}` (e.g., `logging-6.0`, `logging-6.6`)
- **Purpose**: Contains logging-specific build configurations and metadata
- **Available Versions**: 
  - `logging-6.0`
  - `logging-6.1` 
  - `logging-6.2`
  - `logging-6.3`
  - `logging-6.4`
  - `logging-6.5`
  - `logging-6.6`
- **Content**: Each logging branch contains logging component configurations, version-specific settings
- **Usage**: Target these branches for logging-specific component changes and updates

#### Infrastructure Branches
- **Main Branch**: Contains repository documentation and tooling, **not build data**
- **Golang Builder Branches**: `rhel-{8,9}-golang-{1.19-1.25}` for cross-version golang support
- **Base Image Branches**: `openshift-base-{rhel8,rhel9,nodejs,python,ruby,etc}` for different base images
- **Assembly Branches**: Auto-generated `art-openshift-X.Y-assembly-*` branches for specific builds

#### Development Branches
- **Feature Branches**: Descriptive names based on work being done
- **EOL Handling**: End-of-life branches are eventually converted to tags

### Branch Selection Guidance
- **Target OpenShift Version**: Choose the appropriate `openshift-X.Y` branch
- **Logging Component Changes**: Use the appropriate `logging-X.Y` branch for logging-specific modifications
- **Golang Updates**: Work on relevant `rhel-X-golang-Y.Z` branches
- **Base Image Changes**: Use corresponding `openshift-base-*` branches
- **Cross-Version Changes**: May require updates to multiple version branches

## Development Guidelines

### Configuration Standards
- **YAML Format**: Strict YAML syntax with 2-space indentation
- **Variable Usage**: Use templated variables for version management
- **Multi-Architecture**: Ensure configurations support all target architectures
- **Ownership**: All components must have owners specified in OWNERS file

### File Modification Patterns
- **Image Configs**: Modify individual `.yml` files in `images/` directory (branch-specific)
- **Stream Updates**: Modify `streams.yml` for golang version changes (coordinate with team leads, affects upstream CI)
- **Global Settings**: Modify `group.yml` for release-wide configuration changes (branch-specific)
- **Cross-Branch Changes**: Some modifications may require updates across multiple version branches

### Critical Considerations

#### Streams.yml Modifications
**WARNING**: Changes to `streams.yml` impact all upstream CI builds across the organization.
- **Multi-Branch Impact**: Changes affect the specific OpenShift version branch and may need coordination across versions
- **Golang Version Changes**: Must announce to aos-devel/aos-leads before modification
- **Upstream Image Names**: Changes trigger 150+ upstream PRs automatically
- **Coordination Required**: Discuss with team lead before any modifications
- **Branch-Specific**: Each version branch has its own streams.yml with version-appropriate configurations

### Validation Commands
Since this is a configuration repository, validation happens through:
- **Schema Validation**: External JSON schema validation tools
- **Build Testing**: Konflux/OSBS build system validation
- **Integration Testing**: OpenShift CI system validation

## Integration Points

### External Build Systems
- **Konflux**: Modern hermetic build system (preferred)
- **OSBS**: Legacy OpenShift Build Service
- **Brew**: Red Hat internal build system

### Related Repositories
- **Private Sources**: Most source repos are in `openshift-priv` organization
- **Public Mirrors**: Corresponding public repos in `openshift` organization
- **CI Integration**: OpenShift CI consumes stream configurations for upstream builds from specific branches

## Version Detection and Context Management

### Branch Context Detection
When working in this repository, it's critical to understand which OpenShift version context you're in:

#### Current Working Branch Detection
1. **Check current branch**: `git branch --show-current`
2. **Verify version from group.yml**: Check MAJOR/MINOR variables
3. **Validate context**: Ensure you're on the correct version branch for your work

#### Branch-Specific Variables
Each `openshift-X.Y` branch contains version-specific configurations:
- **group.yml**: Contains MAJOR, MINOR, GO_LATEST, RHCOS_EL_MAJOR variables
- **streams.yml**: Contains version-appropriate golang builders and base images
- **releases.yml**: Contains version-specific release tracking information

#### Cross-Branch Development Considerations
- **Golang Builder Updates**: May require changes to multiple `rhel-X-golang-Y.Z` branches
- **Base Image Updates**: May affect multiple `openshift-base-*` branches  
- **Security Updates**: May need to be applied across multiple version branches
- **EOL Management**: Older version branches eventually become read-only tags

### Multi-Version Workflow
1. **Identify Target Versions**: Determine which OpenShift versions need changes
2. **Branch Selection**: Switch to appropriate `openshift-X.Y` branch(es)
3. **Context Verification**: Confirm version variables in group.yml match expectations
4. **Implementation**: Make changes with version-appropriate configurations
5. **Testing**: Validate changes work with the specific version's build system
