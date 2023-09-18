for GUEST in \
  git.core.example.com         \
  message.core.example.com     \
  monitor.core.example.com     \
  id.core.example.com          \
  ipsal.core.example.com       \
  gateway.core.example.com     
do 
  sudo virsh shutdown $GUEST
  sleep 1
done
# takes a couple minutes to shut down. 
# check with
# sudo watch virsh list --all
