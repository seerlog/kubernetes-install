echo ‘======== [CentOS 8] Kubernetes Worker Insall Start ========’ 

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

echo '======== [9] kubeadm 으로 클러스터 Join ========'
sudo sed -i 's/disabled/# disabled/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# ip, token, hash 수정 필요
sudo kubeadm join 10.178.0.2:6443 --token 3xpw3n.ydw0g2bunj86qvht --discovery-token-ca-cert-hash sha256:19ef1195dd4d149c5fdb01a782afb99ea930b59f0f5b0cf7b0674f3c72e78299

echo '======== [COMPLETE] ========'
