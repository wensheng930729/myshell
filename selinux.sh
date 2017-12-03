#!/bin/bash 
#一键停用selinux以及清除iptables

sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
setenforce 0
iptables -F
iptables -F -t nat
iptables-save &>/dev/null
