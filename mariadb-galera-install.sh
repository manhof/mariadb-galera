#!/bin/bash
gawk -F= '/^ID=/{print $2}' /etc/os-release > /home/id.txt
serverbuild=$(cat /home/id.txt)
echo " This is the Server Build: " $serverbuild >> /home/test
datastore=$1
if [[ $serverbuild == *"ubuntu"* ]]
 then
  apt-get install software-properties-common -y 
  apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
  add-apt-repository 'deb [arch=amd64,i386,ppc64el] https://mirrors.evowise.com/mariadb/repo/10.1/ubuntu xenial main'
  apt update -y
  openssl rand -base64 32 > /home/pw.txt
  pass=$( cat /home/pw.txt)
  echo "Root Password has been created" >> /home/test
  echo $pass >> /home/test                
  export DEBIAN_FRONTEND=noninteractive
  debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password password PASS'
  debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password_again password PASS'
  apt-get install mariadb-server -y
  mysql -uroot -pPASS -e "SET PASSWORD = PASSWORD('$pass');"
  #rm -rf /home/pw.txt
  apt-get install rsync -y
elif [[ $serverbuild == *"centos"* ]]
 then
  echo "# MariaDB 10.1 CentOS repository list - created 2017-05-22 16:39 UTC" >> /etc/yum.repos.d/MariaDB.repo
  echo "# http://downloads.mariadb.org/mariadb/repositories/" >> /etc/yum.repos.d/MariaDB.repo
  echo "[mariadb]" >> /etc/yum.repos.d/MariaDB.repo
  echo "name = MariaDB" >> /etc/yum.repos.d/MariaDB.repo
  echo "baseurl = http://yum.mariadb.org/10.1/centos7-amd64" >> /etc/yum.repos.d/MariaDB.repo
  echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB" >> /etc/yum.repos.d/MariaDB.repo
  echo "gpgcheck=1" >> /etc/yum.repos.d/MariaDB.repo
  echo "Mariadb Repo Added" >> /home/test
  dnf install MariaDB-server -y
  dnf install MariaDB-client -y
  dnf install MariaDB-compat -y
  dnf install galera -y
  dnf install socat -y
  dnf install jemalloc -y
  dnf install rsync -y
  systemctl start mariadb
  openssl rand -base64 32 > /home/pw.txt
  pass=$( cat /home/pw.txt)
  echo "" /home/test
  echo $pass >> /home/test
  echo "" >> /home/test 
  mysql -e "UPDATE mysql.user SET Password = PASSWORD('$pass') WHERE User = 'root'"
  echo "changed root password " >>/home/test
  mysql -e "DROP USER ''@'localhost'"
  echo "killed an users " >>/home/test
  mysql -e "DROP USER ''@'$(hostname)'"
  echo "killed an users 2" >>/home/test
  mysql -e "DROP DATABASE test"
  echo "drop test db " >>/home/test
  mysql -e  "Delete FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
  echo "dissalow remote login for root " >>/home/test
  mysql -e "FLUSH PRIVILEGES"
  echo "flush" >> /home/test
  systemctl stop mysql
else
 echo "Cannot determine Build Type... Exiting" >> /home/test
 exit 3
fi
systemctl stop mysql
rsync -av /var/lib/mysql $datastore
mv /var/lib/mysql /var/lib/mysql.bak
sed -i -e 's+/var/lib/mysql+/mnt/mariadb/mysql+g' /etc/mysql/my.cnf
	
	
   
