#!/bin/bash

BASE="cloudera-managerizer"
TEMPLATE="${BASE}.tpl"
MYSQL_CONF=$(cat my.cnf.tpl 2>/dev/null)

usageAndExit() {
  echo "Usage: $0 [-v] -h <hostname> -c <cluster_hosts> -r <role> [-p <db_password>]" >&2
  exit 1
}

VERBOSE=no
while getopts "vh:c:r:p:" opt; do
  case $opt in
    v)
      VERBOSE="yes"
      ;;
    h)
      NEW_HOST=$OPTARG
      ;;
    c)
      CLUSTER_HOSTS=$OPTARG
      ;;
    r)
      ROLE=$OPTARG
      ;;
    p)
      MYSQL_PASS=$OPTARG
      ;;
    \?)
      usageAndExit
      ;;
    :)
      usageAndExit
      ;;
  esac
done

[ -z "${NEW_HOST}" ] && usageAndExit
[ -z "${CLUSTER_HOSTS}" ] && usageAndExit
[ "${ROLE}" == "server" ] && [ "${MYSQL_PASS}" == "" ] && usageAndExit

if [ "$VERBOSE" == "yes" ]; then
  echo "Hostname: ${NEW_HOST}"
  echo "Cluster Hosts:"
  echo "${CLUSTER_HOSTS}"
  echo "Role: ${ROLE}"
fi  

INTER=$(cat ${TEMPLATE} \
| sed "s/\${NEW_HOST}/${NEW_HOST}/" \
| sed "s/\${ROLE}/${ROLE}/" \
| sed "s/\${MYSQL_PASS}/${MYSQL_PASS}/")
echo "${INTER/'${CLUSTER_HOSTS}'/\"$CLUSTER_HOSTS\"}" > _tmp.sh
INTER=$(cat _tmp.sh)
echo "${INTER/'${MYSQL_CONF}'/\"$MYSQL_CONF\"}" > _tmp.sh
mv _tmp.sh ${BASE}-${NEW_HOST}.sh
chmod +x ${BASE}-${NEW_HOST}.sh
