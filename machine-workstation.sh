# log into workstation
# download and run this script
#   curl -o - https://raw.githubusercontent.com/nickhardiman/homelab/main/machine-workstation-configure.sh | bash -x

# SSH 
HOST=host1.lab.example.com
# set up password-less remote login
# if using the workstation CLI, not the host1 console or gnome desktop
# copy SSH public key from workstation to host1
USER=nick
ssh-copy-id $USER@$HOST

# test
# connect to the remote machine
ssh $USER@$HOST echo hello from $HOST	

