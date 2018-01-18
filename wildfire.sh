#!/bin/bash
#
# For Doc see https://github.com/nacho26/av-amavisd-new-wildfire/
# 
#
#
#

# If you need Proxysupport to access the wildfire cloud like me
#export https_proxy="http://10.0.0.1:3128"

# redis host
redishost=10.0.0.1
# redis db password
redispw=password
# redis db id normal 0
redisdb=0
# wildfire api key
wfapikey=apikey
# wildfire cloud address usual wildfire.paloaltonetworks.com
wfhost=eu.wildfire.paloaltonetworks.com

FILES=$1
for f in $FILES/*
do
   mimetype=$(/usr/bin/file -b --mime-type $f)
   filesize=$(/usr/bin/stat -c%s "$f")
   if [[ $mimetype == "application/x-dosexec" && $filesize -le 10000000 ]] || \
      [[ $mimetype == "application/msword" && $filesize -le 2000000 ]] || \
      [[ $mimetype == "application/vnd.openxmlformats-officedocument.wordprocessingml.document" && $filesize -le 2000000 ]] || \
      [[ $mimetype == "application/vnd.ms-excel" && $filesize -le 2000000 ]] || \
      [[ $mimetype == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" && $filesize -le 2000000 ]] || \
      [[ $mimetype == "application/java-archive" && $filesize -le 5000000 ]] || \
      [[ $mimetype == "application/x-rar" && $filesize -le 10000000 ]] || \
      [[ $mimetype == "application/pdf" && $filesize -le 1000000 ]] || \
      [[ $mimetype == "application/x-shockwave-flash" && $filesize -le 5000000 ]] || \
      [[ $mimetype == "application/x-7z-compressed" && $filesize -le 10000000 ]]
   then
        hash=($(/usr/bin/sha256sum $f))
        verdict=$(/usr/bin/redis-cli -h $redishost -a $redispw -n $redisdb get $hash)
        /usr/bin/logger "wf: $f $mimetype $hash $verdict checking"

        if [ -z "$verdict" ]
         then
          verdict=$(/usr/local/bin/panwfapi.py -K $wfapikey -h $wfhost --verdict --hash "$hash" -x | /bin/grep '<verdict' | /usr/bin/awk -F">" '{print $2}' | /usr/bin/awk -F"<" '{print $1}')
          /usr/bin/logger "wf: $f $mimetype $hash $verdict"

          if [[ $verdict == "-102" && $mimetype != "application/pdf" ]]
           then
            /usr/local/bin/panwfapi.py -K $wfapikey -h $wfhost --submit $f > /dev/null
            /usr/bin/logger "wf: $f $mimetype $filesize uploaded"
            continue

          elif [ "$verdict" -ge 0 ]
            then
              /usr/bin/redis-cli -h $redishost -a $redispw -n $redisdb setnx $hash $verdict > /dev/null
              /usr/bin/redis-cli -h $redishost -a $redispw -n $redisdb expire $hash 86400 > /dev/null
              /usr/bin/logger "wf: $f $mimetype $hash $verdict in redis eingetragen"
           fi

         fi

        if [ "$verdict" -ge 1 ]
         then
          /usr/bin/logger "wf: $f $mimetype $hash $verdict blockiert"
          exit 60
         fi
   fi
done

exit 50
