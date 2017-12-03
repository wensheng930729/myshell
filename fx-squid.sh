#! /bin/bash
#
#squid反向代理设置

setenforce 0
yum install -y squid
read -p "输入后端web1服务器(jsp)的IP："  ip1
read -p "输入后端web2服务器(php)的IP："  ip2
read -p "输入客户端访问的web服务器的IP："  ip3
sed -i 's/http_access deny all/http_access allow all/' /etc/squid/squid.conf
sed -i 's/^http_port.*/http_port 80 accel vhost vport/' /etc/squid/squid.conf
echo "http_port 80 accel vhost vport" >> /etc/squid/squid.conf
echo "cache_dir ufs /var/spool/squid 256 16 256" >> /etc/squid/squid.conf
echo "cache_peer $ip1 parent 80 0 no-query originserver name=jsp" >> /etc/squid/squid.conf
echo "cache_peer $ip2 parent 80 0 no-query originserver name=php" >> /etc/squid/squid.conf
echo "cache_peer_domain jsp www.jsp.com" >> /etc/squid/squid.conf
echo "cache_peer_domain jsp $ip3" >> /etc/squid/squid.conf
echo "cache_peer_domain php www.bbs.com" >> /etc/squid/squid.conf
echo "cache_peer_domain php $ip3" >> /etc/squid/squid.conf


service squid start
if [ $? -eq 0 ]
then
    echo "service squid start ok"
else
    echo "error"
    exit 1
fi

