#!/bin/bash
echo "正在运行,请根据提示输入相应参数!"
sleep 2 
yum -y install libreswan 
#安装ipsec软件包
if [ ! $? -eq 0 ];then
 while :
 do 
 read -p "请输入ipsec软件包的绝对路径(例:/root/libreswan.x86_64):" ipsec_path
 if [ -z $ipsec_path ];then
  echo "输入为空,请重新输入" 
 else
  yum -y install $ipsec_path 
  [ $? -eq 0 ] && break || echo "路径错误,请重新输入" 
 fi
 done
fi
#------------修改ipsec配置文件---------
cf=/etc/ipsec.d/hkz_ipsec.conf
echo "conn L2TP-PSK-NAT" >> $cf
echo "   rightsubnet=vhost:%priv " >> $cf 
echo "   also=L2TP-PSK-noNAT" >> $cf 
echo "conn L2TP-PSK-noNAT" >> $cf 
echo "   authby=secret   " >> $cf
echo "   ike=3des-sha1;modp1024" >> $cf
echo "   phase2alg=aes256-sha1;modp2048" >> $cf
echo "   pfs=no" >> $cf
echo "   auto=add" >> $cf
echo "   keyingtries=3" >> $cf
echo "   rekey=no" >> $cf
echo "   ikelifetime=8h" >> $cf
echo "   keylife=3h" >> $cf
echo "   type=transport" >> $cf
while :
 do 
 read -p "请输入本机公网IP地址:"  gip
 if [ -z $gip ];then 
  echo "输入为空,请重新输入" 
 else 
 echo " left=$gip" >> $cf
 break
 fi
 done
echo "   leftprotoport=17/1701" >> $cf
echo "   right=%any " >> $cf
echo "   rightprotoport=17/%any" >> $cf
#---------------------------------
echo '$gip  %any: PSK "hkz" ' > /etc/ipsec.d/hkz.secrets
systemctl restart ipsec
systemctl enable  ipsec
#--------------------------------
yum -y install xl2tpd 
if [ ! $? -eq 0 ];then
 while :
 do 
 read -p "请输入Xl2TP软件包的绝对路径(例:/root/XL2TPD.x86_64):" XL2TPD_path
 if [ -z $XL2TPD_path ];then
  echo "输入为空,请重新输入" 
 else
  yum -y install $XL2TPD_path 
  [ $? -eq 0 ] && break || echo "路径错误,请重新输入" 
 fi
 done
fi
#------------------------------
sed -in "s/local.*/local ip=$gip/" /etc/xl2tpd/xl2tpd.conf 
sed -inr  "/crtsct/s/^/#/" /etc/ppp/options.xl2tpd
sed -inr  "/lock/s/^/#/" /etc/ppp/options.xl2tpd
echo "require-mschap-v2" >> /etc/ppp/options.xl2tpd
echo "hkz   *   EleVen.123   * " >> /etc/ppp/chap-secrets
systemctl restart xl2tpd
systemctl enable  xl2tpd
#--------------------------------
echo "1" > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
firewall-cmd --set-default-zone=trusted  &> /dev/null
iptables -t nat -A POSTROUTING -s 192.168.1.0/24  -j SNAT --to-source $gip
echo "完成"
echo '	ipsec :  hkz 
	用户名:  hkz
	密码:	 EleVen.123'

