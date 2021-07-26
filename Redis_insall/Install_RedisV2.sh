#填入IP、用户名（多个IP用空格隔开）
#运行前确保目标设备可免密登录
#依赖包
#devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils gcc netstat 
IP="192.168.0.71 192.168.0.72 192.168.0.73 "
User='redis'
now=`date +%Y%m%d`
CreateShell(){
cat > Install_redis.sh <<HAHA
#!/bin/bash
OutFile=/tmp/Out.${now}
OkFile=/tmp/ok.${now}
echo -n '' > \${OutFile}
echo -n '' > \${OkFile}
case \$# in
1 )
if [[ -f \$1 ]]; then
Packages=\$1 
else
echo -e "Usage: \${0} [RedisPackages] \nExample1:\${0} redis-5.0.9.tar.gz\nExample2:\${0}"
exit 
fi
;;
*)
echo -e "Usage: \${0} [RedisPackages] \nExample1:\${0} redis-5.0.9.tar.gz\nExample2:\${0}"
exit;;
esac
Port="6380 6381"
dirhome=\$(pwd)
packdir="\$(echo \${Packages}|awk -F.tar '{print \$1}')_\$(date +%s|cut -c7-)"
mkdir \${packdir}
mkdir bin &>/dev/null 
tar xf \${Packages} --strip-components=1 -C \${packdir}
cd \${packdir}
if [[ \$(echo \${Packages}|grep -Eo \([0-9]+\.\){2}[0-9]+|awk -F. '{print \$1}')  -ge 6 ]]; then
scl enable devtoolset-9 make &>/dev/null
else
make &>/dev/null
fi
Ser_cmd=\`find . -type f -name redis-server\`
if [[ ! \${Ser_cmd} ]]; then
echo "编译失败，请检查依赖包或gcc与reids版本兼容性"
exit
fi
for i in \${Port}; do
true=1
AllListenPort=\$(netstat -tnl|awk 'NR>2{print \$4}'|awk -F: '{print \$NF}'|sort|uniq)
while [[ \${true} == 1 ]]; do
echo \${AllListenPort}|grep -w \${i} &>/dev/null
if [[ \$? -eq 0 ]]; then
i=\$[i+7]
else
break
fi
done
dir=\${dirhome}/redis/redis_\${i}
ConfFile=\${dir}/redis_\${i}.conf
logfile=\${dir}/redis.log
mkdir -p \${dir}
cp redis.conf \${ConfFile}
echo \${i} >> \${OutFile}
sed -i s/"bind 127.0.0.1"/"bind 0.0.0.0"/ \${ConfFile}
sed -i s/"port 6379"/"port \${i}"/ \${ConfFile}
sed -i s/"daemonize no"/"daemonize yes"/ \${ConfFile}
sed -i s#"pidfile /var/run/redis_6379.pid"#"pidfile /var/run/redis_\${i}.pid"#  \${ConfFile}
sed -i s#"logfile \"\""#"logfile \${logfile}"# \${ConfFile}
sed -i s#"dir \.\/"#"dir \${dir}"# \${ConfFile}
echo "cluster-enabled yes" >> \${ConfFile}
\${Ser_cmd} \${ConfFile} 
done
Cli_cmd=\`find . -type f -name redis-cli\`
cp \${Cli_cmd} ~/bin
echo "ok" > \${OkFile}
HAHA
}
Init(){
    CreateShell 
    # grep "StrictHostKeyChecking" /etc/ssh/ssh_config|grep -qv "#"
    # if [[ $? -eq 1 ]]; then
    #     echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
    # else
    #     StrictHostKeyChecking=`grep "StrictHostKeyChecking" /etc/ssh/ssh_config|grep -v "#"|awk '{print $2}'`
    #     if [[ ${StrictHostKeyChecking} -ne "no" ]]; then
    #         sed -ir s/"StrictHostKeyChecking.+"/"StrictHostKeyChecking no"/ /etc/ssh/ssh_config
    #     fi
    # fi
}
RunShell(){
    scp Install_redis.sh ${User}@${1}:/home/${User}/
    scp ${Packages} ${User}@${1}:/home/${User}/
    ssh ${User}@${1} "bash Install_redis.sh $(echo ${Packages} |awk -F/ '{print $NF}')"
}
CreateCluster(){
    echo -n '' > /tmp/ClusterCmd.${now}
    echo -n 'redis-cli --cluster create' >> /tmp/ClusterCmd.${now}
    for i in ${IP}; do
        port=`ssh ${User}@${i} "cat /tmp/Out.${now}"`
        for j in ${port};do
            echo -n " ${i}:${j}" >> /tmp/ClusterCmd.${now}
        done
    done
    echo -n ' --cluster-replicas 1' >> /tmp/ClusterCmd.${now}
    ssh ${User}@$(echo ${IP} |awk '{print $1}') $(cat /tmp/ClusterCmd.${now}) <<EOF
yes
EOF
}
if [[ $# -ne 1 ]]; then
    echo -e "Usage: ${0} RedisPackages \nExample1:${0} redis-5.0.9.tar.gz"
    exit 
else
    if [[ ! -f $1  ]]; then
        echo -e "Usage: ${0} RedisPackages \nExample1:${0} redis-5.0.9.tar.gz"
        exit
    fi
fi
Packages=$1
Init
for i in ${IP};do
    RunShell $i >/tmp/${i}_Install.out &
done
sleep 10
for i in ${IP}; do
    true=1
    Time=0
    while [[ ${true} == 1 ]]; do
        if [[ ${Time} -gt 300 ]]; then
            echo -e "Error: Time out"
            exit
        fi
        ok=`ssh ${User}@${i} "cat /tmp/ok.${now}"`
        if [[ ${ok} == "ok" ]]; then
            break
        fi
        sleep 15
        Time=$[Time+15]
    done
done
CreateCluster
echo  "集群地址："
cat /tmp/ClusterCmd.${now} |grep -Eo \([0-9]+"\."\){3}[0-9]+\:[0-9]+
