# Community Knowledge Research: Admin & DevOps Skills (Agent Teams Focus)

**Research Date**: 2026-02-11
**Skills Researched**: admin, devops
**Time Window**: January 2025 - February 2026 (post-cutoff focus)
**Special Focus**: Claude Code Agent Teams feature (experimental)

---

## Executive Summary

Agent teams are a new experimental feature in Claude Code (2026) that enables multi-session orchestration where a team lead coordinates multiple independent Claude instances working in parallel. This research examines how agent teams could enhance the admin and devops skills, which currently use traditional subagents.

**Key Findings:**
- Agent teams differ fundamentally from subagents: teammates communicate directly with each other, not just reporting back to lead
- Best use cases for sysadmin/devops: parallel infrastructure provisioning, multi-layer deployments, competing diagnostic hypotheses
- Current admin/devops agents are well-suited for upgrade to team patterns
- Token costs are 2-5x higher but justified when parallel coordination adds real value
- Official documentation is comprehensive; community examples show production patterns

**Total Findings**: 18 (8 TIER 1, 7 TIER 2, 3 TIER 3)

---

## TIER 1 Findings (Official Sources)

### 1.1 Agent Teams Architecture

**Source**: [Official Claude Code Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams)
**Trust Level**: TIER 1 (Official Anthropic documentation)
**Date Published**: January 2026

**Finding**: Agent teams consist of four core components working together:

| Component | Role |
|-----------|------|
| Team lead | Main Claude Code session that creates team, spawns teammates, coordinates work |
| Teammates | Separate Claude Code instances that each work on assigned tasks |
| Task list | Shared list of work items that teammates claim and complete |
| Mailbox | Messaging system for communication between agents |

**Architecture Details**:
- Teams stored locally at `~/.claude/teams/{team-name}/config.json`
- Task list at `~/.claude/tasks/{team-name}/`
- Config contains `members` array with each teammate's name, agent ID, and agent type
- Teammates can read config file to discover other team members

**Communication Patterns**:
- **Automatic message delivery**: Messages sent by teammates are delivered automatically to recipients
- **Idle notifications**: Teammates automatically notify lead when they finish and stop
- **Shared task list**: All agents can see task status and claim available work
- **Direct messaging**: `message` sends to one specific teammate
- **Broadcasting**: `broadcast` sends to all teammates (use sparingly, costs scale with team size)

**Verification**: Official source, applies to current version (Claude Code 2026)

**Recommendation**: Add this architectural overview to admin skill documentation as foundation for agent team implementation.

---

### 1.2 Agent Teams vs Subagents Decision Matrix

**Source**: [Official Claude Code Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams)
**Trust Level**: TIER 1 (Official Anthropic documentation)

**Finding**: Official comparison table for choosing between subagents and agent teams:

|                   | Subagents                                        | Agent teams                                         |
| :---------------- | :----------------------------------------------- | :-------------------------------------------------- |
| **Context**       | Own context window; results return to the caller | Own context window; fully independent               |
| **Communication** | Report results back to the main agent only       | Teammates message each other directly               |
| **Coordination**  | Main agent manages all work                      | Shared task list with self-coordination             |
| **Best for**      | Focused tasks where only the result matters      | Complex work requiring discussion and collaboration |
| **Token cost**    | Lower: results summarized back to main context   | Higher: each teammate is a separate Claude instance |

**Decision Rule**: "Use subagents when you need quick, focused workers that report back. Use agent teams when teammates need to share findings, challenge each other, and coordinate on their own."

**Verification**: Official guidance, confirmed by community examples

**Recommendation**: Add this decision matrix to both admin and devops skills to help Claude choose the right pattern for each task.

---

### 1.3 Best Use Cases for Agent Teams

**Source**: [Official Claude Code Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams)
**Trust Level**: TIER 1

**Finding**: Official documentation identifies strongest use cases:

1. **Research and review**: Multiple teammates investigate different aspects of a problem simultaneously, then share and challenge each other's findings
2. **New modules or features**: Teammates can each own a separate piece without stepping on each other
3. **Debugging with competing hypotheses**: Teammates test different theories in parallel and converge on the answer faster
4. **Cross-layer coordination**: Changes that span frontend, backend, and tests, each owned by a different teammate

**Anti-patterns** (when NOT to use teams):
- Sequential tasks (use single session)
- Same-file edits (conflicts)
- Work with many dependencies (coordination overhead)
- Simple tasks (token cost not justified)

**DevOps/SysAdmin Applications**:
- ✅ Parallel infrastructure provisioning (OCI + Hetzner + Contabo)
- ✅ Multi-layer deployment (server + Docker + app + monitoring)
- ✅ Competing diagnostic hypotheses (network vs. app vs. config)
- ✅ Security audit from multiple angles (firewall, SSH, app, certificates)
- ❌ Simple package installation (use subagent or direct)
- ❌ Sequential dependency chains (use single session)

