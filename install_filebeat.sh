#!/bin/bash
# Install script for Filebeat v6. Version 6.2 tested
# This install script was tested on CentOS 7 with SELinux enforcing.
# CentOS VM was created using Server with GUI & Development Tools and Standard System Security Profile selected
#
# Not tested: Installing on Ubuntu
#
# All of the config files should be in a directory named master-configs
# The master-configs directory should be a child directory to where the install script is located
#
# This script is run after the main install script on a host resolveable to elk-master

INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Test for  CENTOS
CENTOS="/etc/centos-release" 

if [ -f $CENTOS ]; then
   echo "Installing filebeat on CentOS."

   cp master-configs/elk-config/elasticsearch.repo /etc/yum.repos.d/.  

   semanage fcontext -a -t system_conf_t "/etc/yum.repos.d(/.*)?"  
   restorecon -Rv /etc/yum.repos.d  >/dev/null 2>&1

   rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch  
   yum -y install filebeat  >/dev/null 2>&1

else
   # STATUS:  Not tested
   UBUNTU="$(lsb_release -d | grep Ubuntu | cut -f2 | cut -d ' ' -f1)"  
   if [ $UBUNTU -eq 'Ubuntu' ]; then
      echo "Installing filebeat on Ubuntu."
      wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
      echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee -a /etc/apt/sources.list.d/elasticsearch-6.x.list
      apt-get update 
      apt-get -y install filebeat
   else
      echo "Ubuntu not found"
      echo "No valid OS found, exiting..."
      exit 1
   fi
fi

mkdir -p /etc/pki/tls/certs/

# no clobber in case installing on elk-master
cp -n /root/certs/logstash-forwarder.crt /etc/pki/tls/certs/.

# Configure filebeat
mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.orig
cp master-configs/elk-config/filebeat.yml /etc/filebeat/filebeat.yml 
mkdir -p /usr/local/elk/lib/filebeat_inputs
cp master-configs/lib/filebeat_inputs/* /usr/local/elk/lib/filebeat_inputs/.

semanage fcontext -a -t etc_t "/etc/filebeat(/.*)?"
restorecon -Rv /etc/filebeat

# Start filebeat
systemctl enable filebeat  >/dev/null 2>&1
systemctl start filebeat

mkdir -p /logstash/cas
mkdir -p /logstash/csv
mkdir -p /logstash/httpd
mkdir -p /logstash/syslog
