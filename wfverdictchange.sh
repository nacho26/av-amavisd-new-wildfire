#/bin/bash

#Proxy, if you need it like me
#export https_proxy=http://10.0.0.1:3128/

apikey=
redishost=
redispw=

verdictchange=$(/usr/local/bin/panwfapi.py -K $apikey -h eu.wildfire.paloaltonetworks.com --changed --date -1 -x | /usr/bin/xml2 | /bin/grep -v md5 | /usr/bin/awk -F/ '{print $4}' | /bin/grep -v "^$"$
verdictchange2=$(/usr/bin/printf "%s 604800 %s\n" $verdictchange)
/usr/bin/xargs -n 3 /usr/bin/redis-cli -h $redishost -a $redispw -n 2 setex <<<$verdictchange2
