#!/bin/bash
get_info(){
    TMPFILE='/tmp/nginx.tmp'
    #获取端口号、版本号
    NGINXPORT=`ss -tnlp|grep  nginx|grep  -v "\[::\]"|awk '{print $4}'|awk -F: '{print $2}'`
    which nginx &> /dev/null
    if [[ $? -ne 0 ]]; then
        #没有nginx命令
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
        NGINXCMD=`for i in  ${DIR}; do find /${i} -type f  -name "nginx";done |awk 'NR==1{print}' ` 
        ${NGINXCMD} -v &> ${TMPFILE}
        NGINXVER=`cat ${TMPFILE}|awk '{print $3}'`
    else
        nginx -v &> ${TMPFILE}
        NGINXVER=`cat ${TMPFILE}|awk '{print $3}'`
    fi
}
get_cluster(){
    DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
    KEPPCONF=`for i in  ${DIR}; do find /${i} -type f  -name "keepalived.conf";done |awk 'NR==1{print}' ` 
    CLUSTERSTATE=`grep state  ${KEPPCONF} |awk '{print $2}'`
    if [[ ${CLUSTERSTATE} == 'MASTER' ]]; then
        CLUSTERSTATE=Master
    elif [[ ${CLUSTERSTATE} == 'BACKUP' ]]; then
        CLUSTERSTATE=Slave
    fi
}
#获取IP地址
HOSTIP=`grep "$(echo ${HOSTNAME})$" /etc/hosts|awk '{print $1}'`
if [[ ! ${HOSTIP} ]]; then
    HOSTIP=`hostname -I|awk '{print $1}'`
fi
#判断是否存在Nginx进程
NGINXPROCESS=`ss -tnlp|grep  nginx|grep  -v "\[::\]"|awk '{print $NF}'|awk -F\" '{print $2}'|sort|uniq`
if [[ ! ${NGINXPROCESS} ]]; then
    #不存在Nginx进程
    echo "${HOSTIP}##NoInstallNginx"
    exit
fi
#运行函数获取信息
get_info
#判断是否存在Keepalive
KEEPALIVEDPORCESS=`ps -ef |grep -v grep |grep  keepalived`
if [[ ! ${KEEPALIVEDPORCESS} ]]; then
    #不存在keepalived进程-单机模式
    for ports in ${NGINXPORT}; do
        echo "${HOSTIP}:${ports}##Nginx#${NGINXPROCESS}##${NGINXVER}##OneNode"  
    done
    exit
fi
#获取keepalived主备信息
get_cluster
for ports in ${NGINXPORT}; do
        echo "${HOSTIP}:${ports}##Nginx#${NGINXPROCESS}##${NGINXVER}##${CLUSTERSTATE}"  
    done
