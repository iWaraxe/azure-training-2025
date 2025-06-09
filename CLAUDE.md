# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **highly practical** Azure training program structured in three progressive levels, teaching Azure cloud infrastructure using Infrastructure as Code (IaC) practices with Terraform. The training emphasizes hands-on experience over theory.

### Training Philosophy
- **Practical Focus**: Code-first approach - we write Terraform code, deploy it live, and learn through implementation
- **Live Demonstrations**: Each concept is taught by writing and executing code during the training session
- **Problem-Based Learning**: Students learn by encountering and solving real deployment challenges
- **Minimal Theory**: Short lectures (5-10 minutes) followed by extensive hands-on workshops (1+ hours)

### Current Level Structure (Progressive Complexity)
- **Level 1**: Azure IaaS fundamentals (VMs, Networks, Storage, Key Vault) - Foundation concepts
- **Level 2**: Azure PaaS services (App Service, SQL Database, Traffic Manager) - Building on Level 1
- **Level 3**: Kubernetes and containerization (AKS, Docker, Helm, Monitoring) - Advanced concepts

### Course Update Objectives
The primary goal is to **update existing content** with the latest Azure features and service changes, NOT to create a new course:
- Update Terraform code to work with current Azure provider versions
- Replace deprecated Azure services (e.g., Azure Active Directory → Microsoft Entra ID)
- Modernize code examples while maintaining the practical, hands-on approach
- Update screenshots and documentation to reflect current Azure Portal UI
- Ensure all demos work with the latest versions of tools and services

## Common Development Commands

### Terraform Workflows
```bash
# Initialize and create workspaces
terraform init
terraform workspace new dev
terraform workspace select dev

# Apply configuration with environment-specific variables
terraform apply -var-file ../variables/dev.tfvars

# Switch between environments
terraform workspace select qa
terraform apply -var-file ../variables/qa.tfvars
```

### Docker Operations
```bash
# Build the MARS application
docker build . -t linux/mars

# Push to Azure Container Registry
docker login <acrname>.azurecr.io
docker tag linux/mars:latest <acrname>.azurecr.io/linux/mars
docker push <acrname>.azurecr.io/linux/mars
```

### Kubernetes Deployment
```bash
# Create namespace and registry secret
kubectl create namespace development
kubectl create secret docker-registry acr-docker --namespace development \
  --docker-server=acrname.azurecr.io \
  --docker-username=USERNAME \
  --docker-password=PASSWORD

# Deploy with kubectl
kubectl apply -f deployment.yaml -n development

# Deploy with Helm
helm install mars-app ./mars-application -n development
helm install monitoring ./kube-prometheus-stack -n monitoring
```

### MARS Application Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run locally (requires Redis)
python mars.py
```

## Architecture Patterns

### Demo Structure
Each level contains demos with a consistent structure:
- `demo*.md` files describe what each demo accomplishes
- Corresponding Terraform `.tf` files implement the infrastructure
- Code shown in presentations matches exactly what's in the demo files
- Students run the actual code during training sessions

### Terraform Module Structure
Level 2 demonstrates modular Terraform organization:
- Modules are in `/Level2/artifacts/modules/`
- Each module has: main `.tf` file, `variables.tf`, `outputs.tf`
- Environment-specific configurations in `.tfvars` files

### Kubernetes Application Structure
The MARS application serves as the reference implementation:
- Flask web application with Redis backend
- Logs to persistent volumes at `/mnt/logs/info.log`
- Configured via `mars.config` file
- Requires `REDIS_HOST` environment variable

### Helm Chart Organization
Standard Helm structure is used throughout Level 3:
- `Chart.yaml` - Chart metadata
- `values.yaml` - Default configuration values
- `templates/` - Kubernetes manifest templates
- Environment-specific values in separate files (e.g., `dev.yaml`)

### Multi-Environment Strategy
The training demonstrates consistent environment separation:
- **dev** - Development environment
- **qa** - Quality assurance environment  
- **ops** - Operations/production environment

Each environment has:
- Dedicated Terraform workspace
- Separate variable files (`dev.tfvars`, `qa.tfvars`, `ops.tfvars`)
- Isolated Kubernetes namespaces

## Key Technologies and Versions

- **Infrastructure**: Terraform, Azure Resource Manager
- **Containers**: Docker, Kubernetes, Helm
- **Monitoring**: Prometheus, Grafana, Fluent Bit
- **Languages**: Python (Flask), PowerShell, Bash
- **CI/CD**: Jenkins, Azure Automation Account

## Important Considerations

1. **Security**: Key Vault is used for secrets management. Never commit credentials to the repository.

2. **Network Architecture**: VPN access is required for production environments. Network security groups control access between tiers.

3. **High Availability**: Pod disruption budgets and horizontal scaling are configured for production workloads.

4. **Monitoring**: Complete observability stack is deployed in Level 3 with Prometheus and Grafana.

5. **Training Flow**: Each level builds on the previous. Level 1 VMs are replaced by Level 2 PaaS services, which are then containerized in Level 3.

## Update Priorities

### Phase 1: Critical Updates (Immediate)
1. **Update Terraform Code**:
   - Migrate to latest Terraform and Azure Provider versions
   - Fix deprecated resource types and arguments
   - Update syntax to current best practices

2. **Service Name Updates**:
   - Azure Active Directory → Microsoft Entra ID
   - Other renamed/restructured services

3. **Demo Validation**:
   - Test all demos with current Azure subscriptions
   - Update any failing deployments
   - Ensure compatibility with latest Azure features

### Phase 2: Enhanced Content (Level-Specific)
1. **Level 1 Enhancements**:
   - Modern VM deployment patterns
   - Updated networking features (Azure Bastion, etc.)
   - Current Key Vault integration patterns

2. **Level 2 Enhancements**:
   - App Service with containers
   - Managed identities for SQL Database
   - Modern Traffic Manager configurations

3. **Level 3 Enhancements**:
   - AKS-specific features (Azure Policy, GitOps)
   - Service mesh considerations
   - Enhanced monitoring with Azure Monitor integration

### Phase 3: Future Considerations (Optional)
- **CI/CD Integration**: Add Azure DevOps/GitHub Actions examples
- **Security Enhancements**: Managed identities, Azure Policy, Defender for Cloud
- **Cost Management**: Budget alerts, cost analysis, optimization strategies
- **Advanced Patterns**: Event-driven architecture, serverless components

## Working with This Repository

### For Updates:
1. Each demo's `.md` file serves as the specification
2. Update the corresponding `.tf` files to implement the specification with modern Azure/Terraform
3. Test deployments in all three environments (dev, qa, ops)
4. Update presentation slides only after code is validated

### Key Principles:
- **Maintain Practical Focus**: Every update should be demonstrable in a live coding session
- **Preserve Learning Flow**: Updates should enhance, not disrupt, the progressive learning path
- **Keep It Working**: All demos must be executable during training sessions