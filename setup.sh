#!/usr/bin/env bash

sudo dnf -y update
sudo dnf -y tar wget

# selinux無効
grubby --update-kernel ALL --args selinux=0

# ファイヤーウォール
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --zone=public --add-port=8081/tcp --permanent
sudo firewall-cmd --reload

# Javaインストール
sudo rpm --import https://packages.adoptium.net/artifactory/api/gpg/key/public
sudo tee /etc/yum.repos.d/adoptium.repo <<EOF
[adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/rhel/\$releasever/\$basearch/
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF
sudo dnf update -y
sudo dnf install -y temurin-17-jdk

# nexus リポジトリダウンロード
cd /opt/
sudo wget https://download.sonatype.com/nexus/3/nexus-unix-x86-64-3.78.0-14.tar.gz
sudo tar xzvf nexus-unix-x86-64-3.78.0-14.tar.gz

# ユーザー作成
sudo useradd nexus

# ユーザーが作成されたか確認
grep nexus /etc/passwd
cd /opt/
sudo chown -R nexus:nexus /opt/nexus-*
sudo chmod -R go-rw /opt/nexus-*
sudo chown -R nexus:nexus /opt/sonatype-work
sudo chmod -R go-rw /opt/sonatype-work

sudo ln -s /opt/nexus-3.78.0-14 /opt/nexus

# サービス化
sudo tee /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
User=nexus
Group=nexus
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
Restart=on-abort
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

sudo firewall-cmd --reload

# インストール後、ブラウザからコンソール画面にadminでログインした後に、
# 設定で、enable Anonymous accessを選択しないと、リポジトリに接続できない！！