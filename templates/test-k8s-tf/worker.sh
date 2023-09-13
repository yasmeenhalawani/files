#! /bin/bash
apt-get update -y
apt-get upgrade -y
hostnamectl set-hostname kube-worker-1
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
apt update
apt install -y containerd.io
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt update
apt install -y kubelet kubeadm kubectl
systemctl start kubelet
systemctl enable kubelet
wget https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
python3 -m pip install ec2instanceconnectcli
pip install --upgrade pyOpenSSL
until [[ $(mssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ${AWS::Region} ubuntu@${KubeMaster1} kubectl get no | awk 'NR == 2 {print $2}') == Ready ]]; do echo "master node is not ready"; sleep 3; done;
kubeadm join ${KubeMaster1.PrivateIp}:6443 --token $(mssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ${AWS::Region} ubuntu@${KubeMaster1} kubeadm token list | awk 'NR == 2 {print $1}') --discovery-token-ca-cert-hash sha256:$(mssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ${AWS::Region} ubuntu@${KubeMaster1} openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //') --ignore-preflight-errors=All
