# Infrastructure Skills - Quick Reference (Zoom Call)

**1-page cheat sheet for presentation**

---

## The 4 Skills (30-Second Overview)

| Skill | What It Does | Key Script | Main Error Prevented |
|-------|--------------|------------|---------------------|
| **cloudflare-tunnel** | Expose services without inbound ports | `tunnel-setup.sh` (10 steps) | DNS_PROBE_FINISHED_NXDOMAIN |
| **oci-infrastructure** | Deploy Oracle Cloud ARM64 (Free) | `check-oci-capacity.sh` | OUT_OF_HOST_CAPACITY |
| **coolify** | Install self-hosted PaaS | `coolify-installation.sh` | Docker/firewall issues |
| **kasm-workspaces** | Deploy VDI platform | `kasm-installation.sh` | ARM64 compatibility |

**Together**: Complete infrastructure stack in 45 minutes (vs 2 days manual)

---

## Essential Building Blocks (What Every Skill Needs)

### 1. YAML Frontmatter (Discovery)
```yaml
name: cloudflare-tunnel
description: |
  Use when: exposing self-hosted applications, fixing DNS errors
  Keywords: cloudflare tunnel, DNS_PROBE_FINISHED_NXDOMAIN
```

### 2. README.md (Keywords)
- Error-based triggers: "OUT_OF_HOST_CAPACITY"
- Use case triggers: "self-hosted PaaS"

### 3. SKILL.md (Knowledge)
- Quick Start (10-20 min)
- Known Issues (numbered with sources)
- Critical Rules (Always ✅ / Never ❌)
- Bundled Scripts (documented)

### 4. scripts/ (Automation)
- Production-tested
- Saves credentials
- Zero manual steps

### 5. assets/ (Templates)
- Config files
- .env templates

---

## Key Metrics (The Numbers That Matter)

- **Token Savings**: 68.5% average
- **Errors Prevented**: 27 (100% prevention)
- **Setup Time**: 85% faster
- **Scripts**: 21 total (228KB automation)
- **Production Validation**: 6+ months (vibestack)

---

## Demo Flow (15 minutes total)

### Demo 1: Discovery (3 min)
Type: "Expose my app with Cloudflare tunnel"
Show: Claude mentions skill, suggests scripts, warns about errors

### Demo 2: Structure (5 min)
Show files: SKILL.md (31KB), tunnel-setup.sh (10 steps), config-https.yml

### Demo 3: Efficiency (3 min)
Compare: 12k tokens manual vs 4k with skill

### Demo 4: Integration (4 min)
Show: OCI + Coolify + Tunnel working together

---

## Best Practices (What Works)

✅ **Third-person**: "This skill provides..." (not "Use this...")
✅ **Time estimates**: "Quick Start (10 Minutes)"
✅ **Numbered errors**: "Prevents 6 documented issues"
✅ **Always/Never format**: Clear rules
✅ **Production proof**: "Based on vibestack (6+ months)"
✅ **Error keywords**: DNS_PROBE_FINISHED_NXDOMAIN in description
✅ **Script docs**: Document features, creates, output

---

## Real-World Example (vibestack)

**Stack**:
- Oracle Cloud ARM64 (4 OCPU, 24GB RAM - $0/month)
- Coolify (self-hosted PaaS)
- KASM Workspaces (VDI)
- Cloudflare Tunnel (secure access)

**Before Skills**: 2 days setup, 12+ errors
**With Skills**: 45 minutes, 0 errors

**ROI**: 28 hours building → saves 4 hours per deployment → break-even at 7 deployments

---

## Q&A Quick Answers

**"Why not just use docs?"**
→ Docs don't prevent errors. Skills include production mistakes + fixes.

**"How long to build?"**
→ 6-8 hours per skill (if you already have production code to extract from)

**"How measure token savings?"**
→ Test without skill, test with skill, compare tokens + errors

**"Can others use?"**
→ Yes! Same tech stack = same value

---

## Closing Points (Last 2 Minutes)

1. **Skills = Production Knowledge Packages**
   - Not theoretical - extracted from real deployments

2. **Building Blocks Are Simple**
   - YAML + README + SKILL.md + scripts

3. **Impact Is Measurable**
   - 68.5% token savings, 100% error prevention

4. **Value Compounds**
   - 1 build → infinite reuse by you + others

**Share**: github.com/jezweb/claude-skills
