#-------------------------
# Set up the hypervisor 
# Instructions 

# !!! make a new role machine-hypervisor-configure.yml
# and migrate much of this crap to that and to collection roles. 

# Log into your RHEL 9 install host.
# Download this script.
#   curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-core/main/bootstrap.sh 
# Read it. 
# Edit and change my details to yours.
# More details below. 
# 1. Set RHSM (Red Hat Subscription Manager) account.
# 2. Set ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN.
# 3. Set OFFLINE_TOKEN.
# 4. Change git name, email and user.
# Run this script
#   bash -x bootstrap.sh

#-------------------------
# Edit and change my details to yours.


# 1. Set RHSM (Red Hat Subscription Manager) account.
# If you don't have one, get a free
# Red Hat Enterprise Linux Individual Developer Subscription.
# Sign up for your free RHSM (Red Hat Subscription Manager) account at 
#  https://developers.redhat.com/.
# Check your account works by logging in at https://access.redhat.com/.
# You can register up to 16 physical or virtual nodes.
# This core service inventory lists 8.
# (https://github.com/nickhardiman/ansible-playbook-lab/blob/main/inventory.ini)
RHSM_USER=my_developer_user
RHSM_PASSWORD='my developer password'


# 2. Set ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN.
# Anyone with an RHSM account can use Red Hat Automation Hub.
# You can download Ansible collections after authenticating with a token.
#
# Open the API token page. 
#   https://console.redhat.com/ansible/automation-hub/token#
# Click the button to generate a token.
# Copy the token.
# Paste the token here. 
# The ansible-galaxy command looks for this environment variable.
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN=eyJhbGciOi...(about 800 more characters)...asdf
# (You can also put your offline token in ansible.cfg.)


# 3. Set OFFLINE_TOKEN.
# Authenticate to Red Hat portal using an API token.
# After the hypervisor is installed, 
# the role https://github.com/nickhardiman/ansible-collection-platform/tree/main/roles/iso_rhel_download
# downloads RHEL install DVD ISO files. 
# The role uses one of the Red Hat APIs, which requires an API token.
#
# Open the API token page. 
#   https://access.redhat.com/management/api
# Click the button to generate a token.
# Copy the token.
# Paste the token here. 
# The playbook will copy the value from this environment variable.
export OFFLINE_TOKEN=eyJh...(about 600 more characters)...xmtyM


# 4. Change git name, email and user.
GIT_NAME="Nick Hardiman"
GIT_EMAIL=nick@email-domain.com
GIT_USER=nick



# That's it. 
# No need to change anything below here. 


#-------------------------
# Bash functions 
# https://phoenixnap.com/kb/bash-function


configure_host_os() {
     echo get the hypervisor host ready
     # subscription-manager register
     # Uses Simple Content Access, no need to attach a subscription
     # Package update
     # dnf -y update
     # systemctl reboot
     # Set hostname 
     # hostnamectl hostname host.core.example.com
     # Enable nested virtualization? 
     # In /etc/modprobe.d/kvm.conf 
     # options kvm_amd nested=1
     # SSH security
     # If SSH service on this box is accessible to the Internet
     # Use key pairs only, disable password login
     # For more information, see
     #   man sshd_config
     # echo "AuthenticationMethods publickey" >> /etc/ssh/sshd_config
}


setup_git() {
     echo install and configure git
     sudo dnf install --assumeyes git
     git config --global user.name         "$GIT_NAME"
     git config --global user.email        $GIT_EMAIL
     git config --global github.user       $GIT_USER
     git config --global push.default      simple
     # default timeout is 900 seconds (https://git-scm.com/docs/git-credential-cache)
     git config --global credential.helper 'cache --timeout=1200'
     git config --global pull.rebase false
     # check 
     git config --global --list
}


does_ansible_user_exist() {
     ansible_user_exists=false
     id ansible_user
     res_id=$?
     if [ $res_id -eq 0 ]
     then
       ansible_user_exists=true
     fi
}


setup_ansible_user_account() {
     # Add an Ansible user account.
     # Create the ansible_user account (not using --system). 
     sudo useradd ansible_user
}


setup_ansible_user_keys() {
     # Create a new keypair.
     # Put keys in /home/ansible_user/.ssh/ and keep copies in /home/nick/.ssh/.
     ssh-keygen -f ./ansible-key -q -N ""
     mv ansible-key  ansible-key.priv
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
     # This location is set in ansible.cfg. 
     # private_key_file = /home/nick/.ssh/ansible-key.priv
     # Copy the keys to your SSH config directory. 
     cp ansible-key.priv  ansible-key.pub  $HOME/.ssh/
     # Clean up.
     rm ansible-key.priv  ansible-key.pub
}


copy_ansible_user_public_key() {
     USER_ANSIBLE_PUBLIC_KEY=$(<$HOME/.ssh/ansible-key.pub)
     # Public key is fixed here. 
     # https://github.com/nickhardiman/ansible-collection-platform/blob/main/roles/libvirt_machine_kickstart/defaults/main.yml#L88
     # [source,shell]
     # ....
     # user_ansible_public_key: |
     #   ssh-rsa AAA...YO0= pubkey for ansible
     # ....
}


