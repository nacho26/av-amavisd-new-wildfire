# av-amavisd-new-wildfire

This Project consists of to bash scripts witch cloud be used with amavisd-new. The first script wildfire.sh can be integrated to amavisd-new as virusscanner. The scripts use Palo Alto Networks Wildfire API to compute supported filetyps against ther sandbox.


How does it work:


 amavisd-new for example passes the follogwing information to the script:
 
  /var/amavis/tmp/amavis-20171218T132307-01008-XGcahmXN/parts to $1

  example listing of that folder:
  
   ls -l /var/amavis/tmp/amavis-20171218T132307-01008-XGcahmXN/parts
   
   -rw-r----- 1 amavis amavis     75 Dec 18 13:23 p001
   
   -rw-r----- 1 amavis amavis 152336 Dec 18 13:23 p002
   
   -rw-r----- 2 amavis amavis 206713 Dec 18 13:23 p004

 -	First compute a sha256 Hash and determine the mimetype over the files presented by amavisd-new
 
 -	Checks if the mimetype is supported by Wildfire to go on
 
 -	Checks if the hash is present in the local redis storage and uses the verdict (benign|malware) 
 
 -	If the hash isn’t present in redis storge it ask the wildfire cloud for a verdict.
 
 -	Depending on the answer from the wildfire cloud –> if it’s known the verdict gets written in the redis storage and used or 
    if it’s unknown the file gets uploaded to the Cloud for inspection.


 requirements:
 
 
  You need a Wildfire Subscription to get use of their sandbox system.
 
 
  I tested that on a debian 8 system. So you need those apps installed:
 
 
 
  file
  
 
  stat
  
  
  sha256sum
  
  
  redis-cli
  
  
  logger
  
  
  panwfapi.py
  
  
  grep
  
  
  awk
  
  
  and redis-server (if redis db is on the same server) - configuring the redis server is autoside of this guide


  Panwfapi.py you get at https://github.com/kevinsteves/pan-python with 
  
  “git clone https://github.com/kevinsteves/pan-python.git“
  
  and then “cd pan-python/ “ -> ./setup.py install

  Add that to your amavisd-new config to use the script:  
  
  @av_scanners = (
  
  ['Palo Alto Wildfire API', '/usr/local/sbin/wildfire.sh', "{}", [50], [60], ],
  
  ...

  to do: get amavisd-new to support a third exit code for the case where wildfire hasn't a verdict 
  
  because the sample is new to wildfire. Then amavisd-new should tempfail (smtp 450) the mail.

The second script can be run on a daily basis to get use of changed verdicts. for example a benign that was later classivied as malware and so on.


The secound script wfverdictchange.sh can be run on a daily basis. It's updates changed verdicts to your redis storage. For example Malware that was formerly classified as benign or vice versa.
