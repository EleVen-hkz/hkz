#!/bin/bash
recho(){
echo -e "\033[31m$1\033[0m"
}
gecho(){
echo -e "\033[32m$1\033[0m"
}
while :
do
 echo "
wellcome
0.退出
1.添加用户信息
2.删除用户信息
3.更改用户信息
4.查询用户信息"
 read -p "根据需求输入数字"  xuanze
 case $xuanze in
0) 
  echo "退出"
  break;;
1)#============添加用户信息===================
#--------------用户名信息--------------------
p=0
 while :
 do
  read -p "
	请输入用户名称(输入0返回):" name
  if  [ -z $name ];then  echo "输入为空"; else
   if [ $name =  0 ];then echo "返回";let p++ ;break
    else 
     id $name &>/dev/null 
     if [ $? = 0 ];then recho "用户$name 已存在,请重新输入
		" 
      else  useradd $name &>/dev/null; gecho "用户$name 创建完成
		"
     break 
     fi
    fi
  fi
 done
#----------------密码信息--------------------
while [ $p = 0 ]
do
 stty -echo;   
 read -p  "请输入密码" pass
 stty echo 
 if [ -z $pass ];then
  recho "密码不能为空
		" 
 else
  echo "$pass" |passwd --stdin $name &> /dev/null
   gecho "
密码修改完成
	";break
 fi
   done;;
#====================================================
2)#==============删除用户信息========================
while :
do 
 read -p "输入想要删除的用户名称" dname
 if [ -z $dname ];then recho"输入为空,请重新输入用户名"
 else
  id $dname &> /dev/null
  if [ $? = 0 ];then userdel $dname ;gecho "$dname 用户删除成功,home目录保留";break
  else 
   recho "用户不存在请重新输入
 	"
  fi
 fi
 done;;
#====================================================== 
3)#================更改用户信息=========================
while : 
do
 read -p "请输入需要更改的用户名称(输入0返回)" cname
 if [ -z $cname ];then 
  recho"输入为空,请重新输入用户名"
 else
  if [ $cname = 0 ];then recho "返回"
   break 
  else
   id $cname &> /dev/null
   if [ $? = 0 ];then 
   while :
   do
   recho "	您当前修改的用户是:< $cname >请选择要修改的内容"
    read -p "
	0.返回重新输入用户名
	1.修改$cname 用户密码
	2.修改$cname 用户shell
	3.修改$cname 用户UID
	4.添加$cname 用户附加组"  xz2
     case   $xz2 in 
#--------------修改密码------------------
      0)
	recho "返回"
	break;;
      1) 
	 while :
	 do
	 stty -echo;
	 read -p  "请输入新密码" pass1
	 stty echo 
    	  if [ -z $pass1 ];then
     	   recho "密码不能为空        " 
	  else
    	   echo "$pass1" |passwd --stdin $cname &> /dev/null;gecho "
		$cname 密码修改完成"
 	   break
   	  fi
         done;;
#------------------------------------------
#-------------修改shell--------------------
      2)
	while : 
	do
	    read -p "
        0.返回重新输入用户名
        1.修改$cname 为bash
        2.修改$cname 为/sbin/nologin
        3.修改$cname 为/bin/tcsh
        
"  xzs
	case $xzs in
     	 0)
	 recho "返回" 
	 break;;
	 1)
	 usermod -s /bin/bash $cname ; recho "$cname 用户已修改为bash";break ;;
	 2)
	 usermod -s /sbin/nologin $cname ; recho "$cname 用户已修改为/sbin/noligin";break ;;
	 3)
	 usermod -s /bin/tcsh  $cname ; recho "$cname 用户已修改为/bin/tcsh" ;break  ;;
	 *)
	 recho "请根据需求输入数字"
	esac
done;;
#------------------------------------------
#-------------修改UID----------------------
	3)
		while :
		do
		read -p "输入新的UID(q退出)" nuid
		if [ -z $nuid ] ;then
		 recho "输入为空,请重新输入"
		elif [ $nuid == q ];then
		 recho "退出"
		 break
		else
		  [ $nuid -gt 1000 ] && [ $nuid -lt 8000 ] && usermod -u $nuid  $cname && break || recho "UID需大于1000小于8000";
		 
		fi
		done
;;
#------------------------------------------
#-------------修改附加组-------------------
	4)
#		while :
  #              do
 #               read -p "输入附加组的名称(quit退出)" ngid
#                if [ -z $nuid ] ;then
		echo "待完善"

;;
#------------------------------------------
	*) 
      	  recho "请根据选项输入";;
  	esac
	done
    else
     recho "用户不存在"  
    
    fi
   fi
  fi
done;;
#===============结束更改=========================
4)#===============开始查询=========================
while :
do
read -p "
0.退出
1.查询特定用户信息
2.查询最近创建的用户名" xx4
[ -z  $xx4 ] && echo "请选择"
case $xx4 in 
0) 
 echo "退出"
 break;;
1)
 read -p "请输入用户名" name4 
 [ -z $name4 ] && recho "输入为空,重新输入" || id $name4 ;;
2)
 read -p "输入想查询最近创建的用户个数" usernum
 [ -z $usernum ] && echo "请输入个数"|| tail -n  $usernum /etc/passwd;;
*)
 recho "请根据需求输入数字"
esac
done
#================================================
 esac
done
