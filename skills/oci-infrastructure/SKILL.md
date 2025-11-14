---
name: oci-infrastructure
description: |
  This skill provides complete knowledge for deploying infrastructure on Oracle Cloud Infrastructure (OCI), specializing in cost-effective ARM64 instances (Always Free tier eligible). It should be used when creating OCI compartments, VCNs, subnets, security lists, and compute instances, or when encountering OCI CLI configuration issues and capacity errors.

  Use when: setting up Oracle Cloud infrastructure, deploying ARM64 instances, configuring OCI networking, troubleshooting OUT_OF_HOST_CAPACITY errors, creating compartments and VCNs, optimizing for OCI Always Free tier, setting up secure SSH access to OCI instances.

  Keywords: oracle cloud infrastructure, OCI, ARM64 instances, VM.Standard.A1.Flex, OCI CLI, oci compartment, oci vcn, oci subnet, oci security list, OCI Always Free tier, OUT_OF_HOST_CAPACITY, availability domain OCI, OCI compute instance, cost-effective cloud hosting, ARM cloud instances
license: MIT
---

# Oracle Cloud Infrastructure (OCI)

**Status**: Production Ready
**Last Updated**: 2025-11-13
**Dependencies**: OCI CLI, SSH key pair
**Latest Versions**: OCI CLI 3.x (latest), Ubuntu 22.04 ARM64

---

## Quick Start (10 Minutes)

### 1. Install and Configure OCI CLI

Install the OCI CLI and configure credentials:

```bash
# Install OCI CLI (Linux/macOS)
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Configure OCI CLI (interactive setup)
oci setup config

# Verify installation
oci iam region list

# Test authentication
oci iam availability-domain list --compartment-id <your-tenancy-ocid>
```

**Why this matters:**
- OCI CLI is required for all infrastructure automation
- ARM64 instances (A1.Flex) are eligible for Always Free tier (4 OCPUs, 24GB RAM free!)
- Proper configuration prevents authentication errors

### 2. Create Compartment for Resource Isolation

Compartments organize and isolate resources:

```bash
# Set environment variables
export TENANCY_OCID="ocid1.tenancy.oc1..your_tenancy_ocid"
export COMPARTMENT_NAME="MyProjectCompartment"

# Create compartment
oci iam compartment create \
  --compartment-id $TENANCY_OCID \
  --name $COMPARTMENT_NAME \
  --description "Compartment for my project" \
  --wait-for-state ACTIVE

# Get compartment ID
COMPARTMENT_ID=$(oci iam compartment list \
  --compartment-id $TENANCY_OCID \
  --name $COMPARTMENT_NAME \
  --query 'data[0].id' \
  --raw-output)

echo "Compartment ID: $COMPARTMENT_ID"
```

**CRITICAL:**
- Compartments enable resource organization and access control
- Always create dedicated compartments (don't use tenancy root)
- Save COMPARTMENT_ID for subsequent commands

### 3. Deploy ARM64 Instance (Always Free Tier)

Create a cost-effective ARM64 instance:

```bash
# Quick deploy (uses defaults from scripts/oci-setup.sh)
bash scripts/oci-setup.sh

# Or manually:
oci compute instance launch \
  --compartment-id $COMPARTMENT_ID \
  --availability-domain <AD-name> \
  --display-name "MyInstance" \
  --image-id <ubuntu-arm64-image-id> \
  --subnet-id $SUBNET_ID \
  --shape VM.Standard.A1.Flex \
  --shape-config '{"ocpus":4,"memoryInGBs":24}' \
  --assign-public-ip true \
  --ssh-authorized-keys-file ~/.ssh/id_rsa.pub \
  --wait-for-state RUNNING
```

---

## Known Issues Prevention

This skill prevents **6** documented issues:

### Issue #1: OUT_OF_HOST_CAPACITY Error
**Error**: "Out of host capacity" when launching ARM64 instances
**Source**: OCI capacity limitations in specific availability domains
**Why It Happens**: ARM64 Always Free instances highly utilized in some ADs
**Prevention**: Try different availability domains, check capacity with bundled script

### Issue #2: OCI CLI Not Found
**Error**: "oci: command not found"
**Source**: OCI CLI not installed or not in PATH
**Why It Happens**: Fresh system without OCI CLI
**Prevention**: Install OCI CLI via official script, add to PATH

### Issue #3: Authentication Failed
**Error**: "ServiceError: NotAuthenticated"
**Source**: OCI CLI not configured with valid credentials
**Why It Happens**: Missing or incorrect ~/.oci/config
**Prevention**: Run `oci setup config` to configure credentials

### Issue #4: Subnet Not Internet-Accessible
**Error**: Cannot SSH to instance despite security rules
**Source**: Missing internet gateway or route table configuration
**Why It Happens**: Subnet created without internet gateway route
**Prevention**: Create IGW and add 0.0.0.0/0 route to default route table

### Issue #5: Instance Won't Launch (Shape Not Available)
**Error**: "Shape VM.Standard.A1.Flex not available"
**Source**: Requesting incompatible image/shape combination
**Why It Happens**: Using x86 image with ARM shape or vice versa
**Prevention**: Match image architecture to shape (ARM64 image for A1.Flex)

### Issue #6: Exceeded Always Free Tier Limits
**Error**: "Service limit exceeded" when creating A1 instances
**Source**: Total OCPUs/memory exceeds 4 OCPU / 24GB free tier limit
**Why It Happens**: Already have A1 instances using free tier allocation
**Prevention**: Check existing instances, stay within 4 OCPU + 24GB total

---

## Critical Rules

### Always Do

✅ **Use VM.Standard.A1.Flex for Always Free tier** - ARM64 instances eligible for free tier
✅ **Check availability domain capacity** - Use different ADs if OUT_OF_HOST_CAPACITY
✅ **Create dedicated compartments** - Never deploy to tenancy root
✅ **Use 10.0.0.0/8 private IP ranges** - Avoid conflicts with other networks
✅ **Enable internet gateway** - Required for outbound internet access
✅ **Add SSH security rule** - Port 22 must be open for remote access
✅ **Save all OCIDs** - Compartment, VCN, subnet, instance IDs needed for updates

### Never Do

❌ **Never use x86 shapes for Always Free** - Only ARM64 (A1.Flex) qualifies
❌ **Never exceed Always Free limits** - 4 OCPUs, 24GB RAM total across all A1 instances
❌ **Never delete compartment with resources** - Delete all resources first
❌ **Never use overlapping CIDR blocks** - Each VCN needs unique IP range
❌ **Never forget egress rules** - Outbound traffic must be allowed
❌ **Never hardcode OCIDs** - Use environment variables or config files
❌ **Never skip --wait-for-state** - Resources must reach ACTIVE/AVAILABLE before use

---

## Official Documentation

- **OCI Documentation**: https://docs.oracle.com/en-us/iaas/Content/home.htm
- **OCI CLI Reference**: https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/
- **Always Free Tier**: https://www.oracle.com/cloud/free/
- **ARM Instances Guide**: https://docs.oracle.com/en-us/iaas/Content/Compute/References/arm.htm

---

## Production Example

This skill is based on **vibestack** project:
- **Infrastructure**: Oracle Cloud ARM instances (A1.Flex)
- **Services**: KASM Workspaces + Coolify deployed
- **Cost**: $0/month (Always Free tier)
- **Performance**: 4 OCPU + 24GB RAM = Excellent for self-hosted apps
- **Validation**: ✅ Multiple successful deployments across availability domains
