# start
for GUEST in \
  gateway.lab.example.com     \
  ipsal.lab.example.com       \
  id.lab.example.com          \
  message.lab.example.com     \
  git.lab.example.com         \
  monitor.lab.example.com     
do 
  sudo virsh start $GUEST
  sleep 10
done
