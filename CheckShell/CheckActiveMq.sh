#!/bin/bash
Name=`ps -ef|grep -v grep  |grep activemq |awk '{print $8}'|awk -F/ '{print $NF}'`
if [[ ${Name} ]];then
#IS install
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
        Version=`for i in ${DIR};do find /${i}/ -name "activemq*[-][0-9]*.jar" -type f;done |awk 'END{print}'|awk -F- '{print $NF}'|awk -F".jar" '{print $1}'`
#print result
echo -e "${Name}##activemq${Version}"
exit
fi
echo 'NoInstallActivemq##NoVersion'
