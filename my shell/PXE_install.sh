#!/bin/bash
yum -y install wget
#install DHCP
yum -y install dhcp
cat >> /etc/dhcp/dhcpd.conf << EOF
subnet 192.168.4.0 netmask 255.255.255.0 {
  range 192.168.4.100 192.168.4.200;
  option routers 192.168.4.222;
  option broadcast-address 192.168.4.255;
  default-lease-time 600;
  max-lease-time 7200;
  next-server  192.168.4.222;
  filename "pxelinux.0";
}
EOF
systemctl restart dhcpd
systemctl enable  dhcpd
#-----------------------
#install TFTP
yum -y install tftp*
cd /var/lib/tftpboot/
wget ftp://192.168.4.254/centos-1804/isolinux/initrd.img
wget ftp://192.168.4.254/centos-1804/isolinux/isolinux.cfg
wget ftp://192.168.4.254/centos-1804/isolinux/splash.png
wget ftp://192.168.4.254/centos-1804/isolinux/vesamenu.c32
wget ftp://192.168.4.254/centos-1804/isolinux/vmlinuz
mkdir pxelinux.cfg ;mv isolinux.cfg  pxelinux.cfg/default
sed -i 's!append initrd.*! append initrd=initrd.img ks=ftp://127.0.0.1/ks.cfg!' pxelinux.cfg/default
#install syslinux
yum -y install syslinux
cp /usr/share/syslinux/pxelinux.0 .
#install  vsftpd
 yum -y install vsftpd
cat >> /var/ftp/ks.cfg << EOF
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Install OS instead of upgrade
install
# Keyboard layouts
keyboard 'us'
# Root password
rootpw --iscrypted $1$/zEQVja5$WwpY9RLtYbfmE4kox7q961
# Use network installation
url --url="ftp://192.168.4.254/centos-1804/"
# System language
lang en_US
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use graphical install
graphical
firstboot --disable
# SELinux configuration
selinux --disabled

# Firewall configuration
firewall --disabled
# Network information
network  --bootproto=dhcp --device=eth0
# Reboot after installation
reboot
# System timezone
timezone Asia/Shanghai
# System bootloader configuration
bootloader --location=mbr
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part / --fstype="xfs" --grow --size=1

%packages
@base
%end
EOF
systemctl enable  vsftpd tftp
systemctl restart vsftpd tftp

