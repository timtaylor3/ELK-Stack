#!/bin/bash
# This install script was tested on CentOS 7 with SELinux enforcing.
# Installed ELK 5.4.2 with no issues

# This variable should point to the directory where this script resides.
# All of the config files should be in a directory named master-configs
# The master-configs directory should be a child directory to where the install script is located

INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Prep for install - epel-release is needed to install nginx
yum -y install epel-release

# Fix related to the installing of "epel-release"
semanage fcontext -a -t etc_t "/etc/updatedb.conf"
restorecon -v /etc/updatedb.conf

# copy repo and apply SELinux context label
cp master-configs/elk-config/elasticsearch.repo /etc/yum.repos.d/.
semanage fcontext -a -t system_conf_t "/etc/yum.repos.d(/.*)?"
restorecon -Rv /etc/yum.repos.d

# Install and configure ELK
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
yum -y install elasticsearch

sed -i '/#cluster.name: my-application/c\cluster.name: elk-cluster' /etc/elasticsearch/elasticsearch.yml
sed -i '/#node.name: node-1/c\node.name: elk-node-1' /etc/elasticsearch/elasticsearch.yml
sed -i '/#bootstrap.memory_lock: true/c\bootstrap.memory_lock: true ' /etc/elasticsearch/elasticsearch.yml
sed -i '/#network.host: 192.168.0.1/c\network.host: localhost' /etc/elasticsearch/elasticsearch.yml
sed -i '/#http.port: 9200/c\http.port: 9200' /etc/elasticsearch/elasticsearch.yml

# Fix elasticsearch.service
sed -i '/#LimitMEMLOCK=infinity/c\LimitMEMLOCK=infinity' /usr/lib/systemd/system/elasticsearch.service

# Fix elasticsearch
sed -i '/#MAX_LOCKED_MEMORY=unlimited/c\MAX_LOCKED_MEMORY=unlimited' /etc/sysconfig/elasticsearch

# Start elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

# Install kibana
yum -y install kibana

# configure kibana
sed -i '/#server.port: /s/^#//' /etc/kibana/kibana.yml
sed -i '/#server.host: /c\server.host: "0.0.0.0"' /etc/kibana/kibana.yml
# sed -i '/#server.name: "your-hostname"/c\server.name: "elk-host"' /etc/kibana/kibana.yml

# Hack to fix the server name line, uncomment the line and then replace the name
sed -i '/#server.name: /s/^#//' /etc/kibana/kibana.yml
sed -i -e "s|your-hostname|$HOSTNAME|g" /etc/kibana/kibana.yml

sed -i '/^#elasticsearch.url: /s/^#//' /etc/kibana/kibana.yml
# sed -i '/^#kibana.defaultAppId: "discover"/c\kibana.defaultAppId: "dashboard/Main-Dashboard"' /etc/kibana/kibana.yml
sed -i '/^#logging.quiet: false/c\logging.quiet: true' /etc/kibana/kibana.yml

# Start Kibana
systemctl enable kibana
systemctl start kibana

# Restart elasticsearch to be safe
systemctl daemon-reload
systemctl start elasticsearch.service

