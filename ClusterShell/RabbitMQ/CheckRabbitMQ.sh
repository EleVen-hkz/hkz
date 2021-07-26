#!/bin/bash
Get_HostIP(){
    IP_TMP_VAR=`ip addr | grep  inet|grep " scope global"|awk '{print $NF}'`
    for i in ${IP_TMP_VAR}
    do
       RESULT_IS_NULL=`ls /etc/sysconfig/network-scripts/*${i}* 2>/dev/null`
       if [ -n "${RESULT_IS_NULL}" ];then
            IP_ADDR=`ip addr | grep  inet|grep " scope global"|grep ${i}|awk '{print $2}'|awk -F '/' '{print $1}'|awk 'NR==1{print}'`
       fi
    done
} 
get_KeepalivedStatus(){
    DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|ru n"`
    KEPPCONF=`for i in  ${DIR}; do find /${i} -type f  -name "keepalived.conf";done |awk 'NR==1{print}' ` 
    CLUSTERSTATE=`grep state  ${KEPPCONF} |awk '{print $2}'`
    if [[ ${CLUSTERSTATE} == 'MASTER' ]]; then
        CLUSTERSTATE=Master
    elif [[ ${CLUSTERSTATE} == 'BACKUP' ]]; then
        CLUSTERSTATE=Slave
    fi
}

Get_HostIP
PIDS=` ss -tnlp|grep  "beam"|awk -F"pid=" '{print $2}'|awk -F, '{print $1}'|sort |uniq`
if [[ ! ${PIDS} ]]; then
    #没找端口
    echo "<STRESSRESULT>${IP_ADDR}##NoInstallRabbitMQ</STRESSRESULT>"
    exit
fi
RABBIT=`ps -ef |awk -v pid=$PIDS '{if($2 == pid )print}'|grep rabbitmq`
if [[  ! ${RABBIT} ]]; then
    #根据端口没找到进程
    echo "<STRESSRESULT>${IP_ADDR}##NoInstallRabbitMQ</STRESSRESULT>"
    exit
fi
DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
which rabbitmqctl &> /dev/null
if [[ $? -eq 0 ]]; then
    RABBITCMD=`which rabbitmqctl`
else
    RABBITCMD=`for i in  ${DIR}; do find /${i} -type f  -name "rabbitmqctl";done |awk 'NR==1{print}'`
fi
PORTS=`ss -tnlp|awk '/beam/{print}'|awk '{print $4}'|awk -F: '{print $NF}'|sort |uniq|grep -v 25672`
PNAME=`ps -ef |awk -v pid=$PIDS '{if($2 == pid )print}'|grep rabbitmq|awk '{print $8}'|awk -F/ '{print $NF}'`
if [[ ! ${RABBITCMD} ]]; then
     #没找到集群状态查看命令，归为单机
    KEEPALIVEDPORCESS=`ps -ef |grep -v grep |grep  keepalived`
    if [[ ! ${KEEPALIVEDPORCESS} ]]; then
        #不存在keepalived进程-单机模式
        for ports in ${PORTS}; do
            echo "<STRESSRESULT>${IP_ADDR}:${ports}##RabbitMQ##${PNAME}##$(ps -ef |awk -v pid=$PIDS '{if($2 == pid )print}'|grep -Eo "rabbitmq_server-[0-9]+\.[0-9]+\.[0-9]+"|awk 'NR==1{print}')##OneNode</STRESSRESULT>"  
        done
        exit
    fi
    #获取keepalived主备信息
    get_cluster
    for ports in ${PORTS}; do
        echo "<STRESSRESULT>${IP_ADDR}:${ports}##RabbitMQ##${PNAME}##$(ps -ef |awk -v pid=$PIDS '{if($2 == pid )print}'|grep -Eo "rabbitmq_server-[0-9]+\.[0-9]+\.[0-9]+"|awk 'NR==1{print}')##${CLUSTERSTATE}</STRESSRESULT>"  
    done
    exit
fi 
NODENUM=`${RABBITCMD} cluster_status |grep running_nodes|awk  -F@  '{print NF}'`
RABBITVER=`${RABBITCMD} status|grep "RabbitMQ"|grep -w "rabbit"|awk -F\" '{print $(NF-1)}'|sort |uniq`
if [[ ${NODENUM} -gt 2  ]]; then
    #存在集群
    for ports in ${PORTS}; do
        echo "<STRESSRESULT>${IP_ADDR}:${ports}##RabbitMQ##${PNAME}##${RABBITVER}##MASTER</STRESSRESULT>"
    done
    exit
else
    #单机模式
    for ports in ${PORTS}; do
        echo "<STRESSRESULT>${IP_ADDR}:${ports}##RabbitMQ##${PNAME}##${RABBITVER}##OneNode</STRESSRESULT>"
    done
    exit
fi