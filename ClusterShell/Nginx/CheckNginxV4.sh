#!/bin/bash
GET_IP(){
    IP_TMP_VAR=`ip addr | grep  inet|grep " scope global"|awk '{print $NF}'`
    for i in ${IP_TMP_VAR}
    do
       RESULT_IS_NULL=`ls /etc/sysconfig/network-scripts/*${i}* 2>/dev/null`
       if [ -n "${RESULT_IS_NULL}" ];then
            HOSTIP=`ip addr | grep  inet|grep " scope global"|grep ${i}|awk '{print $2}'|awk -F '/' '{print $1}'|awk 'NR==1{print}'`
       fi
    done
}
FIND_DIR(){
    for i in usr opt data home;do
        RESULT=`find /${i}/ -type d  -name ${1} 2>/dev/null`
        if [[ ${RESULT} ]]; then
            break
        fi
    done
    if [[ ! ${RESULT} ]]; then
        #未找到,全盘检索
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "boot|proc|run|dev|usr|opt|data|home"`
        for i in  ${DIR}; do 
            RESULT=`find /${i} -type d  -name ${1} 2>/dev/null`
            if [[ ${RESULT} ]]; then
                break
            fi
        done 
    fi
echo ${RESULT}
}
FIND_FILE(){
    for i in usr opt data home;do
        RESULT=`find /${i}/ -type f  -name ${1} 2>/dev/null`
        if [[ ${RESULT} ]]; then
            break
        fi
    done
    if [[ ! ${RESULT} ]]; then
        #未找到,全盘检索
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "boot|proc|run|dev|usr|opt|data|home"`
        for i in  ${DIR}; do 
            RESULT=`find /${i} -type f -name ${1} 2>/dev/null`
            if [[ ${RESULT} ]]; then
                break
            fi
        done 
    fi
echo ${RESULT}
}

GET_IP
echo  "<STRESSRESULT>"
ALLPID=`ps -ef |grep -v grep |grep  nginx|grep master |awk '{print $2}'|sort|uniq`
for PID in ${ALLPID}; do
    #判断是否为Nginx
    ISNGINX=`ss -tnlp|grep -w ${PID}|grep nginx`
    if [[ ${ISNGINX} ]]; then
        NGINXPID="${NGINXPID} ${PID}"
    fi
done

if [[ ${NGINXPID} ]]; then
    #存在Nginx进程
    for PID in ${NGINXPID}; do
        D_r=0
        TMPFILE=/tmp/nginx${PID}.out
        #获取端口
        PORTS=`ss -tnlp|grep -w ${PID}|awk '{print $4}'|awk -F: '{print $NF}'`
        #获取目录
        #查看进程是否指定目录-p
        ps -ef |grep -v grep |grep  nginx|grep master|grep -w  ${PID}|grep  "\-p" &> /dev/null
        if [[ $? -eq 0 ]]; then
            #有-p指定目录
            NGINXDIR=`ps -ef |grep -v grep |grep  nginx|grep master |grep -w  ${PID}|awk -F"-p" '{print $2}'|awk -F- '{print $1}'|sed s/' '//`
            if [[ ${NGINXDIR} == "." ]]; then
                #相对路径.
                ls -l /proc/${PID}/cwd &> /dev/null
                if [[ $? -eq 0 ]]; then
                    NGINXDIR=`ls -l /proc/${PID}/cwd|awk '{print $NF}'`
                else
                    NGINXDIR=''
                fi
            elif [[ ! $(echo ${NGINXDIR}|grep "^/") ]]; then
                #相对路径
                ls -l /proc/${PID}/cwd &> /dev/null
                if [[ $? -eq 0 ]]; then
                    TMPDIR=`ls -l /proc/${PID}/cwd|awk '{print $NF}'`
                    echo ${TMPDIR}|grep "/$" && NGINXDIR="${TMPDIR}${NGINXDIR}" || NGINXDIR="${TMPDIR}/${NGINXDIR}"
                else
                    ALLDIR=`FIND_DIR $(echo ${NGINXDIR}|awk -F/ '{print $NF}')`
                    for i in ALLDIR; do
                        NGINXDIR=`echo ${i} |grep "${NGINXDIR}"`
                        if [[ $? -eq 0  ]]; then
                            break
                        fi
                    done
                fi
            fi
        else
            #未指定目录
            ls -l /proc/${PID}/exe|awk '{print $NF}' &> /dev/null
            if [[ $? -eq 0 ]]; then
                NGINXCMD=`ls -l /proc/${PID}/exe|awk '{print $NF}'`
                if [[ ${NGINXCMD} ]]; then
                    
                    ${NGINXCMD} -h &> ${TMPFILE}
                    NGINXDIR=`grep "set prefix path"  ${TMPFILE} |awk -F: '{print $NF}'|awk -F\) '{print $1}'|sed s/" "//`
                else
                    NGINXDIR=`ls -l /proc/${PID}/cwd|awk '{print $NF}'`
                fi
            else
                NGINXDIR=''
            fi
        fi
        if [[ ! ${NGINXDIR} ]]; then
            NGINXDIR=`FIND_DIR nginx |awk 'NR==1{print}'`
        fi

        if [ ! -d ${NGINXDIR} ]; then
            NGINXDIR=null
            D_r=1
        fi
