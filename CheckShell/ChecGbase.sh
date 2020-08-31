#!/bin/bash
Name=`ps -ef |grep -v grep |grep gbased|awk '{print $8}'|awk -F/ '{print $NF}'`
if [[ ${Name} ]];then
#IS install
which gbase &> /dev/null
    if [[ $? -eq 1 ]]; then
        #have no kube cmd
        su  --session-command -l GBase "gbase -V" &> /tmp/gbasetmp
        Version=`cat /tmp/gbasetmp |awk '{print $1,$3}'|awk -F, '{print $1}'`
        echo -e "${Name}##${Version}"
        exit
    fi
Version=`gbase -V|awk '{print $1,$3}'|awk -F, '{print $1}'`
#print result
echo -e "${Name}##${Version}"
exit
fi
echo 'NoInstallGbase##NoVersion'