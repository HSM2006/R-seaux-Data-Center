#!/bin/bash

###############################################################################
# Setup Script pour gNMI Telemetry Stack - SAE DevCloud 4D01
# 
# Usage: bash setup-gnmi.sh
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Paths
TELEMETRY_DIR="${HOME}/telemetry"
GRAFANA_PROVISIONING="${TELEMETRY_DIR}/grafana-provisioning/datasources"

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   gNMI Telemetry Stack Setup${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Step 1: Check Prerequisites
echo -e "\n${YELLOW}[1/5] Checking prerequisites...${NC}"

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 not found. Please install it first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ $1 found${NC}"
}

check_command "docker"
check_command "docker-compose"
check_command "python3"

# Step 2: Create Directory Structure
echo -e "\n${YELLOW}[2/5] Creating directory structure...${NC}"

mkdir -p "${TELEMETRY_DIR}"
mkdir -p "${GRAFANA_PROVISIONING}"
echo -e "${GREEN}✅ Directories created${NC}"

# Step 3: Copy Configuration Files
echo -e "\n${YELLOW}[3/5] Setting up configuration files...${NC}"

if [ -f "docker-compose-telemetry.yml" ]; then
    cp docker-compose-telemetry.yml "${TELEMETRY_DIR}/"
    echo -e "${GREEN}✅ Copied docker-compose-telemetry.yml${NC}"
fi

if [ -f "telegraf.conf" ]; then
    cp telegraf.conf "${TELEMETRY_DIR}/"
    echo -e "${GREEN}✅ Copied telegraf.conf${NC}"
fi

if [ -f "prometheus.yml" ]; then
    cp prometheus.yml "${TELEMETRY_DIR}/"
    echo -e "${GREEN}✅ Copied prometheus.yml${NC}"
fi

if [ -f "grafana-datasources.yml" ]; then
    cp grafana-datasources.yml "${GRAFANA_PROVISIONING}/prometheus.yml"
    echo -e "${GREEN}✅ Copied grafana datasources${NC}"
fi

if [ -f "grafana-dashboard-dc2.json" ]; then
    cp grafana-dashboard-dc2.json "${TELEMETRY_DIR}/"
    echo -e "${GREEN}✅ Copied Grafana dashboard${NC}"
fi

if [ -f "test-gnmi.py" ]; then
    cp test-gnmi.py "${TELEMETRY_DIR}/"
    chmod +x "${TELEMETRY_DIR}/test-gnmi.py"
    echo -e "${GREEN}✅ Copied test script${NC}"
fi

# Step 4: Verify gNMI is enabled on routers
echo -e "\n${YELLOW}[4/5] Checking gNMI status on routers...${NC}"

check_gnmi() {
    local router=$1
    if docker exec $router Cli -c "show management api gnmi status" 2>/dev/null | grep -q "enabled"; then
        echo -e "${GREEN}✅ $router : gNMI enabled${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  $router : gNMI disabled or unreachable${NC}"
        return 1
    fi
}

ROUTERS=("spine1" "spine2" "leaf1" "leaf2" "leaf3")
GNMI_OK=0

for router in "${ROUTERS[@]}"; do
    if check_gnmi "$router"; then
        GNMI_OK=$((GNMI_OK + 1))
    fi
done

echo -e "${YELLOW}Found $GNMI_OK/$((${#ROUTERS[@]})) routers with gNMI enabled${NC}"

if [ $GNMI_OK -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No routers detected with gNMI. Enabling on all...${NC}"
    for router in "${ROUTERS[@]}"; do
        docker exec $router Cli << EOF 2>/dev/null || true
configure
management api gnmi
transport grpc default
exit
EOF
        echo -e "${GREEN}✅ Enabled gNMI on $router${NC}"
    done
fi

# Step 5: Launch Docker Stack
echo -e "\n${YELLOW}[5/5] Launching Docker Compose stack...${NC}"

cd "${TELEMETRY_DIR}"

if docker-compose -f docker-compose-telemetry.yml up -d; then
    echo -e "${GREEN}✅ Stack started successfully${NC}"
    
    # Wait for services to be ready
    echo -e "\n${YELLOW}Waiting for services to be ready (30s)...${NC}"
    sleep 30
    
    # Show status
    echo -e "\n${GREEN}Service Status:${NC}"
    docker-compose -f docker-compose-telemetry.yml ps
    
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Setup Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "  1. Test connectivity: ${GREEN}python3 ${TELEMETRY_DIR}/test-gnmi.py${NC}"
    echo -e "  2. Access Grafana: ${GREEN}http://localhost:3000${NC} (admin/admin)"
    echo -e "  3. Access Prometheus: ${GREEN}http://localhost:9090${NC}"
    echo -e "  4. Import dashboard: ${GREEN}${TELEMETRY_DIR}/grafana-dashboard-dc2.json${NC}"
    
else
    echo -e "${RED}❌ Failed to start Docker stack${NC}"
    exit 1
fi
