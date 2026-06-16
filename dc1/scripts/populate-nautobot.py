#!/usr/bin/env python3
"""
populate-nautobot.py — Alimentation automatique Nautobot via API
SAE DevCloud 4D01 — Groupe HSM
Auteur : Houssam

Usage : python3 populate-nautobot.py [--url http://172.20.1.70:8080]
"""

import requests
import json
import sys
import argparse

# Config
DEFAULT_URL = "http://172.20.1.70:8080"
TOKEN = "0123456789abcdef0123456789abcdef01234567"
HEADERS = {
    "Authorization": f"Token {TOKEN}",
    "Content-Type": "application/json",
    "Accept": "application/json",
}


def api_post(base_url, endpoint, data):
    """POST vers l'API Nautobot avec gestion d'erreur."""
    url = f"{base_url}/api/{endpoint}/"
    resp = requests.post(url, headers=HEADERS, json=data, timeout=10)
    if resp.status_code in (200, 201):
        print(f"  OK  {endpoint}: {data.get('name', data)}")
        return resp.json()
    elif resp.status_code == 400 and "already exists" in resp.text:
        print(f"  SKIP {endpoint}: {data.get('name', '')} (existe déjà)")
        return None
    else:
        print(f"  ERR {endpoint}: {resp.status_code} — {resp.text[:100]}")
        return None


def populate(base_url):
    print(f"Connexion Nautobot : {base_url}")

    # 1. Site
    print("\n[1] Création site DC1...")
    site = api_post(base_url, "dcim/sites", {
        "name": "DC1-IUT-Beziers",
        "slug": "dc1-iut-beziers",
        "status": "active",
        "description": "Datacenter 1 — SAE DevCloud 4D01 — Groupe HSM",
    })

    # 2. Manufacturer
    print("\n[2] Fabricants...")
    for mfr in [
        {"name": "Cisco", "slug": "cisco"},
        {"name": "Mikrotik", "slug": "mikrotik"},
        {"name": "Linux (FRR)", "slug": "linux-frr"},
        {"name": "Arista", "slug": "arista"},
    ]:
        api_post(base_url, "dcim/manufacturers", mfr)

    # 3. Device types
    print("\n[3] Types d'équipements...")
    device_types = [
        {"model": "Catalyst 8000", "slug": "catalyst-8000", "manufacturer": {"slug": "cisco"}},
        {"model": "Mikrotik RouterOS v7", "slug": "mikrotik-ros7", "manufacturer": {"slug": "mikrotik"}},
        {"model": "FRR Container", "slug": "frr-container", "manufacturer": {"slug": "linux-frr"}},
        {"model": "Arista cEOS", "slug": "arista-ceos", "manufacturer": {"slug": "arista"}},
    ]
    for dt in device_types:
        api_post(base_url, "dcim/device-types", dt)

    # 4. Device roles
    print("\n[4] Rôles...")
    for role in [
        {"name": "Spine", "slug": "spine", "color": "0000ff"},
        {"name": "Leaf", "slug": "leaf", "color": "00ff00"},
        {"name": "Border Router", "slug": "border-router", "color": "ff6600"},
        {"name": "Service", "slug": "service", "color": "aaaaaa"},
    ]:
        api_post(base_url, "dcim/device-roles", role)

    # 5. Préfixes IP
    print("\n[5] Plan d'adressage...")
    prefixes = [
        {"prefix": "10.202.0.0/16", "description": "Réseau salle IUT — management + eBGP"},
        {"prefix": "172.16.0.0/24", "description": "DC1 underlay P2P /31"},
        {"prefix": "172.16.255.0/24", "description": "DC1 loopbacks /32"},
        {"prefix": "172.20.1.0/24", "description": "DC1 services — web, DNS, AD, monitoring"},
    ]
    for prefix in prefixes:
        api_post(base_url, "ipam/prefixes", prefix)

    # 6. Équipements
    print("\n[6] Équipements...")
    if site:
        site_id = site["id"]
        devices = [
            {"name": "spine1", "device_type": {"slug": "frr-container"},
             "device_role": {"slug": "spine"}, "site": {"id": site_id},
             "status": "active", "comments": "AS 65100 — Route Reflector EVPN"},
            {"name": "spine2", "device_type": {"slug": "frr-container"},
             "device_role": {"slug": "spine"}, "site": {"id": site_id},
             "status": "active", "comments": "AS 65100 — Route Reflector EVPN"},
            {"name": "leaf1", "device_type": {"slug": "frr-container"},
             "device_role": {"slug": "leaf"}, "site": {"id": site_id},
             "status": "active", "comments": "AS 65001 — VTEP VNI 10100"},
            {"name": "leaf2", "device_type": {"slug": "frr-container"},
             "device_role": {"slug": "leaf"}, "site": {"id": site_id},
             "status": "active", "comments": "AS 65002 — VTEP VNI 10100"},
            {"name": "leaf3", "device_type": {"slug": "frr-container"},
             "device_role": {"slug": "leaf"}, "site": {"id": site_id},
             "status": "active", "comments": "AS 65003 — VTEP VNI 10100"},
            {"name": "catalyst8000", "device_type": {"slug": "catalyst-8000"},
             "device_role": {"slug": "border-router"}, "site": {"id": site_id},
             "status": "active", "comments": "AS 65001 — eBGP salle + iBGP Mikrotik"},
            {"name": "mikrotik", "device_type": {"slug": "mikrotik-ros7"},
             "device_role": {"slug": "border-router"}, "site": {"id": site_id},
             "status": "active", "comments": "AS 65001 — eBGP salle + iBGP Catalyst"},
        ]
        for dev in devices:
            api_post(base_url, "dcim/devices", dev)

    print("\n=== Nautobot peuplé avec succès ===")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Populate Nautobot — SAE DevCloud 4D01")
    parser.add_argument("--url", default=DEFAULT_URL, help="URL Nautobot")
    args = parser.parse_args()
    populate(args.url)
