# SAé DevCloud_4D01: Développer et déployer un microservice dans un environnement virtualisé

Jeune embauché dans une filiale on vous demande avec un collègue de bâtir une infrastructure (systèmes, réseaux et sécurité) pour déployer des services réseaux et des micro-services logiciels.


## Organisation du travail

Vous travaillerez au sein d'une équipe de 3 personnes et vous disposerez d'un serveur DELL/HP pour travailler. Vous validerez mutuellement vos travaux avec une autre équipe. (routage acccès). C'est une tâche qui donnera lieu à compte rendu.
Vous devez travailler en mode agile en utilisant la méthode Kanban. Au final chaque tâche sera documentée et affectée à une personne ce qui permettra d'évaluer le travail de votre équipe et l'individualisation de votre rémunération.  Chaque semaine vous devez vous affecter un objectif qui vous permette d'avancer et de produire une avancée tangible.


## Cahier des charges

### réseau

- Un réseau bgp pour vous connecter aux autres équipes et un réseau ospf interne qui permettra d'accéder à vos microservices. Ce réseau de routeurs containairisés sera implémenté à l'aide containerlab (https://containerlab.dev/). Il sera composé de deux types de routeurs containérisés : arista et frr-routing.
- Un infrastructure virtualisée avec la solution Cloud OpenNebula (https://opennebula.io/). Vous disposez d'un serveur pour deux personnes. Un stockage partagé NFS permettra de survivre à l'arrêt d'un serveur pour les containers redondés. Les serveurs dans l'idéal seront sur le même plan d'adressage mais reliés à l'aide du protocole vxlan ou genève.(ethernet dans udp)
- Votre infrastructure sera acessible via un vpn Wireguard (firezone..) et vous mettrez en place un bastion ssh (téléport...).

### Vous devez donc implémenter à minima les services réseaux suivants:

- Un DNS (unbound) en haute disponibilité derrière un équilibreur de charge.
- Un registry de service Consul (https://www.consul.io/)
- Un registry Harbor.
- Un système de supervision de vos réseaux et de vos microservices.
- Une source de vérité (nautobot) commune à tous les groupes.
- Un équilibreur de charge de type haproxy (avec consul template) pour la haute disponibilité commun à tous les groupes.
  
  

### Services applicatifs cloud containairisés suivants à destination des usagers:

- Un serveur web IUT à base d'un "Content" Management System" comme celui de l'IUT de Béziers. HA proxy assurera l'équilibrage de charge et la haute disponibilité.
- Un serveur Nextcloud.
- Un Kanban de votre choix. (wekan...) qui vous servira à suivre le projet.
- Les containers seront déployables à l'aide de playbook ansible.

Une solution de management (Portainer,rancher) devra être utilisé pour piloter vos containers.
Un durcissement des containers est souhaité ( limits, rootless..). 

Vous devrez aussi réaliser de l'automatisation par script ( Python, Ansible) par exemple pour alimenter Nautobot ou Consul ou produire des états.

Un compte-rendu écrit et un repos git par groupe sont obligatoires.


## Critères d'évaluation de la SAE:

### Critères pour le groupe:

- Conformité au CCTP.
- Clarté des schémas réseaux.
- Haute disponibilité de l'infrastructure.
- Sécurité de l'infrastructure.
- Organisation.
- Ecrits.
- Esprit et outils DevOps
- Soutenance orale.

### Critères individualisables:

- Communication.
- Quantité de travail.
- Evaluation par les pairs.
- Soutenance orale.
