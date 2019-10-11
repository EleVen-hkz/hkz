#!/bin/bash
while :
do
echo "
输入想要安装的软件名称"
read -p "在此输入:" name
[ -z $name ] && echo "输入为空,请重试!" || 

#===========过滤匹配关键的软件包并输出=============
yum list |grep $name | awk '{print $1}' > /tmp/appname.txt 2> /dev/null
#num=`wc -l /tmp/appname.txt |awk '{print $1}'`
num=`sed -n '$=' /tmp/appname.txt`
[ -z  $num ]&& echo "没有找到相关软件包,请重试" && continue 
echo "共找到 $num 个与$name 相关软件包,选择需要安装的软件包,输入相应的数字(输入0返回重新输入软件名)"
for  i in `seq $num `
do
 echo "第 $i 个包:$(head -$i /tmp/appname.txt|tail -1)"
done
while :
do
 read -p "在此输入数字(输入0返回重新输入软件名):" xz 
 [ -z $xz ] && echo "输入为空,请重试" && continue 
 b=`[ $xz -eq 1 ] &>  /dev/null ;echo $?`
 [ $b -eq 2 ] && echo "请输入正整数" && continue
break
done
[ $xz -eq 0 ] && continue || yum -y install $(head -$xz /tmp/appname.txt|tail -1) 
echo "$(head -$xz /tmp/appname.txt|tail -1) 安装完成!" 

done
