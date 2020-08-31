#!/bin/bash
Name=`ps -ef |grep -v grep |grep vsftpd |awk '{print $8}'|awk -F/ '{print $NF}'`
if [[ ${Name} ]];then
#IS install
which rpm  &> /dev/null
    if [[ $? -eq 1 ]]; then
        #have no nfsstat cmd
        DIR=`ls /|grep -Ev "bin|boot|proc|run|dev|run"`
        rpm_cmd=`for i in ${DIR};do find /${i}/ -type f  -name "rpm";done |awk 'NR==1{print}'`
        Version=`${rpm_cmd} -qa|grep vsftpd|awk -F".el" '{print $1}'`
        echo -e "${Name}##${Version}"
        exit
    fi
Version=`rpm -qa|grep vsftpd|awk -F".el" '{print $1}'`
#print result
echo -e "${Name}##${Version}"
exit
fi
echo 'NoInstallNfs##NoVersion'
