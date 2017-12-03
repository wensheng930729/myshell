#! /bin/bash
#
#一台服务器一键安装LNMP
setenforce 0
iptables -F
iptables-save
read -p "输入虚拟主机域名后缀(如：bbs.com)：" hname
read -p "输入本机IP地址：" hipa
rpm -ivh ftp://172.25.254.250/notes/project/UP200/UP200_nginx-master/pkg/nginx-1.8.0-1.el7.ngx.x86_64.rpm

cat > /etc/nginx/nginx.conf << EOF
user  nginx;
worker_processes  2;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}



http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    tcp_nopush      on;
    keepalive_timeout  65;
    gzip  on;
    include /etc/nginx/conf.d/*.conf; 
}
EOF


cat > /etc/nginx/conf.d/www.$hname\.conf << EOF 
server {
    listen       80;
    server_name  www.$hname;
    root /usr/share/nginx/$hname;
       index index.php index.html index.htm;
       location ~ \.php$ {
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME /usr/share/nginx/$hname\$fastcgi_script_name;
            include fastcgi_params;
     }
}
EOF

mkdir -p /usr/share/nginx/$hname
echo OK > /usr/share/nginx/$hname\/index.html
if nginx -t &>/dev/null
then
    echo "nginx 配置正确！"
    systemctl start nginx
    systemctl enable nginx
else
    echo "error,exiting....."
fi

echo "$hipa www.$hname" >> /etc/hosts
yum install -y elinks 
elinks -dump http://www.$hname >/dev/null
if [ $? -eq 0 ]
then
    echo "测试成功,已创建www.$hname"
else
    echo "测试失败"
    exit 1
fi
yum install -y lftp
lftp 172.25.254.250 <<EOF
cd /notes/project/UP200/UP200_nginx-master/pkg
get spawn-fcgi-1.6.3-5.el7.x86_64.rpm
EOF
rpm -ivh spawn-fcgi-1.6.3-5.el7.x86_64.rpm
yum -y install php php-mysql

echo 'OPTIONS="-u nginx -g nginx -p 9000 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"' >> /etc/sysconfig/spawn-fcgi

/etc/init.d/spawn-fcgi start
if [ $? -eq 0 ]
then 
    chkconfig spawn-fcgi on
else
    echo "PHP服务启动失败，退出！"
    exit 2
fi

lftp 172.25.254.250 <<EOF
cd /notes/project/software/lnmp_soft
get Discuz_X3.2_SC_UTF8.zip
EOF

unzip Discuz_X3.2_SC_UTF8.zip &>/dev/null
mv upload/* /usr/share/nginx/$hname/
cd /usr/share/nginx/$hname
chown nginx.nginx -R data/ config/ uc_client/ uc_server/
echo "PHP已经部署完毕！"


yum install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb

mysql -e "delete from mysql.user where user='';"
mysql -e "update mysql.user set password=password('redhat') where user='root';"
mysql -e "flush privileges;"
mysql -uroot -predhat -e "drop database test;"
mysql -uroot -predhat -e "create database bbs default charset utf8;"
mysql -uroot -predhat -e "grant all on bbs.* to runbbs@'localhost' identified by '123456';"
mysql -uroot -predhat -e "flush privileges;"

echo "数据库初始化成功！"
