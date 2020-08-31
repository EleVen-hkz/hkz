#!/bin/bash
Name=`ss -tnlp|grep -Eo ceph-.*|awk -F\" '{print $1}'|sort|uniq`
if [[ ${Name} ]];then
#IS install
which ceph &> /dev/null
    if [[ $? -eq 1 ]]; then
        #have no ceph cmd
        DIR=`ls -l /|grep "^d"|awk '{print $NF}'|grep -Ev "bin|boot|proc|run|dev|run"`
        ceph_cmd=`for i in ${DIR};do find /${i}/ -type f  -name "ceph";done |awk 'NR==1{print}'`
        Version=`${kube_cmd} versions|grep -Eo "[0-9]+\.[0-9]+\.[0-9]"|sort |uniq`
        for j in ${Name}
        do
            echo -e "${j}##Ceph${Version}"
        done
        exit
    fi
Version=`ceph versions|grep -Eo "[0-9]+\.[0-9]+\.[0-9]"|sort |uniq`
#print result

for j in ${Name}
do
    echo -e "${j}##Ceph${Version}"
done
exit
fi
echo 'NoInstallCeph##NoVersion'