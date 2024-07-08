# KVM Cheat Sheet

## Selinux 비활성화
- HostOS + GuestOS 둘 다 해주어야 함.
- ip 설정 시 문제가 될 수 있음.
------
`vim /etc/selinux/config`
```sh
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#       enforcing - SELinux security policy is enforced.
#       permissive - SELinux prints warnings instead of enforcing.
#       disabled - No SELinux policy is loaded.
SELINUX=disabled # 변경
# SELINUXTYPE= can take one of these two values:
#       targeted - Targeted processes are protected,
#       mls - Multi Level Security protection.
SELINUXTYPE=targeted
```
`source /etc/selinux/config`

## VM 설정
`vim /etc/sysctl.conf`
```sh
net.ipv4.ip_forward=1
vm.max_map_count=262144
vm.overcommit_memory=1
```
`sysctll -p`

## 브릿지 네트워크 만들기
#### 1. 기존 네트워크 설정 파일 백업 생성: `cp -r /etc/sysconfig/network-scripts /etc/sysconfig/network-scripts-bak`
#### 2. 브릿지 네트워크 설정 파일 생성: `cp /etc/sysconfig/network-scripts/ifcfg-{{ 인터페이스_이름 }} /etc/sysconfig/network-scripts/ifcfg-br{{ N }}`
#### 3. 기존 네트워크 설정 파일 수정: `/etc/sysconfig/network-scripts/ifcfg-{{ 인터페이스_이름 }}`
```shell
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none  # DHCP를 사용하지 않음
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=eui64
NAME={{ 인터페이스_이름 }}
UUID=
DEVICE={{ 인터페이스_이름 }}
ONBOOT=yes
# IPADDR={{ 기존 IP ex) 10.10.0.100 }}     # IP 주소 설정을 제거하거나 주석 처리
# PREFIX={{ 기존 설정 ex)24 }}              # 서브넷 마스크 설정을 제거하거나 주석 처리
# GATEWAY={{ 기존 설정 ex)10.10.0.1 }}      # 게이트웨이 설정을 제거하거나 주석 처리
# DNS1={{ 기존 설정 ex) 8.8.8.8 }}          # DNS 설정을 제거하거나 주석 처리
BRIDGE=br0                                # <- 추가: eno1 인터페이스를 br0 브리지에 연결 
```
#### 4. 브릿지 네트워크 설정 파일 수정: `/etc/sysconfig/network-scripts/ifcfg-br{{ N }}`
```shell
TYPE=Bridge
BOOTPROTO=static  # 정적 IP 주소 사용
NAME=br0
DEVICE=br0
ONBOOT=yes
IPADDR={{ 기존 IP ex) 10.10.0.100 }}    # 브리지의 정적 IP 주소 설정
PREFIX={{ 기존 설정 ex)24 }}             # 브리지의 서브넷 마스크 설정
GATEWAY={{ 기존 설정 ex)10.10.0.1 }}     # 브리지의 게이트웨이 주소 설정
DNS1={{ 기존 설정 ex) 8.8.8.8 }}         # 브리지에서 사용할 DNS 서버 주소 설정
```
#### 5. 네트워크 재시작 커맨드
```shell
# 종류에 따라 택1
systemctl restart network
systemctl restart NetworkManager
systemctl restart systemd-networkd

ip addr show br0
ip link show br0
```

## [가상머신 생성하기](https://docs.redhat.com/ko/documentation/red_hat_enterprise_linux/7/html/virtualization_deployment_and_administration_guide/sect-guest_virtual_machine_installation_overview-creating_guests_with_virt_install)

```shell
# 예시
sudo virt-install \
  --name {{ vm_name }} \                                            # 가상 머신의 이름을 지정합니다.
  --memory {{ memory_MB }} \                                        # 할당할 메모리 양을 MB 단위로 지정합니다.
  --vcpus {{ cpu }} \                                               # 할당할 가상 CPU 코어의 개수를 지정합니다.
  --disk path={{ path of image }}.qcow2,size={{ qcow_size_GB }} \   # 가상 머신의 디스크 이미지 경로와 크기를 설정합니다.
  --os-type {{ os_type }} \                                         # 사용할 운영 체제의 종류를 지정합니다.
  --os-variant {{ os_variant }} \                                   # 사용할 운영 체제의 Variant를 지정합니다.
  --network bridge={{ interface }} \                                # 사용할 네트워크 인터페이스를 지정합니다 (브리지 네트워크를 사용할 경우).
  --graphics {{ none|vnc|spice }} \                                 # 가상 머신의 그래픽 출력 방식을 지정합니다 (none, vnc, spice 등).
  --console pty,target_type=serial \                                # 가상 콘솔의 설정을 지정합니다 (시리얼을 사용하여 콘솔 접근 설정).
  --location {{ path of iso }}.iso \                                # 가상 머신에 설치할 운영 체제 ISO 이미지의 경로를 지정합니다.
  --extra-args 'console=ttyS0,115200n8'                             # 부가적인 커널 부팅 인자를 지정합니다 (시리얼 콘솔 설정).
```
```shell
virt-install --name centos9 --memory 2048 --vcpus 2 --disk path=/data/disk/centos9.qcow2,size=20 --os-type linux --os-variant centos-stream9 --network bridge=br0 --graphics none --console pty,target_type=serial --location /data/images/centos-stream-9.iso  --extra-args 'console=ttyS0,115200n8'
```


## Command
#### `osinfo-query os` : variant옵션에 넣을 os 찾기
#### `virsh list`: 실행중인 vm
#### `virsh define <file-name>.xml`: 설정파일이 있을 시 생성하는 방법
#### `virsh list --all`: 전체 vm
- `virsh list --all --name `: 이름만 확인
#### `virsh net-list --all`: 네트워크 확인
#### `virsh start <vm-name>`: vm 시작
#### `virsh shutdown <vm-name>`: vm 종료
#### `virsh reboot <vm-name>`: vm 재부팅
#### `virsh destroy <vm-name>`: vm 파괴
#### `virsh dumpxml <vm-name>`: 구성 확인
- `virsh dumpxml <vm-name> > vm-config.xml`: 구성 파일 저장
- `virsh edit <vm-name>`: xml 편집
- `virsh net-edit <vm-name>`: 네트워크 편집
#### `virsh dominfo <vm-name>`: 세부 정보 보기
#### `virsh domifaddr <vm-name>`: IP 확인
#### `virsh domiflist <vm-name>`: 인터페이스 확인
#### `virsh domstate <vm-name>`: 실행 여부 확인
#### `virsh console <vm-name>`: 콘솔 연결