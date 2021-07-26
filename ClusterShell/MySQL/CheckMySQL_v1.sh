#!/bin/bash
Get_HostIP(){
    IP_TMP_VAR=`ip addr | grep  inet|grep " scope global"|awk '{print $NF}'`
    for i in ${IP_TMP_VAR}
    do
       RESULT_IS_NULL=`ls /etc/sysconfig/network-scripts/*${i}* 2>/dev/null`
       if [ -n "${RESULT_IS_NULL}" ];then
            IP_ADDR=`ip addr | grep  inet|grep " scope global"|grep ${i}|awk '{print $2}'|awk -F '/' '{print $1}'`
       fi
    done
}
get_clusterStatus(){
    DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
    KEPPCONF=`for i in  ${DIR}; do find /${i} -type f  -name "keepalived.conf";done |awk 'NR==1{print}' ` 
    CLUSTERSTATE=`grep state  ${KEPPCONF} |awk '{print $2}'`
    if [[ ${CLUSTERSTATE} == 'MASTER' ]]; then
        CLUSTERSTATE=Master
    elif [[ ${CLUSTERSTATE} == 'BACKUP' ]]; then
        CLUSTERSTATE=Slave
    fi
}
Get_HostIP
PORTS=`ss -tnlp|awk '/mysqld/{print $4}'|awk -F: '{print $NF}'|sort |uniq`
if [[ ! ${PORTS} ]]; then
    #没找到MySQLd进程
    echo "${IP_ADDR}##NoInstallMySQL"
    exit
fi
DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
MYSQLD_CMD=`for i in  ${DIR}; do find /${i} -type f  -name "mysqld";done ` 
for i in ${MYSQLD_CMD};do
    ${i} --version &> /dev/null
    if [[ $? -eq 0 ]]; then
        VERSION=`${i} --version |awk '{print $3}'`
    else
        continue
    fi

done
#VERSION=`${MYSQLD_CMD} --version |awk '{print $3}'`
ps -ef|grep -v grep|grep  keepalived|awk '{print $8}'|grep -w keepalived &> /dev/null
if [[ $? -eq 0 ]]; then
    get_clusterStatus
    for PORT in ${PORTS}; do
        echo "${IP_ADDR}:${PORT}##MySQL##mysqld##${VERSION}##${CLUSTERSTATE}"
    done
    exit
fi
for PORT in ${PORTS}; do
    echo "${IP_ADDR}:${PORT}##MySQL##mysqld##${VERSION}##OneNode"
done
