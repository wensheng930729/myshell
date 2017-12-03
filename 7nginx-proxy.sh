#! /bin/bash
#
#快速搭建Nginx反向代理虚拟主机

read -p "输入要代理的服务器IP地址：" ipa
read -p "输入虚拟主机的域名：" yname
iptables -F
iptablse-save
setenforce 0
yum install -y expect
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

cat > /etc/nginx/conf.d/www.$yname\.conf << EOF
server {
    listen       80;
    server_name  www.$yname;
       location / {
		proxy_pass http://$ipa:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_redirect off;
     }
}
EOF

if nginx -t &>/dev/null
then
    echo "nginx 配置正确！启动服务"
	systemctl start nginx
else
    echo "error,exiting....."
	exit 1
fi
