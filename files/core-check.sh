for GUEST in \
  git.lab.example.com         \
  message.lab.example.com     \
  monitor.lab.example.com     \
  id.lab.example.com          \
  ipsal.lab.example.com       \
  gateway.lab.example.com     
do 
  echo -n $GUEST
  ssh nick@$GUEST echo ': alive'
  sleep 1
done
