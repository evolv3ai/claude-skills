# Infrastructure Skills - Presentation Overview

**Date**: 2025-11-14
**Presenter**: Jeremy Dawes | Jezweb
**Topic**: Claude Code Skills - Infrastructure & Deployment Examples
**Skills Covered**: cloudflare-tunnel, oci-infrastructure, coolify, kasm-workspaces

---

## What Are Claude Code Skills?

**Definition**: Modular knowledge packages that extend Claude's expertise in specific domains

**Purpose**:
- Reduce token usage by 60-70% vs manual setup
- Prevent 100% of documented errors
- Speed up deployments from hours to minutes
- Share production-validated knowledge

**How They Work**:
1. Skills live in `~/.claude/skills/` directory
2. Claude auto-discovers them based on keywords
3. Loads full knowledge only when relevant
4. Composes multiple skills automatically for complex tasks

---

## The 4 Infrastructure Skills

### Overview Table

| Skill | Purpose | Scripts | Tokens Saved | Errors Prevented |
|-------|---------|---------|--------------|------------------|
| **cloudflare-tunnel** | Secure service exposure (no inbound ports) | 2 (20.5KB) | 67% | 8 |
| **oci-infrastructure** | Oracle Cloud ARM64 deployment (Always Free) | 6 (84KB) | 67% | 6 |
| **coolify** | Self-hosted PaaS (open-source Heroku) | 6 (40KB) | 70% | 6 |
| **kasm-workspaces** | Virtual Desktop Infrastructure (VDI) | 7 (80KB) | 70% | 7 |
| **Total** | **Complete infrastructure stack** | **21 (228KB)** | **68.5% avg** | **27 total** |

---

## Production Context: The vibestack Project

**What is vibestack?**
- Real production deployment running for 6+ months
- Oracle Cloud ARM64 instance (4 OCPU, 24GB RAM - $0/month Always Free tier)
- Runs KASM Workspaces VDI + Coolify PaaS
- Exposed via Cloudflare Tunnel (no public IP needed)
- Hosts multiple apps: Next.js, Node.js, Docker containers

**Why This Matters**:
- These skills aren't theoretical - they're extracted from working production code
- Every error documented was actually encountered and fixed
- Scripts have been battle-tested in real deployments
- Token savings measured against actual setup experiences

---

## Essential Building Blocks of Skills

### 1️⃣ YAML Frontmatter (Metadata)

**Purpose**: Help Claude discover the skill contextually

**Example from cloudflare-tunnel:**
```yaml
---
name: cloudflare-tunnel
description: |
  This skill provides complete knowledge for creating and managing Cloudflare Tunnels
  to securely expose any self-hosted service without opening inbound firewall ports.

  Use when: exposing self-hosted applications securely, eliminating inbound port
  requirements, setting up Cloudflare tunnel for KASM/Coolify/web apps, configuring
  tunnel daemon with systemd, fixing DNS PROBE FINISHED NXDOMAIN errors.

  Keywords: cloudflare tunnel, cloudflared, secure tunnel, no inbound ports,
  self-hosted service exposure, tunnel ingress, DNS CNAME cloudflare,
  cfargotunnel.com, tunnel credentials, systemd cloudflared service
license: MIT
---
```

**Key Elements**:
- `name`: Lowercase hyphen-case (matches directory name)
- `description`: Third-person, includes "Use when" scenarios
- `keywords`: Comprehensive (technologies, use cases, error messages)
- `license`: MIT

**Why "Use when" scenarios matter**:
- Helps Claude understand WHEN to suggest this skill
- Specific triggers: "exposing self-hosted", "no inbound ports", "DNS CNAME cloudflare"
- Error-based triggers: "DNS PROBE FINISHED NXDOMAIN" auto-loads skill

---

### 2️⃣ README.md (Auto-Trigger Keywords)

**Purpose**: Additional keywords for discovery (not loaded into context initially)