#-------------查看进程是否指定配置文件-c---------------------------
        ps -ef |grep -v grep |grep  nginx|grep master|grep -w  ${PID}|grep  "\-c" &> /dev/null
        if [[ $? -eq 0 ]]; then
            #有-c指定配文件
            NGINXCONF=`ps -ef |grep -v grep |grep  nginx|grep master|grep -w  ${PID}|awk -F"-c" '{print $2}'|awk -F- '{print $1}'|sed s/' '//`
            #判断配置文件是否为绝对路径
            if [[ ! $(echo ${NGINXCONF}|grep "^/") ]]; then
                ls -l /proc/${PID}/cwd &> /dev/null
                if [[ $? -eq 0 ]]; then
                    TMPDIR=`ls -l /proc/${PID}/cwd|awk '{print $NF}'`
                    echo ${TMPDIR}|grep "/$" && NGINXCONF="${TMPDIR}${NGINXCONF}" || NGINXCONF="${TMPDIR}/${NGINXCONF}"
                fi 
            fi
        else
            #没有指定配置文件
            if [ -d ${NGINXDIR} ]; then
                NGINXCONF=`find ${NGINXDIR} -name "nginx.conf" |awk 'NR==1{print }'`
                if [[ ! ${NGINXCONF} ]]; then
                    if [ -f /proc/${PID}/exe ]; then
                        NGINXCMD=`ls -l /proc/${PID}/exe|awk '{print $NF}'`
                        ${NGINXCMD} -h &> ${TMPFILE}
                        NGINXCONF=$(grep "set configuration"  ${TMPFILE} |awk '{print $NF}'|awk -F\) '{print $1}')
                    fi
                fi
            else
                if [ -f /proc/${PID}/exe ]; then
                    NGINXCMD=`ls -l /proc/${PID}/exe|awk '{print $NF}'`
                    ${NGINXCMD} -h &> ${TMPFILE}
                    NGINXCONF=$(grep "set configuration"  ${TMPFILE} |awk '{print $NF}'|awk -F\) '{print $1}')
                else
                    NGINXCONF=''
                fi
            fi
        fi
        if [[ ! ${NGINXCONF} ]]; then
            NGINXCONF=`FIND_FILE "nginx.conf"`
        fi
#------------------------------------------------------------
#----------获取版本------------------------------------
    #判断proc目录中是否存在nginx命令目录
    if [ -f /proc/${PID}/exe ]; then
        #存在
        NGINXCMD=`ls -l /proc/${PID}/exe|awk '{print $NF}'`
        ${NGINXCMD} -h &> ${TMPFILE}
        NGINXVER=`cat ${TMPFILE} |awk  '/nginx version/{print $NF}'`
    else
        #不存在，搜索NGINX命令
        for i in usr opt data home;do
        NGINXCMD=`find /${i}/ -type f  -name nignx 2>/dev/null`
        if [[ ${NGINXCMD} ]]; then
            ${NGINXCMD} -h &> /dev/null
            if [[ $? -eq 0 ]]; then
                break
            fi
        fi
        done
        ${NGINXCMD} -h &> /dev/null
        if [[ $? -ne 0 ]]; then
            #未找到,全盘检索
            DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "boot|proc|run|dev|usr|opt|data|home"`
            for i in  ${DIR}; do 
                NGINXCMD=`find /${i} -type f -name nignx 2>/dev/null`
                if [[ ${NGINXCMD} ]]; then
                    ${NGINXCMD} -h &> /dev/null
                    if [[ $? -eq 0 ]]; then
                        break
                    fi
                fi
            done 
        fi
        if [[ -x ${NGINXCMD} ]]; then
            ${NGINXCMD} -h &> ${TMPFILE}
            NGINXVER=`cat ${TMPFILE} |awk  '/nginx version/{print $NF}'`
        else
            NGINXVER='null'
        fi
    fi
#------------------------------------------
#----------日志----------------------
    NGINXLOGS=`cat ${NGINXCONF} |sed -e 's/^[ \t]*//g'|grep -Ev "^#|^$"|grep -Ev "stderr|off" |grep -E "error_log|access_log" |awk '{print $2}'|awk -F\; '{print $1}'`
        if [[ ! ${NGINXLOGS} ]]; then
            #主配置文件未设置错误日志
            CONFS=`cat ${NGINXCONF} |sed -e 's/^[ \t]*//g'|grep -Ev "^#|^$"|awk '/include/{print $2}'|awk -F\; '{print $1}'`
            NGINXLOGS=`grep -E "error_log|access_log" ${CONFS} 2>/dev/null|grep -Ev "stderr|off" |awk '{print $3}'|awk -F\; '{print $1}'|sort|uniq`
        fi
        if [[ ! ${NGINXLOGS} ]]; then
            if [[ ${D_r} == 0 ]]; then
                NGINXLOGS=`find ${NGINXDIR} -name "*.log" `
                if [[ ! ${NGINXLOGS} ]]; then
                    NGINXLOGS='null'
                fi
            else
                NGINXLOGS='null'
            fi
        fi
#-----------------------------------------

        # echo ${NGINXDIR}
        # echo ${NGINXCONF}
        # echo ${NGINXVER}
        # echo ${NGINXLOGS}
        for i in ${PORTS}; do
            echo "${HOSTIP}:${i}##Nginx##nginx##${NGINXVER}##OneNode##${HOSTIP}$(printf ':%s' ${PORTS})##${NGINXDIR}##$(printf '%s;' ${NGINXLOGS})##${NGINXCONF}"
        done
    done
else
    #不存在NGINX
    echo "${HOSTIP}##NoInstallNginx"
fi
echo "</STRESSRESULT>"