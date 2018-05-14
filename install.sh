#!/bin/bash
# Install script for Elasticsearch v6. Version 6.2 tested
# This install script was tested on CentOS 7 with SELinux enforcing.
# CentOS VM was created using Server with GUI & Development Tools and Standard System Security Profile selected

INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEVICE="$(ip route | grep default | awk '{print $5}')"
IP="$(ip a | grep $DEVICE | grep inet |  awk '{print $2}' | cut -d "/" -f 1)"

# Test for  CENTOS
CENTOS="/etc/centos-release" 

if [ -f $CENTOS ]; then
   echo "CentOS found"
else
   echo "CentOS NOT Found"
   exit 1
fi

echo "Installing epel-release"
yum -y install epel-release >/dev/null 2>&1

semanage fcontext -a -t etc_t "/etc/updatedb.conf" >/dev/null 2>&1
restorecon -v /etc/updatedb.conf >/dev/null 2>&1

echo "Setting up the ELK repo" 
cp master-configs/elk-config/elasticsearch.repo /etc/yum.repos.d/.
semanage fcontext -a -t system_conf_t "/etc/yum.repos.d(/.*)?" >/dev/null 2>&1
restorecon -Rv /etc/yum.repos.d >/dev/null 2>&1

echo "Installing elasticsearch"
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch >/dev/null 2>&1
yum -y install elasticsearch >/dev/null 2>&1

sed -i '/#cluster.name: my-application/c\cluster.name: elk-cluster' /etc/elasticsearch/elasticsearch.yml
sed -i '/#node.name: node-1/c\node.name: elk-node-1' /etc/elasticsearch/elasticsearch.yml
sed -i '/#bootstrap.memory_lock: true/c\bootstrap.memory_lock: true ' /etc/elasticsearch/elasticsearch.yml
sed -i '/#network.host: 192.168.0.1/c\network.host: localhost' /etc/elasticsearch/elasticsearch.yml
sed -i '/#http.port: 9200/c\http.port: 9200' /etc/elasticsearch/elasticsearch.yml

echo "Fixing various elastisearch settings"
sed -i '/#LimitMEMLOCK=infinity/c\LimitMEMLOCK=infinity' /usr/lib/systemd/system/elasticsearch.service
sed -i '/#MAX_LOCKED_MEMORY=unlimited/c\MAX_LOCKED_MEMORY=unlimited' /etc/sysconfig/elasticsearch

systemctl daemon-reload
systemctl enable elasticsearch.service >/dev/null 2>&1
systemctl start elasticsearch.service

echo "Installing Kibana"
yum -y install kibana >/dev/null 2>&1

echo "Configuring Kibana"
sed -i '/#server.port: /s/^#//' /etc/kibana/kibana.yml
# sed -i '/#server.host: /c\server.host: "0.0.0.0"' /etc/kibana/kibana.yml

# Hack to fix the server name line, uncomment the line and then replace the name
sed -i '/#server.name: /s/^#//' /etc/kibana/kibana.yml
sed -i -e "s|your-hostname|$HOSTNAME|g" /etc/kibana/kibana.yml

sed -i '/^#elasticsearch.url: /s/^#//' /etc/kibana/kibana.yml
# sed -i '/^#kibana.defaultAppId: "discover"/c\kibana.defaultAppId: "dashboard/Main-Dashboard"' /etc/kibana/kibana.yml
sed -i '/^#logging.quiet: false/c\logging.quiet: true' /etc/kibana/kibana.yml

systemctl enable kibana >/dev/null 2>&1
systemctl start kibana

systemctl daemon-reload
systemctl start elasticsearch.service

