#!/bin/bash
sudo yum update -y
sudo yum install -y curl unzip tar wget sed gcc* openssl-devel openssl krb5-workstation krb5-libs python-devel python java-1.8.0-openjdk-devel snappy openssh-server openssh-clients
sudo systemctl disable firewalld
sudo service firewalld stop
sudo setenforce 0
enabled=0
sudo sed -i '1i10.0.0.2   master.cdp\n10.0.0.3   node1.cdp\n10.0.0.4   node2.cdp\n10.0.0.5   node3.cdp' /etc/hosts
echo "${public_ssh_key}" >> ~/.ssh/authorized_keys
sudo chmod 700 /root/.ssh
sudo chmod 600 /root/.ssh/authorized_keys
sudo systemctl start chronyd
sudo systemctl enable chronyd
sudo wget -O- https://clemlabs.s3.eu-west-3.amazonaws.com/RPM-GPG-KEY-SHA256-Jenkins -O /tmp/RPM-GPG-KEY-SHA256-Jenkins
sudo rpm --import /tmp/RPM-GPG-KEY-SHA256-Jenkins
sudo wget -O /etc/yum.repos.d/odp.repo https://clemlabs.s3.eu-west-3.amazonaws.com/centos9-aarch64/odp-release/1.2.2.0-128/odp.repo
sudo wget -O /etc/yum.repos.d/ambari.repo https://clemlabs.s3.eu-west-3.amazonaws.com/centos9-aarch64/ambari-release/2.7.9.0.0-61/ambari.repo
sudo yum update -y
sudo yum install odp-select.aarch64 -y
sudo yum install ambari-agent.aarch64 -y
sudo yum install ambari-server.aarch64 -y
sudo yum install postgresql-server postgresql-contrib -y
yes "" | sudo ambari-server setup -j /usr/lib/jvm/java-1.8.0-openjdk
sudo ambari-server start
sudo ambari-agent start
sudo useradd console
sudo usermod -aG wheel console
echo "console:1aB@2bC#" | sudo chpasswd
echo ' 
#!/bin/bash
sudo ambari-server stop
sudo -u hdfs hdfs dfs -chown root:root /odp/apps/1.2.2.0-128/hbase
sudo -u hdfs hdfs dfs -chmod 755 /odp/apps/1.2.2.0-128/hbase
sudo -u hdfs hdfs dfs -put /var/lib/ambari-agent/tmp/yarn-ats/1.2.2.0-128/hbase.tar.gz /odp/apps/1.2.2.0-128/hbase/
sudo -u hdfs hdfs dfs -chmod 555 /odp/apps/1.2.2.0-128/hbase
sudo ambari-server restart
' >> ~/hdfscorrections.sh
chmod +x ~/hdfscorrections.sh
echo ' 
#!/bin/bash
sudo ambari-server stop
sudo sed -i "s/^#port = 5432/port = 5432/" /var/lib/pgsql/data/postgresql.conf
echo "host all hive 10.0.0.2/32 trust" | sudo tee -a /var/lib/pgsql/data/pg_hba.conf
sudo -u postgres psql -U postgres -c "CREATE DATABASE hive;"
sudo -u postgres psql -U postgres -c "CREATE USER hive WITH PASSWORD '\''hive'\'';"
sudo -u postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE hive TO hive;"
sudo service postgresql restart
sudo yum install postgresql-jdbc.noarch -y
sudo ambari-server setup -j /usr/lib/jvm/java-1.8.0-openjdk --jdbc-db=postgres --jdbc-driver=/usr/share/java/postgresql-jdbc.jar
sudo ambari-server start
' >> ~/hivesetup.sh
chmod +x ~/hivesetup.sh

echo '
export ZOOKEEPER_HOME="/usr/odp/1.2.2.0-128/zookeeper"
export PATH=$PATH:$ZOOKEEPER_HOME/bin
export PATH=$ZOOKEEPER_HOME/bin:$PATH

export KAFKA_HOME="/usr/odp/1.2.2.0-128/kafka"
export PATH=$PATH:$KAFKA_HOME/bin
export PATH=$KAFKA_HOME/bin:$PATH

export NIFI_HOME="/usr/odp/1.2.2.0-128/nifi"
export PATH=$PATH:$NIFI_HOME/bin
export PATH=$NIFI_HOME/bin:$PATH

export SPARK_HOME="/usr/odp/1.2.2.0-128/spark3"
export PATH=$PATH:$SPARK_HOME/bin
export PATH=$SPARK_HOME/bin:$PATH

export HIVE_HOME="/usr/odp/1.2.2.0-128/hive"
export PATH=$PATH:$HIVE_HOME/bin
export PATH=$HIVE_HOME/bin:$PATH
' >> ~/.bashrc
source ~/.bashrc