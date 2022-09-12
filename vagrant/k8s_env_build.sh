#!/usr/bin/env bash

# vim configuration 
echo 'alias vi=vim' >> /etc/profile

# 설치 완료 후 스왑의 비활성화가 필요합니다.
# swapoff -a to disable swapping
swapoff -a
# sed to comment the swap partition in /etc/fstab
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

# kubernetes repo
gg_pkg="packages.cloud.google.com/yum/doc" # Due to shorten addr for key
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://${gg_pkg}/yum-key.gpg https://${gg_pkg}/rpm-package-key.gpg
EOF

# add docker-ce repo
# docker-ce 란?
# EE는 연간 혹은 노드 단위의 과금 체계를 가지고 있으며 CE는 비용없이 사용이 가능합니다.
# CE는 개발자나 소규모의 팀에 적합한 에디션으로 Docker CE를 우분투 서버에 설치하는 방법입니다.
yum install yum-utils -y 
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# SELinux(Security-Enhanced Linux)는 관리자가 시스템 액세스 권한을 효과적으로 제어할 수 있게 하는
# Linux® 시스템용 보안 아키텍처입니다. 이는 원래 미국 국가안보국(United States National Security Agency, NSA)이
# LSM(Linux Security Module)을 사용하여 Linux 커널에 대한 일련의 패치로 개발한 것입니다.
# Selinux 비활성화
# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# CentOS 같은 리눅스 배포판은 net.bridge.bridge-no-call-iptables 값이 디폴트 0 (zero)다
# 이는 bridge 네트워크를 통해 송수신되는 패킷이 iptables 설정을 우회한다는 의미다
# 컨테이너의 네트워크 패킷이 호스트머신의 iptables 설정에 따라 제어되도록 하는 것이 바람직하며 이를 위해서는 이 값을 1로 설정해야 한다
# RHEL/CentOS 7 have reported traffic issues being routed incorrectly due to iptables bypassed
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
# 쿠버네티스 설치 시 br_netfilter 모듈이 필요 (network 관련 linux kernel 모듈)
# 이 커널 모듈을 사용하면 브릿지를 통과하는 패킷이 필터링 및 포트 전달을 위해 iptables에 의해 처리되고 클러스터의 쿠버네티스 Pod는 서로 통신 가능.
modprobe br_netfilter

# hosts 파일은 도메인의 IP를 찾을 때 컴퓨터가 맨 처음 조사하는 파일이다(그러니깐 DNS 파일인 것이다).
# local small dns & vagrant cannot parse and delivery shell code.
echo "192.168.1.10 m-k8s" >> /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.1.10$i w$i-k8s" >> /etc/hosts; done

# 네임 서버(DNS 서버)를 설정하는 파일
# DNS(Domain Name Server)는 도메인 주소를 IP주소로 변경해주는 서버입니다.
# 쉽게 말해 우리가 철수(도메인)네 집을 찾아가기 위해서 주소(IP주소)를 보고 찾아 가는것 처럼 DNS는 철수네 집 주소를 알려주는 역활을 합니다.
# 일반적으로 가정집에서 쓰는 인터넷은 통신사(ISP)에서 제공하는 DNS 서버를 이용합니다.
# 대부분의 국내 웹페이지, 게임 ,서비스 등을 이용할 때는 빠르게 동작하지만
# 해외에 서버를 둔 웹페이지, 넷플릭스, 애플 아이클라우드 등 다양한 서비스들은
# 1.1.1.1(Cloudflare), 8.8.8.8(Google)과 같은 대형 DNS 서비스 업체들의 DNS를 쓸 경우 더 빠르게 동작하는 경우가 많습니다.
# 이밖에도 DNS에는 다양한 보안과 관련된 서비스들을 제공하기 때문에 본인에게 맞는 DNS를 사용하면 됩니다.
# 1.1.1.1(Cloudflare)
# 8.8.8.8(Google)
# 시스템 DNS(OS에 설정된 기본 DNS, 일반적으로 통신사 DNS로 설정되어 있음)
# config DNS  
cat <<EOF > /etc/resolv.conf
nameserver 1.1.1.1 #cloudflare DNS
nameserver 8.8.8.8 #Google DNS
EOF

# DNS(Domain Name System)이란?
# 네트워크 상에 존재하는 모든 PC는 IP 주소가 있다.
# 그러나 모든 IP 주소가 도메인 이름을 가지는 것은 아니다.
# 로컬 PC를 나타내는 127.0.0.1 은 localhost 로 사용할 수 있지만, 그 외의 모든 도메인 이름은 일정 기간 동안 대여하여 사용한다.
# 👉 도메인 이름과 IP 주소는 어떻게 매칭하는 걸까?
# 브라우저의 검색창에 도메인 이름을 입력하여 해당 사이트로 이동하기 위해서는, 해당 도메인 이름과 매칭된 IP 주소를 확인하는 작업이 반드시 필요하다.
# 네트워크에는 이것을 위한 서버가 별도로 있다.
# 이 서버가 바로 DNS 서버이다.
# 👉 DNS 하는 일
# DNS는 Domain Name System의 줄임말로, 데이터베이스 시스템이다.
# 호스트의 도메인 이름을 IP 주소로 변환하거나 반대의 경우를 수행할 수 있도록 개발된 데이터베이스 시스템이다.
# DNS(Domain Name System)는 범국제적 단위로 웹사이트의 IP 주소와 도메인 주소를 이어주는 환경/시스템이다.
# DNS 시스템 안에서 이어주는 역할을 하는 서버를 풀네임으로 DNS 서버라고 한다.
# 👉 DNS 처리 순서
# 브라우저의 검색창에 naver.com을 입력한다.
# 이 요청은 DNS에서 IP 주소(125.209.222.142)를 찾는다.
# 그리고 이 IP 주소에 해당하는 웹 서버로 요청을 전달하여 클라이언트와 서버가 통신할 수 있도록 한다.
# 👉 네임서버란 무엇일까?
# 네임서버 = DNS 서버 같은 말이다…