**Example from oci-infrastructure:**
```markdown
# Oracle Cloud Infrastructure (OCI) Skill

**Auto-Trigger Keywords**:
- oracle cloud infrastructure, OCI, ARM64 instances, VM.Standard.A1.Flex
- OCI CLI, oci compartment, oci vcn, oci subnet
- OUT_OF_HOST_CAPACITY, availability domain OCI, OCI Always Free tier
- cost-effective cloud hosting, ARM cloud instances

**Error-Based Triggers**:
- "OUT_OF_HOST_CAPACITY" - Most common OCI Always Free error
- "OCI CLI not found"
- "Authentication failed" with OCI
```

**Token Efficiency Strategy**:
- README.md is smaller (~3-9KB)
- SKILL.md is comprehensive (~30KB for cloudflare-tunnel, ~10KB for oci-infrastructure)
- Claude only loads SKILL.md body when skill is actually needed

---

### 3️⃣ SKILL.md (The Knowledge Base)

**Structure** (all 4 skills follow this pattern):

#### Section 1: Quick Start (10-20 minutes)
```markdown
## Quick Start (10 Minutes)

### 1. Install OCI CLI
[Step-by-step commands]

### 2. Create Compartment
[Exact commands with explanations]

### 3. Deploy ARM64 Instance
[Production-ready configuration]
```

**Why this matters**: Gets users running fast, specific time estimates build trust

---

#### Section 2: Known Issues Prevention

**Example from oci-infrastructure:**
```markdown
## Known Issues Prevention

This skill prevents **6** documented issues:

### Issue #1: OUT_OF_HOST_CAPACITY Error
**Error**: "Out of host capacity" when launching ARM64 instances
**Source**: OCI capacity limitations in specific availability domains
**Why It Happens**: ARM64 Always Free instances highly utilized in some ADs
**Prevention**: Try different availability domains, check capacity with bundled script
```

**Pattern**:
- Numbered issues with exact counts
- Error message (what user sees)
- Source (root cause)
- Why it happens (explanation)
- Prevention (how skill solves it)

**Real Example from vibestack**:
- OUT_OF_HOST_CAPACITY error stopped deployment for 2 weeks
- Built check-oci-capacity.sh to scan all availability domains
- Built monitor-and-deploy.sh to auto-deploy when capacity found
- Now documented in skill - others avoid this 2-week delay

---

#### Section 3: Critical Rules

**Example from cloudflare-tunnel:**
```markdown
## Critical Rules

### Always Do
✅ **Set proxied=true in DNS CNAME** - Required for tunnel to work
✅ **Use noTLSVerify for self-signed certs** - KASM/Coolify use self-signed SSL
✅ **Wait 60 seconds after tunnel creation** - DNS propagation delay
✅ **Save tunnel credentials** - Cannot be retrieved later

### Never Do
❌ **Never delete tunnel while active** - Breaks existing connections
❌ **Never use proxied=false** - Tunnel won't route traffic
❌ **Never expose tunnel token publicly** - Security risk
```

**Why this format**:
- Checkbox format easy to scan during implementation
- "Always" vs "Never" creates clear mental model
- Specific technical details (proxied=true, noTLSVerify)
- Each rule learned from production mistakes

---

#### Section 4: Bundled Scripts

**Example from coolify skill:**
```markdown
## Bundled Scripts

This skill includes 6 production-tested automation scripts:

### 1. **coolify-installation.sh** - Complete Installation
Full Docker and Coolify installation automation for OCI ARM64 instances.

```bash
# Automated Coolify installation
./scripts/coolify-installation.sh
```

**Features:**
- System verification and updates
- Docker CE installation with Compose Plugin
- Coolify installation via official script
- Firewall configuration (ports 8000, 80, 443, 6001, 6002)
- Service health verification
- Admin credentials extraction and saving
- Post-install testing and validation

**Creates:**
- Coolify web interface on port 8000
- Traefik proxy on ports 80/443
- Docker networks and volumes
- Admin access file: `coolify-access.txt`
```

**Key Pattern**: Each script documented with:
- Purpose (one-line description)
- Usage command
- Features (bullet list)
- Creates/Output (what it produces)

