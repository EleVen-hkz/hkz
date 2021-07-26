#!/bin/bash
echo "<STRESSRESULT>"
IP_TMP_VAR=`ip addr | grep  inet|grep " scope global"|awk '{print $NF}'`
for i in ${IP_TMP_VAR}
do
   RESULT_IS_NULL=`ls /etc/sysconfig/network-scripts/*${i}* 2>/dev/null`
   if [ -n "${RESULT_IS_NULL}" ];then
        HOSTIP=`ip addr | grep  inet|grep " scope global"|grep ${i}|awk '{print $2}'|awk -F '/' '{print $1}'|awk 'NR==1{print}'`
   fi
done
if [[ ! ${HOSTIP} ]]; then
    HOSTIP=`hostname -I 2>/dev/null|awk '{print $1}'`
fi
PROCESSID=`for i in $(ss -tnlp|awk '/java/{print $NF}'|awk -F, '{print $2}'|grep -Eo [0-9]+|sort |uniq); do ps -ef |grep -v grep |grep ${i}|grep -i tomcat-juli.jar|awk '{print $2}'; done`
if [[ ! ${PROCESSID} ]]; then
    echo "${HOSTIP}##NoInstallTomcat"
    echo "</STRESSRESULT>"
    exit
fi
for PID in ${PROCESSID}; do
    TOMCATHOME=`ps -ef|grep -v grep|grep  ${PID}|awk -F'Dcatalina.home=' '{print $2}'|awk '{print $1}'`
    # which tomcat &>/dev/null 
    # if [[ $? -eq 0 ]]; then
        #TOMCATVERSION=`tomcat version|awk 'NR==1{print $NF}'`
    # else
        TOMCATVERSION=`${TOMCATHOME}/bin/version.sh 2>/dev/null|grep "Server version"|awk '{print $NF}'`
    # fi
    if [[ ! ${TOMCATVERSION} ]]; then
        TOMCATVERSION=`tomcat version 2>/dev/null |awk 'NR==1{print $NF}'`
    fi
    TOMCATPORTS=`ss -tnlp|awk -v pid=${PID} '{if(match($NF,pid)){print $4}}'|awk -F: '{print $NF}'|sort|uniq`
    #TOMCATPORTS=`cat ${TOMCATHOME}/conf/server.xml| grep -E "<Connector port=\"[0-9]+\""|grep  HTTP|awk '{print $2}'|awk -F\" '{print $2}'`
    TOMCATCONF=${TOMCATHOME}/conf/server.xml 
    TMPLOGDIR=`find  ${TOMCATHOME} -maxdepth 1 -name "*log*" `
    for i in ${TMPLOGDIR}; do
        TYPE=`ls -ld ${i}|awk '{print $1}'|grep -Eo ^.`
        if [[ ${TYPE} == "l" ]]; then
            TOMCATLOGDIR="${TOMCATLOGDIR} $(ls -l ${i}|awk '{print $NF}')"
        elif [[ ${TYPE} == "d" ]]; then
            TOMCATLOGDIR="${TOMCATLOGDIR} ${i}"
        fi
    done
    [ ! "${TOMCATHOME}" ] && TOMCATHOME='NULL'
    [ ! "${TOMCATVERSION}" ] && TOMCATVERSION='NULL'
    [ ! "${TOMCATLOGDIR}" ] && TOMCATLOGDIR='NULL'
    [[ -f ${TOMCATCONF} ]] || TOMCATCONF='NULL'
    #TOMCATLOG=${TOMCATHOME}/logs
    for i in ${TOMCATPORTS}; do
        echo "${HOSTIP}:${i}##Tomcat##tomcat-juli.jar##${TOMCATVERSION}##OneNode##${HOSTIP}$(printf ':%s' ${TOMCATPORTS})##${TOMCATHOME}##$(printf '%s;' ${TOMCATLOGDIR})##${TOMCATCONF}"
    done
done
echo "</STRESSRESULT>"