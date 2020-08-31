#!/bin/bash
Name=`ps -ef |grep -v grep |grep  hadoop|grep hive.server |awk '{print $8}'|awk -F/ '{print $NF}'`
if [[ ${Name} ]];then
#IS instal
DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
Verfile=`for i in ${DIR};do find /${i}/ -type f  -name ""hive-service-[0-9]*.jar"";done |awk 'NR==1{print}'`
Version=`echo $Verfile|awk -F/ '{print $NF}'|grep -Eo [0-9]+\.[0-9]+\.[0-9]+`
#print result
echo -e "${Name}##Hive${Version}"
exit
fi
echo 'NoInstallHive##NoVersion'