**Verification**: Official source with clear examples

**Recommendation**: Add use case guidance to admin/devops skills with specific infrastructure examples.

---

### 1.4 Enabling and Configuring Agent Teams

**Source**: [Official Claude Code Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams)
**Trust Level**: TIER 1

**Finding**: Agent teams are **disabled by default** and require explicit enablement:

**Enable via settings.json**:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

**Enable via environment variable**:
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

**Display Modes**:

| Mode | Description | Requirements | Best For |
|------|-------------|--------------|----------|
| `in-process` | All teammates run inside main terminal | Any terminal | Universal compatibility |
| `split panes` | Each teammate gets own pane | tmux or iTerm2 | Parallel visibility |
| `auto` (default) | Uses split panes if in tmux, otherwise in-process | None | Automatic selection |

**Configuration**:
```json
{
  "teammateMode": "in-process"  // or "auto" or "tmux"
}
```

**One-time override**:
```bash
claude --teammate-mode in-process
```

**Verification**: Official configuration options

**Recommendation**: Add setup instructions to admin skill's first-run documentation, explaining that agent teams require explicit opt-in.

---

### 1.5 Task Dependencies and Auto-Unblocking

**Source**: [Official Claude Code Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams)
**Trust Level**: TIER 1

**Finding**: The shared task list supports **automatic dependency resolution**:

- Tasks can depend on other tasks
- Pending task with unresolved dependencies cannot be claimed
- When teammate completes a task that other tasks depend on, blocked tasks **unblock automatically** without manual intervention
- System uses file locking to prevent race conditions when multiple teammates try to claim same task

**DevOps Application Example**:
```
Task 1: Provision server (no dependencies)
Task 2: Install Docker (depends on Task 1)
Task 3: Deploy Coolify (depends on Task 2)
Task 4: Configure monitoring (depends on Task 3)
```

When Task 1 completes, Task 2 auto-unblocks. When Task 2 completes, Task 3 auto-unblocks, etc.

**Self-Organizing Pattern**:
- Workers poll TaskList
- Claim unclaimed, unblocked tasks
- Complete work
- Repeat until queue empties

**Verification**: Official feature documentation

**Recommendation**: Use this pattern for multi-step deployments in devops skill (provision → configure → deploy → verify).

---

### 1.6 Plan Approval Gates for Risky Operations

**Source**: [Official Claude Code Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams)
**Trust Level**: TIER 1

**Finding**: Teammates can be required to plan before implementing, with lead approval required:

**Usage**:
```
Spawn an architect teammate to refactor the authentication module.
Require plan approval before they make any changes.
```

**Workflow**:
1. Teammate works in **read-only plan mode** until approved
2. Teammate finishes planning, sends plan approval request to lead
3. Lead reviews plan and either:
   - **Approves**: Teammate exits plan mode, begins implementation
   - **Rejects with feedback**: Teammate stays in plan mode, revises, resubmits
4. Approval cycle repeats until approved

**Lead Autonomy**: Lead makes approval decisions autonomously. Influence judgment by giving criteria in prompt:
- "Only approve plans that include test coverage"
- "Reject plans that modify the database schema"
- "Require rollback procedures for all deployment plans"

**DevOps/SysAdmin Applications**:
- ✅ Server provisioning (verify specs, region, firewall rules before executing)
- ✅ Database migrations (review backup strategy first)
- ✅ Infrastructure changes (validate against security policies)
- ✅ Deployment plans (confirm rollback procedures exist)

**Verification**: Official feature with clear workflow

**Recommendation**: Add plan approval requirement to devops skill for all infrastructure-modifying operations. Particularly important for server-provisioner and deployment-coordinator agents.

---

### 1.7 Delegate Mode to Prevent Lead Implementation

**Source**: [Official Claude Code Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams)
**Trust Level**: TIER 1

**Finding**: **Common problem**: Lead sometimes starts implementing tasks itself instead of waiting for teammates.

**Solution**: **Delegate mode** restricts lead to coordination-only tools:
- Spawning teammates
- Messaging teammates
- Shutting down teammates
- Managing tasks

**How to Enable**: Press `Shift+Tab` to cycle into delegate mode (after team is started)

**When to Use**:
- Lead should focus entirely on orchestration
- Breaking down work into tasks
- Assigning tasks to right teammates
- Synthesizing results from teammates
- NOT touching code directly

**DevOps Application**:
For complex multi-server deployments, lead should:
1. Break deployment into discrete tasks
2. Spawn specialist teammates (provisioner, configurator, deployer)
3. Monitor progress and synthesize results
4. NOT start provisioning servers itself

