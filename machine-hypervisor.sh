# Set up the hypervisor 

# !!! make a new role machine-hypervisor-configure.yml
# and migrate much of this crap to that and to collection roles. 

# Log into hypervisor.
# Download this script.
#   curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-lab/main/machine-hypervisor.sh 
# Read it. 
# Edit and change my details to yours.
# Set ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN (see below)
# Run this script
#   bash -x machine-hypervisor.sh


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
useradd ansible_user
# Copy the keys to ansible_user's SSH config directory. 
mkdir /home/ansible_user/.ssh
chmod 0700 /home/ansible_user/.ssh
cp ansible-key.priv  /home/ansible_user/.ssh/id_rsa
chmod 0600 /home/ansible_user/.ssh/id_rsa
cp ansible-key.pub  /home/ansible_user/.ssh/id_rsa.pub
# enable SSH to localhost with key-based login
cat ansible-key.pub >> /home/ansible_user/.ssh/authorized_keys
chmod 0600 /home/ansible_user/.ssh/authorized_keys
chown -R ansible_user:ansible_user /home/ansible_user/.ssh
# Keep a spare set of keys handy. 
# Copy the keys to your SSH config directory. 
cp ansible-key.priv  ansible-key.pub  $HOME/.ssh/
rm ansible-key.priv  ansible-key.pub
# This location is set in ansible.cfg. 
# private_key_file = /home/nick/.ssh/ansible-key.priv


# Allow passwordless sudo.
echo 'ansible_user      ALL=(ALL)       NOPASSWD: ALL' > /etc/sudoers.d/ansible_user 


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
cd ~/ansible/
git clone https://github.com/nickhardiman/ansible-playbook-lab.git
cd ansible-playbook-lab


# Authenticate to Red Hat Automation Hub using a token.
# Get a token from https://console.redhat.com/ansible/automation-hub/token#
# Set an environment variable.
# export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN=eyJhbGciOi...


# Download Ansible libraries.
# Install collections. 
ansible-galaxy collection install -r collections/requirements.yml 
# Install roles. 
ansible-galaxy role install -r roles/requirements.yml 


# set up the QEMU/KVM/libvirt hypervisor
# ansible-playbook --ask-become-pass machine-hypervisor.yml

