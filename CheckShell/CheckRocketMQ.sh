#!/bin/bash
Name=`ps -ef|grep  -v grep |grep  rocketmq|awk '{print $8}'|awk -F/ '{print $NF}'|grep -v sh`
if [[ ${Name} ]];then
#IS instal
Version=`ps -ef|grep  -v grep |grep  -Eo rocketmq-[0-9]+\.[0-9]+\.[0-9]+|sort|uniq`
#print result
echo -e "${Name}##rocketmq${Version}"
exit
fi
echo 'NoInstallRocketmq##NoVersion'