# Configure the firewall
echo "Copying the elk service config file"
cp master-configs/firewall/* /etc/firewalld/services/.

# Re-load to use the configs
echo "Reloading the firewall"
firewall-cmd --reload

# Apply SELinux context label
echo "Appling the SELinux context label"
semanage fcontext -a -t firewalld_etc_rw_t "/etc/firewalld/services(/.*)?"
restorecon -Rv /etc/firewalld/services

# Nginx
echo "Adding the http service"
firewall-cmd --zone=public --add-service http --permanent

# selinux port context label commands
echo "Appling the SELinux port context labels"

# Elasticsearch standard Configs
# Security note:  Ports 9200 & 9300 should not be accessible from another computer
echo "Adding the standard service ports"
firewall-cmd --zone=public --add-service elk-app --permanent
semanage port -a -t http_port_t -p tcp 5044
semanage port -a -t http_port_t -p tcp 5601
semanage port -a -t http_port_t -p tcp 9200
semanage port -a -t http_port_t -p tcp 9300

# Insert firewall-cmd and SELinux commands here as needed
# Example:  XXX = service name, #### = the port number
# echo "Adding the service ports for XXXX:"
# firewall-cmd --zone=public --add-service XXXX
# semanage port -a -t http_port_t -p tcp ####

# Re-load to install the services
echo "Reloading the firewall"
firewall-cmd --reload

# Install Logstash
yum -y install logstash

# Install logstash plugins
/usr/share/logstash/bin/logstash-plugin install logstash-input-log4j
/usr/share/logstash/bin/logstash-plugin install logstash-input-relp
/usr/share/logstash/bin/logstash-plugin install logstash-filter-translate
/usr/share/logstash/bin/logstash-plugin install logstash-filter-tld

# Configure logstash
mkdir -p /usr/local/elk/configfiles
mkdir -p /usr/local/elk/dashboards
mkdir -p /usr/local/elk/grok-patterns
mkdir -p /usr/local/elk/lib

# ELK configs
cp -r master-configs/configfiles/* /usr/local/elk/configfiles/.
cp -r master-configs/dashboards/* /usr/local/elk/dashboards/.
cp -r master-configs/lib/* /usr/local/elk/lib/.

cp -r master-configs/grok-patterns/* /usr/local/elk/grok-patterns/.
cp -r master-configs/lib/* /usr/local/elk/lib/.

chmod -R 755 /usr/local/elk/configfiles
ln -s /usr/local/elk/configfiles/* /etc/logstash/conf.d/.

semanage fcontext -a -t etc_t "/etc/logstash(/.*)?"
restorecon -Rv /etc/logstash/

systemctl enable logstash
systemctl start logstash.service

# Install filebeat
yum -y install filebeat

# Configure filebeat
mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.orig
cp master-configs/elk-config/filebeat.yml /etc/filebeat/filebeat.yml 
mkdir -p /usr/local/elk/lib/filebeat_inputs
cp master-configs/lib/filebeat_inputs/* /usr/local/elk/lib/filebeat_inputs/.

semanage fcontext -a -t etc_t "/etc/filebeat(/.*)?"
restorecon -Rv /etc/filebeat

# Start filebeat
systemctl enable filebeat
systemctl start filebeat

# Install nginx to handle port forwarding, since firewalld won't port forward  
# kibana won't listen on port 80

yum -y install nginx

cd $INSTALL_DIR
cp -f master-configs/nginx/nginx.conf /etc/nginx/nginx.conf
cp -f master-configs/nginx/kibana.conf /etc/nginx/conf.d/kibana.conf

# Fix SELinux context labels
semanage fcontext -a -t httpd_config_t "/etc/nginx/(/.*)?"
restorecon -Rv /etc/nginx

# Start nginx
nginx -t
systemctl enable nginx
systemctl start nginx

cd $INSTALL_DIR

# Maxmind
# ASOF Logstash 5.4.2, GeoLite2-ASN was not usueable.
# GeoLite2-City worked fine.
  
mkdir -p /usr/local/share/GeoIP/

cd master-configs/maxmind
wget -N http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz
wget -N http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz
wget -N http://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN.tar.gz

tar -xvf GeoLite2-City.tar.gz -C /usr/local/share/GeoIP/
tar -xvf GeoLite2-Country.tar.gz -C /usr/local/share/GeoIP/
tar -xvf GeoLite2-ASN.tar.gz -C /usr/local/share/GeoIP/
cd /usr/local/share/GeoIP/
find . -type f -name "*.mmdb" -exec ln -s '{}' \;
cd $INSTALL_DIR

# Insert test data

YEAR=`date +%Y`	
mkdir -p /logstash/syslog/${YEAR}
mkdir -p /logstash/httpd
# Create a syslog record for ingesting by file beat
SYSLOG_DATE=`date +"%b %m %H:%M:%S"`
echo $SYSLOG_DATE ${HOSTNAME} test-record[1]: First syslog record, inserted by ${USER} > /logstash/syslog/$YEAR/test.log

#Nginx sample
HDATE=`date -u +%d/%b/%Y:%H:%M:%S`
echo 127.0.0.1 - - [$HDATE] "GET /plugins/kibana/assets/discover.svg HTTP/1.1" 304 0 "http://127.0.0.1/app/kibana" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36" > /logstash/httpd/test.log

echo 192.168.0.10 - - [1$HDATE] "GET /presentations/logstash-monitorama-2013/images/kibana-search.png HTTP/1.1" 200 203023 "http://semicomplete.com/presentations/logstash-monitorama-2013/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.77 Safari/537.36" > /logstash/httpd/test.log
echo
echo
systemctl status filebeat
echo 
echo
systemctl status logstash
echo 
echo
systemctl status kibana
echo 
echo
systemctl status elasticsearch
echo

