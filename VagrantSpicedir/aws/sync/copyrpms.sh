#!/bin/sh

yum --nogpgcheck -y install unzip
yum --nogpgcheck -y install wget
echo 'Performing a ~250MB download of ScaleIO RPMs'
wget -nv ftp://ftp.emc.com/Downloads/ScaleIO/ScaleIO_RHEL6_Download.zip -O /tmp/ScaleIO_RHEL6_Download.zip
unzip -o /tmp/ScaleIO_RHEL6_Download.zip -d /tmp/scaleio/
cp /tmp/scaleio/ScaleIO_*_RHEL7_Download/*.rpm /etc/puppet/modules/scaleio/files/.
cp /tmp/scaleio/ScaleIO_*_Gateway_*_Download/*.rpm /etc/puppet/modules/scaleio/files/.
version=`basename /tmp/scaleio/ScaleIO_*_RHEL7_Download/EMC-ScaleIO-mdm* .el7.x86_64.rpm | cut -d- -f4,5,6`
sed -i "/\$version = /c\$version = \'$version\'" /etc/puppet/manifests/site.pp
