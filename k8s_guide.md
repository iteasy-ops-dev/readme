# k8s guide
1. 환경 설정: 각 노드에 SSH로 접속하여 호스트네임 설정
```sh
#################################### ALL
ssh {account}@{ip}
hostnamectl set-hostname NODE_NAME # 서로 달라야함
```
2. 설치
```sh
#################################### ALL
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable kubelet
sudo systemctl start kubelet
```
3. Swap 비활성화: 모든 노드에서 Swap을 비활성화합니다.
```sh
#################################### ALL
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
```
4. 포트포워딩 활성화
```sh
#################################### ALL
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
```
5. Docker 설정
```sh
cat > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
systemctl restart docker
```
6. 마스터 노드 설정: 클러스터를 초기화하고 kubeconfig를 설정합니다.
```sh
#################################### MASTER
# kubeadm init 에서 에러 발생시
rm -f /etc/containerd/config.toml
systemctl restart containerd

kubeadm init --pod-network-cidr=192.168.0.0/16 # Calico에 맞는 네트워크 CIDR

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
7. 네트워크 플러그인 설치
```sh
#################################### MASTER
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
8. 워커 노드 설정: 워커 노드를 클러스터에 조인합니다.
```sh
#################################### WORKER
rm -f /etc/containerd/config.toml
systemctl restart containerd

# 마스터 노드에서 제공하는 조인 명령어 사용
kubeadm join {master-ip}:6443 --token {token} --discovery-token-ca-cert-hash sha256:{hash}
```
9. 클러스터 상태 확인: 모든 노드가 클러스터에 성공적으로 조인되었는지 확인합니다.
```sh
#################################### MASTER
kubectl get nodes
```
10. 설정 리셋
```sh
kubeadm reset
rm -rf /etc/kubernetes
rm -rf /var/lib/etcd
rm -rf $HOME/.kube

systemctl stop kubelet
systemctl stop docker
```
