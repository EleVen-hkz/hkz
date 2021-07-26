#!/bin/bash
GET_IP(){
  IP_TMP_VAR=`ip addr | grep  inet|grep " scope global"|awk '{print $NF}'`
for i in ${IP_TMP_VAR}
do
   RESULT_IS_NULL=`ls /etc/sysconfig/network-scripts/*${i}* 2>/dev/null`
   if [ -n "${RESULT_IS_NULL}" ];then
        h_ip=`ip addr | grep  inet|grep " scope global"|grep ${i}|awk '{print $2}'|awk -F '/' '{print $1}'|awk 'NR==1{print}'`
   fi
done
}
GET_PORT(){
#     ALLPORT=`ss -tnlp|awk '/redis/{print $4}'|awk -F: '{print $NF}'|sort|uniq`
#     PORT=''
#     for i in ${ALLPORT}; do
#         #获取正确的端口
#         if [[  ${ALLPORT} =~ $[${i}-10000] ]]; then
#             continue
#         else
#             PORT="${PORT} $i"
#         fi
#     done
    PORT=`ps -ef |grep -v grep|grep redis|awk '{print $9}'|awk -F: '{print $2}'`
}
GET_CMD(){
    which redis-cli &> /dev/null
    if [[ $? -eq 0 ]]; then
        #有redis-cli
        CLI_CMD=`which redis-cli`
    else
        for i in usr opt data home;do
            CLI_CMD=`find /${i}/ -type f  -name "redis-cli" 2>/dev/null|awk 'NR==1{print}'`
            if [[ -x ${CLI_CMD} ]]; then
                break
            fi
        done
        if [[ ! ${CLI_CMD} ]]; then
            #未找到,全盘检索
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
    echo "<STRESSRESULT>${h_ip}##NoInstallRedis</STRESSRESULT>" 
    exit
fi
GET_PORT
GET_CMD
if [[ ! ${CLI_CMD} ]]; then
    #没有找到cli命令
    pass
fi
#进行循环输出
for port in ${PORT};do
    isok=''
    INFO_FILE="/tmp/redis${port}_info.out"
    CONFIG_FILE="/tmp/redis${port}config.out"
    CLUSTER_FILE="/tmp/redis${port}cluster.out"
    ${CLI_CMD} -c -h ${h_ip} -p ${port} info &> ${INFO_FILE}
    grep -i "redis_version" ${INFO_FILE} &> /dev/null
    if [[ $? -ne 0 ]]; then
    #有密码
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
        if [ !　${PASS} ]; then
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
    #----------------------------------
    
    REDISCONF=`awk -F: '/config_file/{print $2}'  ${INFO_FILE}`
    #REDISVER=`awk -F: '/redis_version/{print $2}'  ${INFO_FILE} |sed s/\r/''/`
    REDISVER=`cat ${INFO_FILE} |grep  redis_version|grep -Eo "([0-9]+\.){2}[0-9]+"`
    #REDISVER=`${CLI_CMD} -v|awk '{print $2}'`
    #ISCLUSTER=`awk -F: '/cluster_enabled/{print $2}' ${INFO_FILE}`
    #PID=`awk -F: '/process_id/{print $2}' ${INFO_FILE}`
    REDISDIR=`cat ${CONFIG_FILE}|grep -A1 "dir"|awk 'NR==2{print}'`
    REDISLOGS=`cat ${CONFIG_FILE}|grep -A1 "logfile"|awk 'NR==2{print}'`
    [ ! ${REDISCONF} ] && REDISCONF='null'
    [ ! ${REDISVER} ] && REDISVER='null'
    [ ! ${REDISDIR} ] && REDISDIR='null'
    [ ! ${REDISLOGS} ] && REDISLOGS='null'
    ps -ef |grep  -v grep |grep redis-server|grep ${port}|grep -i cluster &>/dev/null
    if [[ $? -eq 0 ]]; then
        ISCLUSTER=1
    else
        ISCLUSTER=0
    fi
    if [ ${ISCLUSTER} == 1 ]; then
        #集群模式
        CLUSTERNODES=`cat ${CLUSTER_FILE} |grep -Ei "master|slave"|awk '{print $2}'|awk -F@ '{print $1}'`
        if [[ $(echo ${CLUSTERNODES}|wc -w) -eq 1 ]]; then
            CLUSTERNODES="${h_ip}:${port}"
        fi
        CLUSTERSTATUS=`grep -w ${port} ${CLUSTER_FILE} |grep -Eio "master|slave"`

        echo -e "${h_ip}:${port}##Redis##redis-server##${REDISVER}##${CLUSTERSTATUS}##$(printf '%s;' ${CLUSTERNODES})##${REDISDIR}##${REDISLOGS}##${REDISCONF}"
    elif [ ${ISCLUSTER} == 0 ]; then
        #单机
        echo -e "${h_ip}:${port}##Redis##redis-server##${REDISVER}##OneNode##${h_ip}:${port}##${REDISDIR}##${REDISLOGS}##${REDISCONF}"
    fi
    # echo "${h_ip}:"
    # echo ${port}
    # echo ${REDISVER}
    # echo ${PASS}
    # echo ${REDISCONF}
    # echo ${ISCLUSTER}
    # echo ${REDISDIR}
    # echo ${REDISLOGS}
done
echo "</STRESSRESULT>"