**Verification**: Official feature with clear use case

**Recommendation**: Document delegate mode as recommended pattern for devops skill's deployment-coordinator agent.

---

### 1.8 Agent Teams Limitations (Official)

**Source**: [Official Claude Code Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams)
**Trust Level**: TIER 1

**Finding**: Official documented limitations of experimental feature:

| Limitation | Impact | Workaround |
|------------|--------|------------|
| **No session resumption with in-process teammates** | `/resume` and `/rewind` don't restore teammates | Tell lead to spawn new teammates after resuming |
| **Task status can lag** | Teammates fail to mark tasks complete, blocks dependent tasks | Check if work is done, update status manually or nudge teammate |
| **Shutdown can be slow** | Teammates finish current request/tool call before shutting down | Wait or force quit if necessary |
| **One team per session** | Lead can only manage one team at a time | Clean up current team before starting new one |
| **No nested teams** | Teammates cannot spawn their own teams | Only lead can manage team |
| **Lead is fixed** | Cannot promote teammate to lead or transfer leadership | Plan team structure upfront |
| **Permissions set at spawn** | All teammates start with lead's permission mode | Change individual modes after spawning |
| **Split panes require tmux/iTerm2** | Not supported in VS Code, Windows Terminal, Ghostty | Use in-process mode for universal compatibility |

**CLAUDE.md Compatibility**: Teammates read `CLAUDE.md` files from their working directory. This works normally for project-specific guidance.

**Verification**: Official limitations list

**Recommendation**: Add limitations section to admin skill documentation. Particularly important for profile-aware operations where teammates need consistent permissions.

---

## TIER 2 Findings (High-Quality Community)

### 2.1 Token Cost Analysis: Teams vs Solo vs Subagents

