#! /bin/bash
#
#Tomcat的数据迁移

mysqldump --databases jsp -uroot -predhat > /tmp/jsp.sql
##使用密钥对或者expect
/usr/bin/expect <<EOF
spawn scp /tmp/jsp.sql 172.25.15.18:/root/
expect {
	"yes/no" { send "yes\r";exp_continue }
	"*password:" { send "uplooking\r" }
}
expect eof
EOF

/usr/bin/expect <<EOF
spawn ssh root@172.25.15.18
expect "*password:"
send "uplooking\r"
expect "]#"
send "mysql -uroot -predhat < /root/jsp.sql\r"
expect "]#"
send "mysql -uroot -predhat -e "grant all on jsp.* to runjsp@'172.25.15.%' identified by '123456';"\r"
expect "]#"
send "mysql -uroot -predhat -e "flush privileges;"\r"
send "exit\r"
expect eof
EOF
systemctl stop mariadb

sed -i 's/localhost:3306/172.25.254.18:3306/' /home/tomcat/apache-tomcat-8.0.24/jsp.com/ROOT/WEB-INF/conf/config.xml
service tomcat stop
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

#tar -czf /tmp/tomcat.tgz /home/tomcat/apache-tomcat-8.0.24/ /etc/init.d/tomcat
#scp /tmp/tomcat.tgz $rmtip1:/root/

