#!/bin/bash
echo "[TASK 1] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "[TASK 2] Stop and Disable firewall"
systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 3] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "[TASK 4] Add Kernel settings"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null 2>&1

echo "[TASK 5] Install containerd runtime"
apt update -qq >/dev/null 2>&1
apt install -qq -y containerd apt-transport-https >/dev/null 2>&1
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd >/dev/null 2>&1

echo "[TASK 6] Add apt repo for kubernetes"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - >/dev/null 2>&1
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/dev/null 2>&1

echo "[TASK 7] Install Kubernetes components (kubeadm, kubelet and kubectl)"
apt install -qq -y kubeadm=1.21.0-00 kubelet=1.21.0-00 kubectl=1.21.0-00 >/dev/null 2>&1

echo "[TASK 8] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

echo "[TASK 9] Set root password"
echo root:kubeadmin | sudo chpasswd
echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[TASK 10] Pull required containers"
kubeadm config images pull >/dev/null 2>&1

echo "[TASK 11] Initialize Kubernetes Cluster"
kubeadm init --apiserver-advertise-address=$(hostname -I) --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null

echo "[TASK 12] Deploy Calico network"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml >/dev/null 2>&1

echo "[TASK 13] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null