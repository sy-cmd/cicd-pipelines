# cicd-pipelines
## GitActions 
This repository contains the workflows i develop and worked on to automate repetitive tasks on giteaAction with a self hosted runner

### structure 

````
cicd-pipeline/
├── concourse/                    
├── golden-image/                    
├── infrastructure/                 
├── vault-unsealing/                

````

### Usage 
+ To implement these workflows, ensure the .yaml files are placed in the correct hidden directory so the runners can detect them:
  + GitHub: **.github/workflows/*.yaml**
  + Gitea: **.gitea/workflows/*.yaml** 

```
.gitea/
└── workflows/
    ├── vault-unseal.yml        # Workflow file 1
    ├── nomad-backup.yml        # Workflow file 2
    └── consul-backup.yml       # Workflow file 3
vault-unsealing/
    └── unseal.sh               # The script the workflow calls
infrastructure/
    └── gitea-backup          
golden-image/
     └── Dockerfile
```