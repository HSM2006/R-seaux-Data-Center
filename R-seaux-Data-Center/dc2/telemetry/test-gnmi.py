#!/usr/bin/env python3
"""
Test gNMI connectivity to Arista cEOS routers
Usage: python3 test-gnmi.py
"""

import subprocess
import json
import sys
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class Router:
    name: str
    ip: str
    port: int = 6030
    username: str = "admin"
    password: str = "admin"

ROUTERS = [
    Router("spine1", "spine1"),
    Router("spine2", "spine2"),
    Router("leaf1", "leaf1"),
    Router("leaf2", "leaf2"),
    Router("leaf3", "leaf3"),
]

def test_gnmi_connectivity(router: Router) -> bool:
    """Test gNMI connectivity using gnmic"""
    try:
        cmd = [
            "docker", "run", "--rm", "--network", "host",
            "ghcr.io/openconfig/gnmic:latest",
            "-a", f"{router.ip}:{router.port}",
            "-u", router.username,
            "-p", router.password,
            "--insecure",
            "capabilities"
        ]
        result = subprocess.run(cmd, capture_output=True, timeout=10, text=True)
        return result.returncode == 0
    except Exception as e:
        print(f"❌ {router.name}: {str(e)}")
        return False

def get_bgp_summary(router: Router) -> Optional[dict]:
    """Get BGP summary from router"""
    try:
        cmd = [
            "docker", "run", "--rm", "--network", "host",
            "ghcr.io/openconfig/gnmic:latest",
            "-a", f"{router.ip}:{router.port}",
            "-u", router.username,
            "-p", router.password,
            "--insecure",
            "get",
            "--path", "/network-instances/network-instance[name=default]/protocols/protocol[identifier=BGP]/bgp/global/state"
        ]
        result = subprocess.run(cmd, capture_output=True, timeout=10, text=True)
        if result.returncode == 0:
            return json.loads(result.stdout)
        return None
    except Exception as e:
        print(f"Error getting BGP from {router.name}: {str(e)}")
        return None

def get_route_count(router: Router) -> Optional[int]:
    """Get total route count"""
    try:
        cmd = [
            "docker", "exec", router.ip,
            "Cli", "-c", "show ip route json"
        ]
        result = subprocess.run(cmd, capture_output=True, timeout=10, text=True)
        if result.returncode == 0:
            data = json.loads(result.stdout)
            routes = data.get("vrfs", {}).get("default", {}).get("routes", {})
            return len(routes)
        return None
    except Exception as e:
        print(f"Error getting routes from {router.name}: {str(e)}")
        return None

def main():
    print("=" * 60)
    print("🔍 gNMI Connectivity Test - DC2 Infrastructure")
    print("=" * 60)
    
    # Test 1: gNMI connectivity
    print("\n[1/3] Testing gNMI Connectivity...")
    print("-" * 60)
    
    results = {}
    for router in ROUTERS:
        status = "✅ OK" if test_gnmi_connectivity(router) else "❌ FAIL"
        results[router.name] = status
        print(f"  {router.name:10s} {status}")
    
    # Test 2: BGP Summary
    print("\n[2/3] BGP Summary via gNMI...")
    print("-" * 60)
    
    for router in ROUTERS:
        bgp = get_bgp_summary(router)
        if bgp:
            print(f"  ✅ {router.name}: BGP data retrieved")
        else:
            print(f"  ❌ {router.name}: BGP data failed")
    
    # Test 3: Route Counts
    print("\n[3/3] Route Counts...")
    print("-" * 60)
    
    for router in ROUTERS:
        count = get_route_count(router)
        if count is not None:
            print(f"  ✅ {router.name:10s} : {count:5d} routes")
        else:
            print(f"  ❌ {router.name:10s} : Failed to retrieve")
    
    print("\n" + "=" * 60)
    success = all("✅" in v for v in results.values())
    if success:
        print("✅ All tests passed! gNMI is ready.")
    else:
        print("⚠️  Some tests failed. Check Arista gNMI configuration.")
    print("=" * 60)
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
