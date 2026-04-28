# **FOCUSED CORE GOLANG BUILDER REGISTRY ANALYSIS REPORT**
## **Excluding All Partner/IBM Streams**

## **Systematic Methodology - CORE STREAMS ONLY**

### **1. Scope Refinement**
- **Excluded**: All `partner-*`, `ibm-*` streams (not core infrastructure)
- **Included**: `golang`, `rhel-8-golang`, `rhel-9-golang`, `rhel-9-golang-extra`, `etcd_golang`, `etcd_rhel9_golang`
- **Total Core Streams Analyzed**: 15 unique golang images across 13 OCP versions

### **2. Core Stream Categories**
- **Primary Golang**: `golang` (legacy, RHEL 8 based)
- **Modern Dual Architecture**: `rhel-8-golang`, `rhel-9-golang` 
- **Extra/Preview**: `rhel-9-golang-extra` (newer Go versions)
- **ETCD Special**: `etcd_golang`, `etcd_rhel9_golang` (ETCD-specific builds)

## **COMPLETE VERSION-BY-VERSION ANALYSIS - CORE STREAMS ONLY**

### **OpenShift 4.12 - LEGACY + MODERN HYBRID**
- **Branch**: `openshift-4.12`
- **Core Streams**:
  - **`golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.19.13-202604231229.p2.g276c5af.el8` ✅
  - **`rhel-9-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.19.13-202604231941.p2.g805400d.el9` ✅  
  - **`etcd_golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.19.13-202604231229.p2.g276c5af.el8` ✅
- **Registry Status**: ✅ **ALL 3 core streams have registry.redhat.io equivalents**

### **OpenShift 4.13 - ETCD SPLIT**
- **Branch**: `openshift-4.13`
- **Core Streams**:
  - **`golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.19.13-202604231229.p2.g276c5af.el8` ✅
  - **`rhel-9-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.19.13-202604231941.p2.g805400d.el9` ✅
  - **`etcd_rhel9_golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.19.13-202604231941.p2.g805400d.el9` ✅
- **Registry Status**: ✅ **ALL 3 core streams have registry.redhat.io equivalents**

### **OpenShift 4.14 - GO VERSION BUMP**
- **Branch**: `openshift-4.14`
- **Core Streams**:
  - **`golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.20.12-202604101100.p2.g6e050e4.el8` ❌
  - **`rhel-9-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.20.12-202604101907.p2.g5595e7d.el9` ❌
  - **`etcd_rhel9_golang`**: `openshift/golang-builder:v1.19.13-202507041126.g3172d57.el9` (Different registry)
- **Registry Status**: ❌ **NO registry.redhat.io equivalents for v1.20.12 builds**

### **OpenShift 4.15 - SAME AS 4.14**
- **Branch**: `openshift-4.15`
- **Core Streams**: Same as 4.14
- **Registry Status**: ❌ **NO registry.redhat.io equivalents for v1.20.12 builds**

### **OpenShift 4.16 - GO VERSION BUMP + ETCD LEGACY**
- **Branch**: `openshift-4.16`
- **Core Streams**:
  - **`golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.21.13-202604230643.p2.ge674f93.el8` ✅
  - **`rhel-9-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.21.13-202604151128.p2.g670cbfa.el9` ❌
  - **`etcd_golang`**: `openshift/golang-builder:v1.19.13-202408070335.gfa00de2.el8` (Different registry)
  - **`etcd_rhel9_golang`**: `openshift/golang-builder:v1.19.13-202408070451.g3172d57.el9` (Different registry)
- **Registry Status**: ✅ **PARTIAL - Only golang (el8) has registry.redhat.io equivalent**

### **OpenShift 4.17 - MODERN DUAL ARCHITECTURE**
- **Branch**: `openshift-4.17`
- **Core Streams**:
  - **`rhel-8-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.22.12-202603181325.p2.g3a22db8.el8` ❌
  - **`rhel-9-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.22.12-202603181325.p2.g388ceb2.el9` ❌
- **Registry Status**: ❌ **NO registry.redhat.io equivalents for v1.22.12 builds**
- **Architecture**: **Legacy `golang` stream REMOVED**

### **OpenShift 4.18 - SAME AS 4.17**
- **Branch**: `openshift-4.18`
- **Core Streams**: Same as 4.17
- **Registry Status**: ❌ **NO registry.redhat.io equivalents for v1.22.12 builds**

