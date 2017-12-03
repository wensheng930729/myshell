#! /bin/bash
#
#这个脚本，实现了从serverb上迁移出mysql数据库到serveri上，同时修改了serverb上php
#的dbhost指向，并授权了15.0/24网段对本服务器即serveri的访问。
setenforce 0
iptables -F
yum install -y expect
yum install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb

mysql -e "delete from mysql.user where user='';"
mysql -e "update mysql.user set password=password('redhat') where user='root';"
mysql -e "flush privileges;"
mysql -uroot -predhat -e "drop database test;"
echo "数据库初始化成功！"

/usr/bin/expect <<EOF
spawn ssh root@172.25.15.11
expect {
	"yes/no" { send "yes\r";exp_continue }
	"*password:" { send "uplooking\r" } 
}
expect "]#"
send "mysqldump --all-databases -uroot -predhat > /tmp/mariadb-all.sql\r"
send "exit\r"
expect eof
EOF

#/usr/bin/expect <<EOF
#spawn ssh root@172.25.15.11
#expect "*password:" 
#send "uplooking\r"
#expect "]#"
#send "mysqldump --all-databases -uroot -predhat > /tmp/mariadb-all.sql\r"
#send "exit\r"
#expect eof
#EOF


/usr/bin/expect <<EOF
spawn scp 172.25.15.11:/tmp/mariadb-all.sql /tmp/
expect "*password:"
send "uplooking\r"
expect eof
EOF

mysql -uroot -predhat < /tmp/mariadb-all.sql
systemctl restart mariadb
mysql -uroot -predhat -e "show databases;"
echo "grant all on bbs.* to runbbs@'172.25.15.%' identified by '123456';" |mysql -uroot -predhat
mysql -uroot -predhat -e "flush privileges;"
if [ $? -eq 0 ]
then
    echo "mariadb迁移完成!"
else
    echo "error!"
    exit 1
fi

/usr/bin/expect <<EOF
spawn ssh root@172.25.15.11
expect "*password:"
send "uplooking\r"
expect "]#"
send "sed -i s/localhost/172.25.15.18/ /usr/share/nginx/bbs.com/config/config_global.php\r"
expect "]#"
send "sed -i s/localhost/172.25.15.18/ /usr/share/nginx/bbs.com/config/config_ucenter.php\r"
expect "]#"
send "sed -i s/localhost/172.25.15.18/ /usr/share/nginx/bbs.com/uc_server/data/config.inc.php\r"
expect eof
EOF

