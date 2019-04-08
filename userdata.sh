#!/bin/bash
yum install httpd24.x86_64 -y
chkconfig httpd on
service httpd start
