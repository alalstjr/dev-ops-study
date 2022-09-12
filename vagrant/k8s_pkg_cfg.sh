#!/usr/bin/env bash

# $1 $2 $3 같은 것은 전달받은 매개변수를 표현한것
# Vagrantfile 에서 전달받은 매개변수 지금 전달받은 값은
# args: [ k8s_V, docker_V, ctrd_V ] 와 같다.

# epel-release 이란?
# EPEL 은 Extra Packages of Enterprise Linux 의 준말
# 리눅스의 추가 패키지 yum 이외 추가적으로 설치하도록 도와주는 시스템
# install util packages
yum install epel-release -y
yum install vim-enhanced -y
yum install git -y

# install docker 
yum install docker-ce-$2 docker-ce-cli-$2 containerd.io-$3 -y

# install kubernetes
# both kubelet and kubectl will install by dependency
# but aim to latest version. so fixed version by manually
yum install kubelet-$1 kubectl-$1 kubeadm-$1 -y 

# docker 서비스 시작 및 활성화 방법입니다.
# Ready to install for k8s 
systemctl enable --now docker
systemctl enable --now kubelet
