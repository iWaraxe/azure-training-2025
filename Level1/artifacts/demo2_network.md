
1. Create dev and qa workspace: 
> terraform workspace new dev
> terraform workspace new qa
2. Run shell, cd demo2_network and deploy code with terraform. 
> terraform workspace select dev
> terraform init -var-file ..\variables\dev.tfvars
> terraform apply -var-file ..\variables\dev.tfvars

> terraform workspace select qa
> terraform init -var-file ..\variables\qa.tfvars
> terraform apply -var-file ..\variables\qa.tfvars

3. Explain:
- how to update a resource settings
- demonstrate how terraform plan and apply works in details.
- show were to find a settings for the code (terraform web site). 
- explain how state file works (explain purpuse of terraform.tfstate.d). Open it and show configuration.

4. Open azure portal and walk student throught network configuration. 
5. Update some setting of virtul network and demonstrate how terraform roll back changes.

