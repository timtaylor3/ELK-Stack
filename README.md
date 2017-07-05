# ELK-Stack

**First and foremost:**  This work is highly derivative in that so far my original work is the install script. 

Imagine you work for a global corporation that does not provide a highly trained global team with the proper tools to do collaborative log analysis.  Imagine that an awesome tool exists, but in present form isn't scalable and/or is not secure enough for the corporate enterprise?  This is my motivation and starting point for this project.  To address this, I've started this project based on Phil Hagen's project [SOF-ELK](https://github.com/philhagen/sof-elk).  Many thanks to him and others for this work.  

My goal is to create a secure system that anyone can take and modify to their individual needs.  That means, no OS version lock in, no docker, special voodoo in configuration files, or any kind of secret sauce.  The script should always work on the latest verion of CentOS and hopefully the lastet verion of ELK.  Keep in mind that the makers of ELK depreciate items frequently between verions, so this could be challenging.  

This is my first attempt to create a secure ELK v5 stack.  The end goal is that analyst in different locations can securely use the same tool/data for log analysis.  My end goal is to have a fully functional ELKv5 stack running with X-Pack and SSL enabled.  Ideally, a complete install would be accomplished by a script, so that anyone can easily modify and create their own secure ELK instance.  

## Status:

+ CentOS 7 with SELinux Enforcing                                 -- Complete
+ Lastet ELK 5 Stack will install on CentOS 7                     -- Complete
+ Configure Filebeat to operate on separate nodes:         
  +    CentOS                                                     -- Complete
  +    Ubuntu                                                     -- Not Tested
+ Utilize SSL to connect Filebeat with Logstash                   -- Complete
+ X-Pack installation                                             -- Complete
+ Make Kibana work again                                          -- WIP
+ Connect logstash to elasticsearch using encryption              -- Configured not tested

## Issues:
+ After X-Pack installation and configuration, kibana is running, but not responding/listening.
  ++ No kibana error messages.


## Why CentOS?

I'm using CentOS 7 as my base operating system to ensure it can run in a Red Hat enviornment with little to no modification.  It shouldn't be to hard to adapt this script to Ubuntu, if that's your Linux flavor of choice.  I may support Ubuntu in the future.

My current focus is a, secure functionality; ie, get data in and allow the user to create their own visualzations and dashboards.  Gettting the X-Pack Security module and SSL enabled is top priority.

I will be adding logstash config files as I have **time and logs** to validate the logstash configurations.  Since this is based on the hard work of Phil Phil Hagen's SOF-ELK, I have used some of the SOF-ELK configs as a starting point.  In this initial release only basic functionailty has been included; ie, no visualizations or dashboards.  

I welcome sample logs to parse as long as they are shareable and will not cause a rukas for me.  I'll take config files as long as there is some sample data available for validation.  I will not upload logstash configs that I have not personally tested.

## Hasn't someone already done this

Sort of.  Take a look at [Security Onion](http://blog.securityonion.net/2017/06/towards-elastic-on-security-onion.html) if your are looking for network analysis functionality.  If you want a more mature system, check out [SOF-ELK](https://github.com/philhagen/sof-elk).  In most cases, one of these two systems might fit your needs.

Want to roll your own from scratch, start here: [Giles's Notes](https://www.gilesorr.com/blog/elkbeats-intro.html) or here: [HowToForge](https://www.howtoforge.com/tutorial/how-to-install-elastic-stack-on-centos-7/).  Note on the latter link, the ssl configuration will work, but isn't optimal.

## Assumptions

I assume the user know something about how Kibana works and can browse to the appropriate url, ie an IP or localhost.  To view the two records inserted at the end of the installation, create a default index of logstash-\* and an index named httpdlog-\* to see the sample records on the discovery table.  Don't forget you may need to change the time range to see the records.

New syslog records can be ingested by placing them in a /logstash/syslog/year/.  The year will be added to the syslog date, since syslog doesn't store the year.  New httpd logs can be ingested simply by putting them in /logstash/httpd.  

## TODO: 
* Fix the sample HTTP log so it will parse properly.
* Create an initial syslog entry that has more fields parsed out, perhaps mimick an ssh log entry.
* Keep checking to see if logstash can use the maxmind db with ASN data (ASOF 5.4.3, this didn't work.)
* Add the ability for graphics to be displayed in a markdown 
* Upload and maintain working VM to share
* Add the ability to:
    + "cat" or "zcat" logs into the stack (I'm not the big fan of this capability since it requires the opening and closing of ports on the firewall.
    + insert saved dashboards and visualizations
    + Create the indexes on install
    + Build logstash pipelines based on logs
* Maybe some documentation
* Create a brand name?
* Install X-Pack and SSL using a script (I could use some advice/assistance on this piece.)
    + X-Pack with no SSL
    + Add SSL
    + Automate the creation of a secure ELK Cluster
    + Automate the installation
* Refine the install script
* More to come
