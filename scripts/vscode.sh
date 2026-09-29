#!/usr/bin/env bash
# Install Visual Studio Code from the official Microsoft RPM repository.
set -euo pipefail

# Trust the Microsoft signing key
rpm --import https://packages.microsoft.com/keys/microsoft.asc

# Add the VS Code repository. gpgcheck=1 still verifies RPM signatures; if
# Microsoft rotates its metadata signing key and builds break, set repo_gpgcheck=0.
cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[vscode]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

dnf5 install -y --setopt=install_weak_deps=False code