---

### 4️⃣ Bundled Resources (Scripts, Templates, References)

**Directory Structure** (cloudflare-tunnel example):
```
cloudflare-tunnel/
├── SKILL.md                          # Knowledge base (31KB)
├── README.md                         # Auto-trigger keywords (9KB)
├── scripts/                          # Automation (20.5KB total)
│   ├── tunnel-setup.sh              # 10-step automated setup (16KB)
│   └── dns-fix.sh                   # DNS troubleshooting (4.5KB)
├── assets/                           # Configuration templates (13KB)
│   ├── env-template                 # Environment variables (2.6KB)
│   ├── config-http.yml              # HTTP service config (2.5KB)
│   ├── config-https.yml             # HTTPS service config (2.8KB)
│   └── multi-service.yml            # Multi-service routing (4.1KB)
└── references/                       # Empty (placeholder for docs)
```

**Script Example** (tunnel-setup.sh - 10-step automation):

```bash
#!/bin/bash
# Complete Cloudflare Tunnel Setup (10 Steps)
# Automates: tunnel creation, DNS config, service setup, systemd integration

# Step 1: Validate environment variables
echo "Step 1/10: Validating environment variables..."
required_vars=(
    "CLOUDFLARE_API_TOKEN"
    "CLOUDFLARE_ACCOUNT_ID"
    "TUNNEL_NAME"
    "TUNNEL_HOSTNAME"
    "SERVICE_IP"
    "SERVICE_PORT"
)
# [validation logic...]

# Step 2: Install cloudflared
echo "Step 2/10: Installing cloudflared..."
# [ARM64 detection and download...]

# Step 3: Create tunnel via API
echo "Step 3/10: Creating tunnel..."
TUNNEL_ID=$(curl -X POST "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"name\":\"$TUNNEL_NAME\",\"tunnel_secret\":\"$TUNNEL_SECRET\"}" | \
  jq -r '.result.id')

# Step 4: Get tunnel token
# Step 5: Create DNS CNAME record (with proxied=true!)
# Step 6: Create tunnel config.yml
# Step 7: Create systemd service
# Step 8: Start tunnel service
# Step 9: Verify tunnel is running
# Step 10: Test DNS resolution

echo "✅ Tunnel setup complete!"
echo "Public URL: https://$TUNNEL_HOSTNAME"
echo "Routing to: $SERVICE_PROTOCOL://$SERVICE_IP:$SERVICE_PORT"
```

**Why Full Automation Matters**:
- vibestack setup: Manual = 4 hours + 3 errors
- With script: 15 minutes, zero errors
- Token savings: ~67% (Claude just runs script vs debugging setup)

---

### 5️⃣ Configuration Templates

**Example** (cloudflare-tunnel/assets/config-https.yml):

```yaml
# Cloudflare Tunnel Configuration for HTTPS Services
# Use for: KASM Workspaces (8443), Admin Panels with SSL
#
# CRITICAL: Set noTLSVerify: true for self-signed certificates!

tunnel: YOUR_TUNNEL_ID_HERE
credentials-file: /etc/cloudflared/YOUR_TUNNEL_ID.json

ingress:
  # HTTPS service (self-signed certificate)
  - hostname: YOUR_HOSTNAME_HERE
    service: https://SERVICE_IP:SERVICE_PORT
    originRequest:
      noTLSVerify: true        # CRITICAL for self-signed certs
      connectTimeout: 30s
      httpHostHeader: SERVICE_IP

  # Catch-all rule (required by Cloudflare)
  - service: http_status:404
```

**Key Features**:
- Inline comments explain CRITICAL settings
- ALL_CAPS placeholders are obvious
- Real-world context (KASM Workspaces uses this)
- Explains WHY settings matter (noTLSVerify for self-signed)

---

## How These 4 Skills Work Together

### Real-World Deployment Flow (vibestack)

**Goal**: Deploy VDI + PaaS on Oracle Cloud for $0/month

