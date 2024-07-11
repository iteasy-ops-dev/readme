# Red Hat Enterprise Linux 7 
## Virtualization Deployment and Administration Guide
이는 RedHat에서 제공하는 PDF를 굉장히 간략하게 정리한 문서입니다.
자세한 내용은 PDF를 확인하세요

## Part 1. Deployment
### 최소 요구 사항
- disk: 6G
- memory: 2G
### 가상화를 지원하는지 확인
```sh
grep -E 'svm|vmx' /proc/cpuinfo
lsmod | grep kvm
# kvm_intel             348160  8
# kvm                   970752  1 kvm_intel
# irqbypass              16384  33 kvm
virsh capabilities
```
### 패키지 설치
```sh
yum -y install qemu-kvm libvirt
yum -y install virt-install libvirt-python virt-manager virt-install libvirt-client 
```
- `virt-manager`: 그래픽 관리 도구
### 가상머신 생성
- `virt-install` 사용
- storage 옵션
  - `--disk`
  - `--filesystem`
- 설치 메소드 옵션
  - `--location`: 설치 미디어 경로
  - `--cdrom`: iso image 
  - `--pxe`
  - `--import`: OS 설치단계를 skip할 수 있음
  - `--boot`
```sh
# 예시
virt-install  \
--name bastion  \
--os-type linux \
--os-variant centos7.0 \
--vcpus 4  \
--memory 4096 \
--disk path=/data/images/bastion.qcow2,device=disk,bus=virtio,format=qcow2 \
--network default \
--network bridge=br0 \
--graphics none  \
--noautoconsole  \
--import
```
### 네트워크 생성
`virt-install` 사용 시
- `NAT`: --network default
- `Bridge network`
  - DHCP: --network=br0
  - Static: --network=br0 --extra-args "ip=192.168.1.2::192.168.1.1:255.255.255.0:test.example.com:eth0:none"
- `No network`: --network none
### 가상 머신 복제
- 종류
  - clone
  - template
- 복제 전에 유니크한 설정은 삭제를 미리 해야한다.
- `virt-sysprep`이 준비되어 있거나
- 다음 스텝을 따라야한다.
