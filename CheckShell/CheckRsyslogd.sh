#!/bin/bash
Name=`ps -ef |grep -v grep |grep  rsyslogd |awk '{print $8}'|awk -F/ '{print $NF}'`
if [[ ${Name} ]];then
#IS install
which rsyslogd &> /dev/null
    if [[ $? -eq 1 ]]; then
        #have no rsyslogd cmd
        DIR=`ls /|grep -Ev "bin|boot|proc|run|dev|run"`
        rsyslogd_cmd=`for i in ${DIR};do find /${i}/ -type f  -name "rsyslogd";done |awk 'NR==1{print}'`
        Version=`${rsyslogd_cmd} -ver |awk -F, 'NR==1{print $1}'`
        echo -e "${Name}##${Version}"
        exit
    fi
Version=`rsyslogd -ver|awk -F, 'NR==1{print $1}'`
#print result
echo -e "${Name}##${Version}"
exit
fi
echo 'NoInstallRsyslogd##NoVersion'
