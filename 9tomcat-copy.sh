#! /bin/bash
#
#Tomcat的程序复制脚本
setenforce 0
iptables -F
iptables-save
yum install -y expect
yum install -y lftp &>/dev/null
cd ~
lftp 172.25.254.250 <<EOF
cd /notes/project/UP200/UP200_tomcat-master
mirror pkg/
EOF

cd pkg
mkdir /usr/local/tomcat
tar xf jdk-7u15-linux-x64.tar.gz -C /usr/local/tomcat/
/usr/bin/expect <<EOF
spawn ssh root@172.25.15.10
expect {
	"yes/no" { send "yes\r";exp_continue }
	"*password:" { send "uplooking\r" }
}
expect "]#"
send "tar -czf /tmp/tomcat.tgz /home/tomcat/apache-tomcat-8.0.24/ /etc/init.d/tomcat\r"
send "exit\r"
expect eof
EOF

/usr/bin/expect <<EOF
spawn scp 172.25.15.10:/tmp/tomcat.tgz /root/
expect "*password:"
send "uplooking\r"
expect eof
EOF



tar -zxf /root/tomcat.tgz -C /
groupadd -g 888 tomcat
useradd -u 888 -g 888 -s /sbin/nologin tomcat
chown tomcat.tomcat /home/tomcat/ -R
chmod 700 /home/tomcat/
chkconfig --add tomcat
chkconfig tomcat on
service tomcat start
pnum1=`netstat -lntp |grep :8009|awk -F: '{ print $4 }'`
pnum2=`netstat -lntp |grep :8080|awk -F: '{ print $4 }'`
if [ "$pnum1"=8009 ] && [ "$pnum2"=8080 ]
then
    echo "Tomcat启动成功！"
else
    echo "Tomcat启动失败，已退出"
    exit 1
fi


/usr/bin/expect <<EOF
spawn ssh root@172.25.15.13
expect {
        "yes/no" { send "yes\r";exp_continue }
        "*password:" { send "uplooking\r" }
}
expect "]#"
send "sed -i /gzip.*/a'\upstream jsp-pools { server 172.25.15.10:8080 weight=1;server 172.25.15.15:8080 weight=1;}' /etc/nginx/nginx.conf\r"
expect "]#"
send "sed -i 's#proxy_pass.*#proxy_pass http://jsp-pools;#' /etc/nginx/conf.d/www.jsp.com.conf\r"
expect "]#"
send "systemctl restart nginx\r"
send "exit\r"
expect eof
EOF



