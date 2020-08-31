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
#get info
h_port=`ps aux |grep redis-server|grep -v grep |awk 'NR==1{print $(NF-1)}'|awk -F: '{print $2}'`
h_ip=`grep "$(echo ${HOSTNAME})$" /etc/hosts|awk '{print $1}'`
if [[ ! ${h_ip} ]]; then
    h_ip=`hostname -I|awk '{print $1}'`
fi
p_name=`ps -ef |grep -v grep |grep redis-server|awk '{print $8}'|awk -F/ '{print $NF}'|uniq`
if [[ ! ${p_name} ]];then
#  NoInstall
    echo "${h_ip}##${HOSTNAME}##NoInstallRedis" 
    exit
fi
ps -ef |grep redis-server |grep -v grep  |grep cluster &> /dev/null
iscluster=`echo $?`
if [[ ${iscluster} -eq 1  ]]; then
# OneNode
    which redis-server &> /dev/null
    if [[ $? -eq 0 ]]; then
        versrion=`redis-server -v|awk '{print $3}'|awk -Fv= '{print $2}'`
        for port in ${h_port}
        do
            echo -e "${h_ip}:${port}##${HOSTNAME}##Redis##${p_name}##${versrion}##OneNode"
        done
        exit
    else
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
        server_cmd=`for i in ${DIR};do find /${i}/ -type f  -name "redis-server";done |awk 'NR==1{print}'`
        versrion=`${server_cmd} -v |awk '{print $3}'|awk -Fv= '{print $2}'`
        for port in ${h_port}
        do
            echo -e "${h_ip}:${port}##${HOSTNAME}##Redis##${p_name}##${versrion}##OneNode"
        done
        exit
    fi
elif [[ ${iscluster} -eq 0 ]]; then
    #cluster
    which redis-server &> /dev/null
    if [[ $? -eq 0 ]]; then
        versrion=`redis-server -v|awk '{print $3}'|awk -Fv= '{print $2}'`
        conff=`find_conf`
        which redis-cli &> /dev/null
        if [[ $? -eq 0 ]];then
            #have redis-cli
            redis-cli -c -h ${h_ip} -p ${h_port} cluster nodes |awk '{print $2,$3}' > /tmp/CheckRedis.test
            grep -i "Authentication required" /tmp/CheckRedis.test &> /dev/null
            if [[ $? -eq 1 ]]; then
                #no passwd
                sed -i s/mysalf,/''/ /tmp/CheckRedis.test
                while [[ $(cat /tmp/CheckRedis.test) ]]; do
                    #statements
                    awk -v ${p_name}=name -v ${versrion}=ver 'NR==1{print$1"##Redis##"name"##"ver"##"$2}' /tmp/CheckRedis.test
                    sed -i 1d /tmp/CheckRedis.test
                done
                exit
            fi
            for conf in ${conff} 
            do
                passwd=`grep -v "^#"  ${conff} |grep -E "requirepass|masterauth"|awk 'NR==1{print $2}'`
                redis-cli -c -h ${h_ip} -p ${h_port} -a ${passwd} cluster nodes |awk '{print $2,$3}' > /tmp/CheckRedis.test
                grep -i "Authentication required" /tmp/CheckRedis.test &> /dev/null 
                if [[ $? -eq 0 ]]; then   
                    break
                fi
                sed -i s/mysalf,/''/ /tmp/CheckRedis.test
                while [[ $(cat /tmp/CheckRedis.test) ]]; do
                    #statements
                    awk -v ${p_name}=name -v ${versrion}=ver 'NR==1{print$1"##Redis##"name"##"ver"##"$2}' /tmp/CheckRedis.test
                    sed -i 1d /tmp/CheckRedis.test
                done
                exit
            done
        fi 
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
        cli_cmd=`for i in  ${DIR}; do find /${i} -type f  -name "redis-cli";done |awk 'NR==1{print}' `
        ${cli_cmd} -c -h ${h_ip} -p ${h_port} cluster nodes |awk '{print $2,$3}' > /tmp/CheckRedis.test
        grep -i "Authentication required" /tmp/CheckRedis.test &> /dev/null
        if [[ $? -eq 1 ]]; then
            #no passwd
            sed -i s/mysalf,/''/ /tmp/CheckRedis.test
            while [[ $(cat /tmp/CheckRedis.test) ]]; do
                #statements
                awk -v ${p_name}=name -v ${versrion}=ver 'NR==1{print$1"##Redis##"name"##"ver"##"$2}' /tmp/CheckRedis.test
                sed -i 1d /tmp/CheckRedis.test
            done
            exit
        fi
        for conf in ${conff} 
        do
            passwd=`grep -v "^#"  ${conff} |grep -E "requirepass|masterauth"|awk 'NR==1{print $2}'`
            ${cli_cmd} -c -h ${h_ip} -p ${h_port} -a ${passwd} cluster nodes |awk '{print $2,$3}' > /tmp/CheckRedis.test
            grep -i "Authentication required" /tmp/CheckRedis.test &> /dev/null 
            if [[ $? -eq 0 ]]; then   
                break
            fi
            sed -i s/mysalf,/''/ /tmp/CheckRedis.test
            while [[ $(cat /tmp/CheckRedis.test) ]]; do
                #statements
                awk -v ${p_name}=name -v ${versrion}=ver 'NR==1{print$1"##Redis##"name"##"ver"##"$2}' /tmp/CheckRedis.test
                sed -i 1d /tmp/CheckRedis.test
            done
            exit
        done            
    else
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
        server_cmd=`for i in ${DIR};do find /${i}/ -type f  -name "redis-server";done |awk 'NR==1{print}'`
        versrion=`${server_cmd} -v |awk '{print $3}'|awk -Fv= '{print $2}'`
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
            cli_cmd=`for i in  ${DIR}; do find /${i} -type f  -name "redis-cli";done |awk 'NR==1{print}' `
            conff=`find_conf|awk 'NR==1{print}'`
            passwd=`grep -v "^#"  ${conff} |grep  masterauth|awk  '{print $2}'|sed 's/\"//g'`
            if [[ ${passwd} ]];then
                echo -e "versrion:${versrion}"
                ${cli_cmd} -c -h ${h_ip} -p ${h_port} -a ${passwd} cluster nodes |awk '{print $2}'
                exit
            else
                echo -e "versrion:${versrion}"
                ${cli_cmd} -c -h ${h_ip} -p ${h_port} cluster nodes|awk '{print $2}'
                exit
            fi              
        fi
    fi
fi
