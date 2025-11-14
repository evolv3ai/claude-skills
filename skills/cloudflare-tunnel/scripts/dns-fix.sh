#!/bin/bash

# DNS Fix Script for Cloudflare Tunnel
# This script fixes DNS resolution issues by ensuring the CNAME record is properly proxied
# Fixes the common DNS_PROBE_FINISHED_NXDOMAIN error

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/../.env}"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo -e "${RED}❌ .env file not found at: $ENV_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}🔧 Fixing DNS Resolution for $TUNNEL_HOSTNAME...${NC}"
echo ""

# Validate required variables
if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_ZONE_ID" ] || [ -z "$DNS_RECORD_ID" ] || [ -z "$TUNNEL_ID" ]; then
    echo -e "${RED}❌ Missing required environment variables${NC}"
    echo "Please run tunnel-setup.sh first, or ensure .env has:"
    echo "  - CLOUDFLARE_API_TOKEN"
    echo "  - CLOUDFLARE_ZONE_ID"
    echo "  - DNS_RECORD_ID"
    echo "  - TUNNEL_ID"
    exit 1
fi

# Step 1: Check current DNS record status
echo -e "${BLUE}🔍 Checking current DNS record status...${NC}"
CURRENT_RECORD=$(curl -s -X GET \
  "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=$TUNNEL_HOSTNAME" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json")

echo "📊 Current record status:"
echo "$CURRENT_RECORD" | grep -o '"type":"[^"]*".*"content":"[^"]*".*"proxied":[^,}]*' | \
    while IFS= read -r line; do
        TYPE=$(echo "$line" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
        CONTENT=$(echo "$line" | grep -o '"content":"[^"]*"' | cut -d'"' -f4)
        PROXIED=$(echo "$line" | grep -o '"proxied":[^,}]*' | cut -d':' -f2)
        echo "   Type: $TYPE, Content: $CONTENT, Proxied: $PROXIED"
    done

echo ""

# Step 2: Update DNS record to enable proxy (orange cloud)
echo -e "${BLUE}🔧 Updating DNS record to enable proxy (orange cloud)...${NC}"
HOSTNAME_PART=$(echo "$TUNNEL_HOSTNAME" | cut -d'.' -f1)

UPDATE_RESULT=$(curl -s -X PATCH \
  "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$DNS_RECORD_ID" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{
    \"type\": \"CNAME\",
    \"name\": \"$HOSTNAME_PART\",
    \"content\": \"$TUNNEL_ID.cfargotunnel.com\",
    \"proxied\": true,
    \"comment\": \"Cloudflare Tunnel - Fixed to enable IPv4/IPv6 resolution\"
  }")

# Check if update was successful
SUCCESS=$(echo "$UPDATE_RESULT" | grep -o '"success":[^,]*' | cut -d':' -f2)
if [ "$SUCCESS" = "true" ]; then
    echo -e "${GREEN}✅ DNS record updated successfully!${NC}"
    echo ""

    # Show updated record details
    echo "📋 Updated record details:"
    echo "$UPDATE_RESULT" | grep -o '"type":"[^"]*".*"content":"[^"]*".*"proxied":[^,}]*' | \
        while IFS= read -r line; do
            TYPE=$(echo "$line" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
            CONTENT=$(echo "$line" | grep -o '"content":"[^"]*"' | cut -d'"' -f4)
            PROXIED=$(echo "$line" | grep -o '"proxied":[^,}]*' | cut -d':' -f2)
            echo "   Type: $TYPE, Content: $CONTENT, Proxied: $PROXIED"
        done
    echo ""

    echo -e "${GREEN}🎉 DNS Fix Complete!${NC}"
    echo ""
    echo "📝 What was fixed:"
    echo "   ❌ Before: CNAME record may not have been proxied (gray cloud)"
    echo "   ✅ After:  CNAME record is now proxied (orange cloud)"
    echo ""
    echo "🌐 Expected results:"
    echo "   • $TUNNEL_HOSTNAME will now resolve to both IPv4 and IPv6 addresses"
    echo "   • Traffic will be secured and accelerated by Cloudflare"
    echo "   • DNS_PROBE_FINISHED_NXDOMAIN errors should be resolved"
    echo ""
    echo "⏱️  DNS propagation time: 5-10 minutes globally"
    echo ""
    echo "🧪 Test the fix:"
    echo "   • Wait 5-10 minutes for DNS propagation"
    echo "   • Try accessing: https://$TUNNEL_HOSTNAME"
    echo "   • Check DNS resolution: nslookup $TUNNEL_HOSTNAME"

else
    echo -e "${RED}❌ Failed to update DNS record${NC}"
    echo "Error details:"
    echo "$UPDATE_RESULT" | grep -o '"message":"[^"]*"' | cut -d'"' -f4 | \
        while IFS= read -r msg; do
            echo "   $msg"
        done
    exit 1
fi

echo ""
echo -e "${GREEN}✅ DNS fix completed successfully!${NC}"
