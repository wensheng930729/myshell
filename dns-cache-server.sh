#! /bin/bash
#
#DNS缓存服务器
yum install -y bind
read -p "输入服务器IP地址：" ipb
cat > /etc/named.conf <<EOF
options {
        listen-on port 53 { 127.0.0.1; $ipb; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        allow-query     { localhost; any; };
        recursion yes;
        forwarders { 8.8.8.8; };
        forward only;
        dnssec-enable no;
        dnssec-validation no;
        dnssec-lookaside auto;
        bindkeys-file "/etc/named.iscdlv.key";
        managed-keys-directory "/var/named/dynamic";
        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};
EOF

service named start
if [ $? -eq 0 ]
then
	echo "DNS服务启动成功"
else
	echo "DNS error.exit....."
	exit 1
fi

chkconfig named on
echo "nameserver $ipb" > /etc/resolv.conf
