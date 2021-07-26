#!/bin/bash
PORT=$(netstat -antup | grep dockerd|awk '{print $4}'|awk -F: '{print $NF}')
PROCESS=$(ps -ef |grep -v grep |grep dockerd|awk '{print $8}'|awk -F"/" '{print $NF}')
VERSION=$(docker version 2>/dev/null  | grep Version | awk NR==1 | awk '{print $2}')
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
Get_HostIP
DOCKER_EXIST=`ps -ef|grep dockerd |grep -v grep`
if [[ ! ${DOCKER_EXIST} ]]; then
    #不存在DOCKER进程
    echo "${IP_ADDR}##NoInstallDocker"
    exit
fi
ps -ef |grep -v grep |grep dockerd|awk '{print $8}'|awk -F"/" '{print $NF}' &> /dev/null
if [[ $? -eq 0 ]]; then
    #单机
        echo "${IP_ADDR}:${PORT:="null"}##Docker##${PROCESS}##${VERSION}##OneNode"
        exit
fi

