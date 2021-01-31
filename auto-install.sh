#!/bin/bash
#By:Platowg 
#Date:2021.01.31


echo "改主机名"
hostname
hostname k8s-master
hostnamectl set-hostname k8s-master


echo "改hosts文件"
ip=$(ifconfig ens33 | grep "inet " | sed 's/^.*inet //g' | sed 's/ netmask.*//g')
hostname=$(hostname)
echo "${ip} ${hostname}" >> /etc/hosts


echo "将桥接的IPV4流量传递到iptables 的链"
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system


echo "关防火墙"
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
swapoff -a
 free
sed -ri 's/.*swap.*/#&/' /etc/fstab


echo"装Git、wget"
yum -y install git
yum -y install wget


echo "拉yaml"
git clone https://github.com/dongfna/K8S-Prometheus-Grafana.git
sed -i "s/server: 192.168.3.80/server: ${ip}/g"  ./K8S-Prometheus-Grafana/grafana/grafana-volume.yaml


echo "装docker"
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O/etc/yum.repos.d/docker-ce.repo
yum -y install docker-ce-19.03.5 docker-ce-cli-19.03.5 containerd.io
systemctl enable docker
systemctl start docker
sleep 10


echo "配置yum源"
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[k8s]
name=k8s
enabled=1
gpgcheck=0
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
EOF


echo "装 kubeadm，kubelet、kubectl"
yum install kubelet kubeadm kubectl -y
systemctl enable kubelet
sed -i 's/}/,"exec-opts":["native.cgroupdriver=systemd"]}/g' /etc/docker/daemon.json
systemctl restart docker
sleep 15
systemctl status docker
kubeadmV=$(kubeadm version | grep 'GitVersion:"' |sed 's/^.*GitVersion:"//g' | sed 's/", GitCommit.*//g')
echo "装 kubeadm，kubelet、kubectl"
kubeadm init --apiserver-advertise-address=${ip} --image-repository registry.aliyuncs.com/google_containers --kubernetes-version ${kubeadmV} --service-cidr=10.1.0.0/16 --pod-network-cidr=10.244.0.0/16
systemctl enable kubelet
echo “export KUBECONFIG=/etc/kubernetes/admin.conf” >> ~/.bash_profile
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f ./K8S-Prometheus-Grafana/kube-flannel.yml
kubectl get pod --all-namespaces -o wide
kubectl get nodes
sed -i /port=0/s#^#//#g /etc/kubernetes/manifests/kube-controller-manager.yaml
sed -i /port=0/s#^#//#g /etc/kubernetes/manifests/kube-scheduler.yaml
kubectl taint nodes --all node-role.kubernetes.io/master-


echo "装nfs"
yum install -y nfs-utils rpcbind
mkdir /nfsdata
chmod 777 /nfsdata/
systemctl start nfs && systemctl enable nfs
echo "/nfsdata *(rw,no_root_squash,no_all_squash,sync)" >> /etc/exports


echo "配置镜像pull加速"
curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://f1361db2.m.daocloud.io


echo "部署Kubernetes-Dashboard"
kubectl create -f ./K8S-Prometheus-Grafana/kubernetes-dashboard/kubernetes-dashboard.yaml


echo "部署kube-state-metrics"
kubectl create -f ./K8S-Prometheus-Grafana/kube-state-metrics/cluster-role-binding.yaml
kubectl create -f ./K8S-Prometheus-Grafana/kube-state-metrics/cluster-role.yaml
kubectl create -f ./K8S-Prometheus-Grafana/kube-state-metrics/service-account.yaml
kubectl create -f ./K8S-Prometheus-Grafana/kube-state-metrics/service.yaml
kubectl create -f ./K8S-Prometheus-Grafana/kube-state-metrics/deployment.yaml


echo "部署prometheus"
kubectl create -f ./K8S-Prometheus-Grafana/prometheus/rbac-setup.yaml
kubectl create -f ./K8S-Prometheus-Grafana/prometheus/prometheus.svc.yml
kubectl create -f ./K8S-Prometheus-Grafana/prometheus/configmap.yaml
kubectl create -f ./K8S-Prometheus-Grafana/prometheus/prometheus.deploy.yml


echo "部署grafana"
kubectl create -f ./K8S-Prometheus-Grafana/grafana/grafana-volume.yaml
kubectl create -f ./K8S-Prometheus-Grafana/grafana/grafana-chown-job.yaml
kubectl create -f ./K8S-Prometheus-Grafana/grafana/grafana-svc.yaml
kubectl create -f ./K8S-Prometheus-Grafana/grafana/grafana-ing.yaml
kubectl create -f ./K8S-Prometheus-Grafana/grafana/grafana-deploy.yaml







