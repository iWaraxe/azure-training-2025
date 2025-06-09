# Lecture 1 - Homework 
## Task requirement
Create and deploy 3 environments for development, qa and operation purpuse.
Define naming convention requirements for terraform code (define all in file naming_convention.tf)
Deploy the following resources:
- Virtual network with network security group: 
    - Development
    - Qa
    - Operation
- Network security group with the following ports open (inbound and outbound):
    - Development - 80, 443
    - Qa - 80, 443
    - Ops -  - 80, 443, 22 (for jenkins install since terraform provisioner block use 22 port to connect and install soft.)

>  The public access to Development, Qa and Ops environments on port 22 should be closed.

- Network gateway for VPN (with MFA auth) for environment access:
    - Ops
- Key vault with secret for Jenkins virtual machine password:
    - Operation
- Virtual machine with Jenkins server where soft should be installed using terraform provisioner (password should be used from key vault resource):
    - Ops
> Note: You will be not able to install Jenkins server on VM with VPN enabled if terraform connection block use private IP. 
- Use the following folder structure for terraform code:
    - resource group: 
        - resource_group.tf
        - variables.tf
    - application_network:
        - application_network.tf
        - variables.tf
    - ops_network:
        - ops_network.tf
        - variables.tf
    - storage:
        - storage.tf
        - variables.tf
    - ops_virtual_machine:
        - ops_virtual_machine.tf
        - variables.tf
    - variables:
        - dev.tfvars
        - qa.tfvars
        - ops.tfvars
> Note: This is our recomendation. You can use any folder structure but during of homework check you should argument your choice.






