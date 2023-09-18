for GUEST in \
  git.lab.example.com         \
  message.lab.example.com     \
  monitor.lab.example.com     \
  id.lab.example.com          \
  ipsal.lab.example.com       \
  gateway.lab.example.com     
do 
  sudo virsh shutdown $GUEST
  sleep 1
done
# takes a couple minutes to shut down. 
# check with
# sudo watch virsh list --all
