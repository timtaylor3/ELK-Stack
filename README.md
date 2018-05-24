# ELK-Stack

**First and foremost:**  This work is highly derivative in that so far my original work is the install script. I'm scripting a custom install, so of course others have done this.

Imagine you work for a global corporation that does not provide a highly trained global team with the proper tools to do collaborative log analysis.  Imagine that an awesome tool exists, but in present form isn't scalable and/or is not secure enough for the corporate enterprise?  This is my motivation and starting point for this project.  To address this, I've started this project based on Phil Hagen's project [SOF-ELK](https://github.com/philhagen/sof-elk).  Many thanks to him and others for this work.  

My goal is to create a secure system that anyone can take and modify to their individual needs.  That means, no docker, no special voodoo in configuration files, or any kind of secret sauce.  The script should always work on the latest verion of CentOS and hopefully the lastet verion of ELK.  Keep in mind that the makers of ELK depreciate items frequently between versions, so this could be challenging.  

The end goal is that analyst in different locations can securely use the same tool/data for log analysis.  Ideally, a complete install would be accomplished by a script, so that anyone can easily modify and create their own secure ELK instance.  Also, in the future, I would like to add support for separate hosts handling elasticsearch, logstash and kibana.

## Enabled Security Features
* CentOS 7 with SELinux Enforcing 
* Firewall enabled and locked down
* SSL between filebeat and logstash  

## Status:
* Configure Filebeat to operate on separate nodes:         
  +    CentOS                                                     -- Complete
  +    Ubuntu                                                     -- Not Tested

## Next Items:
* Add X-Pack to the install script (Contains useful developer tools)
* Configure SSL to Nginx (Really important to get this done soon)
* Remaining Security configs to allow for multi-hosts stack:
  + Configure SSL between kibana and Nginx access  (Not really necessary if kibana and nginix are on the same host)
  + Configure SSL between Elasticsearch and Kibana (Not really necessary if elaselasticsearch and kibana are on the same host)
  + Configure SSL between logstash and elasticsearch (Not really necessary if logstash and elaselasticsearch are on the same host)

## Why CentOS?

I'm using CentOS 7 as my base operating system to ensure it can run in a Red Hat enviornment with little to no modification.  

I will be adding logstash config files as I have **time and logs** to validate the logstash configurations.  Since this is based on the hard work of Phil Phil Hagen's SOF-ELK, I have used some of the SOF-ELK configs as a starting point.  In this initial release only basic functionailty has been included; ie, no visualizations or dashboards.  

I welcome sample logs to parse as long as they are shareable and will not cause a rukas for me.  I'll take config files as long as there is some sample data available for validation.  I will not upload logstash configs that I have not personally tested.

## Hasn't someone already done this?

Sort of.  Take a look at [Security Onion](http://blog.securityonion.net/2017/06/towards-elastic-on-security-onion.html) if your are looking for network analysis functionality.  If you want a more mature system, a single user system, or security isn't a concern, check out [SOF-ELK](https://github.com/philhagen/sof-elk).  In most cases, one of these two systems might fit your needs.  If you need security, then it is likely, these won't work. This script and configurations will get you to the fun stuff faster (writing filters).  

## Assumptions

This project will always require some, well alot of site specific configuration.  Therefore, I assume the user know something about how Kibana works and can browse to the appropriate url, ie an IP or localhost, then setup a default index.  

Filebeat is setup expecting a top level directory of /logstash.  

Note regarding ingesting logs:  New syslog records can be ingested by placing them in a /logstash/syslog/year/.  The year will be added to the syslog date, since syslog doesn't store the year.  Otherwise, logs can be ingested simply by putting them in /logstash/some other dir, where file beat has been configured to parse "some other dir".  

## Filebeat Gotchas
Filebeat config files are very picky and white space in the wrong spot will cause error.  To create your own filebeat configs, I highly recommend duplicating an existing one and very carefully modifing it to work on the new directory.

## TODO, in no certain order: 
* Fix the sample HTTP log so it will parse properly. 
* Fix the install script to use the current host name all configurations.  
* Add the ability for graphics to be displayed on dashboards.
* Upload and maintain working VM to share
* Add the ability to:
    + Create basic dashboards and visualizations
    + Insert saved dashboards and visualizations
    + Create the default indexes on install, will require initial contrived data
* Maybe some documentation, would be nice (A blog perhaps?)
* Refine the install script to branch for Ubuntu.
* Maintenance scripts:
  + Key re-generation - Needs testing
  + Database/index reset - Not started
  + Reset Filebeat to re-ingest data - Not started
* More logstash filters.
* Logstash CSV output filter.
* Create a set of scripts to install on multiple systems (Need all security features implemented first).
