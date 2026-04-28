---
name: hermetic-migration
description: Orchestrate hermetic migration workflows for ocp-build-data components by managing JIRA tickets, PR linking, status tracking, and migration recovery. Use when user mentions "hermetic migration", "migrate to hermetic", "hermetic status", "konflux migration", "hermetic build failure", "start hermetic", "what's the status of", "continue migration", or working with OpenShift component migrations. Handles JIRA discovery, context reconstruction, and seamless pickup of interrupted migrations using JIRA as source of truth.
---

# Hermetic Migration Assistant

Orchestrates hermetic migration workflows for ocp-build-data components by coordinating existing skills for JIRA operations, PR creation, and commit management.

## Step 1: Skill Activation
Print: "🔧 Using hermetic-migration skill to orchestrate migration workflow"

## Step 2: Operation Detection
- **Bootstrap**: "start", "begin", "migrate [component] to hermetic"
- **Status & Recovery**: "status", "progress", "what's the status of", "show hermetic", "continue migration", "pick up where I left"
- **PR integration**: "link pr", "created pr for", "pr ready for"
- **Transitions**: "move to review", "mark complete", "transition"

## Step 3: Component Context
For component operations:
1. Extract component name from user request
2. Normalize to ocp-build-data context - map to `images/` directory names
3. Validate: `ls images/ | grep -i [component]`
4. Store working component context

## Step 4: Execute Operations

### Bootstrap Migration
1. Call jira-operations to create main task:
   - Summary: "Migrate [component] to hermetic builds"
   - Description: Component failing hermetic builds. Track migration by analyzing dependencies, updating network isolation, pre-staging dependencies, testing compliance.
   - Labels: hermetic-build-failure, konflux-migration, ocp-build-data

2. Create version-specific sub-tasks via jira-operations

3. Output ticket URLs and next steps

### Status Lookup & Recovery
1. **Multi-Pattern Component Discovery**:
   - Extract component from user request ("golang builders", "cluster-logging", etc.)
   - Generate search patterns:
     - Exact match: `[component]`
     - Variations: `[component]-operator`, `[component]-builder`, `openshift-[component]`
     - Related: For "golang builders" → `golang`, `rhel-*-golang-*`, `golang-builder`
   - Validate against `images/` directory for actual component names

2. **Advanced JIRA Discovery**:
   - Primary search: `project = ART AND labels = hermetic-build-failure AND summary ~ "[pattern]"`
   - For each pattern, search tickets and linked issues
   - Include epic links and sub-task hierarchies
   - Cross-reference component mentions in descriptions and comments

3. **State Reconstruction Engine**:
   - Parse ticket status, transitions, and comment history
   - Extract linked PRs and their merge status
   - Map tickets to ocp-build-data branches and components
   - Identify incomplete work from ticket activity timestamps
   - Analyze PR links to determine actual implementation branches

4. **Context Recovery & Preparation**:
   - Auto-populate session context with discovered state
   - Set current component(s), ticket numbers, branch mappings
   - Identify actionable next steps from ticket analysis
   - Prepare for immediate continuation without re-setup

5. **Enhanced Status Report**:
```
Hermetic Migration Recovery: [component-group]
Discovered Components: [list]
Related Tickets: [count] found

Main Migration:
• ART-XXXX: [component] - [status] - [branch] - [PR-status]

Sub-Migrations:
• ART-YYYY: [component-variant] - [status] - [branch] - [PR-status]
• ART-ZZZZ: [component-variant] - [status] - [branch] - [PR-status]

Overall Progress: [X/Y] complete
Next Actions:
• [specific-action-1] - [ticket] - [branch]
• [specific-action-2] - [ticket] - [branch]

Ready for continuation: [component] on [branch]
```

### PR Integration
1. Detect context from git branch, commits, component name
2. Find ticket by component + hermetic labels
3. Create PR using pr-create skill
4. Update JIRA: link PR, transition status

### Ticket Transitions
1. Identify target ticket from context
2. Get available transitions via jira-operations
3. Apply transition logic:
   - "In Progress": auto-assign to current user
   - "Review": when PR created
   - "Done": when PR merged
4. Include default_assignee for "In Progress" transitions

## Step 5: Context Persistence & Recovery
Maintain session context from discovery or reconstruction:
- Current component(s) and related variants
- Associated ticket numbers and hierarchy
- Version sub-tasks and target branches
- Recent PR numbers and merge status
- Incomplete work items and next actions
- Migration group state for complex components

## Step 6: Skill Coordination

### With jira-operations
- Pass hermetic templates and queries
- Handle ticket hierarchy and linking
- Include assignee for transitions

### With pr-create
- Reference correct tickets
- Target version-specific branches (openshift-4.X)

### With git-commit
- Include ticket references in commit messages

## Step 7: OCP Intelligence

### Component Discovery
Validate: `ls images/ | grep -i [component]`

### Hermetic Detection
Check: `grep -r "network_mode\|curl\|wget\|yum install\|dnf install" images/[component]*.yml`
- Missing `network_mode: none`
- External downloads in Dockerfile

### Version Strategy
- Feature branches from main
- Target openshift-4.X branches
- Cherry-pick between versions

## Step 8: Error Handling
- **Missing component**: Search similar names, suggest alternatives
- **JIRA failures**: Try broader search, suggest new ticket
- **Branch issues**: Check available branches, suggest targets

## Step 9: Migration Lifecycle
1. **Discovery**: Create tickets, validate component
2. **Implementation**: Branch, update Dockerfile, "In Progress"
3. **Review**: Create PR, link tickets
4. **Integration**: Merge PR, close tickets

## Rules
- OCP-Build-Data focused: Understand repository structure and versioning
- Orchestrate, don't reimplement: Delegate to existing skills
- Component validation: Verify components exist in images/ directory
- Version branch awareness: Target correct openshift-X.Y branches
- Context awareness: Remember component and ticket associations
- Auto-assignment: Assign tickets when transitioning to "In Progress"