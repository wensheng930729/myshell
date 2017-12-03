#! /bin/bash
#
#

function tomcheck(){

pnum1=`netstat -lntp |grep :8009|awk -F: '{ print $4 }'`
pnum2=`netstat -lntp |grep :8080|awk -F: '{ print $4 }'`
if [ "$pnum1"=8009 ] && [ "$pnum2"=8080 ]
then
	echo "Tomcat启动成功！"
else
	echo "Tomcat启动失败，已退出"
	exit 1
fi

}


setenforce 0
iptables -F
iptables-save
yum install -y lftp
yum install -y expect

cd ~
lftp 172.25.254.250 <<EOF
cd /notes/project/UP200/UP200_tomcat-master
mirror pkg/
EOF

mkdir /usr/local/tomcat
cd pkg
tar xf jdk-7u15-linux-x64.tar.gz  -C  /usr/local/tomcat
tar xf apache-tomcat-8.0.24.tar.gz -C /usr/local/tomcat/

yum -y install gcc
cd /usr/local/tomcat/apache-tomcat-8.0.24/bin/
tar xf commons-daemon-native.tar.gz
cd commons-daemon-1.0.15-native-src/unix/
./configure  --with-java=/usr/local/tomcat/jdk1.7.0_15/ &> /dev/null
if [ $? -eq 0 ]
then
	make &> /dev/null
else
	echo "编译出错"
	exit 2
fi

cp -a jsvc  /usr/local/tomcat/apache-tomcat-8.0.24/bin/
cd /usr/local/tomcat/apache-tomcat-8.0.24/bin/
cp daemon.sh /etc/init.d/tomcat

sed -i '/^\#\!\/bin\/sh/a\# chkconfig: 2345 85 15\nCATALINA_HOME=/home/tomcat/apache-tomcat-8.0.24\nCATALINA_BASE=/home/tomcat/apache-tomcat-8.0.24\nJAVA_HOME=/usr/local/tomcat/jdk1.7.0_15' /etc/init.d/tomcat

chkconfig --add tomcat
chkconfig tomcat on

groupadd -g 888 tomcat &>/dev/null
useradd -u 888 -g 888 -s /sbin/nologin tomcat &>/dev/null

cd /usr/local/tomcat
tar -czf - apache-tomcat-8.0.24/ | tar -xzf - -C /home/tomcat/

cd  /home/tomcat
chown tomcat. -R apache-tomcat-8.0.24/

service tomcat start
tomcheck

##
##Tomcat配置虚拟主机
read -p "输入你要设置的虚拟主机域名：xxx.xxx :" sname
sed -i 's/<Host name=\".*\"$/<Host name="www.'$sname'" appBase="'$sname'"/g' /home/tomcat/apache-tomcat-8.0.24/conf/server.xml
service tomcat stop
service tomcat start
tomcheck

mkdir /home/tomcat/apache-tomcat-8.0.24/$sname/ROOT -p
echo hello > /home/tomcat/apache-tomcat-8.0.24/$sname/ROOT/index.jsp


wget ftp://172.25.254.250:/notes/project/software/tomcat_soft/ejforum-2.3.zip
unzip ejforum-2.3.zip  -d /tmp/
mv /tmp/ejforum-2.3/ejforum/* /home/tomcat/apache-tomcat-8.0.24/$sname/ROOT/

##
##配置和数据库的连接
cd ~/pkg
tar -xf mysql-connector-java-5.1.36.tar.gz
cp mysql-connector-java-5.1.36/mysql-connector-java-5.1.36-bin.jar /home/tomcat/apache-tomcat-8.0.24/lib/
read -p "输入数据库的用户名：" sqlname
read -p "输入密码：" sqlpasswd
cat > /home/tomcat/apache-tomcat-8.0.24/$sname/ROOT/WEB-INF/conf/config.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<config>
        <database maxActive="10" maxIdle="10" minIdle="2" maxWait="10000" 
                          username="$sqlname" password="$sqlpasswd" 
                          driverClassName="com.mysql.jdbc.Driver" 
                          url="jdbc:mysql://localhost:3306/jsp?characterEncoding=gbk&amp;autoReconnect=true&amp;autoReconnectForPools=true&amp;zeroDateTimeBehavior=convertToNull"
                          sqlAdapter="sql.MysqlAdapter"/>
        <system adminUser="admin"/>

        <misc>
                <maxMemberPages>20</maxMemberPages>
                <maxSessionPosts>10</maxSessionPosts>
                <maxFavorites>50</maxFavorites>
                <maxShortMsgs>50</maxShortMsgs>
                <maxAvatarPixels>150</maxAvatarPixels>
        </misc>

</config>

EOF
 
yum -y install mariadb-server
service mariadb start
mysql -e "delete from mysql.user where user='';"
mysql -e "update mysql.user set password=password('redhat') where user='root';"
mysql -e "flush privileges;"
mysql -uroot -predhat -e "drop database test;"
mysql -uroot -predhat -e "create database jsp default charset utf8;"
mysql -uroot -predhat -e "grant all on jsp.* to runjsp@'localhost' identified by '123456';"
mysql -uroot -predhat -e "flush privileges;"


echo "数据库初始化完成！开始导入表。。。"

mysql -urunjsp -p123456 jsp < /tmp/ejforum-2.3/install/script/easyjforum_mysql.sql
chown tomcat. -R /home/tomcat/apache-tomcat-8.0.24/
service tomcat stop
service tomcat start
tomcheck


