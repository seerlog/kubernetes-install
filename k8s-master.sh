echo ‘======== [CentOS 8] Kubernetes Master Insall Start ========’ 

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
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address 10.178.0.2

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://calico-v3-25.netlify.app/archive/v3.25/manifests/calico.yaml

echo '======== [COMPLETE] ========'

# kubeadm token list
# openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //’
# kubeadm token list 에서 토큰 안보이면 kubeadm token create 로 토큰생성
