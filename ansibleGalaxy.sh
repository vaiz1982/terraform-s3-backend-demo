#!/bin/bash

# ============================================
# Ansible Installation Script for Ubuntu
# Includes ansible-galaxy command
# ============================================

set -e  # Exit immediately if a command exits with non-zero status
set -u  # Treat unset variables as an error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/tmp/ansible_install_$(date +%Y%m%d_%H%M%S).log"

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}" | tee -a "$LOG_FILE"
}

# Function to print error and exit
error_exit() {
    print_message "$RED" "ERROR: $1"
    exit 1
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_message "$YELLOW" "Warning: Running as root. Consider running as a regular user with sudo privileges."
    fi
}

# Function to detect Ubuntu version
detect_ubuntu_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]]; then
            error_exit "This script is designed for Ubuntu systems only. Detected: $ID"
        fi
        print_message "$BLUE" "Detected Ubuntu version: $VERSION"
    else
        error_exit "Cannot detect Ubuntu version"
    fi
}

# Function to check internet connectivity
check_internet() {
    print_message "$BLUE" "Checking internet connectivity..."
    if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        error_exit "No internet connection. Please check your network."
    fi
    print_message "$GREEN" "✓ Internet connection detected"
}

# Function to update system packages
update_system() {
    print_message "$BLUE" "Updating package lists..."
    sudo apt update 2>&1 | tee -a "$LOG_FILE" || error_exit "Failed to update package lists"
}

# Function to install required dependencies
install_dependencies() {
    print_message "$BLUE" "Installing required dependencies..."
    sudo apt install -y \
        software-properties-common \
        curl \
        wget \
        git \
        python3 \
        python3-pip \
        python3-venv \
        gnupg \
        lsb-release 2>&1 | tee -a "$LOG_FILE" || error_exit "Failed to install dependencies"
    print_message "$GREEN" "✓ Dependencies installed"
}

# Function to install Ansible via PPA (recommended)
install_ansible_ppa() {
    print_message "$BLUE" "Adding Ansible PPA repository..."
    sudo add-apt-repository -y --no-update ppa:ansible/ansible 2>&1 | tee -a "$LOG_FILE" || error_exit "Failed to add Ansible PPA"
    
    print_message "$BLUE" "Updating package lists with PPA..."
    sudo apt update 2>&1 | tee -a "$LOG_FILE" || error_exit "Failed to update package lists after adding PPA"
    
    print_message "$BLUE" "Installing Ansible from PPA..."
    sudo apt install -y ansible 2>&1 | tee -a "$LOG_FILE" || error_exit "Failed to install Ansible from PPA"
}

