#! /bin/bash
#
#
setenforce 0
iptables -F
iptables-save
yum install -y expect
/usr/bin/expect <<EOF
spawn ssh root@172.25.15.12
expect {
	"yes/no" { send "yes\r";exp_continue }
	"*password:" { send "uplooking\r" }
}
expect "]#"
send "tar cf /tmp/data1.tar /usr/share/nginx/bbs.com/\r"
send "exit\r"
expect eof
EOF

/usr/bin/expect <<EOF
spawn scp 172.25.15.12:/tmp/data1.tar /tmp/
expect "*password:"
send "uplooking\r"
expect eof
EOF

tar -xf /tmp/data1.tar -C /

groupadd -g 994 nginx
useradd -u 996 -g nginx nginx
echo "/usr/share/nginx/bbs.com 172.25.15.0/24(rw)" >>/etc/exports

systemctl start rpcbind
systemctl start nfs-server

/usr/bin/expect <<EOF
spawn ssh root@172.25.15.12
expect "*password:"
send "uplooking\r"
expect "]#"
send "mount 172.25.15.19:/usr/share/nginx/bbs.com /usr/share/nginx/bbs.com\r"
send "exit\r"
expect eof
EOF

/usr/bin/expect <<EOF
spawn ssh root@172.25.15.14
expect {
        "yes/no" { send "yes\r";exp_continue }
        "*password:" { send "uplooking\r" }
}
expect "]#"
send "mount 172.25.15.19:/usr/share/nginx/bbs.com /usr/share/nginx/bbs.com\r"
send "exit\r"
expect eof
EOF

/usr/bin/expect <<EOF
spawn ssh root@172.25.15.11
expect {
        "yes/no" { send "yes\r";exp_continue }
        "*password:" { send "uplooking\r" }
}
expect "]#"
send "mount 172.25.15.19:/usr/share/nginx/bbs.com /usr/share/nginx/bbs.com\r"
send "exit\r"
expect eof
EOF

