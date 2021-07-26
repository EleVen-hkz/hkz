#!/bin/bash
find_conf(){
    for i in `ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"` 
    do 
        for j in `find /${i}/ -type f  -name "*.conf" 2>/dev/null` 
        do 
            grep -v "^#" ${j} |grep "cluster-enabled" &> /dev/null 
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
GetCliCmd(){
    DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run|usr|opt|data|home|sys"`
    cli_cmd=`for i in  ${DIR}; do find /${i} -type f  -name "redis-cli";done |awk 'NR==1{print}' ` 
}
GetSerCmd(){
    DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run|usr|opt|data|home|sys"`
    server_cmd=`for i in ${DIR};do find /${i}/ -type f  -name "redis-server";done |awk 'NR==1{print}'`
}
#get info
h_port=`ps -ef |grep  -v grep |grep  redis-server|awk -F: '{print $NF}'|sort|uniq`
#获取IP地址，任何情况都可以获取到本机的IP地址
IP_TMP_VAR=`ip addr | grep  inet|grep " scope global"|awk '{print $NF}'`
for i in ${IP_TMP_VAR}
do
   RESULT_IS_NULL=`ls /etc/sysconfig/network-scripts/*${i}* 2>/dev/null`
   if [ -n "${RESULT_IS_NULL}" ];then
        h_ip=`ip addr | grep  inet|grep " scope global"|grep ${i}|awk '{print $2}'|awk -F '/' '{print $1}'|awk 'NR==1{print}'`
   fi
done
p_name=`ps -ef |grep -v grep |grep redis-server|awk '{print $8}'|awk -F/ '{print $NF}'|uniq`

if [[ ! ${p_name} ]];then
#  NoInstall
    echo "<STRESSRESULT>${h_ip}##NoInstallRedis</STRESSRESULT>" 
    exit
fi
cli_cmd=$(for i in usr opt data home; do find /${i}/ -type f  -name "redis-cli" 2>/dev/null|awk 'NR==1{print}'; done)
if [[ ! ${cli_cmd} ]]; then
    GetCliCmd
fi
server_cmd=`echo ${cli_cmd} |sed s/cli/server/`
${server_cmd} -v &> /tmp/Redis.ver
if [[ $? -ne 0 ]]; then
    #Server命令错误
    GetSerCmd
fi
versrion=`${server_cmd} -v|awk '{print $3}'|awk -Fv= '{print $2}'`
ifcluster=`ps -ef |grep redis-server |grep -v grep  |grep cluster`
if [[ ! ${ifcluster}  ]]; then
# OneNode
    ps -ef|grep -v grep|grep  keepalived|awk '{print $8}'|grep -w keepalived &> /dev/null
    if [[ $? -eq 0 ]]; then
        #有keepalived进程
         get_clusterStatus
        for port in ${h_port};do
            echo -e "<STRESSRESULT>${h_ip}:${port}##Redis##${p_name}##${versrion}##${CLUSTERSTATE}</STRESSRESULT>"
            continue
        done
        exit
    fi
    for port in ${h_port}; do
        echo -e "<STRESSRESULT>${h_ip}:${port}##Redis##${p_name}##${versrion}##OneNode</STRESSRESULT>"
    done
    exit
fi
#cluster
port=`echo ${h_port}|awk '{print $1}'`
${cli_cmd} -c -h ${h_ip} -p ${port} cluster nodes |awk '{print $2,$3}' > /tmp/CheckRedis.tmp
grep -i "Authentication required" /tmp/CheckRedis.tmp &> /dev/null
if [[ $? -eq 1 ]]; then
    #no passwd
    cat /tmp/CheckRedis.tmp |sort|uniq > /tmp/CheckRedis.test
sed -i -r s/@[0-9]+/''/ /tmp/CheckRedis.test
    sed -i s/myself,/''/ /tmp/CheckRedis.test
    while [[ $(cat /tmp/CheckRedis.test) ]]; do
        #statements
        awk -v ver=${versrion} 'NR==1{print"<STRESSRESULT>"$1"##Redis##redis-server##"ver"##"$2"</STRESSRESULT>"}' /tmp/CheckRedis.test
        sed -i 1d /tmp/CheckRedis.test
    done
    exit
fi
conff=`find_conf`
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
        awk  -v ver=${versrion} 'NR==1{print"<STRESSRESULT>"$1"##Redis##redis-server##"ver"##"$2"</STRESSRESULT>"}' /tmp/CheckRedis.test
        sed -i 1d /tmp/CheckRedis.test
    done
    exit
done                      