# Function to install Ansible via pip (alternative)
install_ansible_pip() {
    local version=${1:-"latest"}
    
    print_message "$BLUE" "Installing Ansible via pip (method 2)..."
    
    # Upgrade pip first
    python3 -m pip install --upgrade pip 2>&1 | tee -a "$LOG_FILE" || error_exit "Failed to upgrade pip"
    
    # Install Ansible
    if [[ "$version" == "latest" ]]; then
        python3 -m pip install --user ansible 2>&1 | tee -a "$LOG_FILE" || error_exit "Failed to install Ansible via pip"
    else
        python3 -m pip install --user "ansible==$version" 2>&1 | tee -a "$LOG_FILE" || error_exit "Failed to install Ansible version $version via pip"
    fi
    
    # Add ~/.local/bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        print_message "$YELLOW" "Adding ~/.local/bin to PATH..."
        export PATH="$HOME/.local/bin:$PATH"
        
        # Add to shell config files
        if [[ -f "$HOME/.bashrc" ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            print_message "$GREEN" "✓ Added to ~/.bashrc"
        fi
        if [[ -f "$HOME/.zshrc" ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
            print_message "$GREEN" "✓ Added to ~/.zshrc"
        fi
    fi
}

# Function to verify Ansible installation
verify_installation() {
    print_message "$BLUE" "Verifying Ansible installation..."
    
    # Check if ansible command exists
    if ! command -v ansible &>/dev/null; then
        error_exit "Ansible command not found in PATH"
    fi
    
    # Get versions
    local ansible_version=$(ansible --version 2>/dev/null | head -n1)
    local galaxy_version=$(ansible-galaxy --version 2>/dev/null | head -n1)
    
    print_message "$GREEN" "✓ Ansible installed successfully"
    print_message "$GREEN" "  $ansible_version"
    print_message "$GREEN" "✓ ansible-galaxy installed successfully"
    print_message "$GREEN" "  $galaxy_version"
}

# Function to create test directory and examples
create_test_examples() {
    print_message "$BLUE" "Creating test examples in ~/ansible-test..."
    
    local test_dir="$HOME/ansible-test"
    mkdir -p "$test_dir"
    
    # Create a requirements.yml example
    cat > "$test_dir/requirements.yml" << 'EOF'
---
# Example requirements.yml for ansible-galaxy
roles:
  - name: geerlingguy.docker
  - name: geerlingguy.nginx
  - name: geerlingguy.mysql

collections:
  - name: community.general
  - name: ansible.posix
EOF
    
    # Create a test playbook example
    cat > "$test_dir/test-playbook.yml" << 'EOF'
---
- name: Test Ansible Installation
  hosts: localhost
  gather_facts: yes
  tasks:
    - name: Display system info
      debug:
        msg: "Ansible is working on {{ ansible_distribution }} {{ ansible_distribution_version }}"
    
    - name: Check ansible-galaxy is available
      command: ansible-galaxy --version
      register: galaxy_check
    
    - name: Display ansible-galaxy info
      debug:
        var: galaxy_check.stdout_lines
EOF
    
    # Create a simple ansible.cfg
    cat > "$test_dir/ansible.cfg" << 'EOF'
[defaults]
host_key_checking = False
stdout_callback = debug
gathering = smart
EOF
    
    print_message "$GREEN" "✓ Test examples created in $test_dir"
    print_message "$YELLOW" "Files created:"
    echo "  - requirements.yml"
    echo "  - test-playbook.yml"
    echo "  - ansible.cfg"
}

# Function to test ansible-galaxy
test_ansible_galaxy() {
    print_message "$BLUE" "Testing ansible-galaxy command..."
    
    # Test role installation
    print_message "$YELLOW" "Testing ansible-galaxy role install (dry run)..."
    if ansible-galaxy role install --help &>/dev/null; then
        print_message "$GREEN" "✓ ansible-galaxy role commands work"
    else
        print_message "$YELLOW" "Warning: ansible-galaxy role commands not responding as expected"
    fi
    
    # Test collection installation
    print_message "$YELLOW" "Testing ansible-galaxy collection (dry run)..."
    if ansible-galaxy collection install --help &>/dev/null; then
        print_message "$GREEN" "✓ ansible-galaxy collection commands work"
    else
        print_message "$YELLOW" "Warning: ansible-galaxy collection commands not responding as expected"
    fi
}

# Function to display usage examples
display_usage() {
    cat << EOF

============================================
          ANSIBLE-GALAXY USAGE EXAMPLES
============================================

1. Install a role from Ansible Galaxy:
   ansible-galaxy role install geerlingguy.docker

2. Install a collection:
   ansible-galaxy collection install community.general

3. Install from requirements.yml file:
   ansible-galaxy install -r requirements.yml

4. Search for roles:
   ansible-galaxy role search nginx

5. Get info about a role:
   ansible-galaxy role info geerlingguy.docker

6. List installed roles:
   ansible-galaxy role list

7. Remove a role:
   ansible-galaxy role remove geerlingguy.docker

============================================
          QUICK START COMMANDS
============================================

cd ~/ansible-test

# Install roles from requirements.yml
ansible-galaxy install -r requirements.yml

# Run the test playbook
ansible-playbook test-playbook.yml

============================================
EOF
}

# Main installation function
main() {
    print_message "$BLUE" "==========================================="
    print_message "$BLUE" "Ansible Installation Script for Ubuntu"
    print_message "$BLUE" "==========================================="
    
    # Pre-installation checks
    check_root
    detect_ubuntu_version
    check_internet
    
    # Choose installation method
    print_message "$YELLOW" "\nSelect installation method:"
    echo "1) Install from official PPA (recommended)"
    echo "2) Install via pip (alternative)"
    echo "3) Exit"
    read -p "Enter your choice [1-3]: " choice
    
    case $choice in
        1)
            update_system
            install_dependencies
            install_ansible_ppa
            ;;
        2)
            update_system
            install_dependencies
            install_ansible_pip
            ;;
        3)
            print_message "$YELLOW" "Exiting..."
            exit 0
            ;;
        *)
            error_exit "Invalid choice. Please run the script again and select 1 or 2."
            ;;
    esac
    
    # Verify installation
    verify_installation
    
    # Test ansible-galaxy
    test_ansible_galaxy
    
    # Create test examples
    create_test_examples
    
    # Display usage examples
    display_usage
    
    # Final message
    print_message "$GREEN" "\n==========================================="
    print_message "$GREEN" "✅ Ansible installation completed successfully!"
    print_message "$GREEN" "==========================================="
    print_message "$YELLOW" "Log file saved to: $LOG_FILE"
    
    # Reminder to reload shell if using pip
    if [[ $choice -eq 2 ]]; then
        print_message "$YELLOW" "\n⚠️  If ansible commands are not found, please reload your shell:"
        echo "   source ~/.bashrc  (or open a new terminal)"
    fi
}

# Run the main function
main
