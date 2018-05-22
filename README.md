# ELK-Stack

**First and foremost:**  This work is highly derivative in that so far my original work is the install script. I'm scripting a custom install, so of course others have done this.

Imagine you work for a global corporation that does not provide a highly trained global team with the proper tools to do collaborative log analysis.  Imagine that an awesome tool exists, but in present form isn't scalable and/or is not secure enough for the corporate enterprise?  This is my motivation and starting point for this project.  To address this, I've started this project based on Phil Hagen's project [SOF-ELK](https://github.com/philhagen/sof-elk).  Many thanks to him and others for this work.  

My goal is to create a secure system that anyone can take and modify to their individual needs.  That means, no docker, no special voodoo in configuration files, or any kind of secret sauce.  The script should always work on the latest verion of CentOS and hopefully the lastet verion of ELK.  Keep in mind that the makers of ELK depreciate items frequently between versions, so this could be challenging.  

X-Pack is not free, so that convenience is out. I'm looking for alternatives.  I may re-visit this as an option in the future.

The end goal is that analyst in different locations can securely use the same tool/data for log analysis.  Ideally, a complete install would be accomplished by a script, so that anyone can easily modify and create their own secure ELK instance.  Also, in the future, I would like to add support for separate hosts handling elasticsearch, logstash and kibana.

## Status:

+ CentOS 7 with SELinux Enforcing                                 -- Complete
+ Latest ELK 6 Stack will install on CentOS 7                     -- Complete
+ Configure Filebeat to operate on separate nodes:         
  +    CentOS                                                     -- Complete
  +    Ubuntu                                                     -- Not Tested
+ Utilize SSL to connect Filebeat with Logstash                   -- Complete
+ Logstash configurations need to be updated to remove logic where "Type" is used in favor of "Tags"  -- Complete

## Next Item:
+ Configure SSL between Elasticsearch and Kibana
+ Configure SSL Kibana browser access 
+ Create a custom log on method in-lieu of X-Pack

## Why CentOS?

I'm using CentOS 7 as my base operating system to ensure it can run in a Red Hat enviornment with little to no modification.  It shouldn't be to hard to adapt this script to Ubuntu, if that's your Linux flavor of choice.  I may support Ubuntu in the future.

I will be adding logstash config files as I have **time and logs** to validate the logstash configurations.  Since this is based on the hard work of Phil Phil Hagen's SOF-ELK, I have used some of the SOF-ELK configs as a starting point.  In this initial release only basic functionailty has been included; ie, no visualizations or dashboards.  

I welcome sample logs to parse as long as they are shareable and will not cause a rukas for me.  I'll take config files as long as there is some sample data available for validation.  I will not upload logstash configs that I have not personally tested.

## Hasn't someone already done this

Sort of.  Take a look at [Security Onion](http://blog.securityonion.net/2017/06/towards-elastic-on-security-onion.html) if your are looking for network analysis functionality.  If you want a more mature system or security isn't a concern, check out [SOF-ELK](https://github.com/philhagen/sof-elk).  In most cases, one of these two systems might fit your needs.  

If you need customization, then it is likely, these won't work. This script and configurations will get you to the fun stuff faster.

## Assumptions

I assume the user know something about how Kibana works and can browse to the appropriate url, ie an IP or localhost.  To view the two records inserted at the end of the installation, create a default index of logstash-\* and an index named httpdlog-\* to see the sample records on the discovery table.  Don't forget you may need to change the time range to see the records.

New syslog records can be ingested by placing them in a /logstash/syslog/year/.  The year will be added to the syslog date, since syslog doesn't store the year.  New httpd logs can be ingested simply by putting them in /logstash/httpd.  

## TODO, in no certain order: 
* Fix the sample HTTP log so it will parse properly. (Not an easy task)
* Add the ability for graphics to be displayed on the dashboards.
* Upload and maintain working VM to share
* Add the ability to:
    + "cat" or "zcat" logs into the stack (I'm not the big fan of this capability since it requires the opening and closing of ports on the firewall.
    + Create basic dashboards and visualizations
    + Insert saved dashboards and visualizations
    + Create the default indexes on install, will require initial data
* Maybe some documentation, would be nice.
* Refine the install script to branch for Ubuntu.
* Maintaince scripts:
  + Key re-generation - Needs testing
  + Database/index reset - Not started
  + Reset Filebeat to re-ingest data - Not started

* More to come
