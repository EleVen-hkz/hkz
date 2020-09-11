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
