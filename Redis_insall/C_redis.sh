#拷贝脚本
#IP=("192.168.73.11" "192.168.73.12" "192.168.73.13")
IP="192.168.73.11
192.168.73.12
192.168.73.13"
Passwd='123'
SetYum(){
for i in `ls /etc/yum.repos.d/*.repo 2>/dev/null` ; do mv ${i} ${i}.back; done
cat > /etc/yum.repos.d/Centos7_aliyun.repo << EOF
[base]
name=Centos7 mirrors.aliyun.com -Base
baseurl=https://mirrors.aliyun.com/centos/7/os/x86_64/
gpgcheck=0
[updates]
name=Centos7 mirrors.aliyun.com -updates
baseurl=https://mirrors.aliyun.com/centos/7/updates/x86_64/
gpgcheck=0
[extras]
name=Centos7 mirrors.aliyun.com -extras
baseurl=https://mirrors.aliyun.com/centos/7/extras/x86_64/
gpgcheck=0
[epel]
name=Centos7 mirrors.aliyun.com epel
baseurl=https://mirrors.aliyun.com/epel/7/x86_64/
gpgcheck=0
[sclo]
baseurl=https://mirrors.aliyun.com/centos/7/sclo/x86_64/sclo/
name=Centos7 mirrors.aliyun.com Sclo
gpgcheck=0
[sclo-rh]
name=Centos7 mirrors.aliyun.com Sclo-rh
baseurl=https://mirrors.aliyun.com/centos/7/sclo/x86_64/rh/
gpgcheck=0
EOF
yum clean all &>/dev/null
}

Init(){
    SetYum
    yum -y install sshpass &>/dev/null
    grep "StrictHostKeyChecking" /etc/ssh/ssh_config|grep -qv "#"
    if [[ $? -eq 1 ]]; then
        echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
    else
        StrictHostKeyChecking=`grep "StrictHostKeyChecking" /etc/ssh/ssh_config|grep -v "#"|awk '{print $2}'`
        if [[ ${StrictHostKeyChecking} -ne "no" ]]; then
            sed -ir s/"StrictHostKeyChecking.+"/"StrictHostKeyChecking no"/ /etc/ssh/ssh_config
        fi
    fi
}
RunShell(){
    sshpass -p ${Passwd} scp Install_redis.sh root@${1}:/root/
    sshpass -p ${Passwd} ssh root@${1} 'bash /root/Install_redis.sh'
}
CreateCluster(){
    echo -n '' >/tmp/ClusterCmd
    echo -n 'redis-cli --cluster create' >> /tmp/ClusterCmd
    for i in ${IP}; do
        port=`sshpass -p ${Passwd} ssh root@${i} 'cat /tmp/Install.out'`
        for j in ${port};do
            echo -n " ${i}:${j}" >> /tmp/ClusterCmd
        done
    done
    echo -n ' --cluster-replicas 1' >> /tmp/ClusterCmd
    sshpass -p ${Passwd} ssh root@$(echo ${IP} |awk '{print $1}') $(cat /tmp/ClusterCmd) <<EOF
yes
EOF
}

Init
for i in ${IP};do
    RunShell $i &
done

# true=1
# while [[ ${true} == "1" ]]; do
#     sleep 5
#     ok=`sshpass -p ${Passwd} ssh root@$(echo ${IP} |awk '{print $1}') 'cat /tmp/Install.ok'`
#     if [[ ${ok} == "ok" ]]; then
#         break
#     fi
# done
for i in ${IP}; do
    true=1
    while [[ ${true} == 1 ]]; do
        sleep 15
        ok=`sshpass -p ${Passwd} ssh root@${i} 'cat /tmp/Install.ok'`
        if [[ ${ok} == "ok" ]]; then
            break
        fi
    done
done
CreateCluster