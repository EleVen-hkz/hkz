CheckSysInfo(){
 #检查主机主要性能指标
    SysStatus=on
    #disk used 
    Disk=`df -h |awk 'NR>1{print $5}'|awk -F% '{print $1}'|awk 'BEGIN{max=0}{if(max<$1){max=$1}}END{print max}'`
    #Mem used
    Mem=`free |awk '/Mem/{printf "%d",$3/$2*100}'`
    #CPU used 
    CPU=`top -b -n1|awk -F, '/Cpu/{printf "%d" ,100-$4}'`
    echo ${Disk} ${Mem} ${CPU}
    if [[ ${Disk} -gt 25 && ${Mem} -gt 30 && ${CPU} -gt 2 ]]; then
        SysStatus=off
    fi
}

#-------------------------------------------
GET_PORT(){
#获取端口
    SoftName=redis-server
    PORT=''
    ALLPORT=''
    ALLPID=`ps -ef|grep -v grep |grep  ${SoftName}|awk '{print $2}'`
    for i in ${ALLPID}; do
        ALLPORT="${ALLPORT} `ss -tnlp|awk -v PID=${i} '{if(match($6,PID) ){print $4}}'|awk -F: '{print $2}'|sort|uniq`"
    done
    echo ${ALLPORT}
}

FIND_DIR(){
    DIRNAME="hello"
    First_DIR="data usr opt home var"
    for i in ${First_DIR};do
        RESULT=`find /${i}/ -type d  -name ${DIRNAME} 2>/dev/null`
        if [[ ${RESULT} ]]; then
            break
        fi
    done
    if [[ ! ${RESULT} ]]; then
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "boot|proc|run|dev|usr|opt|data|home|var"`
        for i in  ${DIR}; do 
            RESULT=`find /${i} -type d  -name ${DIRNAME} 2>/dev/null`
            if [[ ${RESULT} ]]; then
                break
            fi
        done 
    fi
    echo ${RESULT}
}

FIND_FILE(){
    FILENAME="hello.world"
    First_DIR="data home usr opt var"
    for i in ${First_DIR};do
        RESULT=`find /${i}/ -type f  -name ${FILENAME} 2>/dev/null`
        if [[ ${RESULT} ]]; then
            break
        fi
    done
    if [[ ! ${RESULT} ]]; then
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "boot|proc|run|dev|usr|opt|data|home|var"`
        for i in  ${DIR}; do 
            RESULT=`find /${i} -type f  -name ${FILENAME} 2>/dev/null`
            if [[ ${RESULT} ]]; then
                break
            fi
        done 
    fi
echo ${RESULT}
}

#获取IP（粗略）
IP_TMP_VAR=`ip addr | grep  inet|grep " scope global"| awk '{print $NF}'`
for i in ${IP_TMP_VAR}
do
   RESULT_IS_NULL=`ls /etc/sysconfig/network-scripts/*${i}* 2>/dev/null`
   if [ -n "${RESULT_IS_NULL}" ];then
        IP=`ip addr | grep  inet|grep " scope global"|grep ${i}|grep 'brd'|awk '{print $2}'|awk -F '/' '{print $1}'`
        if [[ "$IP"=="10.212.221.222" ]];then
           break
        fi
   fi
done
if [[ ! ${IP} ]]; then
    IP=`hostname -I|awk '{print $1}'`
fi