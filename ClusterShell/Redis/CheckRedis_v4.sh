#!/bin/bash
find_conf(){
    for i in `ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"` 
    do 
        for j in `find /${i}/ -type f  -name "*.conf"` 
        do 
            grep -v "^#" ${j} |grep "cluster-enabled" > /dev/null 
            if [[ $? -eq 0  ]]; then 
                echo "${j}" 
            fi
        done
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
#get info
h_port=`ps -ef |grep  -v grep |grep  redis-server|awk -F: '{print $NF}'|sort|uniq`
h_ip=`grep "$(echo ${HOSTNAME})$" /etc/hosts|awk '{print $1}'`
if [[ ! ${h_ip} ]]; then
    h_ip=`hostname -I|awk '{print $1}'`
fi
p_name=`ps -ef |grep -v grep |grep redis-server|awk '{print $8}'|awk -F/ '{print $NF}'|uniq`

if [[ ! ${p_name} ]];then
#  NoInstall
    echo "${h_ip}##NoInstallRedis" 
    exit
fi
#Get cmd
DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
cli_cmd=`for i in  ${DIR}; do find /${i} -type f  -name "redis-cli";done |awk 'NR==1{print}' ` 
server_cmd=`for i in ${DIR};do find /${i}/ -type f  -name "redis-server";done |awk 'NR==1{print}'`
versrion=`${server_cmd} -v|awk '{print $3}'|awk -Fv= '{print $2}'`
conff=`find_conf`
ps -ef |grep redis-server |grep -v grep  |grep cluster &> /dev/null
iscluster=`echo $?`
if [[ ${iscluster} -eq 1  ]]; then
# OneNode
    ps -ef|grep -v grep|grep  keepalived|awk '{print $8}'|grep -w keepalived &> /dev/null
    if [[ $? -eq 0 ]]; then
        #有keepalived进程
         get_clusterStatus
        for port in ${h_port};do
            echo -e "${h_ip}:${port}##Redis##${p_name}##${versrion}##${CLUSTERSTATE}"
            continue
        done
        exit
    fi
    for port in ${h_port}; do
        #没有keepalived进程
        echo -e "${h_ip}:${port}##Redis##${p_name}##${versrion}##OneNode"
    done
    exit
elif [[ ${iscluster} -eq 0 ]]; then
    #cluster
    port=`echo ${h_port}|awk '{print $1}'`
    ${cli_cmd} -c -h ${h_ip} -p ${port} cluster nodes |awk '{print $2,$3}' > /tmp/CheckRedis.tmp
    grep -i "Authentication required" /tmp/CheckRedis.tmp &> /dev/null
    if [[ $? -eq 1 ]]; then
        #no passwd
        cat /tmp/CheckRedis.tmp |sort|uniq > /tmp/CheckRedis.test
        sed -i -r s/@[0-9]+/''/  /tmp/CheckRedis.tmp
        sed -i s/myself,/''/ /tmp/CheckRedis.test
        while [[ $(cat /tmp/CheckRedis.test) ]]; do
            #statements
            awk -v ver=${versrion} 'NR==1{print$1"##Redis##redis-server##"ver"##"$2}' /tmp/CheckRedis.test
            sed -i 1d /tmp/CheckRedis.test
        done
        exit
    fi
    for conf in ${conff} 
    do
        passwd=`grep -v "^#"  ${conff} |grep -E "requirepass|masterauth"|awk 'NR==1{print $2}'`
        ${cli_cmd} -c -h ${h_ip} -p ${port} -a ${passwd} cluster nodes |awk '{print $2,$3}' > /tmp/CheckRedis.tmp
        grep -i "Authentication required" /tmp/CheckRedis.tmp &> /dev/null 
        if [[ $? -eq 0 ]]; then   
            break
        fi
        sed -i -r s/@[0-9]+/''/  /tmp/CheckRedis.tmp
        cat /tmp/CheckRedis.tmp |sort|uniq > /tmp/CheckRedis.test
        sed -i s/myself,/''/ /tmp/CheckRedis.test

        while [[ $(cat /tmp/CheckRedis.test) ]]; do
            
            awk  -v ver=${versrion} 'NR==1{print$1"##Redis##redis-server##"ver"##"$2}' /tmp/CheckRedis.test
            sed -i 1d /tmp/CheckRedis.test
        done
        exit
    done                      
fi