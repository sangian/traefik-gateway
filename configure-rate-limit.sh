#!/bin/bash
# =============================================================================
# Rate Limiting Configuration Calculator
# =============================================================================
# Calculates appropriate rate limiting values based on server specifications
# Usage: ./configure-rate-limit.sh [output-file]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get server specs
CORES=$(nproc)
TOTAL_MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEMORY_GB=$((TOTAL_MEMORY_KB / 1024 / 1024))

echo -e "${BLUE}=== Rate Limiting Configuration Calculator ===${NC}"
echo -e "${YELLOW}Server Specifications:${NC}"
echo "  CPU Cores: $CORES"
echo "  Total RAM: ${TOTAL_MEMORY_GB}GB"
echo ""

# Calculate rate limiting values
# Formula: Base 100 req/s per core, adjusted by RAM
# Burst: 2x the average 
BASE_PER_CORE=100
AVERAGE_RATE=$((BASE_PER_CORE * CORES))

# Adjust for RAM (small servers get lower limits)
if [[ $TOTAL_MEMORY_GB -lt 2 ]]; then
    AVERAGE_RATE=$((AVERAGE_RATE / 2))
elif [[ $TOTAL_MEMORY_GB -lt 4 ]]; then
    AVERAGE_RATE=$((AVERAGE_RATE * 75 / 100))
fi

BURST_RATE=$((AVERAGE_RATE * 2))

echo -e "${YELLOW}Calculated Rate Limits:${NC}"
echo "  Average: $AVERAGE_RATE req/s"
echo "  Burst: $BURST_RATE req/s"
echo ""

# Calculate API limits (stricter)
API_AVERAGE=$((AVERAGE_RATE / 4))
API_BURST=$((BURST_RATE / 4))

echo -e "${YELLOW}Recommended API Rate Limits (stricter):${NC}"
echo "  Average: $API_AVERAGE req/s"
echo "  Burst: $API_BURST req/s"
echo ""

# Generate or update .env file
echo -e "${GREEN}✓ Add these values to your .env file:${NC}"
echo ""
echo "RATE_LIMIT_AVERAGE=$AVERAGE_RATE"
echo "RATE_LIMIT_BURST=$BURST_RATE"
echo "RATE_LIMIT_API_AVERAGE=$API_AVERAGE"
echo "RATE_LIMIT_API_BURST=$API_BURST"
echo ""
echo -e "${YELLOW}Then restart Traefik:${NC}"
echo "  docker compose up -d"
