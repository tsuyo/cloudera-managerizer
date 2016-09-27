#!/bin/bash

# these are parameters which should be replaced
NEW_HOST=${NEW_HOST}
CLUSTER_HOSTS=${CLUSTER_HOSTS}
ROLE=${ROLE}
MYSQL_CONF=${MYSQL_CONF}
MYSQL_PASS=${MYSQL_PASS}

CUR_USER=${SUDO_USER:-$(tail -1 /etc/passwd | cut -d: -f1)}
CM_REPO=https://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo
JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jdk-8u102-linux-x64.tar.gz
JDK_VER=jdk1.8.0_102
MYSQL_CONN_URL=https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.39.tar.gz

# copy the cluster hosts to /etc/hosts
setupHosts() {
  # hostname change
  hostnamectl set-hostname ${NEW_HOST}
  echo "${CLUSTER_HOSTS}" >> /etc/hosts
  # for aws to persist this hostname after reboot
  [ -f "/etc/cloud/cloud.cfg" ] && echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg
}

setupRepo() {
  yum -y install wget
  (cd /etc/yum.repos.d/ && wget $CM_REPO)
}

installJDK() {
  (cd /tmp && wget --no-cookies --no-check-certificate \
  --header "Cookie: oraclelicense=accept-securebackup-cookie" ${JDK_URL})
  mkdir -p /usr/java
  (cd /usr/java && tar zxvf /tmp/jdk-*.tar.gz && rm /tmp/jdk-*.tar.gz)
  chown -R ${CUR_USER} /usr/java
  alternatives --install /usr/bin/java java /usr/java/${JDK_VER}/bin/java 1
  alternatives --install /usr/bin/jar jar /usr/java/${JDK_VER}/bin/jar 1
  alternatives --install /usr/bin/javac javac /usr/java/${JDK_VER}/bin/javac 1
  alternatives --install /usr/bin/jps jps /usr/java/${JDK_VER}/bin/jps 1
  echo JAVA_HOME=/usr/java/${JDK_VER} >> /etc/environment
}

installMySQLConnector() {
  (cd /tmp && wget ${MYSQL_CONN_URL} && tar zxvf mysql-connector-java-*.tar.gz && rm mysql-connector-java-*.tar.gz)
  mkdir -p /usr/share/java
  cp /tmp/mysql-connector-java-*/mysql-connector-java-*.jar /usr/share/java
  ln -s /usr/share/java/mysql-connector-java-*.jar /usr/share/java/mysql-connector-java.jar
}

fixInspector() {
  # change vm.swappiness
  sysctl vm.swappiness=10
  echo vm.swappiness=10 >> /etc/sysctl.conf
  # Transparent Huge Page Compaction is enabled and can cause significant performance problems.
  echo never > /sys/kernel/mm/transparent_hugepage/defrag
  echo 'echo never > /sys/kernel/mm/transparent_hugepage/defrag' >> /etc/rc.local
}

installCM() {
  yum -y install cloudera-manager-daemons cloudera-manager-server
}

installAndConfigDB() {
  yum install -y mariadb-server
  echo "${MYSQL_CONF}" > /etc/my.cnf
  /sbin/chkconfig mariadb on
  service mariadb start
  # create databases for cloudera manager
  mysql -e "CREATE DATABASE scm DEFAULT CHARACTER SET utf8"
  mysql -e "CREATE DATABASE amon DEFAULT CHARACTER SET utf8"
  mysql -e "CREATE DATABASE rman DEFAULT CHARACTER SET utf8"
  mysql -e "CREATE DATABASE metastore DEFAULT CHARACTER SET utf8"
  mysql -e "CREATE DATABASE sentry DEFAULT CHARACTER SET utf8"
  mysql -e "CREATE DATABASE nav DEFAULT CHARACTER SET utf8"
  mysql -e "CREATE DATABASE navms DEFAULT CHARACTER SET utf8"
  mysql -e "CREATE DATABASE oozie DEFAULT CHARACTER SET utf8"
  mysql -e "CREATE DATABASE hue DEFAULT CHARACTER SET utf8"
  mysql -e "GRANT ALL ON scm.* TO 'scm'@'%' identified by 'scm_password'"
  mysql -e "GRANT ALL ON amon.* TO 'amon'@'%' identified by 'amon_password'"
  mysql -e "GRANT ALL ON rman.* TO 'rman'@'%' identified by 'rman_password'"
  mysql -e "GRANT ALL ON metastore.* TO 'hive'@'%' identified by 'hive_password'"
  mysql -e "GRANT ALL ON sentry.* TO 'sentry'@'%' identified by 'sentry_password'"
  mysql -e "GRANT ALL ON nav.* TO 'nav'@'%' identified by 'nav_password'"
  mysql -e "GRANT ALL ON navms.* TO 'navms'@'%' identified by 'navms_password'"
  mysql -e "GRANT ALL ON oozie.* TO 'oozie'@'%' identified by 'oozie'"
  mysql -e "GRANT ALL ON hue.* TO 'hue'@'%' identified by 'secretpassword'"
  # the following 5 equals 'mysql_secure_installation'
  mysql -e "UPDATE mysql.user SET Password = PASSWORD(\"${MYSQL_PASS}\") WHERE User = 'root'"
  mysql -e "DROP USER ''@'localhost'"
  mysql -e "DROP USER ''@'$(hostname)'"
  mysql -e "DROP DATABASE test"
  mysql -e "FLUSH PRIVILEGES"

  /usr/share/cmf/schema/scm_prepare_database.sh mysql scm scm scm_password
}

startCM() {
  /sbin/chkconfig cloudera-scm-server on
  service cloudera-scm-server start
}

setupHosts
setupRepo
installJDK
installMySQLConnector
fixInspector
if [ "$ROLE" == "server" ]; then
  installCM
  installAndConfigDB
  startCM
fi
