#! /bin/bash

yum install -y expect
cat > /home/tomcat/apache-tomcat-8.0.24/jsp.com/ROOT/test.jsp <<EOF
<html>
        <body bgcolor="red">
                <center>
                <%out.print(request.getSession().getId()) ;%>
                <h1>Tomcat1</h1>
        </body>
</html>
EOF

lftp 172.25.254.250 <<EOF
cd /notes/project/software/tomcat_soft
mirror msm/
EOF
cp msm/*.jar /home/tomcat/apache-tomcat-8.0.24/lib/
cd /home/tomcat/apache-tomcat-8.0.24/lib/
chmod a-x *.jar

/usr/bin/expect <<EOF
spawn scp msm/*.jar 172.25.15.15:/home/tomcat/apache-tomcat-8.0.24/lib/
expect {
	"yes/no" { send "yes\r";exp_continue }
	"*password:" { send "uplooking\r" }
}
expect eof
EOF

/usr/bin/expect <<EOF
spawn ssh root@172.25.15.15
expect "*password:"
send "uplooking\r"
expect "]#"
send "chmod a-x /home/tomcat/apache-tomcat-8.0.24/lib/*.jar\r"
send "exit\r"
expect eof
EOF



sed -i s/appBase.*\"$/appBase=\"webapps\"/ /home/tomcat/apache-tomcat-8.0.24/conf/server.xml
sed -i '/pattern=.*$/a\\<Context path="" docBase="/home/tomcat/apache-tomcat-8.0.24/jsp.com/ROOT" /\>' /home/tomcat/apache-tomcat-8.0.24/conf/server.xml

read -p "输入memcache服务器的ip：" sc
cat > /home/tomcat/apache-tomcat-8.0.24/conf/context.xml << EOF
<?xml version='1.0' encoding='utf-8'?>
<Context>
    <WatchedResource>WEB-INF/web.xml</WatchedResource>
    <WatchedResource>\${catalina.base}/conf/web.xml</WatchedResource>
  <Manager className="de.javakaffee.web.msm.MemcachedBackupSessionManager"
  memcachedNodes="n1:$sc:11211"
  lockingMode="auto"
  sticky="false"
  requestUriIgnorePattern= ".*\.(png|gif|jpg|css|js)$"
  sessionBackupAsync= "false"
  sessionBackupTimeout= "100"
  copyCollectionsForSerialization="true"
  transcoderFactoryClass="de.javakaffee.web.msm.serializer.kryo.KryoTranscoderFactory" />
</Context>
EOF

chown tomcat. -R /home/tomcat/
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

/usr/bin/expect <<EOF
spawn scp /home/tomcat/apache-tomcat-8.0.24/conf/server.xml 172.25.15.15:/home/tomcat/apache-tomcat-8.0.24/conf/
expect "*password:"
send "uplooking\r"
expect eof
EOF

/usr/bin/expect <<EOF
spawn scp /home/tomcat/apache-tomcat-8.0.24/conf/context.xml 172.25.15.15:/home/tomcat/apache-tomcat-8.0.24/conf/
expect "*password:"
send "uplooking\r"
expect eof
EOF


/usr/bin/expect <<EOF
spawn ssh root@172.25.15.16
expect {
        "yes/no" { send "yes\r";exp_continue }
        "*password:" { send "uplooking\r" }
}
expect "]#"
send "setenforce 0\r"
expect "]#"
send "yum install -y memcached\r"
expect "]#"
send "systemctl start memcached\r"
send "exit\r"
expect eof
EOF

/usr/bin/expect <<EOF
spawn ssh root@172.25.15.15
expect "*password:"
send "uplooking\r"
expect "]#"
send "chown tomcat. -R /home/tomcat/\r"
expect "]#"
send "service tomcat stop;service tomcat start"
expect "]#"
send "exit\r"
expect eof
EOF
