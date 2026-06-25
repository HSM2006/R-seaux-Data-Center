# Synchronisation des configurations live

Date: 2026-06-23 05:34:41 CEST

Objectif: faire correspondre les fichiers du projet avec l'etat reel actuellement configure, sans arreter ni redeployer le lab.

## Sauvegarde

Backup cree avant synchronisation:

- sync-running-configs-20260623-053032/project-backup/

## Equipements FRR Containerlab

Les running-config live des routeurs FRR ont ete exportees dans:

- running-configs/spine1-frr-running.conf
- running-configs/spine2-frr-running.conf
- running-configs/leaf1-frr-running.conf
- running-configs/leaf2-frr-running.conf
- running-configs/leaf3-frr-running.conf

Les etats Linux/IP/link sont aussi dans:

- running-configs/*-linux-state.txt

Modification persistante integree dans les fichiers du projet:

- node_files/spine1/bgp contient maintenant `network 10.25.0.0/30`, necessaire pour le retour du ping leaf1 vers le serveur web binome.

## Equipements externes

Les exports des equipements externes sont ranges dans:

- external-configs/r1-10.202.1.7-running-config-and-state.txt
- external-configs/mikrotik-10.202.1.9-export-and-state.rsc

## Note

Aucun containerlab destroy, deploy, restart ou arret de projet n'a ete effectue.
