
1. Create ops workspace: 
> terraform workspace new ops
2. Run shell, cd demo2_ops_network and deploy code with terraform. 
> terraform workspace select ops
> terraform init -var-file ..\variables\ops.tfvars
> terraform apply -var-file ..\variables\ops.tfvars

3. Explain:
- how to use for_each on NSG example and how compare configuration with demo2_network. 
- how to usa map variables
- how we use count
- data source usage on network peering example
4. Open azure portal and walk student throught network configuration. 
5. Update some setting of virtul network and demonstrate how terraform roll back changes.