### **OpenShift 4.19 - GO VERSION BUMP**
- **Branch**: `openshift-4.19`
- **Core Streams**:
  - **`rhel-8-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.23.10-202603131509.p2.gdc331c7.el8` ❌
  - **`rhel-9-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.23.10-202603131509.p2.gd0321dd.el9` ❌
- **Registry Status**: ❌ **NO registry.redhat.io equivalents for v1.23.10 builds**

### **OpenShift 4.20 - READY FOR MIGRATION**
- **Branch**: `openshift-4.20` (Current working branch)
- **Core Streams**:
  - **`rhel-8-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.24.13-202604221752.p2.gcb9763d.el8` ✅
  - **`rhel-9-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.24.13-202604241621.p2.g867eb73.el9` ✅
- **Registry Status**: ✅ **ALL core streams have registry.redhat.io equivalents**

### **OpenShift 4.21 - ALREADY MIGRATED**
- **Branch**: `openshift-4.21`
- **Core Streams**:
  - **`rhel-8-golang`**: `registry.redhat.io/openshift/art-images-base:openshift-golang-builder-container-v1.24.13-202603271447.p2.gcb9763d.el8` ✅
  - **`rhel-9-golang`**: `registry.redhat.io/openshift/art-images-base:openshift-golang-builder-container-v1.24.13-202603271447.p2.g04d2cd5.el9` ✅
- **Registry Status**: ✅ **ALREADY using registry.redhat.io**

### **OpenShift 4.22 - ALREADY MIGRATED**
- **Branch**: `openshift-4.22`
- **Core Streams**:
  - **`rhel-8-golang`**: `registry.redhat.io/openshift/art-images-base:openshift-golang-builder-container-v1.25.8-202604081607.p2.g2aa6a05.el8` ✅
  - **`rhel-9-golang`**: `registry.redhat.io/openshift/art-images-base:openshift-golang-builder-container-v1.25.8-202604150744.p2.gf28329a.el9` ✅
- **Registry Status**: ✅ **ALREADY using registry.redhat.io**

### **OpenShift 4.23 - REGRESSION TO QUAY.IO**
- **Branch**: `openshift-4.23`
- **Core Streams**:
  - **`rhel-8-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.25.8-202604081607.p2.g2aa6a05.el8` ✅
  - **`rhel-9-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.25.8-202604150744.p2.gf28329a.el9` ✅
- **Registry Status**: ✅ **ALL core streams have registry.redhat.io equivalents available**