**Step 1**: Check OCI Capacity
```bash
# User asks: "Deploy ARM64 instance on OCI"
# Claude loads: oci-infrastructure skill
# Claude suggests: ./scripts/check-oci-capacity.sh

# Output:
Availability Domain: AD-1 ✓ AVAILABLE (4 OCPU, 24GB RAM)
Availability Domain: AD-2 ✗ OUT OF CAPACITY
Availability Domain: AD-3 ✗ OUT OF CAPACITY
```

**Step 2**: Deploy OCI Infrastructure
```bash
# Claude runs: ./scripts/oci-infrastructure-setup.sh
# Creates: Compartment, VCN, Subnet, Instance
# Output: Instance IP: 123.45.67.89
```

**Step 3**: Install Coolify
```bash
# User asks: "Install Coolify on this instance"
# Claude loads: coolify skill
# Claude runs: ./scripts/coolify-installation.sh

# Output:
Coolify web interface: http://123.45.67.89:8000
Admin credentials saved to: coolify-access.txt
```

**Step 4**: Expose Coolify via Tunnel
```bash
# User asks: "Make Coolify accessible at coolify.mydomain.com"
# Claude loads: cloudflare-tunnel skill
# Claude runs: ./scripts/tunnel-setup.sh

# Sets:
SERVICE_IP=localhost
SERVICE_PORT=8000
SERVICE_PROTOCOL=http
TUNNEL_HOSTNAME=coolify.mydomain.com

# Output: Tunnel active at https://coolify.mydomain.com
```

**Step 5**: Install KASM Workspaces
```bash
# User asks: "Set up KASM Workspaces for VDI"
# Claude loads: kasm-workspaces skill
# Claude runs: ./scripts/kasm-installation.sh

# Output: KASM running on port 8443 (HTTPS)
```

**Step 6**: Expose KASM via Tunnel
```bash
# Claude loads: cloudflare-tunnel skill again
# Uses config-https.yml template (noTLSVerify for self-signed cert)
# Creates: https://kasm.mydomain.com -> https://localhost:8443
```

**Total Time**: 45 minutes (vs 2 days manual setup)
**Total Errors**: 0 (vs ~12 without skills)
**Cost**: $0/month (OCI Always Free tier)

---

## Token Efficiency Deep Dive

### Without Skills (Manual Setup)

**Scenario**: "Deploy Coolify on Oracle Cloud"

**Conversation Flow**:
1. User: "How do I deploy Coolify on OCI?"
2. Claude: "First, set up OCI CLI..." [3,000 tokens]
3. User: "Got error: OUT_OF_HOST_CAPACITY"
4. Claude: "This is common, try..." [2,000 tokens, wrong solution]
5. User: "Still not working"
6. Claude: "Let's try different AD..." [2,000 tokens]
7. User: "How do I install Docker on ARM64?"
8. Claude: "Here's the process..." [2,500 tokens]
9. User: "Coolify web interface not loading"
10. Claude: "Check firewall..." [2,500 tokens]

**Total**: ~12,000 tokens, 2-3 hours, 3+ errors

---

### With Skills (Automated)

**Scenario**: Same - "Deploy Coolify on Oracle Cloud"

**Conversation Flow**:
1. User: "Deploy Coolify on Oracle Cloud"
2. Claude: *[Loads oci-infrastructure + coolify skills]*
3. Claude: "I'll check OCI capacity first (prevents OUT_OF_HOST_CAPACITY), then deploy. Run: ./scripts/check-oci-capacity.sh"
4. User: "Capacity found in AD-1"
5. Claude: "Great! Now deploying with ./scripts/oci-infrastructure-setup.sh && ./scripts/coolify-installation.sh"
6. [Scripts run automatically - Docker, Coolify, firewall all configured]
7. Claude: "Done! Coolify at http://IP:8000, credentials in coolify-access.txt"

**Total**: ~4,000 tokens, 15 minutes, 0 errors

**Savings**: 67% tokens, 90% time, 100% errors prevented

---

## Key Patterns Demonstrated

