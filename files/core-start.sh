# start
for GUEST in \
  gateway.core.example.com     \
  ipsal.core.example.com       \
  id.core.example.com          \
  message.core.example.com     \
  git.core.example.com         \
  monitor.core.example.com     
do 
  sudo virsh start $GUEST
  sleep 10
done
