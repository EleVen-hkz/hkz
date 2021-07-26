#!/bin/bash
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
DownLoadRedis(){
    RedisVersion=6.0.8
    Packages="redis-${RedisVersion}.tar.gz"
    rpm -q wget &>/dev/null
    if [[ $? -ne 0 ]]; then
    yum -y install wget &>/dev/null 
    fi
    wget http://download.redis.io/releases/redis-${RedisVersion}.tar.gz &> /dev/null
    if [[ $(ls -l|awk -v a=${Packages} '{if($NF==a){print}}'|awk '{print $5}') -eq 0  ]]; then
        rm -f ${Packages}
        echo "下载错误请使用以下命令尝试手动下载： wget http://download.redis.io/releases/redis-${RedisVersion}.tar.gz"
        exit
    fi
    
}
echo -n '' >/tmp/Install.out
echo -n '' >/tmp/Install.ok
ping baidu.com -c1 &>/dev/null
if [[ $? -ne 0 ]]; then
    echo "请配置网络参数，保证设备能够正常访问互联网"
    exit
fi
case $# in
    1 )
        if [[ -f $1 ]]; then
            SetYum
            Packages=$1 
        else
            echo -e "Usage: ${0} [RedisPackages] \nExample1:${0} redis-5.0.9.tar.gz\nExample2:${0}"
            exit 
        fi
        ;;
    0 )
        SetYum
        DownLoadRedis;;
    *)
        echo -e "Usage: ${0} [RedisPackages] \nExample1:${0} redis-5.0.9.tar.gz\nExample2:${0}"
        exit;;
esac
Port="6380 6381"
dirhome=/data
packdir="$(echo ${Packages}|awk -F.tar '{print $1}')_$(date +%s|cut -c7-)"
mkdir ${packdir}
tar xf ${Packages} --strip-components=1 -C ${packdir}
cd ${packdir}
if [[ $(echo ${Packages}|grep -Eo \([0-9]+\.\){2}[0-9]+|awk -F. '{print $1}')  -ge 6 ]]; then
    yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils &>/dev/null
    scl enable devtoolset-9 make &>/dev/null
else
    yum -y install gcc &>/dev/null
    make &>/dev/null
fi
Ser_cmd=`find . -type f -name redis-server`
if [[ ! ${Ser_cmd} ]]; then
    echo "编译失败请检查gcc与reids版本兼容性"
    exit
fi
Cli_cmd=`find . -type f -name redis-cli`
cp ${Cli_cmd} /usr/local/bin/
for i in ${Port}; do
    true=1
    AllListenPort=`ss -tnlp|awk '{print $4}'|awk -F: '{print $NF}'|sort |uniq`
    while [[ ${true} == 1 ]]; do
        echo ${AllListenPort}|grep -w ${i} &>/dev/null
        if [[ $? -eq 0 ]]; then
            i=$[i+7]
        else
            break
        fi
    done
    dir=${dirhome}/redis/redis_${i}
    ConfFile=${dir}/redis_${i}.conf
    logfile=${dir}/redis.log
    mkdir -p ${dir}
    cp redis.conf ${ConfFile}
    echo ${i} >> /tmp/Install.out
    sed -i s/"bind 127.0.0.1"/"bind 0.0.0.0"/ ${ConfFile}
    sed -i s/"port 6379"/"port ${i}"/ ${ConfFile}
    sed -i s/"daemonize no"/"daemonize yes"/ ${ConfFile}
    sed -i s#"pidfile /var/run/redis_6379.pid"#"pidfile /var/run/redis_${i}.pid"#  ${ConfFile}
    sed -i s#"logfile \"\""#"logfile ${logfile}"# ${ConfFile}
    sed -i s#"dir \.\/"#"dir ${dir}"# ${ConfFile}
    echo "cluster-enabled yes" >> ${ConfFile}
    ${Ser_cmd} ${ConfFile} 
done

echo "ok" >/tmp/Install.ok