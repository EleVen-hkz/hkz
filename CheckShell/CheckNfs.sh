#!/bin/bash
Name=`ps -ef|grep -v grep  |awk '{print $8}' |grep  harbor_core|awk -F/ '{print $NF}'`
if [[ ${Name} ]];then
#IS install
which ntpd &> /dev/null
    if [[ $? -eq 1 ]]; then
        #have no kube cmd
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
        kube_cmd=`for i in ${DIR};do find /${i}/ -type f  -name "ntpd";done |awk 'NR==1{print}'`
        ${kube_cmd} --version &> /tmp/ntdname
        Version=`cat /tmp/ntpdname |awk 'NR==1{print}'`
        echo -e "${Name}##${Version}"
        rm -rf  /tmp/ntdname
        exit
    fi
ntpd --version &> /tmp/ntdname
Version=`cat /tmp/ntdname |awk 'NR==1{print}'`
rm -rf  /tmp/ntdname
#print result
echo -e "${Name}##${Version}"
exit
fi
echo 'NoInstallNtpd##NoVersion'