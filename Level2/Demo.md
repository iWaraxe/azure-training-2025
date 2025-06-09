# Create demo environment.

>Note: create infrastructure before lecture so all artifacts for demo will be created.

Open the Default.tfvars file and add required variables:
- Resource group name and location 
- Service principal credentials for azure access
- Sql server credentials

Execute commands:
``` 
  cd artifacts
  terraform.exe init -var-file Default.tfvars
  terraform.exe apply -var-file Default.tfvars
```

During of each module use created resources to demonstrate configuration of azure services. 

At the end of lecture we show the full environment setup and perform migration steps. 

To migrate "VM infrastructure" to "web app" we use azure traffic manager. 
The automation account contains a script which you need to run. 

Do the following:
  - open the traffic manager url in browser and show content of the site
  - executer runbook from automation account and demonstrate infrastructure migration. 
  - show the traffic manager configuration, the primary endpoint should be disabled. 
  - open the the traffic manager url in browser again (maybe in private mode since your browser may cache the site content)

Explain how it works and use cases. 