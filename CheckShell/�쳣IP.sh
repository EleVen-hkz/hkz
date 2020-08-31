#!/bin/bash
Today=`date |awk '{print $2,$3}'`
grep "^${Today}" /var/log/secure > /tmp/secure.tmp
SecureFile=/tmp/secure.tmp
OutFile=/tmp/failed.tmp
echo -n '' > ${OutFile}
IsError=0
#0 表示正常；1表示有暴力破解；11表示有暴力破解，并且已经创建连接
DeviantIP=`grep -i Failed ${SecureFile} |grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}"|sort|uniq`
for IP in ${DeviantIP};do
    FailedNum=`grep  ${IP} ${SecureFile}|grep  -i failed|wc -l`
    if [[ ${FailedNum} -gt 1 ]]; then
        #错误次数大于1
        IsError=1
        echo -e "${IP} 正在尝试暴力破解，已错误登录${FailedNum}次！！！" >> ${OutFile}
        ConnetPort=`ss -tuanp|grep  ${IP}|awk '{print $5}'|awk -F: '{print $NF}'` 
        if [[ ${ConnetPort} ]]; then
        #异常IP已经与本机建立连接
        echo -e "警告：异常IP[${IP}]已与本机$(echo ${ConnetPort})端口建立连接！！！！" >> ${OutFile}
        IsError=${IsError}1
        fi
    fi
done
echo ${IsError}
