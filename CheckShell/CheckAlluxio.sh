#!/bin/bash
Name=`ps -ef |grep  -v grep |grep -i alluxiomaster|awk '{print $8}'|awk -F/ '{print $NF}'`
if [[ ${Name} ]];then
#IS install
which ntpd &> /dev/null
    if [[ $? -eq 1 ]]; then
        #have no kube cmd
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
        kube_cmd=`for i in ${DIR};do find /${i}/ -type f  -name "alluxio";done |awk 'NR==1{print}'`
        Version=`${kube_cmd} version`
        echo -e "${Name}##Alluxio${Version}"
        exit
    fi
Version=`alluxio version`
#print result
echo -e "${Name}##Alluxio${Version}"
exit
fi
echo 'NoInstallAlluxio##NoVersion'