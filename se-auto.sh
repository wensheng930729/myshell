#! /bin/bash
#
#
for i in `seq 10 19`
do
	a=root
	b=172.25.15.$i
	c=uplooking
	/usr/bin/expect /root/project/auto.exp $a $b $c
done
