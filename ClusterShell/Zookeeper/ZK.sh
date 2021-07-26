#!/bin/bash
Init(){
    DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
    ZKSERVERCMD=`for i in  ${DIR}; do find /${i} -type f  -name "zkServer.sh";done |awk 'NR==1{print}'`
    #获取IP地址
    HOSTIP=`grep "$(echo ${HOSTNAME})$" /etc/hosts|awk '{print $1}'`
    if [[ ! ${HOSTIP} ]]; then
        HOSTIP=`hostname -I|awk '{print $1}'`
    fi
}

get_KeepalivedStatus(){
    DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
    KEPPCONF=`for i in  ${DIR}; do find /${i} -type f  -name "keepalived.conf";done |awk 'NR==1{print}' ` 
    CLUSTERSTATE=`grep state  ${KEPPCONF} |awk '{print $2}'`
    if [[ ${CLUSTERSTATE} == 'MASTER' ]]; then
        CLUSTERSTATE=Master
    elif [[ ${CLUSTERSTATE} == 'BACKUP' ]]; then
        CLUSTERSTATE=Slave
    fi
}

#初始化
Init
TMPFILE=/tmp/zkstatus.tmp
if [[ ! ${ZKSERVERCMD} ]]; then
    #未安装ZK
    echo "${HOSTIP}##NoInstallZookeeper"
    exit
fi
$ZKSERVERCMD status &> ${TMPFILE}
ZK=`grep -i mode ${TMPFILE}`
if [[ ! ${ZK} ]]; then
    #未运行ZK
    echo "${HOSTIP}##NoInstallZookeeper"
    exit
fi
#判断集群状态
$ZKSERVERCMD print-cmd &> /tmp/zkver
ZKCONF=`awk '/config/{print $3}' ${TMPFILE}`
ZKPORT=`grep clientPort  ${ZKCONF}|awk -F= '{print $2}'`
#ZKPORT=`awk '/port/{print $4}' ${TMPFILE}|grep -Eo [0-9]+`
STATUS=`awk '/Mode/{print $2}' ${TMPFILE}`
ZKVER=`grep -Eo "zookeeper-[0-9]+\.[0-9]+\.[0-9]+" /tmp/zkver |sort|uniq`
if [[ ${STATUS} == 'standalone' ]]; then
    #单机模式
    ps -ef|grep -v grep|grep  keepalived|awk '{print $8}'|grep -w keepalived &> /dev/null
    if [[ $? -eq 0 ]]; then
            #有keepalived进程
            get_clusterStatus
            echo "${HOSTIP}:${ZKPORT}##Zookeeper##java##${ZKVER}##${CLUSTERSTATE}"
            exit
    fi
        echo "${HOSTIP}:${ZKPORT}##Zookeeper##java##${ZKVER}##OneNode"
        exit
else
    #集群模式
    echo "${HOSTIP}:${ZKPORT}##Zookeeper##java##${ZKVER}##Master"
fi