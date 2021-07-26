#!/bin/bash
get_info(){
    TMPFILE='/tmp/nginx.tmp'
    #获取端口号、版本号
    which nginx &> /dev/null
    if [[ $? -eq 0 ]]; then
        #有nginx命令
        NGINXCMD=`which nginx`
    else
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|sys"`
        NGINXCMD=`for i in  ${DIR}; do find /${i} -type f  -name "nginx";done ` 
    fi 
}
get_cluster(){
    DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|sys"`
    KEPPCONF=`for i in  ${DIR}; do find /${i} -type f  -name "keepalived.conf";done |awk 'NR==1{print}' ` 
    CLUSTERSTATE=`grep state  ${KEPPCONF} |awk '{print $2}'`
    if [[ ${CLUSTERSTATE} == 'MASTER' ]]; then
        CLUSTERSTATE=Master
    elif [[ ${CLUSTERSTATE} == 'BACKUP' ]]; then
        CLUSTERSTATE=Slave
    fi
    VIP=$(echo `cat ${KEPPCONF} `|awk -F"virtual_ipaddress" '{print $2}'|awk -F\} '{print $1}'|grep -Eo "([0-9]+\.){3}[0-9]+")
}
#获取IP地址
IP_TMP_VAR=`ip addr | grep  inet|grep " scope global"|awk '{print $NF}'`
for i in ${IP_TMP_VAR}
do
   RESULT_IS_NULL=`ls /etc/sysconfig/network-scripts/*${i}* 2>/dev/null`
   if [ -n "${RESULT_IS_NULL}" ];then
        HOSTIP=`ip addr | grep  inet|grep " scope global"|grep ${i}|awk '{print $2}'|awk -F '/' '{print $1}'|awk 'NR==1{print}'`
   fi
done
echo "<STRESSRESULT>"
#判断是否存在Nginx进程
NGINXPROCESS=`ss -tnlp|grep  nginx|grep  -v "\[::\]"|awk '{print $NF}'|awk -F\" '{print $2}'|sort|uniq`
if [[ ! ${NGINXPROCESS} ]]; then
    #不存在Nginx进程
    echo "${HOSTIP}##NoInstallNginx"
    echo "</STRESSRESULT>"
    exit
fi
get_info
#判断是否存在Keepalive
KEEPALIVEDPORCESS=`ps -ef |grep -v grep |grep  keepalived`
if [[ ! ${KEEPALIVEDPORCESS} ]]; then
    #不存在keepalived进程-单机模式
    for i in ${NGINXCMD}; do
        TMPFILE=/tmp/$(echo ${i}|sed s#/##g)
        echo ${TMPFILE} |grep -E "objs|overlay2" &> /dev/null
        if [[ $? -eq 0 ]]; then
            continue
        fi
        ${i} -h &> ${TMPFILE} 
        NGINXDIR=`grep "set prefix path"  ${TMPFILE} |awk '{print $NF}'|awk -F\) '{print $1}'`
        if [[ $(echo ${NGINXDIR}|grep "/$") ]]; then
            NGINXDIR=${NGINXDIR%?}
        fi
        NGINXSONFIF=$(grep "set configuration"  ${TMPFILE} |awk '{print $NF}'|awk -F\) '{print $1}')
        echo ${NGINXSONFIF}|grep "^/" &>/dev/null
        if [[ $? -ne 0 ]]; then
            NGINXSONFIF=$NGINXDIR/${NGINXSONFIF}
        # else
        #     NGINXSONFIF=$NGINXDIR${NGINXSONFIF}
        fi
        #错误日志
        NGINXERRORLOGDIR=`grep -v "#" ${NGINXSONFIF}|grep error_log |awk '{print $2}'|awk -F\; '{print $1}'`
        if [[ ! ${NGINXERRORLOGDIR} ]]; then
            #未设置错误日志
            ls ${NGINXDIR}/logs/error.log &> /dev/null
            if [[ $? -eq 0 ]]; then
                NGINXERRORLOGDIR=${NGINXDIR}/logs/error.log
            else
                NGINXERRORLOGDIR=null
            fi
        fi
        echo ${NGINXERRORLOGDIR}|grep "^/" &>/dev/null
        if [[ $? -ne 0 ]]; then
            NGINXERRORLOGDIR=$NGINXDIR/${NGINXERRORLOGDIR}
        fi
        #访问日志
        NGINXACCESSLOGDIR=`grep -v "#" ${NGINXSONFIF}|grep access_log |awk '{print $2}'|awk -F\; '{print $1}'`
        if [[ ! ${NGINXACCESSLOGDIR} ]]; then
            #未设置访问日志
            ls ${NGINXDIR}/logs/access.log &> /dev/null
            if [[ $? -eq 0 ]]; then
                NGINXACCESSLOGDIR=${NGINXDIR}/logs/access.log
            else
                NGINXACCESSLOGDIR=null
            fi
        fi
        echo ${NGINXACCESSLOGDIR}|grep "^/" &>/dev/null
        if [[ $? -ne 0 ]]; then
            NGINXACCESSLOGDIR=$NGINXDIR/${NGINXACCESSLOGDIR}
        # else
        #     NGINXACCESSLOGDIR=$NGINXDIR${NGINXACCESSLOGDIR}
        fi
        NGINXVER=`cat ${TMPFILE} |awk  '/nginx version/{print $NF}'`
        PORT=`grep -v "#" ${NGINXSONFIF}|grep listen|awk '{print $2}'|awk -F\; '{printf ":%s\n", $1}'|sed s/"\[::\]:"//`
        if [[ ! ${PORT} ]]; then
        PORT=":80"
        fi
        for port in ${PORT}; do
            echo "${HOSTIP}${port}##Nginx##${NGINXPROCESS}##${NGINXVER}##OneNode##${HOSTIP}$(grep -v "#" ${NGINXSONFIF}|grep listen|awk '{print $2}'|awk -F\; '{printf ":%s", $1}'|sed s/"\[::\]:"//)##${NGINXDIR}##${NGINXERRORLOGDIR}"\;"${NGINXACCESSLOGDIR}##${NGINXSONFIF}"
        done
    done
    echo "</STRESSRESULT>"
    exit