echo "Copying the elk firewall service config files"
cp master-configs/firewall/* /etc/firewalld/services/.

echo "Reloading the firewall"
firewall-cmd --reload

echo "Appling the SELinux context label"
semanage fcontext -a -t firewalld_etc_rw_t "/etc/firewalld/services(/.*)?" >/dev/null 2>&1 
restorecon -Rv /etc/firewalld/services >/dev/null 2>&1

echo "Adding the http service (port 80)"
firewall-cmd --zone=public --add-service http --permanent

# echo "Adding the https service (port 443)"
firewall-cmd --zone=public --add-service https --permanent

echo "Applying the SELinux port context labels"

# Security note: Presently only 80 and 5044 are need by external hosts
echo "Adding filebeat port (port 5044)"
firewall-cmd --zone=public --add-service elk-filebeat --permanent
semanage port -a -t http_port_t -p tcp 5044 >/dev/null 2>&1

# firewall-cmd --zone=public --add-service elk-kibana --permanent
semanage port -a -t http_port_t -p tcp 5601 >/dev/null 2>&1
semanage port -a -t http_port_t -p tcp 9200 >/dev/null 2>&1
semanage port -a -t http_port_t -p tcp 9300 >/dev/null 2>&1

echo "Reloading the firewall"
firewall-cmd --reload

echo "Installing Logstash"
yum -y install logstash >/dev/null 2>&1

# echo "Installing Logstash plugins"
# /usr/share/logstash/bin/logstash-plugin install logstash-input-log4j >/dev/null 2>&1
# /usr/share/logstash/bin/logstash-plugin install logstash-input-relp >/dev/null 2>&1 
# /usr/share/logstash/bin/logstash-plugin install logstash-filter-translate >/dev/null 2>&1
# /usr/share/logstash/bin/logstash-plugin install logstash-filter-tld >/dev/null 2>&1

# GeoIP fix to allow the use of GeoLite2-ASN
# /usr/share/logstash/bin/logstash-plugin update logstash-filter-geoip >/dev/null 2>&1
# updating beats
# /usr/share/logstash/bin/logstash-plugin update logstash-input-beats >/dev/null 2>&1

echo "Configuring Logstash"
mkdir -p /usr/local/elk/configfiles
mkdir -p /usr/local/elk/dashboards
mkdir -p /usr/local/elk/grok-patterns
mkdir -p /usr/local/elk/lib

cp -r master-configs/configfiles/* /usr/local/elk/configfiles/.

# cp -r master-configs/dashboards/* /usr/local/elk/dashboards/.
cp -r master-configs/lib/* /usr/local/elk/lib/.
cp -r master-configs/grok-patterns/* /usr/local/elk/grok-patterns/.

# chmod -R 755 /usr/local/elk/configfiles
ln -s /usr/local/elk/configfiles/* /etc/logstash/conf.d/. >/dev/null 2>&1

semanage fcontext -a -t etc_t "/etc/logstash(/.*)?" >/dev/null 2>&1
restorecon -Rv /etc/logstash/ >/dev/null 2>&1

echo "Setting up SSL to use between filebeat and Logstash"
cd /etc/pki/tls
openssl req -subj /CN=elk-master -x509 -days 3650 -batch -nodes -newkey rsa:4096 -keyout /etc/pki/tls/private/logstash-forwarder.key -out /etc/pki/tls/certs/logstash-forwarder.crt  >/dev/null 2>&1

cd $INSTALL_DIR

rm -rf master-configs/elk-config/logstash-forwarder.crt
cp /etc/pki/tls/certs/logstash-forwarder.crt master-configs/elk-config/.
mkdir -p /root/certs

rm -rf /root/certs/logstash-forwarder.crt
cp /etc/pki/tls/certs/logstash-forwarder.crt /root/certs/.

systemctl enable logstash >/dev/null 2>&1
systemctl start logstash.service

# Install nginx to handle port forwarding, since firewalld won't port forward  
# and kibana won't listen on port 80

echo "Installing and configuring nginx"
yum -y install nginx >/dev/null 2>&1

cd $INSTALL_DIR
cp -f master-configs/nginx/nginx.conf /etc/nginx/nginx.conf
cp -f master-configs/nginx/kibana.conf /etc/nginx/conf.d/kibana.conf

semanage fcontext -a -t httpd_config_t "/etc/nginx/(/.*)?" >/dev/null 2>&1 
restorecon -Rv /etc/nginx >/dev/null 2>&1

echo "Starting nginx"
systemctl enable nginx  >/dev/null 2>&1
systemctl start nginx

cd $INSTALL_DIR
 
echo "Setting up GeoIP from Maxmind"
mkdir -p /usr/local/share/GeoIP/

mkdir -p master-configs/maxmind
cd master-configs/maxmind
wget -N http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz >/dev/null 2>&1
wget -N http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz >/dev/null 2>&1
wget -N http://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN.tar.gz >/dev/null 2>&1

tar -xf GeoLite2-City.tar.gz -C /usr/local/share/GeoIP/
tar -xf GeoLite2-Country.tar.gz -C /usr/local/share/GeoIP/
tar -xf GeoLite2-ASN.tar.gz -C /usr/local/share/GeoIP/

cd /usr/local/share/GeoIP/

find . -type f -name "*.mmdb" -exec ln -s '{}' \;

cd $INSTALL_DIR

echo "Copy /root/certs/logstash-forwarder.crt to /root/certs/on the file beat collectors"
echo ""
echo "scp -r root@elk-master:/root/certs /root/."
echo ""
echo "This is a required step to enable ssl on filebeat collectors"
echo "This step is not necessary if installing filebeat on this computer"
echo
echo "Execute install_filebeat.sh on each device that will be collecting logs"



