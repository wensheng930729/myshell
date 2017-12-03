#! /bin/bash
#
#squid 透明代理

yum install -y squid

sed -i 's/^http_port.*/http_port 3128 transparent/' /etc/squid/squid.conf
echo "cache_mem 350 MB" >> /etc/squid/squid.conf
echo "cache_dir ufs /var/spool/squid 1000 16 256" >> /etc/squid/squid.conf
echo "acl mynetwork src 192.168.100.0/255.255.255.0" >> /etc/squid/squid.conf
echo "http_access allow mynetwork" >> /etc/squid/squid.conf

service squid start
if [ $? -eq 0 ]
then
    echo "service squid start ok"
else
    echo "error"
    exit 1
fi
read -p "输入squid代理服务器的外网IP：" ipc
iptables -F -t nat 
iptables -t nat -A PREROUTING -i eth1 -s 192.168.100.0/24 -p tcp --dport 80 -j REDIRECT --to 3128
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -p
iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -j SNAT --to-source $ipc

echo "squid透明代理已经设置OK"
