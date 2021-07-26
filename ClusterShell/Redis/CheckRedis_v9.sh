#!/bin/bash
GET_IP(){
    IP_TMP_VAR=`ip addr | grep  inet|grep " scope global"|awk '{print $NF}'`
    for i in ${IP_TMP_VAR}
    do
       RESULT_IS_NULL=`ls /etc/sysconfig/network-scripts/*${i}* 2>/dev/null`
       if [ -n "${RESULT_IS_NULL}" ];then
            h_ip=`ip addr | grep  inet|grep " scope global"|grep ${i}|awk '{print $2}'|awk -F '/' '{print $1}'|awk 'NR==1{print}'`
            if [[ "$h_ip"=="10.212.221.222" ]];then
               break
            fi
       fi
    done
    if [[ ! ${h_ip} ]]; then
        h_ip=`hostname -I|awk '{print $1}'`
    fi
}
GET_PORT(){
    PORT=`ps -ef |grep -v grep|grep redis|awk '{print $9}'|awk -F: '{print $2}'`
}
GET_CMD(){
    which redis-cli &> /dev/null
    if [[ $? -eq 0 ]]; then
        CLI_CMD=`which redis-cli`
    else
        for i in usr opt data home;do
            CLI_CMD=`find /${i}/ -type f  -name "redis-cli" 2>/dev/null|awk 'NR==1{print}'`
            if [[ -x ${CLI_CMD} ]]; then
                break
            fi
        done
        if [[ ! ${CLI_CMD} ]]; then
            DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "boot|proc|run|dev|usr|opt|data|home"`
            for i in  ${DIR}; do
                CLI_CMD=`find /${i} -type f  -name "redis-cli" 2>/dev/null|awk 'NR==1{print}'`
                if [[ -x ${CLI_CMD} ]]; then
                    break
                fi
            done
        fi
    fi
}
find_conf(){
    for i in `ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|usr|opt|data|home"`
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
echo "<STRESSRESULT>"
GET_IP
PASS='passwd'
p_name=`ps -ef |grep -v grep |grep redis-server|awk '{print $8}'|awk -F/ '{print $NF}'|uniq`
if [[ ! ${p_name} ]];then
#  NoInstall
    echo "${h_ip}##NoInstallRedis" 
    echo "</STRESSRESULT>"
    exit
fi
GET_PORT
GET_CMD
InstanceID=0
for port in ${PORT};do
    let InstanceID+=1
    isok=''
    INFO_FILE="/tmp/redis${port}_info.out"
    CONFIG_FILE="/tmp/redis${port}config.out"
    CLUSTER_FILE="/tmp/redis${port}cluster.out"
    ${CLI_CMD} -c -h ${h_ip} -p ${port} info &> ${INFO_FILE}
    grep -i "redis_version" ${INFO_FILE} &> /dev/null
    if [[ $? -ne 0 ]]; then
        if [[ ! ${PASS} ]]; then
            PASS='passwd'
        fi
        ${CLI_CMD} -c -h ${h_ip} -p ${port} -a ${PASS} info &> ${INFO_FILE}
        grep -i "redis_version" ${INFO_FILE} &> /dev/null
        if [[ $? -ne 0 ]]; then
            for i in usr data etc home opt; do
                if [[ ${isok} ]]; then
                    break
                fi
                for j in `find /${i}/ -type f  -name "*redis*.conf" 2>/dev/null`;do
                    PASS=`cat ${j} |sed -e 's/^[ \t]*//g'|grep -Ev "^#|^$"|awk '/requirepass/{print $2}'|sed s/\"//g`
                    if [[ ${PASS} ]]; then
                        ${CLI_CMD} -c -h ${h_ip} -p ${port} -a ${PASS} info &> ${INFO_FILE}
                        isok=`grep -i "redis_version" ${INFO_FILE} `
                        if [ ${isok} ]; then
                            break

                        else
                            PASS=''
                            continue
                        fi
                    fi
                done
            done
        fi
        if [ ! ${PASS} ]; then
            DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "boot|proc|run|dev|usr|opt|data|home|etc"`
            for i in  ${DIR}; do
                if [[ ${isok} ]]; then
                    break
                fi
                for j in `find /${i}/ -type f  -name "*redis*.conf" 2>/dev/null`;do
                    PASS=`cat ${j} |sed -e 's/^[ \t]*//g'|grep -Ev "^#|^$"|awk '/requirepass/{print $2}'|sed s/\"//g`
                        if [[ ${PASS} ]]; then
                            ${CLI_CMD} -c -h ${h_ip} -p ${port} -a ${PASS} info &> ${INFO_FILE}
                            isok=`grep -i "redis_version" ${INFO_FILE} `
                            if [ ${isok} ]; then
                                break
                            else
                                PASS=''
                                continue
                            fi
                        fi
                done
            done
        fi
        ${CLI_CMD} -c -h ${h_ip} -p ${port} -a ${PASS} CONFIG GET "*" &> ${CONFIG_FILE}
        ${CLI_CMD} -c -h ${h_ip} -p ${port} -a ${PASS} CLUSTER NODES  &> ${CLUSTER_FILE}
    else
        ${CLI_CMD} -c -h ${h_ip} -p ${port} CONFIG GET "*" &> ${CONFIG_FILE}
        ${CLI_CMD} -c -h ${h_ip} -p ${port} CLUSTER NODES  &> ${CLUSTER_FILE}
    fi
    #REDISCONF=`awk -F: '/config_file/{print $2}'  ${INFO_FILE}`
    ItemNum=`printf '%.2d\n' ${InstanceID}`
    REDISCONF=`cat ${INFO_FILE} |grep config_file:|awk -F: '{print $2}'|awk -F"\r" '{print $1}'`
    REDISVER=`cat ${INFO_FILE} |grep  redis_version|grep -Eo "([0-9]+\.){2}[0-9]+"`
    REDISDIR=`cat ${CONFIG_FILE}|grep -A1 "dir"|awk 'NR==2{print}'`
    REDISLOGS=`cat ${CONFIG_FILE}|grep -A1 "logfile"|awk 'NR==  2{print}'`
    [ ! ${REDISCONF} ] && REDISCONF='NULL'
    [ ! ${REDISVER} ] && REDISVER='NULL'
    [ ! ${REDISDIR} ] && REDISDIR='NULL'
    [ ! ${REDISLOGS} ] && REDISLOGS='NULL'
    ps -ef |grep  -v grep |grep redis-server|grep ${port}|grep -i cluster &>/dev/null
    if [[ $? -eq 0 ]]; then
        ISCLUSTER=1
    else
        ISCLUSTER=0
    fi
    if [ ${ISCLUSTER} == 1 ]; then
        CLUSTERNODES=`cat ${CLUSTER_FILE} |grep -Ei "master|slave"|awk '{print $2}'|awk -F@ '{print $1}'`
        if [[ $(echo ${CLUSTERNODES}|wc -w) -eq 1 ]]; then
            CLUSTERNODES="${h_ip}:${port}"
        fi
        CLUSTERSTATUS=`grep -w ${port} ${CLUSTER_FILE} |grep ${h_ip}|grep -Eio "master|slave"`
        echo $(printf '%s;' ${CLUSTERNODES}) &>lin.txt
        LIN=`cat lin.txt |  sed 's/ //g'|sed 's/.$//'`
        echo -e "${h_ip}:${port}##Redis##redis-server##${REDISVER}##${CLUSTERSTATUS}##$LIN##${REDISDIR}##${REDISLOGS}##${REDISCONF}##mid-`hostid`-${h_ip}-redis${ItemNum}"
    elif [ ${ISCLUSTER} == 0 ]; then
        echo -e "${h_ip}:${port}##Redis##redis-server##${REDISVER}##OneNode##${h_ip}:${port}##${REDISDIR}##${REDISLOGS}##${REDISCONF}##mid-`hostid`-${h_ip}-redis${ItemNum}"
    fi
done
rm -rf lin.txt
echo "</STRESSRESULT>"