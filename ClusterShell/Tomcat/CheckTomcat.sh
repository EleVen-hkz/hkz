#!/bin/bash
#Tomcat
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
HOSTIP=`grep "$(echo ${HOSTNAME})$" /etc/hosts|awk '{print $1}'`
if [[ ! ${HOSTIP} ]]; then
    HOSTIP=`hostname -I|awk '{print $1}'`
fi
#判断是否存在Tomcat
PROCESSID=`for i in $(netstat -tnlp|grep  java|awk '{print $NF}'|awk -F/ '{print $1}'|sort|uniq); do ps -ef |grep -v grep |grep ${i}|grep -i tomcat-juli.jar|awk '{print $2}'; done`
if [[ ! ${PROCESSID} ]]; then
    #当PROCESS为空时，不存在Tomcat
    echo "${HOSTIP}##NoInstallTomcat"
    exit
fi
#遍历获取配置文件目录
for PID in ${PROCESSID}; do
    TOMCATHOME=`ps -ef|grep  ${PID}|awk -F'Dcatalina.home=' '{print $2}'|awk '{print $1}'`
    TOMCATVERSION=`${TOMCATHOME}/bin/version.sh 2>/dev/null|grep "Server version"|awk '{print $NF}'`
    if [[ ! ${TOMCATVERSION} ]]; then
        #yum安装使用TOMCAT命令获取
        TOMCATVERSION=`tomcat version|awk 'NR==1{print $NF}'`
    fi
    #获取端口
    TOMCATPORTS=`cat ${TOMCATHOME}/conf/server.xml| grep -E "<Connector port=\"[0-9]+\""|grep  HTTP|awk '{print $2}'|awk -F\" '{print $2}'`
    ISCLUSTER=`cat ${TOMCATHOME}/conf/server.xml |grep -C10  "<Cluster"`
    #配置文件未打开集群配置，为单机模式
    if [[ ! ${ISCLUSTER} ]]; then
        #单机模式
        ps -ef|grep -v grep|grep  keepalived|awk '{print $8}'|grep -w keepalived &> /dev/null
        if [[ $? -eq 0 ]]; then
            #有keepalived进程
            get_clusterStatus
            echo "${HOSTIP}:${TOMCATPORTS}##Tomcat#tomcat-juli.jar##${TOMCATVERSION}##${CLUSTERSTATE}"
            continue
        fi
        echo "${HOSTIP}:${TOMCATPORTS}##Tomcat#tomcat-juli.jar##${TOMCATVERSION}##OneNode"
        continue
    fi
    ISCLUSTER2=$(echo $(cat ${TOMCATHOME}/conf/server.xml |grep -C10  "<Cluster")|awk -F'<Cluster' '{print $2}'|awk -F'<!' '{print $1}'|grep -o "\\-->")
    if [[ ${ISCLUSTER2} ]]; then
        #单机模式
        ps -ef|grep -v grep|grep  keepalived|awk '{print $8}'|grep -w keepalived &> /dev/null
        if [[ $? -eq 0 ]]; then
            #有keepalived进程
            get_clusterStatus
            echo "${HOSTIP}:${TOMCATPORTS}##Tomcat#tomcat-juli.jar##${TOMCATVERSION}##${CLUSTERSTATE}"
            continue
        fi
        echo "${HOSTIP}:${TOMCATPORTS}##Tomcat#tomcat-juli.jar##${TOMCATVERSION}##OneNode"
        continue 
    fi
    #打开了集群配置，获取组播地址
    Multicast=`grep -a1  Membership ${TOMCATHOME}/conf/server.xml|grep  address|awk -F= '{print $2}'|awk -F\" '{print $2}'`
    if [[ ${Multicast} ]]; then
        #配置文件指定组播地址
        echo "${HOSTIP}:${TOMCATPORTS}##Tomcat#tomcat-juli.jar##${TOMCATVERSION}##Master"
        continue
    fi
    #配置文件不存在组播地址，查看是否存在默认组播地址
    DEFAULTADD=`netstat -gan|grep 228.0.0.4|awk '{print $3}'`
    Multicast=228.0.0.4
    if [[ ${DEFAULTADD} ]]; then
        echo "${HOSTIP}:${TOMCATPORTS}##Tomcat#tomcat-juli.jar##${TOMCATVERSION}##Master"
        continue
    fi
    Multicast='unkown Multicast'
    echo "${HOSTIP}:${TOMCATPORTS}##Tomcat#tomcat-juli.jar##${TOMCATVERSION}##Master"
done
