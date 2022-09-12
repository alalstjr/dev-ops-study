#!/usr/bin/env bash

# init kubernetes 
kubeadm init --token 123456.1234567890123456 --token-ttl 0 \
--pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.1.10

# config for master node only 
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# 워크 노드에 추가 후 [kubectl get nodes] 명령어를 실행하면
# STATUS 가 모두 준비되어 있지 않음을 확인할 수 있습니다.
# 이는 [podnetwork] 를 준비하지 않아서 그렇다.
# 아래 명령어로 네트워크를 설치합니다.
# raw_address for gitcontent
raw_git="raw.githubusercontent.com/sysnet4admin/IaC/master/manifests"
# config for kubernetes's network 
kubectl apply -f https://$raw_git/172.16_net_calico_v1.yaml

# 리눅스에서 bash 자동 완성 사용하기
# install bash-completion for kubectl 
yum install bash-completion -y 

# kubectl completion on bash-completion dir
kubectl completion bash >/etc/bash_completion.d/kubectl

# alias kubectl to k 
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# git clone k8s-code
git clone https://github.com/sysnet4admin/_Lecture_k8s_starter.kit.git
mv /home/vagrant/_Lecture_k8s_starter.kit $HOME
find $HOME/_Lecture_k8s_starter.kit -regex ".*\.\(sh\)" -exec chmod 700 {} \;

# make rerepo-k8s-starter.kit and put permission
cat <<EOF > /usr/local/bin/rerepo-k8s-starter.kit
#!/usr/bin/env bash
rm -rf $HOME/_Lecture_k8s_starter.kit 
git clone https://github.com/sysnet4admin/_Lecture_k8s_starter.kit.git $HOME/_Lecture_k8s_starter.kit
find $HOME/_Lecture_k8s_starter.kit -regex ".*\.\(sh\)" -exec chmod 700 {} \;
EOF
chmod 700 /usr/local/bin/rerepo-k8s-starter.kit
