#! /bin/bash
#
#将tomcat服务器加入共享存储
yum install -y expect
setenforce 0
/usr/bin/expect <<EOF
spawn ssh root@172.25.15.10
expect {
	"yes/no" { send "yes\r";exp_continue }
	"*password:" { send "uplooking\r" }
}
expect "]#"
send "tar -czf /tmp/jsp.tgz /home/tomcat/apache-tomcat-8.0.24/jsp.com/\r"
expect "]#"
send "exit\r"
expect eof
EOF

/usr/bin/expect <<EOF
spawn scp 172.25.15.10:/tmp/jsp.tgz /tmp
expect "uplooking"
send "uplooking\r"
expect eof
EOF

tar -zxf /tmp/jsp.tgz -C /
echo "/home/tomcat/apache-tomcat-8.0.24/jsp.com 172.25.15.0/24(rw)" >>/etc/exports
systemctl restart nfs

/usr/bin/expect <<EOF
spawn ssh root@172.25.15.10
expect "uplooking"
send "uplooking\r"
expect "]#"
send "mount  172.25.15.19:/home/tomcat/apache-tomcat-8.0.24/jsp.com /home/tomcat/apache-tomcat-8.0.24/jsp.com\r"
expect "]#"
send "exit\r"
expect eof
EOF

/usr/bin/expect <<EOF
spawn ssh root@172.25.15.15
expect {
        "yes/no" { send "yes\r";exp_continue }
        "*password:" { send "uplooking\r" }
}
expect "]#"
send "mount  172.25.15.19:/home/tomcat/apache-tomcat-8.0.24/jsp.com /home/tomcat/apache-tomcat-8.0.24/jsp.com\r"
expect "]#"
send "exit\r"
expect eof
EOF

