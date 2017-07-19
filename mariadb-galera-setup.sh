#!/bin/bash
gawk -F= '/^ID=/{print $2}' /etc/os-release > /home/id.txt
serverbuild=$(cat /home/id.txt)
echo " This is the Server Build: " $serverbuild >> /home/test
masterb=$1
cluster_name=$2
pub=$3
hostname=$4
master=$5
if [[ $serverbuild == *"ubuntu"* ]]
 then
	location=/etc/mysql/conf.d/galera.cnf
	wsrep_provider=/usr/lib/galera/libgalera_smm.so
elif [[ $serverbuild == *"centos"* ]]
 then
	location=/etc/my.cnf.d/server.cnf
	cp $location /home/server.bak
	rm -rf $location
	wsrep_provider=/usr/lib64/galera/libgalera_smm.so
else
	echo "Cannot determine Build Type... Exiting" >> /home/test
	exit 3
fi
echo "configuring database info" >> /home/test
echo "[mysqld]" >> $location
echo "binlog_format=ROW" >> $location
echo "default-storage-engine=innodb" >> $location
echo "innodb_autoinc_lock_mode=2" >> $location
echo "bind-address=0.0.0.0" >> $location
echo "" >> $location
if [ $masterb = true ]
 then
	echo "Setting Up Server As Master Server" >> /home/test
	echo "# Galera Provider Configuration" >> $location
	echo "wsrep_on=ON" >> $location
    echo "wsrep_provider=$wsrep_provider" >> $location
	echo "" >> $location
    echo "# Galera Cluster Configuration" >> $location
    echo "wsrep_cluster_name=\"$cluster_name\"" >> $location
    echo "wsrep_cluster_address=\"gcomm://$pub\"" >> $location
    echo "" >> $location
    echo "# Galera Synchronization Configuration" >> $location
    echo "wsrep_sst_method=rsync" >> $location
    echo "" >> $location
    echo "# Galera Node Configuration" >> $location
    echo "wsrep_node_address=\"$pub\"" >> $location
    echo "wsrep_node_name=\"$hostname\"" >> $location
    echo "" >> $location
    galera_new_cluster
else
	echo "Setting Up Server as slave" >> /home/test
	echo "Galera Provider Configuration" >> $location
    echo "wsrep_on=ON" >> $location
    echo "wsrep_provider=$wsrep_provider" >> $location
	echo "" >> $location
    echo "# Galera Cluster Configuration" >> $location
    echo "wsrep_cluster_name=\"$cluster_name\"" >> $location
    echo "wsrep_cluster_address=\"gcomm://$master,$pub\"" >> $location
    echo "" >> $location
    echo "# Galera Synchronization Configuration" >> $location
    echo "wsrep_sst_method=rsync" >> $location
    echo "" >> $location
    echo "# Galera Node Configuration" >> $location
    echo "wsrep_node_address=\"$pub\"" >> $location
    echo "wsrep_node_name=\"$hostname\"" >> $location
    echo "" >> $location
    systemctl start mysql
fi
