#!/bin/bash
Name=`ps -ef |grep -v grep |grep -i HMaster|awk '{print $8}'|awk -F/ '{print $NF}'`
if [[ ${Name} ]];then
#IS install
TmpFile=/tmp/hbasetmp
which hbase &> /dev/null
    if [[ $? -eq 1 ]]; then
        #have no kube cmd
        user=`ps -ef |grep -v grep |grep -i HMaster|awk '{print $1}'`
        su --session-command -l  ${user} "hbase version" &> ${TmpFile}
        Version=`cat ${TmpFile} |awk 'NR==1{print}'`
        echo -e "${Name}##${Version}"
        rm -rf  ${TmpFile}
        exit
    fi
su --session-command -l  msp "hbase version" &> ${TmpFile}
Version=`cat ${TmpFile} |awk 'NR==1{print}'`
rm -rf  ${TmpFile}
#print result
echo -e "${Name}##${Version}"
exit
fi
echo 'NoInstallHbase##NoVersion'