**Source**: [From Tasks to Swarms: Agent Teams in Claude Code](https://alexop.dev/posts/from-tasks-to-swarms-agent-teams-in-claude-code/)
**Trust Level**: TIER 2 (Technical blog with specific measurements)
**Date Published**: February 2026

**Finding**: Empirical token cost measurements for different patterns:

| Pattern | Token Usage | Use Case |
|---------|-------------|----------|
| Solo session | ~200k tokens | Standard single-agent work |
| 3-person agent team | ~440k tokens | Parallel coordination with cross-team communication |
| Cost ratio | **2.2x** | Team vs solo |
| 5-person team | ~500k+ tokens | Large-scale parallel work |
| Subagents | Lower than teams | Parallel work WITHOUT inter-agent communication |

**Break-Even Analysis**:
- 3-person team costs roughly 2x solo session
- Justified when parallel execution cuts total time by 50%+
- **Critical distinction**: Only when work truly needs cross-team communication
- Independent parallel tasks should use subagents (more efficient)

**Cost-Benefit Decision Framework**:
```
Use teams when: Coordination benefits > Token premium

Examples that justify teams:
✅ Debugging where agents debate competing theories
✅ Code review with security/performance/testing specialization
✅ Multi-layer deployment with cross-layer dependencies

Examples that don't justify teams:
❌ Parallel research with no interdependencies (use subagents)
❌ Simple bug fix (use solo session)
❌ Sequential dependency chain (use solo session)
```

**Verification**: Author provides specific token counts from production usage

**Recommendation**: Add token cost guidance to admin/devops skills. Help Claude make informed decisions about when team overhead is justified.

---

### 2.2 Plan-First Workflow to Manage Costs

**Source**: [From Tasks to Swarms: Agent Teams in Claude Code](https://alexop.dev/posts/from-tasks-to-swarms-agent-teams-in-claude-code/)
**Trust Level**: TIER 2 (Technical blog with tested pattern)

**Finding**: **Two-step workflow** to prevent expensive team execution on wrong approach:

**Step 1: Plan Mode (Low Cost)**
- Solo session or single agent in plan mode
- Break work into independent tracks
- Define task boundaries and dependencies
- Review task breakdown (~10k tokens)

**Step 2: Team Execution (High Cost)**
- After approving plan, spawn team for parallel execution
- Each teammate knows exact scope and dependencies
- Parallel execution (500k+ tokens)

**Rationale**: "Plan first with plan mode, then hand the plan to a team for parallel execution. This two-step workflow lets you review the task breakdown (~10k tokens) before committing to expensive parallel execution (500k+ tokens)."

**DevOps Application**:
```
Phase 1 (Plan, Solo, ~10k tokens):
1. User: "Deploy Coolify + KASM on new infrastructure"
2. Claude (solo): Creates deployment plan
   - Task 1: Provision 2 servers (Coolify + KASM)
   - Task 2: Install Docker on both
   - Task 3: Deploy Coolify
   - Task 4: Deploy KASM
   - Task 5: Configure networking
3. User reviews and approves plan

Phase 2 (Execute, Team, ~500k tokens):
1. Spawn 2 teammates: provisioner, deployer
2. Provisioner: Claims Tasks 1-2
3. Deployer: Claims Tasks 3-5 (dependencies auto-unblock)
4. Lead: Synthesizes results
```

**Verification**: Pattern used in production by author

**Recommendation**: Add plan-first workflow to devops skill's deployment-coordinator agent. Particularly valuable for complex multi-server deployments.

---

### 2.3 Task Sizing Best Practice: 5-6 Tasks Per Teammate

**Source**: [Addy Osmani - Claude Code Agent Teams](https://addyosmani.com/blog/claude-code-agent-teams/)
**Trust Level**: TIER 2 (Senior engineering expert with practical examples)
**Date Published**: February 2026

**Finding**: Optimal task granularity is **5-6 tasks per teammate**:

**Too Small**:
- Coordination overhead exceeds benefit
- Too much context switching
- Lead spends more time managing than value gained

**Too Large**:
- Teammates work too long without check-ins
- Increased risk of wasted effort
- Hard to reassign if teammate gets stuck

**Just Right**:
- Self-contained units producing clear deliverable
- Examples: a function, a test file, a review, a server provision
- Keeps everyone productive
- Enables reassignment when needed

**Practical Example (QA Swarm)**:
- 5 teammates, 5 tasks
- Task 1: Core page responses (16 URLs)
- Task 2: Blog post rendering (83 posts)
- Task 3: Navigation integrity (146 links)
- Task 4: SEO/RSS metadata
- Task 5: Accessibility & HTML structure
- Result: Each teammate had clear scope, no overlap

**DevOps Application**:
```
Team size: 3 (provisioner, configurator, verifier)
Tasks: 15-18 total (5-6 per teammate)

Provisioner tasks:
1. Provision OCI server
2. Provision Hetzner server
3. Provision Contabo server
4. Configure firewall rules (all)
5. Upload SSH keys (all)

Configurator tasks:
6. Install Docker on OCI
7. Install Docker on Hetzner
8. Install Docker on Contabo
9. Create swap files
10. Configure storage

Verifier tasks:
11. Verify OCI connectivity
12. Verify Hetzner connectivity
13. Verify Contabo connectivity
14. Run security audit
15. Document access details
```

**Verification**: Pattern confirmed across multiple high-quality sources

**Recommendation**: Add task sizing guidance to devops skill. Help Claude break complex deployments into appropriately-sized work units.

---

### 2.4 Context Degradation Problem That Teams Solve

**Source**: [Addy Osmani - Claude Code Agent Teams](https://addyosmani.com/blog/claude-code-agent-teams/)
**Trust Level**: TIER 2

**Finding**: **Core problem agent teams solve**: "LLMs perform worse as context expands. Narrow scopes maximize reasoning quality."

**Mechanism**:
- Single agent working on large multi-component system: Context window fills with all components
- Reasoning quality degrades as context grows beyond optimal size
- Errors increase, suggestions become less precise

**Team Solution**:
- Partition context by component/layer/concern
- Each teammate maintains narrow context window
- Specialist focus = higher quality reasoning
- Lead synthesizes across specialized contexts

**Analogy**: "Just as human teams don't CC everyone on every decision, agent teams compartmentalize context to enhance reasoning within each domain."

**DevOps Application**:

**Anti-pattern (Solo Agent, Degraded Context)**:
```
Context includes:
- OCI provisioning API
- Hetzner provisioning API
- Contabo provisioning API
- Docker installation procedures
- Coolify configuration
- KASM configuration
- Monitoring setup
- Firewall rules
→ 50,000+ token context, quality degrades
```

**Better Pattern (Agent Team, Focused Contexts)**:
```
Provisioner teammate context:
- OCI/Hetzner/Contabo APIs only
- Firewall rules
→ 15,000 token context, high quality

Deployer teammate context:
- Docker installation
- Coolify/KASM deployment
→ 12,000 token context, high quality

Monitor teammate context:
- Monitoring setup
- Verification procedures
→ 8,000 token context, high quality
```

**Verification**: Well-documented LLM behavior

**Recommendation**: Add context management guidance to admin/devops skills. Explain why teams improve quality for complex multi-component operations.

---

### 2.5 File Ownership Conflict Prevention

**Source**: [Official Claude Code Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams) + [Addy Osmani Blog](https://addyosmani.com/blog/claude-code-agent-teams/)
**Trust Level**: TIER 2 (Confirmed across multiple sources)

**Finding**: **Critical gotcha**: Two teammates editing the same file leads to overwrites.

**Problem**:
- Teammate A edits `server-config.sh`, makes changes
- Teammate B edits `server-config.sh` simultaneously
- Last write wins, one set of changes is lost
- No merge conflict detection

**Solution**: **Break work so each teammate owns different set of files**

**Architecture Patterns**:

**Good: Directory Ownership**
```
provisioner/ (Teammate A)
  ├── oci-provision.sh
  ├── hetzner-provision.sh
  └── contabo-provision.sh

configurator/ (Teammate B)
  ├── docker-setup.sh
  ├── swap-setup.sh
  └── firewall-setup.sh

deployer/ (Teammate C)
  ├── coolify-deploy.sh
  ├── kasm-deploy.sh
  └── verify.sh
```

**Bad: Shared File Ownership**
```
scripts/
  ├── provision.sh (A and B both edit)
  ├── configure.sh (B and C both edit)
  └── deploy.sh (A and C both edit)
```

**DevOps Application**: Structure deployments with clear file boundaries:
- Provisioner owns `provision-*.sh` scripts
- Configurator owns `config-*.sh` scripts
- Deployer owns `deploy-*.sh` scripts
- No overlap in file ownership

**Verification**: Official documentation + community confirmation

**Recommendation**: Add file ownership pattern to devops skill's deployment-coordinator documentation. Critical for avoiding data loss.

---

### 2.6 Production-Scale Example: C Compiler with 16 Agents

**Source**: [Official Anthropic Blog - Eight Trends Defining Software in 2026](https://claude.com/blog/eight-trends-defining-how-software-gets-built-in-2026)
**Trust Level**: TIER 2 (Official Anthropic source, blog not docs)
**Date Published**: February 2026

**Finding**: Real-world scale demonstration of agent teams:

**Project**: Build a C compiler from scratch
**Team Size**: 16 Claude agents
**Sessions**: Nearly 2,000 Claude sessions
**Token Usage**: Around 2 billion input tokens
**Cost**: Under $20,000
**Result**: Working compiler that could build a bootable Linux kernel

**Insights**:
- Agent teams can coordinate on extremely complex tasks
- Token costs at scale are manageable (2B tokens = $20k)
- Quality maintained across massive session count
- Parallel coordination enabled completion of traditionally months-long project

**Scale Comparison**:

| Project | Agents | Sessions | Tokens | Cost | Outcome |
|---------|--------|----------|--------|------|---------|
| C Compiler | 16 | 2,000 | 2B | $20k | Bootable Linux kernel |
| Typical deployment | 2-5 | 10-50 | 5M-50M | $50-500 | Production infrastructure |

**DevOps/SysAdmin Implications**:
- Multi-datacenter deployments could benefit from team orchestration
- Each agent handles one datacenter/provider
- Parallel provisioning across multiple clouds
- Centralized coordination and consistency checking

**Verification**: Official Anthropic case study

**Recommendation**: Add scale perspective to devops skill. Demonstrates agent teams can handle enterprise-scale infrastructure tasks.

---

### 2.7 Swarm Orchestration Patterns

**Source**: [Claude Code Swarm Orchestration Skill](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
**Trust Level**: TIER 2 (Community gist with comprehensive patterns)
**Date Published**: February 2026

**Finding**: Four distinct orchestration patterns for agent teams:

**1. Leader Pattern** (Centralized Control)
```
Lead: Assigns specific tasks to specific teammates
      "Provisioner: Do Task 1"
      "Deployer: Do Task 2"
      Waits for completion, synthesizes results

Use when: Clear role separation, explicit handoffs needed
```

**2. Swarm Pattern** (Self-Organization)
```
Lead: Populates task list with all work
      Spawns generic teammates

Teammates: Poll task list
           Claim first available unclaimed task
           Complete, mark done
           Repeat until queue empty

Use when: Tasks are independent, any teammate can do any task
```

**3. Pipeline Pattern** (Sequential Dependencies)
```
Tasks: 1 → 2 → 3 → 4 → 5
       Dependencies auto-unblock as predecessors complete

Teammates: Claim next available unblocked task

Use when: Multi-stage workflow (research → plan → implement → test → review)
```

**4. Watchdog Pattern** (Quality Gates)
```
Implementers: Do work, mark tasks complete
Watchdog: Hooks into task completion
          Validates quality
          Approves or rejects

Use when: Quality/security/compliance verification needed
```

**DevOps Applications**:

**Leader Pattern**: Multi-cloud provisioning with provider-specific agents
**Swarm Pattern**: Parallel server hardening across identical VMs
**Pipeline Pattern**: Provision → Configure → Deploy → Verify
**Watchdog Pattern**: Security audit agent approves each infrastructure change

**Verification**: Comprehensive gist with working examples

**Recommendation**: Add orchestration patterns to devops skill. Provide template for different deployment scenarios.

---

## TIER 3 Findings (Community Consensus)

### 3.1 Competing Hypotheses Debugging Pattern

**Source**: [Addy Osmani Blog](https://addyosmani.com/blog/claude-code-agent-teams/) + [Official Docs](https://code.claude.com/docs/en/agent-teams)
**Trust Level**: TIER 3 (Pattern mentioned in multiple sources, not yet widely tested)

**Finding**: **Competing hypotheses** is particularly effective for complex debugging:

**Traditional Sequential Investigation** (Anti-pattern):
1. Investigate hypothesis A
2. Find plausible explanation
3. Anchoring bias: Stop looking further
4. Implement fix based on A
5. Fix doesn't work (was actually hypothesis B)

**Agent Team Investigation** (Better):
1. Spawn 3-5 teammates with different theories
2. Each investigates their hypothesis
3. Teammates **actively try to disprove each other's theories**
4. Lead facilitates debate
5. Theory that survives scrutiny is likely correct

**DevOps/SysAdmin Example**:
```
Problem: "App exits after one message instead of staying connected"

Teammates:
1. Network specialist: Investigates firewall/connectivity
2. App specialist: Investigates application code
3. Config specialist: Investigates environment variables
4. Security specialist: Investigates authentication/authorization
5. Infrastructure specialist: Investigates resource limits

Each teammate:
- Gathers evidence for their theory
- Attempts to disprove other theories
- Reports findings to lead

Lead synthesizes and identifies true root cause
```

**Prompt Pattern**:
```
Spawn 5 agent teammates to investigate different hypotheses.
Have them talk to each other to try to disprove each other's
theories, like a scientific debate. Update the findings doc
with whatever consensus emerges.
```

**Verification**: Pattern appears in official docs and high-quality blog, not yet widely tested in production

**Recommendation**: Add to devops skill as advanced troubleshooting pattern. Flag as experimental, encourage user feedback.

---

### 3.2 Teammate Idle Hooks for Quality Gates

**Source**: [Official Agent Teams Documentation - Hooks Section](https://code.claude.com/docs/en/agent-teams)
**Trust Level**: TIER 3 (Official feature, limited examples of production use)

**Finding**: Two hooks enable quality enforcement:

**TeammateIdle Hook**:
```
Runs when: Teammate is about to go idle
Exit code 2: Send feedback, keep teammate working
Use for: Quality review before accepting completion
```

**TaskCompleted Hook**:
```
Runs when: Task is being marked complete
Exit code 2: Prevent completion, send feedback
Use for: Automated quality gates
```

**DevOps Application Example**:
```bash
#!/bin/bash
# .claude/hooks/task_completed.sh

TASK_ID=$1
TASK_FILE="~/.claude/tasks/$TEAM_NAME/$TASK_ID.json"

# For infrastructure tasks, verify:
if [[ $(jq -r '.title' "$TASK_FILE") == *"provision"* ]]; then
  # Check server is accessible via SSH
  SERVER_IP=$(jq -r '.notes' "$TASK_FILE" | grep -oP 'IP: \K[0-9.]+')

  if ! ssh -o ConnectTimeout=5 root@"$SERVER_IP" echo "ok" &>/dev/null; then
    echo "REJECT: Server at $SERVER_IP is not SSH accessible"
    exit 2
  fi
fi

# For deployment tasks, verify:
if [[ $(jq -r '.title' "$TASK_FILE") == *"deploy"* ]]; then
  # Check service is running
  APP_URL=$(jq -r '.notes' "$TASK_FILE" | grep -oP 'URL: \K\S+')

  if ! curl -f -s "$APP_URL/health" &>/dev/null; then
    echo "REJECT: Service at $APP_URL health check failed"
    exit 2
  fi
fi

# All checks passed
exit 0
```

**Benefit**: Automated verification prevents incomplete work from being marked done

**Limitation**: Requires bash scripting, adds complexity

**Verification**: Official feature, limited production examples

**Recommendation**: Add hooks example to devops skill as advanced pattern. Include template for common infrastructure verification checks.

---

### 3.3 Agent Team Configuration in Project CLAUDE.md

**Source**: [wshobson/agents GitHub Repository](https://github.com/wshobson/agents)
**Trust Level**: TIER 3 (Community project, pattern not yet widespread)

**Finding**: Agent teams can be **pre-configured** in project CLAUDE.md:

**Pattern**:
```markdown
# Project CLAUDE.md

## Agent Teams Configuration

### Multi-Cloud Deployment Team

**When to use**: User requests deployment across multiple cloud providers

**Team structure**:
- Lead: deployment-coordinator (delegate mode)
- Teammates:
  - oci-provisioner (provision OCI infrastructure)
  - hetzner-provisioner (provision Hetzner infrastructure)
  - configurator (configure all servers)
  - verifier (verify all deployments)

**Task template**:
1. Provision OCI server (oci-provisioner)
2. Provision Hetzner server (hetzner-provisioner)
3. Configure OCI server (configurator, depends on 1)
4. Configure Hetzner server (configurator, depends on 2)
5. Verify OCI deployment (verifier, depends on 3)
6. Verify Hetzner deployment (verifier, depends on 4)

**Spawn command**:
"Create multi-cloud deployment team. Use delegate mode for lead.
Require plan approval for all provisioning tasks."
```

**Benefits**:
- Standardized team structures for common scenarios
- Consistent task breakdown
- Reduces cognitive load for lead agent
- Project-specific best practices

**Limitations**:
- No examples in official docs yet
- Pattern not widely tested
- May need adjustment per project

**Verification**: Found in community repository, not yet mainstream

**Recommendation**: Add agent team templates to devops skill's references. Start with 2-3 proven patterns (multi-cloud, full-stack deployment, security audit).

---

## Recommended Actions (Priority Order)

### Priority 1: Essential Updates (Do Now)

#### 1.1 Add Agent Teams Architecture to Admin Skill
- **Location**: `skills/admin/references/agent-teams.md` (new file)
- **Content**: TIER 1 findings 1.1, 1.2, 1.8
- **Rationale**: Foundation knowledge for using teams

#### 1.2 Add Decision Matrix to Both Skills
- **Location**: `skills/admin/SKILL.md` and `skills/devops/SKILL.md`
- **Content**: TIER 1 finding 1.2 (subagents vs teams table)
- **Rationale**: Help Claude choose right pattern for each task

#### 1.3 Update Agent Frontmatter to Support Teams
- **Location**: All 5 existing agents (profile-validator, mcp-troubleshooter, tool-installer, server-provisioner, deployment-coordinator)
- **Add field**: `team_compatible: true` (YAML frontmatter)
- **Add section**: "When to Use as Teammate" (markdown body)
- **Rationale**: Mark agents as team-ready

---

### Priority 2: High-Value Additions (Next)

#### 2.1 Create Agent Team Templates
- **Location**: `skills/devops/references/agent-team-patterns.md` (new file)
- **Content**:
  - Multi-cloud provisioning pattern (TIER 2 finding 2.7)
  - Full-stack deployment pattern (TIER 1 finding 1.5)
  - Parallel security audit pattern (TIER 1 finding 1.3)
- **Rationale**: Provide proven templates for common scenarios

#### 2.2 Add Plan-First Workflow to Deployment Coordinator
- **Location**: `skills/devops/agents/deployment-coordinator.md`
- **Content**: TIER 2 finding 2.2 (plan mode → team execution)
- **Rationale**: Prevent expensive team execution on wrong approach

#### 2.3 Add Task Sizing Guidance
- **Location**: `skills/devops/references/agent-team-patterns.md`
- **Content**: TIER 2 finding 2.3 (5-6 tasks per teammate)
- **Rationale**: Help Claude create appropriately-sized work units

---

### Priority 3: Advanced Features (Later)

#### 3.1 Add Quality Gate Hooks
- **Location**: `skills/devops/templates/hooks/` (new directory)
- **Files**:
  - `task_completed_infrastructure.sh`
  - `task_completed_deployment.sh`
  - `teammate_idle_security.sh`
- **Content**: TIER 3 finding 3.2
- **Rationale**: Automated verification for infrastructure tasks

#### 3.2 Create Lead Agent Definition
- **Location**: `skills/devops/agents/infrastructure-lead.md` (new file)
- **Content**: Orchestrator agent that uses delegate mode
- **Rationale**: Dedicated lead for complex multi-agent deployments

#### 3.3 Add Competing Hypotheses Pattern
- **Location**: `skills/admin/references/troubleshooting-patterns.md` (new file)
- **Content**: TIER 3 finding 3.1
- **Rationale**: Advanced debugging pattern for complex issues

---

### Priority 4: Documentation & Examples (Polish)

#### 4.1 Add Token Cost Guidance
- **Location**: `skills/devops/references/agent-teams.md`
- **Content**: TIER 2 finding 2.1 (cost analysis)
- **Rationale**: Help users understand when teams are worth the cost

#### 4.2 Create Example CLAUDE.md with Team Config
- **Location**: `skills/devops/templates/project-claude-md-teams.md`
- **Content**: TIER 3 finding 3.3 (team templates in CLAUDE.md)
- **Rationale**: Show how to pre-configure teams for projects

#### 4.3 Add Context Management Explanation
- **Location**: `skills/devops/references/agent-teams.md`
- **Content**: TIER 2 finding 2.4 (context degradation)
- **Rationale**: Explain WHY teams improve quality

---

## Gap Analysis: What's Missing

### 1. Production Examples for Infrastructure
- **Gap**: No confirmed production use of agent teams for infrastructure/devops
- **Community has**: Code review, debugging, multi-module development
- **Community lacks**: Server provisioning, multi-cloud deployment, infrastructure audits
- **Action**: Create and test patterns, share back to community

### 2. Error Recovery Patterns
- **Gap**: Official docs mention error recovery, but no detailed patterns
- **Needed**: Rollback procedures when teammate fails mid-deployment
- **Action**: Develop and document infrastructure-specific recovery patterns

### 3. Security/Compliance Integration
- **Gap**: No guidance on using teams with security constraints
- **Needed**: How to enforce security policies across teammates
- **Action**: Develop security-aware team patterns with plan approval gates

### 4. Cost Optimization Strategies
- **Gap**: Token cost analysis exists, but no optimization strategies
- **Needed**: How to minimize costs while maintaining team benefits
- **Action**: Test and document cost-effective team configurations

---

## Gotchas & Warnings

### 1. Enable Feature First (CRITICAL)
- ⚠️ Agent teams are **disabled by default**
- Must set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- If not set, spawn commands silently fail
- Add to admin skill's setup documentation

### 2. Session Resumption Broken
- ⚠️ `/resume` does not restore in-process teammates
- Lead may try to message non-existent teammates after resume
- Workaround: Spawn new teammates after resume
- Document in troubleshooting section

### 3. File Ownership Conflicts
- ⚠️ **Data loss risk**: Two teammates editing same file
- No merge conflict detection
- Must architect with clear file boundaries
- Add to deployment-coordinator documentation

### 4. Task Status Lag
- ⚠️ Teammates sometimes forget to mark tasks complete
- Blocks dependent tasks
- Lead must manually verify and update
- Add to agent team patterns documentation

### 5. Token Costs Can Explode
- ⚠️ 3-person team = 2.2x cost of solo
- 5-person team = 5x cost
- Easy to waste tokens on wrong approach
- Use plan-first workflow (Priority 2.2)

### 6. Delegate Mode Not Automatic
- ⚠️ Lead may start implementing instead of delegating
- Must manually enable with `Shift+Tab`
- No programmatic way to force delegate mode
- Document as required step for deployment-coordinator

---

## Next Steps

### Immediate (This Week)
1. ✅ Complete this research document
2. Add agent teams reference to admin skill (Priority 1.1)
3. Update agent frontmatter with team compatibility (Priority 1.3)
4. Add decision matrix to both skills (Priority 1.2)

### Short-Term (This Month)
1. Create agent team patterns reference (Priority 2.1)
2. Update deployment-coordinator with plan-first workflow (Priority 2.2)
3. Test multi-cloud provisioning pattern in production
4. Gather feedback on team patterns

### Long-Term (Next Quarter)
1. Develop quality gate hooks (Priority 3.1)
2. Create infrastructure-lead agent (Priority 3.2)
3. Document cost optimization strategies
4. Share infrastructure team patterns with community

---

## Sources

All findings are sourced from official Anthropic documentation and high-quality community resources:

### Official Sources (TIER 1)
- [Orchestrate teams of Claude Code sessions - Claude Code Docs](https://code.claude.com/docs/en/agent-teams)
- [Eight trends defining how software gets built in 2026 | Claude](https://claude.com/blog/eight-trends-defining-how-software-gets-built-in-2026)

### High-Quality Community (TIER 2)
- [From Tasks to Swarms: Agent Teams in Claude Code | alexop.dev](https://alexop.dev/posts/from-tasks-to-swarms-agent-teams-in-claude-code/)
- [Claude Code Agent Teams: Practical Guide | Addy Osmani](https://addyosmani.com/blog/claude-code-agent-teams/)
- [Claude Code Swarm Orchestration Skill - GitHub Gist](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
- [Claude Code Agent Teams: Multi-Session Orchestration](https://claudefa.st/blog/guide/agents/agent-teams)

### Community Resources (TIER 3)
- [GitHub - wshobson/agents: Intelligent automation and multi-agent orchestration for Claude Code](https://github.com/wshobson/agents)
- [GitHub - ruvnet/claude-flow: Agent orchestration platform for Claude](https://github.com/ruvnet/claude-flow)
- [GitHub - VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)

---

**Research Completed**: 2026-02-11
**Next Review**: 2026-03-11 (monthly check for new patterns/examples)
**Researcher**: community-knowledge-discovery agent
