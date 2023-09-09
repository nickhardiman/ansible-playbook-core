# Set up the hypervisor 

# !!! make a new role machine-hypervisor-configure.yml
# and migrate much of this crap to that and to collection roles. 

# Log into hypervisor.
# Download this script.
#   curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-lab/main/machine-hypervisor.sh 
# Read it. 
# Edit and change my details to yours.
# Set ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN
# Set OFFLINE_TOKEN
# Run this script
#   bash -x machine-hypervisor.sh

# hostname 
# hostnamectl hostname host.core.example.com

# SSH security
# if SSH service on this box is accessible to the Internet
# use key pairs only, disable password login
# for more information, see
#   man sshd_config
#echo "AuthenticationMethods publickey" >> /etc/ssh/sshd_config


# install and configure git
sudo dnf install --assumeyes git
git config --global user.name         "Nick Hardiman"
git config --global user.email        nick@email-domain.com
git config --global github.user       nick
git config --global push.default      simple
# default timeout is 900 seconds (https://git-scm.com/docs/git-credential-cache)
git config --global credential.helper 'cache --timeout=1200'
git config --global pull.rebase false
# check 
git config --global --list


# Add an Ansible user account.
# create a new keypair 
ssh-keygen -f ./ansible-key -q -N ""
mv ansible-key  ansible-key.priv
# Create the ansible_user account (not using --system). 
sudo useradd ansible_user
# Copy the keys to ansible_user's SSH config directory. 
sudo mkdir /home/ansible_user/.ssh
sudo chmod 0700 /home/ansible_user/.ssh
sudo cp ansible-key.priv  /home/ansible_user/.ssh/id_rsa
sudo chmod 0600 /home/ansible_user/.ssh/id_rsa
sudo cp ansible-key.pub  /home/ansible_user/.ssh/id_rsa.pub
# enable SSH to localhost with key-based login
sudo su -c 'cat ansible-key.pub >> /home/ansible_user/.ssh/authorized_keys'
sudo chmod 0600 /home/ansible_user/.ssh/authorized_keys
sudo chown -R ansible_user:ansible_user /home/ansible_user/.ssh
# Keep a spare set of keys handy. 
# Copy the keys to your SSH config directory. 
cp ansible-key.priv  ansible-key.pub  $HOME/.ssh/
rm ansible-key.priv  ansible-key.pub
# This location is set in ansible.cfg. 
# private_key_file = /home/nick/.ssh/ansible-key.priv

# !!! pubkey update is missing. 
# Public key is fixed here. 
# https://github.com/nickhardiman/ansible-collection-platform/blob/main/roles/libvirt_machine_kickstart/defaults/main.yml#L88
# [source,shell]
# ....
# user_ansible_public_key: |
#   ssh-rsa AAA...YO0= pubkey for ansible
# ....

# Allow passwordless sudo.
sudo su -c 'echo "ansible_user      ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/ansible_user'

# Check your work. 
# Log in with key-based authentication and run the ID command as root.
ssh \
     -o StrictHostKeyChecking=no \
     -i $HOME/.ssh/ansible-key.priv \
     ansible_user@localhost  \
     sudo id


# enable nested virtualization? 
# /etc/modprobe.d/kvm.conf 
# options kvm_amd nested=1


# install Ansible
sudo dnf install --assumeyes ansible-core
# install Ansible libvirt collection
sudo ansible-galaxy collection install community.libvirt --collections-path /usr/share/ansible/collections
# check 
ls /usr/share/ansible/collections/ansible_collections/community/


# get my libvirt collection.
# I'm not using ansible-galaxy because I am actively developing this role.
# Check out the directive in ansible.cfg in some playbooks.
mkdir -p ~/ansible/collections/ansible_collections/nick/
cd ~/ansible/collections/ansible_collections/nick/
# If the repo has already been cloned, git exits with this error message. 
#   fatal: destination path 'libvirt-host' already exists and is not an empty directory.
# !!! not uploaded
git clone https://github.com/nickhardiman/ansible-collection-platform.git platform


# Get my lab playbook.
mkdir -p ~/ansible/playbooks/
cd ~/ansible/playbooks/
git clone https://github.com/nickhardiman/ansible-playbook-core.git
cd ansible-playbook-core/


# Authenticate to Red Hat Automation Hub using a token.
# Get a token from https://console.redhat.com/ansible/automation-hub/token#
# Set an environment variable for identification.
# You can also put your offline token in ansible.cfg.
# export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN=eyJhbGciOi...


# Authenticate to Red Hat portal using an API token.
# After the hypervisor is installed, 
# the role iso_rhel_download downloads a RHEL 9.2 ISO file. 
# The role uses one of the Red Hat APIs, which requires 
# an API token.
# Open the API token page. https://access.redhat.com/management/api
# Click the button to generate a token.
# Copy the token.
# Paste the token into an environment variable.
# export OFFLINE_TOKEN=eyJh...(about 600 more characters)...xmtyM


# Download Ansible libraries.
# Install collections and roles from Ansible Galaxy 
# (https://galaxy.ansible.com) and from Ansible Automation Hub
# (https://console.redhat.com/ansible/automation-hub).
# Installing from Ansible Automation Hub requires the env var 
# ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN.
# Install collections. 
ansible-galaxy collection install -r collections/requirements.yml 
# Install roles. 
ansible-galaxy role install -r roles/requirements.yml 


# create machines
# ansible-playbook main.yml
