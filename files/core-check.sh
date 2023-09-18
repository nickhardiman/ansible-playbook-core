for GUEST in \
  git.core.example.com         \
  message.core.example.com     \
  monitor.core.example.com     \
  id.core.example.com          \
  ipsal.core.example.com       \
  gateway.core.example.com     
do 
  echo -n $GUEST
  ssh nick@$GUEST echo ': alive'
  sleep 1
done