setup_ansible_user_sudo() {
     # Allow passwordless sudo.
     sudo su -c 'echo "ansible_user      ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/ansible_user'
}


check_ansible_user() {
     # Check your work. 
     # Log in with key-based authentication and run the ID command as root.
     ssh \
          -o StrictHostKeyChecking=no \
          -i $HOME/.ssh/ansible-key.priv \
          ansible_user@localhost  \
          sudo id
     res_ssh=$?
     if [ $res_ssh -ne 0 ]; then 
          echo "error: can't SSH and sudo with ansible_user"
          exit $res_ssh
     fi
}


install_ansible_core() {
     # install Ansible
     sudo dnf install --assumeyes ansible-core
}


clone_my_ansible_collection() {
     # get my libvirt collection.
     # I'm not using ansible-galaxy because I am actively developing this role.
     # Check out the directive in ansible.cfg in some playbooks.
     mkdir -p ~/ansible/collections/ansible_collections/nick/
     cd ~/ansible/collections/ansible_collections/nick/
     # If the repo has already been cloned, git exits with this error message. 
     #   fatal: destination path 'libvirt-host' already exists and is not an empty directory.
     # !!! not uploaded
     git clone https://github.com/nickhardiman/ansible-collection-platform.git platform
}

clone_my_ansible_playbook() {
     # Get my lab playbook.
     mkdir -p ~/ansible/playbooks/
     cd ~/ansible/playbooks/
     git clone https://github.com/nickhardiman/ansible-playbook-core.git
     cd ansible-playbook-core/
}


download_ansible_libraries() {
    # Install collections and roles from Ansible Galaxy 
    # (https://galaxy.ansible.com) 
    # and from Ansible Automation Hub
    # (https://console.redhat.com/ansible/automation-hub).
    # Installing from Ansible Automation Hub requires the env var 
    # ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN.
    # install Ansible libvirt collection to the central location.
    sudo ansible-galaxy collection install community.libvirt \
        --collections-path /usr/share/ansible/collections
    # check 
    ls /usr/share/ansible/collections/ansible_collections/community/
    # Install other collections to ~/.ansible/collections/
    # (https://github.com/nickhardiman/ansible-playbook-core/blob/main/ansible.cfg#L13)
    cd ~/ansible/playbooks/ansible-playbook-core/
    ansible-galaxy collection install -r collections/requirements.yml 
    # Install roles. 
    ansible-galaxy role install -r roles/requirements.yml 
}



add_rhsm_account_to_vault () {
     # Create a new vault file.
     cp vault-credentials-plaintext.yml ~/vault-credentials.yml
     cat << EOF >>  ~/vault-credentials.yml
rhsm_user: "$RHSM_USER"
rhsm_password: "$RHSM_PASSWORD"
EOF
     # Encrypt the new file. 
     echo 'my vault password' >  ~/my-vault-pass
     ansible-vault encrypt --vault-pass-file ~/my-vault-pass ~/vault-credentials.yml
}


setup_ca_certificate() {
    # Role https://github.com/nickhardiman/ansible-collection-platform/tree/main/roles/server_cert
    # expects to find a CA certificate and matching private key.
    # CA private key, a file on the hypervisor here.
    #   /etc/pki/tls/private/ca-certificate.key
    # CA certificate, a file on the hypervisor here.
    #   /etc/pki/ca-trust/source/anchors/ca-certificate.pem
    # https://hardiman.consulting/rhel/9/security/id-certificate-ca-certificate.html
    CA_CN=ca.build.example.com
    mkdir ~/ca
    cd ~/ca
    # Create a CA private key.
    openssl genrsa \
        -out $CA_CN_key.pem 2048
    # Create a CA certificate.
    openssl req \
        -x509 \
        -sha256 \
        -days 365 \
        -nodes \
        -key ./$CA_CN_key.pem \
        -subj "/C=UK/ST=mystate/O=myorg/OU=myou/CN=$CA_CN" \
        -out $CA_CN_cert.pem
    # https://hardiman.consulting/rhel/9/security/id-certificate-ca-trust.html
    # Trust the certificate. 
    sudo cp ./$CA_CN_cert.pem /etc/pki/ca-trust/source/anchors/ca-certificate.pem
    sudo cp ./$CA_CN_key.pem /etc/pki/tls/private/ca-certificate.key
    sudo update-ca-trust
    # Clean up.
    # rm cakey.pass cakey.pem careq.pem cacert.pem
}


run_playbook() {
    cd ~/ansible/playbooks/ansible-playbook-core/
    # create machines
    ansible-playbook \
        --vault-pass-file ~/my-vault-pass  \
        --extra-vars="user_ansible_public_key=$USER_ANSIBLE_PUBLIC_KEY" \
    main.yml
}


#-------------------------
# main 

configure_host_os
setup_git
does_ansible_user_exist
if $ansible_user_exists 
then
    echo ansible_user already exists
else
    setup_ansible_user_account
    setup_ansible_user_keys
    copy_ansible_user_public_key
    setup_ansible_user_sudo
fi
check_ansible_user
install_ansible_core
clone_my_ansible_collection
clone_my_ansible_playbook
download_ansible_libraries
add_rhsm_account_to_vault
setup_ca_certificate
run_playbook

#-------------------------
