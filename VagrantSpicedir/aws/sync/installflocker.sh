#!/bin/sh

# TODO, Run Flocker installl steps.

if selinuxenabled; then setenforce 0; fi
yum clean all
yum install -y https://clusterhq-archive.s3.amazonaws.com/centos/clusterhq-release$(rpm -E %dist).noarch.rpm
yum install -y clusterhq-flocker-node

# Docker is started after flokcer is install
# in this file VagrantSpicedir/spice-conf/images_config.rb 
#systemctl enable docker.service
#systemctl start docker.service

mkdir /etc/flocker
chmod 0700 /etc/flocker

# TODO can we do key managment this way?
# I think vagrant spice puts key into the nodes :)
if [ $HOSTNAME == "tb.vagrantspice.local" ]; then
    printf '%s\n' "on the tb host"
    cd /etc/flocker/
    flocker-ca initialize mycluster
    flocker-ca create-control-certificate tb.vagrantspice.local
    cp control-tb.vagrantspice.local.crt /etc/flocker/control-service.crt
    cp controltb.vagrantspice.local.key /etc/flocker/control-service.key
    cp cluster.crt /etc/flocker/cluster.crt
    chmod 0600 /etc/flocker/control-service.key

     # We have three nodes in the cluster.
    flocker-ca create-node-certificate
#    < COPY THIS AS THE FIRST NODE >
    flocker-ca create-node-certificate
#    < COPY INTO second-node/node2.crt|key>
    flocker-ca create-node-certificate
#    < COPY INTO second-node/node2.crt|key>

    # Create an API certificate for the plugin
    flocker-ca create-api-certificate plugin

    # Create a general purpose user api cert
    flocker-ca create-api-certificate vagrantspice
fi

#if [ $HOSTNAME != "mdm1.vagrantspice.local" ]; then
#   SCP, with pem file in sync folder?
#fi

# TODO Install scaleio_flocker_driver
git clone https://github.com/emccorp/scaleio-flocker-driver
cd scaleio-flocker-driver/
/opt/flocker/bin/python setup.py install

# TODO edit agent.yml
cp /etc/flocker/example_sio_agent.yml /etc/flocker/agent.yml
sed -i -e \"s/^hostname:*/hostname: tb.vagrantspice.local/g\" /etc/flocker/agent.yml
sed -i -e \"s/^mdm:*/mdm: mdm1.vagrantspice.local/g\" /etc/flocker/agent.yml

yum install -y python-pip build-essential libssl-devel libffi-devel python-devel
pip install git+https://github.com/clusterhq/flocker-docker-plugin.git

# TODO start	

