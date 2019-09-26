#!/bin/bash
read -p "请输入需要监控的网址(例:192.168.1.1/www.hkz.com):" Url
read -p "请输入该网址文件的原始HASH值(使用 md5sum 文件路径 即可获得):" True
while :
do
 curl $Url  &> /dev/null
 if [ $? -eq 0 ];then
  curl $Url  | md5sum  > /tmp/watchweb.tmp 
  now=`awk '{print $1}' /tmp/watchweb.tmp`
  [ $True  =  $now ] && echo "一致" || echo " 不一致"
 else 
  echo "主机不可用,检查网络或者服务"
 fi
 sleep 3 
done

