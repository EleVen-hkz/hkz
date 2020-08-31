#!/bin/bash
Name=`ps -ef|grep -v grep  |grep resin|awk '{print $8}'|uniq|awk -F/ '{print $NF}'`
if [[ ${Name} ]];then
#IS install
DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "sbin|bin|boot|proc|run|dev|run"`
ResinFile=`for i in ${DIR};do find /${i}/ -type f  -name "resin.jar";done|awk 'NR==1{print}'`
which java  &> /dev/null
    if [[ $? -eq 1 ]]; then
        #have no java cmd
        java_cmd=`for i in ${DIR};do find /${i}/ -type f  -name "java";done |awk 'NR==1{print}'`
        Version=`${java_cmd} -classpath ${ResinFile} com.caucho.Version|awk 'NR==1{print $1}'`
        echo -e "${Name}##${Version}"
        exit
    fi
Version=`java -classpath ${ResinFile} com.caucho.Version|awk 'NR==1{print $1}'`
#print result
echo -e "${Name}##${Version}"
exit
fi
echo 'NoInstallResin##NoVersion'
