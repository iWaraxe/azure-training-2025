#!/bin/bash

# GitHub Repository Setup Script for Azure Training Course
# This script helps you create a GitHub repo and push your updates

echo "🚀 Azure Training Course - GitHub Repository Setup"
echo "================================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it first:"
    echo "  macOS: brew install gh"
    echo "  Or visit: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "📝 You need to authenticate with GitHub first."
    echo "Running: gh auth login"
    gh auth login
fi

echo ""
echo "📋 Repository Configuration"
echo "=========================="
echo ""

# Get repository details
read -p "Enter repository name (default: azure-training-2025): " REPO_NAME
REPO_NAME=${REPO_NAME:-azure-training-2025}

read -p "Enter repository description: " REPO_DESC
REPO_DESC=${REPO_DESC:-"Azure Training Course - Modernized for 2025 with Terraform, PaaS, and Kubernetes"}

read -p "Make repository public? (y/N): " IS_PUBLIC
if [[ $IS_PUBLIC =~ ^[Yy]$ ]]; then
    VISIBILITY="--public"
else
    VISIBILITY="--private"
fi

echo ""
echo "Creating repository with:"
echo "  Name: $REPO_NAME"
echo "  Description: $REPO_DESC"
echo "  Visibility: ${VISIBILITY#--}"
echo ""

read -p "Continue? (Y/n): " CONFIRM
if [[ $CONFIRM =~ ^[Nn]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Create the repository
echo ""
echo "🔧 Creating GitHub repository..."
gh repo create "$REPO_NAME" --description "$REPO_DESC" $VISIBILITY --confirm

# Get the repository URL
REPO_URL=$(gh repo view "$REPO_NAME" --json sshUrl -q .sshUrl)

# Add remote
echo "🔗 Adding remote origin..."
git remote add origin "$REPO_URL"

# Create main branch if it doesn't exist
echo "📌 Setting up main branch..."
git branch -M main

# Push main branch first
echo "📤 Pushing main branch..."
git push -u origin main

# Push the feature branch
echo "📤 Pushing course-update-2025 branch..."
git push -u origin course-update-2025

# Create PR
echo ""
echo "🔄 Creating Pull Request..."
echo ""

PR_TITLE="Course Modernization 2025: Update all levels to current Azure standards"
PR_BODY=$(cat << 'EOF'
# Azure Training Course - 2025 Modernization

## 🎯 Overview
This PR contains comprehensive updates to modernize the Azure Training course from 2021 standards to current 2025 best practices.

## 📊 Key Updates

### Infrastructure as Code
- ✅ Terraform Provider: 2.46.0 → 4.0
- ✅ Modern resource types (azurerm_linux_virtual_machine, azurerm_windows_web_app)
- ✅ Enhanced security with managed identities and Key Vault integration

### Container & Kubernetes
- ✅ Python: 2.7 → 3.11 with multi-stage secure builds
- ✅ Kubernetes: Replaced PSP with Pod Security Standards
- ✅ AKS Integration: Workload Identity, CSI drivers, modern patterns

### Security Improvements
- ✅ No hardcoded credentials - environment variables and Key Vault
- ✅ Pod Security Standards (Restricted/Baseline)
- ✅ Non-root containers with read-only filesystems
- ✅ Microsoft Entra ID (formerly Azure AD) updates

## 📚 Updated Components

### Level 1 - IaaS Fundamentals
- Demo 1: Resource Groups with tagging
- Demo 2: Modern networking with proper NSG associations
- Demo 3: Enhanced Key Vault and Storage security
- Demo 4: Linux VMs with cloud-init (replacing provisioners)
- Demo 2 OPS: VPN with Entra ID authentication

### Level 2 - PaaS Services
- Modern App Service (Windows Web Apps)
- Application Insights integration
- Azure SQL with AD authentication
- Environment-aware configurations

### Level 3 - Kubernetes
- MARS application modernization
- Production-ready Kubernetes manifests
- AKS-specific integrations
- Complete monitoring stack

## 🔍 Breaking Changes
1. VM resource type changes
2. App Service resource type changes
3. Python 2.7 → 3.11 migration
4. PodSecurityPolicy removal

## 📋 Testing Checklist
- [ ] Level 1 demos deploy successfully
- [ ] Level 2 PaaS services integrate properly
- [ ] Level 3 MARS application runs in AKS
- [ ] All security contexts validate
- [ ] Monitoring and logging functional

## 📖 Documentation
- Updated CLAUDE.md with course philosophy
- Comprehensive COURSE-UPDATE-SUMMARY.md
- Migration guide for students and instructors

## 🚀 Ready for Review
All changes maintain the hands-on, practical training approach while ensuring students learn current production-ready Azure patterns.

---
Please review the changes and test in your Azure subscription before merging.
EOF
)

gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base main \
    --head course-update-2025 \
    --assignee @me

echo ""
echo "✅ Done! Your repository is set up:"
echo "   Repository: https://github.com/$(gh api user -q .login)/$REPO_NAME"
echo "   PR is ready for review!"
echo ""
echo "📝 Next steps:"
echo "1. Share the PR link with your colleagues"
echo "2. Have them review the changes"
echo "3. Test deployments in Azure"
echo "4. Merge when approved"