### Pattern 1: Capacity Checking Before Deployment

**Problem**: OUT_OF_HOST_CAPACITY wastes hours of setup time

**Solution** (oci-infrastructure):
```bash
# ALWAYS check capacity FIRST
./scripts/check-oci-capacity.sh

# If no capacity, use monitor
./scripts/monitor-and-deploy.sh --stack-id <STACK_OCID>
# Polls every 3 minutes, auto-deploys when capacity found
```

**Why This Matters**:
- Without skill: Try deploy → fail → retry → fail → give up
- With skill: Check first → deploy when ready → success
- Saved vibestack project 2 weeks of frustration

---

### Pattern 2: Credentials Management

**Problem**: Credentials lost after installation (can't be retrieved)

**Solution** (all 4 skills):
```bash
# cloudflare-tunnel saves:
/etc/cloudflared/credentials.json
~/.cloudflared/config.yml

# coolify saves:
coolify-access.txt (admin credentials)

# kasm-workspaces saves:
kasm-credentials.txt (admin + database passwords)

# oci-infrastructure saves:
# All OCIDs to environment variables
```

**Pattern**: Every script that generates credentials SAVES them immediately

---

### Pattern 3: DNS Troubleshooting

**Problem**: DNS_PROBE_FINISHED_NXDOMAIN error (most common tunnel issue)

**Solution** (cloudflare-tunnel):
```bash
# Dedicated troubleshooting script
./scripts/dns-fix.sh

# Checks:
1. CNAME record exists?
2. CNAME points to correct tunnel hostname?
3. proxied=true flag set? (CRITICAL!)
4. DNS propagated? (60-second delay)
5. Tunnel hostname format correct?
```

**Why Separate Script**:
- Error happens AFTER initial setup
- Users need quick fix, not full reinstall
- Script runs all checks in 30 seconds

---

### Pattern 4: Service-Specific Configurations

**Problem**: HTTP vs HTTPS services need different tunnel configs

**Solution** (cloudflare-tunnel templates):

**For HTTP** (Coolify):
```yaml
# config-http.yml
ingress:
  - hostname: coolify.domain.com
    service: http://localhost:8000
```

**For HTTPS with self-signed cert** (KASM):
```yaml
# config-https.yml
ingress:
  - hostname: kasm.domain.com
    service: https://localhost:8443
    originRequest:
      noTLSVerify: true    # CRITICAL for self-signed!
```

**Pattern**: Templates for each common use case

---

### Pattern 5: Production Validation Documentation

**Every skill includes production example**:

```markdown
## Production Example

This skill is based on **vibestack** project:
- **Infrastructure**: Oracle Cloud ARM64 instance (A1.Flex, 4 OCPU, 24GB RAM)
- **Coolify Version**: 4.x (latest stable)
- **Deployed Apps**: Multiple Next.js and Node.js applications
- **Cost**: $0/month (OCI Always Free tier)
- **Access Method**: Cloudflare Tunnel (secure external access)
- **Performance**: Excellent - handles 10+ concurrent deployments
- **Validation**: ✅ Production-tested for 6+ months
```

**Why This Matters**:
- Not theoretical - actually works in production
- Specific versions documented (Coolify 4.x, Docker 24.x+)
- Performance metrics (10+ concurrent deployments)
- Time validation (6+ months production use)

---

## Building Blocks Summary

### Essential Components (All 4 Skills Have These)

| Component | Purpose | Size | Example |
|-----------|---------|------|---------|
| **YAML Frontmatter** | Discovery metadata | ~20 lines | `name`, `description`, `keywords` |
| **README.md** | Auto-trigger keywords | 3-9KB | Error triggers, use case keywords |
| **SKILL.md** | Complete knowledge | 10-31KB | Quick Start, Known Issues, Critical Rules |
| **scripts/** | Automation | 20-84KB | Installation, troubleshooting, cleanup |
| **assets/** | Templates | 0-13KB | Config files, env templates |
| **references/** | Optional docs | 0KB | Placeholder (unused in these skills) |

### Content Patterns (What Makes Skills Effective)

1. **Third-Person Descriptions** - "This skill provides..." (not "Use this skill...")
2. **"Use when" Scenarios** - Specific triggers for auto-discovery
3. **Error-Based Keywords** - OUT_OF_HOST_CAPACITY, DNS_PROBE_FINISHED_NXDOMAIN
4. **Numbered Issue Lists** - "This skill prevents 6 documented issues"
5. **Critical Rules Format** - Always Do ✅ / Never Do ❌
6. **Time Estimates** - "Quick Start (10 Minutes)"
7. **Production Validation** - "Based on vibestack project"
8. **Script Documentation** - Features, Creates, Output for each script

---

## Metrics Summary

### Token Efficiency
| Skill | Manual Tokens | With Skill | Savings |
|-------|---------------|------------|---------|
| cloudflare-tunnel | ~12,000 | ~4,000 | 67% |
| oci-infrastructure | ~12,000 | ~4,000 | 67% |
| coolify | ~10,000 | ~3,000 | 70% |
| kasm-workspaces | ~15,000 | ~4,500 | 70% |
| **Average** | **~12,250** | **~3,875** | **68.5%** |

### Error Prevention
| Skill | Errors Without Skill | With Skill | Prevention Rate |
|-------|---------------------|------------|-----------------|
| cloudflare-tunnel | 8 | 0 | 100% |
| oci-infrastructure | 6 | 0 | 100% |
| coolify | 6 | 0 | 100% |
| kasm-workspaces | 7 | 0 | 100% |
| **Total** | **27** | **0** | **100%** |

### Automation Impact
| Metric | Without Skills | With Skills | Improvement |
|--------|---------------|-------------|-------------|
| Setup Time | 4-8 hours | 15-45 min | 85-90% faster |
| Credentials Lost | Common | Never | 100% prevented |
| Capacity Errors | Frequent | Checked first | 100% avoided |
| DNS Issues | Trial & error | Scripted fix | 95% faster resolution |

---

## Q&A Preparation

### Common Questions

**Q: Why not just use official documentation?**

A: Official docs are comprehensive but not error-aware. Skills include:
- Common mistakes to avoid (learned from production)
- Error prevention (OUT_OF_HOST_CAPACITY checking)
- Integrated workflows (OCI + Coolify + Tunnel together)
- Time-saving automation (scripts do the work)

**Q: How long does it take to build a skill?**

A: These 4 skills: 28 hours total (6-8 hours each)
- Research: Extract from production code (vibestack)
- Writing: SKILL.md, README.md, documenting scripts
- Testing: Install locally, verify auto-discovery
- Already had scripts (from vibestack), just documented them

**Q: How do you measure token savings?**

A: Real testing:
1. Fresh session, ask Claude to set up Coolify manually
2. Count tokens used, errors encountered
3. Fresh session, install coolify skill, ask same question
4. Compare tokens and errors

**Q: What's the return on investment?**

A: For vibestack project:
- 28 hours building skills
- Saves ~4 hours per deployment
- After 7 deployments: Break-even
- Additional value: Others can use skills too

**Q: Can skills be updated?**

A: Yes! Skills are just directories:
- Update SKILL.md with new knowledge
- Add new scripts
- Claude loads latest version each session
- vibestack updates flow back to skills

**Q: Do skills work for others?**

A: Yes, if they have same tech stack:
- OCI ARM64 instances → oci-infrastructure skill
- Coolify on any server → coolify skill
- Cloudflare Tunnel → cloudflare-tunnel skill
- Sharing knowledge = compounding value

---

## Demo Script (For Zoom Call)

### Demo 1: Show Skill Discovery (3 minutes)

**Screen Share**: Open Claude Code

**Say**: "Let me show you how skills work. I'll ask Claude to set up a Cloudflare tunnel."

**Type**: "Help me expose my local web app using a Cloudflare tunnel"

**Point Out**:
- Claude mentions "cloudflare-tunnel skill"
- References specific scripts (tunnel-setup.sh)
- Warns about DNS_PROBE_FINISHED_NXDOMAIN
- Suggests noTLSVerify for self-signed certs

**Say**: "Notice Claude didn't just give generic advice - it loaded production-tested knowledge from the skill."

---

### Demo 2: Show Skill Structure (5 minutes)

**Screen Share**: File explorer

**Navigate to**: `~/.claude/skills/cloudflare-tunnel/`

**Show**:
1. **SKILL.md**: "This is the knowledge base - 31KB of setup instructions, known issues, and critical rules"
2. **scripts/tunnel-setup.sh**: "This is the 10-step automation - Claude can run this instead of manually configuring"
3. **assets/config-https.yml**: "This is a template for HTTPS services with self-signed certs - KASM Workspaces uses this"

**Point Out**:
- All learned from vibestack production deployment
- Every error was encountered, fixed, and documented
- Templates are exactly what worked in production

---

### Demo 3: Show Token Efficiency (3 minutes)

**Screen Share**: Show comparison document

**Before (Without Skill)**:
```
User: "How do I set up a Cloudflare tunnel?"
Claude: [Long explanation of cloudflared installation...]
User: "I got DNS_PROBE_FINISHED_NXDOMAIN"
Claude: [Troubleshooting steps...]
User: "Still not working"
Claude: [More debugging...]
Total: ~12,000 tokens, 2-3 errors
```

**After (With Skill)**:
```
User: "Set up Cloudflare tunnel"
Claude: [Loads skill] "Run ./scripts/tunnel-setup.sh with these env vars..."
User: "Done! Tunnel is up"
Total: ~4,000 tokens, 0 errors
```

**Say**: "That's 67% fewer tokens and zero errors - because the skill has production knowledge built-in."

---

### Demo 4: Show Integration (4 minutes)

**Screen Share**: Show how skills compose

**Scenario**: "Deploy Coolify on OCI"

**Show**:
1. **oci-infrastructure** skill loads first
   - Checks capacity (prevents OUT_OF_HOST_CAPACITY)
   - Deploys compartment, VCN, instance

2. **coolify** skill loads second
   - Installs Docker
   - Installs Coolify
   - Configures firewall

3. **cloudflare-tunnel** skill loads third
   - Creates tunnel
   - Sets up DNS CNAME
   - Exposes Coolify publicly

**Say**: "Claude automatically composed 3 skills to complete a complex deployment - that's the power of modular knowledge."

---

## Key Takeaways (Closing Slide)

### What Makes These Skills Effective?

1. **Production-Validated** - Extracted from 6+ months of vibestack deployments
2. **Error-Aware** - Documents 27 errors and how to prevent them
3. **Fully Automated** - 21 scripts (228KB) do the work
4. **Token-Efficient** - 68.5% average savings
5. **Composable** - Skills work together for complex workflows

### Essential Building Blocks

1. **YAML Frontmatter** - Discovery metadata with "Use when" scenarios
2. **README.md** - Auto-trigger keywords (including error messages)
3. **SKILL.md** - Complete knowledge (Quick Start, Known Issues, Critical Rules)
4. **scripts/** - Production-tested automation
5. **assets/** - Configuration templates

### Best Practices Demonstrated

- ✅ Third-person descriptions
- ✅ Specific time estimates ("Quick Start (10 Minutes)")
- ✅ Numbered issue lists with sources
- ✅ Always Do / Never Do format
- ✅ Production validation evidence
- ✅ Complete script documentation
- ✅ Error-based auto-trigger keywords

### ROI: vibestack Project

- **Investment**: 28 hours building 4 skills
- **Savings**: ~4 hours per deployment
- **Break-even**: 7 deployments
- **Bonus**: Shareable with others (compounding value)

---

## Additional Resources

- **Skills Repository**: https://github.com/jezweb/claude-skills
- **Official Anthropic Skills**: https://github.com/anthropics/skills
- **vibestack**: Production deployment (6+ months)
- **Contact**: jeremy@jezweb.net

---

**End of Presentation**
