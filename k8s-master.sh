echo ‘======== [CentOS 8] Kubernetes Master Insall Start ========’ 

echo '======== [0] 설정 변수 초기화 ========'
server_ip=$(hostname -I)
pod_network=10.244.0.0/16

echo '======== [1] 패키지 업데이트 ========'
sudo yum -y update

echo '======== [2] 타임존 설정 ========'
sudo timedatectl set-timezone Asia/Seoul

echo '======== [3] 도커 레포지토리 추가 ========'
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

echo '======== [4] 도커 설치 ========'
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo '======== [5] 도커 시작 ========'
sudo systemctl start docker
sudo systemctl enable docker

echo '======== [6] 쿠버네티스 레포지토리 추가 ========'
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

echo '======== [7] SELinux OFF ========'
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

echo '======== [8] 쿠버네티스 패키지 설치 ========'
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

echo '======== [9] kubeadm 으로 클러스터 생성 ========'
sudo sed -i 's/disabled/# disabled/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# apiserver-advertise-address 를 서버 ip로 설정 필요
sudo kubeadm init --pod-network-cidr=$pod_network --apiserver-advertise-address $server_ip

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo '======== [10] calico 설치 ========'
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/tigera-operator.yaml

curl https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/custom-resources.yaml -O
sudo sed -i "s|cidr: *.*.*.*/*|cidr: $pod_network|g" ~/custom-resources.yaml
kubectl create -f custom-resources.yaml

echo '======== [COMPLETE] ========'