fi
#获取keepalived主备信息
get_cluster
for i in ${NGINXCMD}; do
    TMPFILE=/tmp/$(echo ${i}|sed s#/##g)
    echo ${TMPFILE} |grep -E "objs|overl"&> /dev/null
        if [[ $? -eq 0 ]]; then
            continue
        fi
    ${i} -h &> ${TMPFILE} 
    NGINXDIR=`grep "set prefix path"  ${TMPFILE} |awk '{print $NF}'|awk -F\) '{print $1}'`
    if [[ $(echo ${NGINXDIR}|grep "/$") ]]; then
        NGINXDIR=${NGINXDIR%?}
    fi
    NGINXSONFIF=$(grep "set configuration"  ${TMPFILE} |awk '{print $NF}'|awk -F\) '{print $1}')
    echo ${NGINXSONFIF}|grep "^/" &>/dev/null
    if [[ $? -ne 0 ]]; then
        NGINXSONFIF=$NGINXDIR/${NGINXSONFIF}
    # else
    #     NGINXSONFIF=$NGINXDIR${NGINXSONFIF}
    fi
    #错误日志   
    NGINXERRORLOGDIR=`grep -v "#" ${NGINXSONFIF}|grep error_log |awk '{print $2}'|awk -F\; '{print $1}'`
    if [[ ! ${NGINXERRORLOGDIR} ]]; then
        #未设置错误日志
        ls ${NGINXDIR}/logs/error.log &> /dev/null
        if [[ $? -eq 0 ]]; then
            NGINXERRORLOGDIR=${NGINXDIR}/logs/error.log
        else
            NGINXERRORLOGDIR=null
        fi
    fi
    echo ${NGINXERRORLOGDIR}|grep "^/" &>/dev/null
    if [[ $? -ne 0 ]]; then
        NGINXERRORLOGDIR=$NGINXDIR/${NGINXERRORLOGDIR}
    # else
    #     NGINXERRORLOGDIR=$NGINXDIR${NGINXERRORLOGDIR}
    fi
    #访问日志
    NGINXACCESSLOGDIR=`grep -v "#" ${NGINXSONFIF}|grep access_log |awk '{print $2}'|awk -F\; '{print $1}'`
    if [[ ! ${NGINXACCESSLOGDIR} ]]; then
        #未设置访问日志
        ls ${NGINXDIR}/logs/access.log &> /dev/null
        if [[ $? -eq 0 ]]; then
            NGINXACCESSLOGDIR=${NGINXDIR}/logs/access.log
        else
            NGINXACCESSLOGDIR=null
        fi
    fi
    echo ${NGINXACCESSLOGDIR}|grep "^/" &>/dev/null
    if [[ $? -ne 0 ]]; then
        NGINXACCESSLOGDIR=$NGINXDIR/${NGINXACCESSLOGDIR}
    # else
    #     NGINXACCESSLOGDIR=$NGINXDIR${NGINXACCESSLOGDIR}
    fi
    NGINXVER=`cat ${TMPFILE} |awk  '/nginx version/{print $NF}'`
    PORT=`grep -v "#" ${NGINXSONFIF}|grep listen|awk '{print $2}'|awk -F\; '{printf ":%s\n", $1}'|sed s/"\[::\]:"//`
    if [[ ! ${PORT} ]]; then
        PORT=":80"
    fi
        for port in ${PORT}; do
            echo "${HOSTIP}${port}##Nginx##${NGINXPROCESS}##${NGINXVER}##${CLUSTERSTATE}##${VIP}"\;"${HOSTIP}$(grep -v "#" ${NGINXSONFIF}|grep listen|awk '{print $2}'|awk -F\; '{printf ":%s", $1}'|sed s/"\[::\:]"//)##${NGINXDIR}##${NGINXERRORLOGDIR}"\;"${NGINXACCESSLOGDIR}##${NGINXSONFIF}"
        done
    echo "</STRESSRESULT>"
done
