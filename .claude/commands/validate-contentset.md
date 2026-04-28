# Content Set Validation Command

## Content Set Validation Task Prompt

**Objective**: Validate that all `content_set` values defined in `group.yml` repository configurations exist in the authoritative `known_rpm_repositories.yml` file, identify any invalid entries, and propose corrections.

### Task Context
- **File 1**: `group.yml` - Contains repository definitions with `content_set` mappings
- **File 2**: `known_rpm_repositories.yml` - Authoritative source of valid content sets
- **Variable Substitution**: Replace `{MAJOR}` and `{MINOR}` with values from `group.yml` vars section (currently MAJOR: 4, MINOR: 15, but these are dynamic per release)

### Validation Requirements

1. **Extract Variables**: Read MAJOR and MINOR values from `group.yml` vars section
2. **Extract Content Sets**: Parse all `content_set` values from `group.yml` repos section
3. **Variable Resolution**: Apply template variable substitution before validation
4. **Cross-Reference**: Check each content set against `known_rpm_repositories.yml`
5. **Report Findings**: Document valid/invalid content sets with details
6. **Propose Corrections**: For invalid entries, suggest valid alternatives

### Technical Implementation

**Extract Variables**:
```bash
MAJOR=$(yq '.vars.MAJOR' group.yml)
MINOR=$(yq '.vars.MINOR' group.yml)
```

**Primary Validation Command**:
```bash
for cs in $(cat group.yml | yq '.repos[] | .content_set | to_entries[] | .value' | sort -u | grep -v true | gsed -e "s/{MAJOR}/$MAJOR/g" -e "s/{MINOR}/$MINOR/g"); do 
    grep -q "$cs" known_rpm_repositories.yml || echo "$cs not found"
done
```

**Alternative with Dynamic Variables**:
```bash
MAJOR=$(yq '.vars.MAJOR' group.yml)
MINOR=$(yq '.vars.MINOR' group.yml)
for cs in $(cat group.yml | yq '.repos[] | .content_set | to_entries[] | .value' | sort -u | grep -v true | gsed -e "s/{MAJOR}/$MAJOR/g" -e "s/{MINOR}/$MINOR/g"); do 
    grep -q "$cs" known_rpm_repositories.yml || echo "$cs not found"
done
```

### Expected Deliverables

1. **Validation Summary**: Count of total/valid/invalid content sets
2. **Invalid Content Sets List**: Specific entries that failed validation
3. **Correction Recommendations**: Mapping of invalid → valid content sets
4. **Implementation Plan**: Step-by-step correction approach
5. **User Approval Process**: Present findings before making changes

### Success Criteria
- All content sets validated against authoritative source
- Clear documentation of any discrepancies
- Actionable recommendations for fixes
- User confirmation before modifications
- Verification of corrections post-implementation

This structured approach ensures thorough validation while maintaining proper approval workflows for configuration changes.