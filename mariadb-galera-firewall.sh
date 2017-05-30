#!/bin/bash
gawk -F= '/^ID=/{print $2}' /etc/os-release > /home/id.txt
serverbuild=$(cat /home/id.txt)
echo " This is the Server Build: " $serverbuild >> /home/test
service="Mariadb-Galera"
title="Mariadb Clustering Ports"
description="Mariadb Ports required for running Mariadb-Galera which include 3306,4567,4568,4444/tcp & 4567/udp"
port1="3306"
port2="4567"
port3="4568"
port4="4444"
protocol="tcp"
protocol2="udp"
echo "Firewall Configuration" >> /home/test
if [[ $serverbuild == *"ubuntu"* ]]
 then
	echo "[$service]" >> /etc/ufw/applications.d/$service
    echo "title=$title" >> /etc/ufw/applications.d/$service
    echo "description=$description" >> /etc/ufw/applications.d/$service
    echo "ports=$port1,$port2,$port3,$port4/$protocol|$port2/$protocol2" >> /etc/ufw/applications.d/$service
    ufw app update $service
	ufw allow in OpenSSH
    ufw allow in $service
    ufw enable
    ufw status >> /home/test
elif [[ $serverbuild == *"centos"* ]]
 then
	dnf install firewalld -y
	echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" >> /etc/firewalld/services/$service.xml
	echo "<service>" >> /etc/firewalld/services/$service.xml
	echo "   <short>$title</short>" >> /etc/firewalld/services/$title.xml
	echo "   <description>$description</description>" >> /etc/firewalld/services/$service.xml
	echo "   <port protocol=\"$protocol\" port=\"$port1\"/>" >> /etc/firewalld/services/$service.xml
	echo "   <port protocol=\"$protocol\" port=\"$port2\"/>" >> /etc/firewalld/services/$service.xml	
	echo "   <port protocol=\"$protocol\" port=\"$port3\"/>" >> /etc/firewalld/services/$service.xml
	echo "   <port protocol=\"$protocol\" port=\"$port4\"/>" >> /etc/firewalld/services/$service.xml
	echo "   <port protocol=\"$protocol2\" port=\"$port2\"/>" >> /etc/firewalld/services/$service.xml	
	echo "</service>" >> /etc/firewalld/services/$service.xml
	firewall-offline-cmd --zone=public --add-interface=eth0
	firewall-offline-cmd --set-default-zone=public
	firewall-offline-cmd --zone=public --add-service=ssh
	firewall-offline-cmd --zone=public --add-service=$service
	echo "Default Zone" >> /home/test
	firewall-offline-cmd --get-default-zone >> /home/test
	firewall-offline-cmd --info-zone=public >> /home/test
	systemctl start firewalld
	systemctl enable firewalld
else
	echo "Cannot determine Build Type... Exiting" >> /home/test
	exit 3
fi  
echo "END FIREWALL CONFIG" >> /home/test

