#!/bin/bash
# Install script for Elasticsearch v7. 
# Tested on Ubuntu VM 18.04.04 Desktop -> Needs more testing.
# TODO:  This script needs to be changed to use ansible.

# Test for Ubuntu
OS="/etc/lsb-release" 

if [ -f $OS ]; then
   echo "Ubuntu found"
else
   echo "Ubuntu NOT Found"
   exit 1
fi

INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEVICE="$(ip route | grep default | awk '{print $5}')"
IP="$(ip a | grep $DEVICE | grep inet |  awk '{print $2}' | cut -d "/" -f 1)"

apt update -y >/dev/null 2>&1
apt upgrade -y >/dev/null 2>&1

echo "Installing Required Packages"

apt install -y openjdk-8-jre apt-transport-https wget curl >/dev/null 2>&1

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -

echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list

echo "Updating before installing the ELK Stack"
apt update -y  >/dev/null 2>&1

echo "Installing elasticsearch"

apt install elasticsearch -y >/dev/null 2>&1

echo "Applying initial elasticsearch configs"

sed -i '/#cluster.name: my-application/c\cluster.name: elk-cluster' /etc/elasticsearch/elasticsearch.yml
sed -i '/#node.name: node-1/c\node.name: elk-node-1' /etc/elasticsearch/elasticsearch.yml
sed -i '/#bootstrap.memory_lock: true/c\bootstrap.memory_lock: true ' /etc/elasticsearch/elasticsearch.yml
sed -i '/#network.host: 192.168.0.1/c\network.host: localhost' /etc/elasticsearch/elasticsearch.yml
sed -i '/#http.port: 9200/c\http.port: 9200' /etc/elasticsearch/elasticsearch.yml

systemctl daemon-reload >/dev/null 2>&1
systemctl enable elasticsearch >/dev/null 2>&1
systemctl start elasticsearch >/dev/null 2>&1

echo "Installing Kibana"

apt install kibana -y >/dev/null 2>&1

echo "Configuring Kibana"

sed -i '/#server.port: /s/^#//' /etc/kibana/kibana.yml
# sed -i '/#server.host: /c\server.host: "0.0.0.0"' /etc/kibana/kibana.yml

# Hack to fix the server name line, uncomment the line and then replace the name
sed -i '/#server.name: /s/^#//' /etc/kibana/kibana.yml
sed -i -e "s|your-hostname|$HOSTNAME|g" /etc/kibana/kibana.yml

sed -i '/^#elasticsearch.url: /s/^#//' /etc/kibana/kibana.yml
# sed -i '/^#kibana.defaultAppId: "discover"/c\kibana.defaultAppId: "dashboard/Main-Dashboard"' /etc/kibana/kibana.yml
sed -i '/^#logging.quiet: false/c\logging.quiet: true' /etc/kibana/kibana.yml

systemctl daemon-reload >/dev/null 2>&1
systemctl start kibana >/dev/null 2>&1
systemctl enable kibana >/dev/null 2>&1

echo "Installing Logstash"

apt install -y logstash >/dev/null 2>&1

cp ./master-configs/configfiles/* /etc/logstash/conf.d/.

echo "Installing Filebeat"

apt install -y filebeat >/dev/null 2>&1

# Start filebeat
systemctl enable filebeat  >/dev/null 2>&1
systemctl start filebeat

mkdir -p /logtash/plaso
mkdir -p /logstash/csv

echo "Installing nginx"

apt install nginx -y >/dev/null 2>&1

echo "Configuring nginx"
echo "Work In Progress, Needs Virtual Server configs applied"

#cp -f master-configs/nginx/nginx.conf /etc/nginx/nginx.conf
#cp -f master-configs/nginx/kibana.conf /etc/nginx/conf.d/kibana.conf

echo "Starting nginx"
systemctl enable nginx  >/dev/null 2>&1
systemctl start nginx
 
cd $INSTALL_DIR

curl -X GET "localhost:9200/"

echo "For standalone file beat collects the following needs to be accomplished."
echo "Copy /root/certs/logstash-forwarder.crt to /root/certs/on the file beat collectors"
echo ""
echo "scp -r root@elk-master:/root/certs /root/."
echo ""
echo "This is a required step to enable ssl on filebeat collectors"
echo "This step is not necessary if installing filebeat on this computer"
echo
echo "Execute install_filebeat.sh on each device that will be collecting logs"
