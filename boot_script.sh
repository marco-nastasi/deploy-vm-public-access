#!/bin/bash
yum update -y
yum -y install git
yum -y install docker
systemctl start docker
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
cd /home/ec2-user/
git clone https://github.com/marco-nastasi/example-voting-app-monitored