### **OpenShift 5.0 - LATEST WITH EXTRA GOLANG**
- **Branch**: `openshift-5.0`
- **Core Streams**:
  - **`rhel-8-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.25.8-202604081607.p2.g2aa6a05.el8` ✅
  - **`rhel-9-golang`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.25.8-202604150744.p2.gf28329a.el9` ✅
  - **`rhel-9-golang-extra`**: `quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-v1.26.1-202604202010.p2.g43aca9a.el9` ❌
- **Registry Status**: ✅ **2/3 core streams have registry.redhat.io equivalents** (v1.26.1 missing)

## **CORE REGISTRY VALIDATION RESULTS**

### **✅ Registry.redhat.io Equivalents EXIST (8/15 core images)**
1. **v1.19.13-202604231229.p2.g276c5af.el8** (4.12, 4.13 golang/etcd_golang)
2. **v1.19.13-202604231941.p2.g805400d.el9** (4.12, 4.13 rhel-9-golang)
3. **v1.21.13-202604230643.p2.ge674f93.el8** (4.16 golang)
4. **v1.24.13-202604221752.p2.gcb9763d.el8** (4.20 rhel-8-golang)
5. **v1.24.13-202604241621.p2.g867eb73.el9** (4.20 rhel-9-golang)
6. **v1.25.8-202604081607.p2.g2aa6a05.el8** (4.23, 5.0 rhel-8-golang)
7. **v1.25.8-202604150744.p2.gf28329a.el9** (4.23, 5.0 rhel-9-golang)

### **❌ Registry.redhat.io Equivalents NOT FOUND (7/15 core images)**
1. **v1.20.12-202604101100.p2.g6e050e4.el8** (4.14, 4.15 golang)
2. **v1.20.12-202604101907.p2.g5595e7d.el9** (4.14, 4.15 rhel-9-golang)
3. **v1.21.13-202604151128.p2.g670cbfa.el9** (4.16 rhel-9-golang)
4. **v1.22.12-202603181325.p2.g3a22db8.el8** (4.17, 4.18 rhel-8-golang)
5. **v1.22.12-202603181325.p2.g388ceb2.el9** (4.17, 4.18 rhel-9-golang)
6. **v1.23.10-202603131509.p2.gdc331c7.el8** (4.19 rhel-8-golang)
7. **v1.23.10-202603131509.p2.gd0321dd.el9** (4.19 rhel-9-golang)
8. **v1.26.1-202604202010.p2.g43aca9a.el9** (5.0 rhel-9-golang-extra)

## **MIGRATION READINESS ASSESSMENT - CORE ONLY**

### **🟢 IMMEDIATE MIGRATION READY (4 versions)**
1. **OpenShift 4.12**: 3/3 core streams ready
2. **OpenShift 4.13**: 3/3 core streams ready  
3. **OpenShift 4.20**: 2/2 core streams ready
4. **OpenShift 4.23**: 2/2 core streams ready

### **🟡 PARTIAL MIGRATION READY (1 version)**
- **OpenShift 5.0**: 2/3 core streams ready (missing v1.26.1)

### **🔴 NEEDS REGISTRY BUILD FIRST (6 versions)**
1. **OpenShift 4.14**: Missing v1.20.12 variants
2. **OpenShift 4.15**: Missing v1.20.12 variants  
3. **OpenShift 4.16**: Missing v1.21.13 rhel-9 variant
4. **OpenShift 4.17**: Missing v1.22.12 variants
5. **OpenShift 4.18**: Missing v1.22.12 variants
6. **OpenShift 4.19**: Missing v1.23.10 variants

### **🟢 ALREADY MIGRATED (2 versions)**
- **OpenShift 4.21**: Core streams use registry.redhat.io
- **OpenShift 4.22**: Core streams use registry.redhat.io

## **KEY FINDINGS - CORE STREAMS FOCUS**

### **1. Simplified Architecture**
Without partner/IBM streams, the core architecture is much cleaner:
- **Early versions (4.12-4.16)**: Legacy `golang` + modern `rhel-9-golang`
- **Modern versions (4.17+)**: Dual `rhel-8-golang` + `rhel-9-golang`
- **Latest (5.0)**: + `rhel-9-golang-extra` for preview versions

### **2. Clear Migration Pattern**
- **4.21-4.22**: Successfully migrated to registry.redhat.io  
- **4.23+**: **Mysteriously reverted back to quay.io** (investigate!)
- Registry equivalents exist for 4.23+ but aren't being used

### **3. Missing Registry Builds**
Core missing versions: **Go 1.20.12, 1.21.13 (rhel-9), 1.22.12, 1.23.10, 1.26.1**

### **4. Immediate Action Items**
1. **Migrate immediately**: 4.12, 4.13, 4.20, 4.23 (registry equivalents exist)
2. **Investigate 4.23+ regression**: Why revert from registry.redhat.io?
3. **Build missing registries**: Go versions 1.20.12, 1.22.12, 1.23.10, 1.26.1
4. **5.0 partial migration**: Migrate core streams, build v1.26.1 equivalent

## **EXECUTIVE SUMMARY**

**Core golang streams analysis reveals a much cleaner migration picture:**

- **4 versions ready for IMMEDIATE migration** (registry equivalents exist)
- **6 versions need registry builds first** 
- **2 versions already migrated but mysteriously reverted**
- **8 missing golang builder variants** need to be built in registry.redhat.io

The focus on core streams eliminates partner complexity and shows the **true state of core OCP golang infrastructure** across all versions 4.12-5.0.

## **URL TRANSFORMATION PATTERN**

For all migrations, use this pattern:
```
FROM: quay.io/redhat-user-workloads/ocp-art-tenant/art-images:golang-builder-{VERSION}
TO:   registry.redhat.io/openshift/art-images-base:openshift-golang-builder-container-{VERSION}
```

## **Technical Details**

### **Analysis Commands Used**
- **Branch Discovery**: `git branch -r | grep "origin/openshift-"`
- **Stream Extraction**: Manual `yq` queries per branch for core streams only
- **Registry Validation**: `skopeo inspect --raw docker://{registry-url}` for each image
- **Total Validations**: 15 unique core golang images tested

### **Repository Context**
- **Repository**: `ocp-build-data` (OpenShift Container Platform build metadata)
- **Analysis Date**: 2026-04-27
- **Working Branch**: `openshift-4.20`
- **Scope**: Core golang builder streams only (partner/IBM excluded)

---
*Generated by Claude Code analysis of ocp-build-data golang builder registry migration status*