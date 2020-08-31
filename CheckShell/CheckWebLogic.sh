#!/bin/bash
getProcPid=`ss -tnlp|grep java|awk -F, '{print $2}'|sort |uniq`
for pid in ${getProcPid}
do
#get weblogic info
    Name=`ps -ef |grep -v grep |grep ${pid}|grep weblogic|awk '{print $8}'|awk -F/ '{print $NF}'`
    if [[ ${Name} ]];then
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
        JarFile=`for i in ${DIR};do find /${i}/ -type f  -name "weblogic.jar" 2> /dev/null;done |awk 'NR==1{print}'`
    Version=`java -cp ${JarFile} weblogic.version|awk 'NR==2{print $1,$3}'`
    echo -e "${Name}##${Version}"
    exit
    fi
done
echo 'NoInstallweblogic##NoVersion'
