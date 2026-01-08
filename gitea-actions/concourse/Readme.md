### conssourse pipeline
This repository contains a Concourse CI/CD pipeline designed to automate the maintenance of a HashiCorp-based homelab environment. It ensures that the HashiStack servers are kept up-to-date by running scheduled Ansible playbooks.

+ we used consconurse vault to authenticate concourse to gitea for it to access the repositories on gitea that contained the ansible roles  
+ the pipeline was used to update the hashistack every friday 
+ it used one of the ansible roles to update the servers that where outdated 

#### Infrastructure Components
1. Source Control (Gitea)
+ We use a self-hosted Gitea instance to store the Ansible roles and playbooks.
+ Repository: homelab-ansible-hashicorp.git
+ Branch: SAAS-45
+ Authentication: Concourse authenticates to Gitea using a private key stored in Concourse Vault (((git-private-key))).

2. Registry (Docker)
The pipeline pulls a custom environment image from a local registry:
+ Image: 192.168.50.20:5000/golden-image:v2.0
+ Purpose: Contains ansible-playbook and all necessary dependencies.

3. job
Workflow:
+ Fetch Resources: Pulls the latest code from Gitea and the Golden Image from the local registry.
+ Environment Setup: Disables SSH StrictHostKeyChecking to allow seamless connection to homelab nodes.
+ Ansible Execution: Runs the update playbook: