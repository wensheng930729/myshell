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
spawn scp 172.25.15.12:/etc/sysconfig/spawn-fcgi /etc/sysconfig
expect {
	"yes/no" { send "yes\r";exp_continue }
	"*password:" { send "uplooking\r" }	
}
expect eof
EOF

/usr/bin/expect <<EOF
spawn ssh root@172.25.15.12
expect "*password:"
send "uplooking\r"
expect "]#"
send "tar cf /tmp/data.tar /usr/share/nginx/bbs.com/\r"
send "exit\r"
expect eof
EOF

/usr/bin/expect <<EOF
spawn scp 172.25.15.12:/tmp/data.tar /tmp/
expect "*password:"
send "uplooking\r"
expect eof
EOF

tar xf /tmp/data.tar -C /
/usr/bin/expect <<EOF
spawn ssh root@172.25.15.11
expect {
        "yes/no" { send "yes\r";exp_continue }
        "*password:" { send "uplooking\r" }
}
expect "]#"
send "sed -i /gzip.*$/a"\upstream php_pools {\nserver 172.25.15.12:9000;\nserver 172.25.15.14:9000;\n}" /etc/nginx/nginx.conf\r"
expect "]#"
send "sed -i "s/fastcgi_pass.*/fastcgi_pass php_tools/" /etc/nginx/conf.d/www.bbs.com.conf\r"
expect eof
EOF

groupadd -g 994 nginx
useradd -u 996 -g nginx nginx
systemctl start spawn-fcgi.service 
chkconfig spawn-fcgi on

