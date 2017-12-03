#! /bin/bash
#
#
setenforce 0
iptables -F
yum install -y lftp
yum install -y expect
lftp 172.25.254.250 <<EOF
cd /notes/project/UP200/UP200_nginx-master/pkg
get spawn-fcgi-1.6.3-5.el7.x86_64.rpm
EOF
rpm -ivh spawn-fcgi-1.6.3-5.el7.x86_64.rpm
yum -y install php php-mysql


/usr/bin/expect <<EOF
spawn ssh root@172.25.15.11
expect {
        "yes/no" { send "yes\r";exp_continue }
        "*password:" { send "uplooking\r" } 
}
expect "]#"
send "tar cf /tmp/datafile.tar /usr/share/nginx/bbs.com/\r"
expect "]#"
send "sed -i s/127.0.0.1/172.25.15.12/ /etc/nginx/conf.d/www.bbs.com.conf\r"
send "exit\r"
expect eof
EOF

/usr/bin/expect <<EOF
spawn scp 172.25.15.11:/etc/sysconfig/spawn-fcgi /etc/sysconfig/
expect  "*password:" 
send "uplooking\r"
expect eof
EOF

/usr/bin/expect <<EOF
spawn scp 172.25.15.11:/tmp/datafile.tar /tmp/
expect  "*password:" 
send "uplooking\r"
expect eof
EOF

tar -xf /tmp/datafile.tar -C /


groupadd -g 994 nginx
useradd -u 996 -g 994 nginx
systemctl start spawn-fcgi
systemctl enable spawn-fcgi

/usr/bin/expect <<EOF
spawn ssh root@172.25.15.11
expect "*password:" 
send "uplooking\r"
expect "]#"
send "systemctl restart nginx.service\r"
expect "]#"
send "systemctl stop spawn-fcgi.service\r"
send "exit\r"
expect eof
EOF
