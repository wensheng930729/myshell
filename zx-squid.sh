#! /bin/bash
#
#正向解析

yum install -y squid




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

