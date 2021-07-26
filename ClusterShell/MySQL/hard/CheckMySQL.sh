#!/bin/bash
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
Get_CnfFile(){
    DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
    CNFFILEs=`for i in  ${DIR}; do find /${i} -type f  -name "my.cnf";done ` 
}

Get_HostIP
PORTS=`ss -tnlp|awk '/mysqld/{print $4}'|awk -F: '{print $NF}'|sort |uniq`
if [[ ! ${PORTS} ]]; then
    #没找到MySQLd进程
    echo "${IP_ADDR}##NoInstallMySQL"
    exit
elif [[ $(echo ${PORTS}|wc -w) == 1 ]]; then
    #单实例
    Get_CnfFile
    for FILE in ${CNFFILEs}; do
        if [[ ${PORTS} == 3306 ]]; then
            #默认端口
            
        fi
    done
done
    exit
fi
echo munlit




Get_CnfFile
for PORT in ${PORTS}; do
    #多实例输出
    for FILE in ${CNFFILEs}; do
        grep 
        CONF=$(echo $(grep -v "^#" ${FILE}))
    done
done
