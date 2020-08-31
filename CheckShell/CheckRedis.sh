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
ps -ef |grep redis-server |grep -v grep &> /dev/null 
if [[ $? -ne 0 ]];then
    echo "Redis process not found" 
    exit
fi
ps -ef |grep redis-server |grep -v grep  |grep cluster &> /dev/null
iscluster=`echo $?`
if [[ ${iscluster} -eq 1  ]]; then
    which redis-server &> /dev/null
    if [[ $? -eq 0 ]]; then
        hostname=`echo $HOSTNAME`
        versrion=`redis-server -v|awk '{print $3}'|awk -Fv= '{print $2}'`
        h_ip=`grep "${hostname}$" /etc/hosts|awk '{print $1}'`
        echo -e "IP：${h_ip} \nversrion:${versrion}"
        exit
    else
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
        server_cmd=`for i in ${DIR};do find /${i}/ -type f  -name "redis-server";done |awk 'NR==1{print}'`
        hostname=`echo $HOSTNAME`
        versrion=`${server_cmd} -v |awk '{print $3}'|awk -Fv= '{print $2}'`
        h_ip=`grep "${hostname}$" /etc/hosts|awk '{print $1}'`
        echo -e "IP：\t${h_ip} \nversrion:\t${versrion}"
        exit
    fi
elif [[ ${iscluster} -eq 0 ]]; then
    which redis-server &> /dev/null
    if [[ $? -eq 0 ]]; then
        hostname=`echo $HOSTNAME`
        versrion=`redis-server -v|awk '{print $3}'|awk -Fv= '{print $2}'`
        h_ip=`grep "${hostname}$" /etc/hosts|awk '{print $1}'`
        h_port=`ps aux |grep redis-server|grep -v grep |awk 'NR==1{print $(NF-1)}'|awk -F: '{print $2}'`
        conff=`find_conf|awk 'NR==1{print}'`
        which redis-cli &> /dev/null
        if [[ $? -eq 0 ]];then
            passwd=`grep -v "^#"  ${conff} |grep  masterauth|awk -F\" '{print $2}'`
            if [[ ${passwd} ]];then
                echo -e "versrion:${versrion}"
                redis-cli -c -h ${h_ip} -p ${h_port} -a ${passwd} cluster nodes |awk '{print $2}'
                exit
            else
                echo -e "versrion:${versrion}"
                redis-cli -c -h ${h_ip} -p ${h_port} cluster nodes |awk '{print $2}'
                exit
            fi 
        fi 

        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
        server_cmd=`for i in  ${DIR}; do find /${i} -type f  -name "redis-cli";done |awk 'NR==1{print}' `
        conff=`find_conf|awk 'NR==1{print}'`
        passwd=`grep -v "^#"  ${conff} |grep  "masterauth" |awk -F\" '{print $2}'`
        if [[ ${passwd} ]];then
            echo -e "versrion:${versrion}"
            ${server_cmd} -c -h ${h_ip} -p ${h_port} -a ${passwd} cluster nodes |awk '{print $2}'
            exit
        else
            echo -e "versrion:${versrion}"
            ${server_cmd} -c -h ${h_ip} -p ${h_port} cluster nodes |awk '{print $2}'
            exit
        fi            
    else
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
        server_cmd=`for i in ${DIR};do find /${i}/ -type f  -name "redis-server";done |awk 'NR==1{print}'`
        hostname=`echo $HOSTNAME`
        versrion=`${server_cmd} -v |awk '{print $3}'|awk -Fv= '{print $2}'`
        h_ip=`grep "${hostname}$" /etc/hosts|awk '{print $1}'`
        h_port=`ps aux |grep redis-server|grep -v grep |awk 'NR==1{print $(NF-1)}'|awk -F: '{print $2}'`
        conff=`find_conf|awk 'NR==1{print}'`
        which redis-cli &> /dev/null
        if [[ $? -eq 0 ]];then
            passwd=`grep -v "^#"  ${conff} |grep  masterauth|awk -F\" '{print $2}'`
            if [[ ${passwd} ]];then
                echo -e "versrion:${versrion}"
                redis-cli -c -h ${h_ip} -p ${h_port} -a ${passwd} cluster nodes |awk '{print $2}'
                exit
            else
                echo -e "versrion:${versrion}"
                redis-cli -c -h ${h_ip} -p ${h_port} cluster nodes|awk '{print $2}'
                exit
            fi              
        else 
            DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
            server_cmd=`for i in  ${DIR}; do find /${i} -type f  -name "redis-cli";done |awk 'NR==1{print}' `
            conff=`find_conf|awk 'NR==1{print}'`
            passwd=`grep -v "^#"  ${conff} |grep  masterauth|awk  '{print $2}'|sed 's/\"//g'`
            if [[ ${passwd} ]];then
                echo -e "versrion:${versrion}"
                ${server_cmd} -c -h ${h_ip} -p ${h_port} -a ${passwd} cluster nodes |awk '{print $2}'
                exit
            else
                echo -e "versrion:${versrion}"
                ${server_cmd} -c -h ${h_ip} -p ${h_port} cluster nodes|awk '{print $2}'
                exit
            fi              
        fi
    fi
fi
