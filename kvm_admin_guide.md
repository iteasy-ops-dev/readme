# Red Hat Enterprise Linux 7 
## Virtualization Deployment and Administration Guide
이는 RedHat에서 제공하는 PDF를 굉장히 간략하게 정리한 문서입니다.
자세한 내용은 PDF를 확인하세요

## Part 1. Deployment
### 1. 최소 요구 사항
- disk: 6G
- memory: 2G
#### 가상화를 지원하는지 확인
```sh
grep -E 'svm|vmx' /proc/cpuinfo
lsmod | grep kvm
# kvm_intel             348160  8
# kvm                   970752  1 kvm_intel
# irqbypass              16384  33 kvm
virsh capabilities
```
### 2. 패키지 설치
```sh
yum -y install qemu-kvm libvirt
yum -y install virt-install libvirt-python virt-manager virt-install libvirt-client 
```
- `virt-manager`: 그래픽 관리 도구
### 3. 가상머신 생성
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
#### 네트워크 생성
`virt-install` 사용 시
- `NAT`: --network default
- `Bridge network`
  - DHCP: --network=br0
  - Static: --network=br0 --extra-args "ip=192.168.1.2::192.168.1.1:255.255.255.0:test.example.com:eth0:none"
- `No network`: --network none
### 4. 가상 머신 복제
- 종류
  - clone
  - template
- 복제 전에 유니크한 설정은 삭제를 미리 해야한다.
- `virt-sysprep`이 준비되어 있거나
- 다음 스텝을 따라야한다.
#### 복제 전 준비사항
  1. 가상머신 복제 준비
     1. template이나 clone에 사용될 머신을 빌드
     2. 복제에 필요한 sw 설치 
     3. non-unique 구성 
        1. os 세팅
        2. 앱 세팅 
  2. 네트워크 구성 삭제
     1. 영구적인 udev 룰 삭제 
        1. `rm -f /etc/udev/rules.d/70-persistent-net.rules` 
        2. 삭제하지 않으면 eth[x]의 상태가 바뀔 수도 있다
     2. 네트워크 스크립트에 존재하는 유니크한 설정을 삭제한다. 
        1. `/etc/sysconfig/network-scripts/ifcfg-eth[x]` 
           1. `HWADDR`와 정적옵션 라인 지우기
           2. ```sh
              DEVICE=eth[x]
              BOOTPROTO=none
              ONBOOT=yes
              # NETWORK=10.0.1.0 <- REMOVE 
              # NETMASK=255.255.255.0 <- REMOVE 
              # IPADDR=10.0.1.20 <- REMOVE 
              # HWADDR=xx:xx:xx:xx:xx <- REMOVE 
              # USERCTL=no <- REMOVE
              # Remove any other *unique* or non-desired settings, such as UUID.
              ```
           3. 아래와 같은 옵션이 남아있는지 확인
              ```sh
              DEVICE=eth[x]
              ONBOOT=yes
              # BOOTPROTO=dhcp
              ```
      3. 아래와 같은 곳의 구성파일도 존재한다면 확인해본다  
         1. `/etc/sysconfig/networking/devices/ifcfg-eth[x]` 
         2. `/etc/sysconfig/networking/profiles/profiles/ifcfg-eth[x]`
#### 가상머신 복제
- ❗️ 복제 전에 가상머신 종료 필수
- `virt-clone` | `virt-manager` 사용
- `virt-clone`은 
  - `root`권한 필요. 
  - cli에서 작동
  - `--original` 옵션만 필수
```sh
# "demo" 기본 연결 가상 머신에 대하여 자동으로 복제본 생성
virt-clone --original demo --auto-clone

# QEMU 사용
virt-clone --connect qemu:///system --original demo --name newdemo --file /var/lib/libvirt/images/newdemo.img --file /var/lib/libvirt/images/newdata.img
```

### 5. 반가상화 드라이버(virtio)
- 반가상화 드라이버는 다음을 개선한다
  - GuestOS의 성능
  - I/O 지연시간 감소
  - 베어-메탈 레벨의 처리량 증가
- I/O가 많은 tasks와 application을 구동하는 전가상화 Guest에 추천
- **virtio**는 KVM의 반가상화 드라이버
  - Guest running on KVM hosts
- 지원
  - block devices(storage)
  - network interface
- 기존 하드디스크 kvm virtio로 수정하기
  - 종료가 필수는 아니지만
  - 적용되기 위해서 종료나 재시작은 필요하다
1. 기존 하드디스크를 위해 virtio 사용하기
   1. 시작 전에 `viostor`가 설치 되어 있는지 확인.
   2. `virsh edit <guestName>`으로 구성 파일 확인.
      1. 파일은 `/etc/libvirt/qemu`에 있음.
   3. 기존 ide를 사용하는 파일 내용 확인
      ```xml
      <disk type='file' device='disk'> 
      ...
         <source file='/var/lib/libvirt/images/disk1.img'/>
         <target dev='hda' bus='ide'/> <!-- 이 부분 확인-->
         <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
      </disk>
      ```
   4. 해당 파일을 virtio를 사용 할 수 있도록 수정
      ```xml
      <disk type='file' device='disk'> 
      ...
         <source file='/var/lib/libvirt/images/disk1.img'/>
         <target dev='vda' bus='virtio'/> <!-- 이 부분 변경-->
         <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
      </disk>
      ```
   5. 반드시 disk 태그 안에있는 address 태그를 삭제한다.
2. 새로운 스토리지를 위해 virtio 사용하기
   1. `virsh attach-disk` | `virsh attach-interface` 사용.
3. network interface를 위해 virtio 사용

### 6. 네트워크 구성
- 지원 목록
  - NAT
  - PCI
  - PCIe SR-IOV
  - Bridge
1. Host 구성 - libvirt로 NAT 설정
   1. `virsh net-lit --all`: default 옵션 확인
   2. default 네트워크 확인
      ```sh
      cat /etc/libvirt/qemu/networks/default.xml
      ```
      ```xml
      <!--
      WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
      OVERWRITTEN AND LOST. Changes to this xml configuration should be made using:
      virsh net-edit default
      or other application using the libvirt API.
      -->

      <network>
      <name>default</name>
      <uuid>a1ae174c-a8c0-4d5c-8370-38069c30a559</uuid>
      <forward mode='nat'/>
      <bridge name='virbr0' stp='on' delay='0'/>
      <mac address='52:54:00:d6:29:4c'/>
      <ip address='192.168.122.1' netmask='255.255.255.0'>
         <dhcp>
            <range start='192.168.122.2' end='192.168.122.254'/>
         </dhcp>
      </ip>
      </network>
      ```
   3. default network 자동 시작 구성
      ```shell
      virsh net-autostart default
      # Network default marked as autostarted
      ```
   4. default network 시작
      ```shell
      virsh net-start default 
      # Network default started
      ```
   5. **libvirt** default network가 시작되면 bridge device를 확인 할 수 있다.
      ```shell
      brctl show
      # bridge name bridge id STP enabled interfaces 
      # virbr0 8000.000000000000 yes
      ```
   6. default network에는 물리 인터페이스를 가질 수 없다.
   7. iptables로 **virbr0**에 대한 관리를 할 수 있다.
      ```shell
      iptables -L -v -n
      Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
      pkts bytes target     prot opt in     out     source               destination
      1554K 8972M LIBVIRT_INP  all  --  *      *       0.0.0.0/0            0.0.0.0/0

      Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
      pkts bytes target     prot opt in     out     source               destination
         0     0 LIBVIRT_FWX  all  --  *      *       0.0.0.0/0            0.0.0.0/0
         0     0 LIBVIRT_FWI  all  --  *      *       0.0.0.0/0            0.0.0.0/0
         0     0 LIBVIRT_FWO  all  --  *      *       0.0.0.0/0            0.0.0.0/0

      Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
      pkts bytes target     prot opt in     out     source               destination
      1215K  274M LIBVIRT_OUT  all  --  *      *       0.0.0.0/0            0.0.0.0/0

      Chain LIBVIRT_INP (1 references)
      pkts bytes target     prot opt in     out     source               destination
         0     0 ACCEPT     udp  --  virbr0 *       0.0.0.0/0            0.0.0.0/0            udp dpt:53
         0     0 ACCEPT     tcp  --  virbr0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:53
         0     0 ACCEPT     udp  --  virbr0 *       0.0.0.0/0            0.0.0.0/0            udp dpt:67
         0     0 ACCEPT     tcp  --  virbr0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:67

      Chain LIBVIRT_OUT (1 references)
      pkts bytes target     prot opt in     out     source               destination
         0     0 ACCEPT     udp  --  *      virbr0  0.0.0.0/0            0.0.0.0/0            udp dpt:53
         0     0 ACCEPT     tcp  --  *      virbr0  0.0.0.0/0            0.0.0.0/0            tcp dpt:53
         0     0 ACCEPT     udp  --  *      virbr0  0.0.0.0/0            0.0.0.0/0            udp dpt:68
         0     0 ACCEPT     tcp  --  *      virbr0  0.0.0.0/0            0.0.0.0/0            tcp dpt:68

      Chain LIBVIRT_FWO (1 references)
      pkts bytes target     prot opt in     out     source               destination
         0     0 ACCEPT     all  --  virbr0 *       192.168.122.0/24     0.0.0.0/0
         0     0 REJECT     all  --  virbr0 *       0.0.0.0/0            0.0.0.0/0            reject-with icmp-port-unreachable

      Chain LIBVIRT_FWI (1 references)
      pkts bytes target     prot opt in     out     source               destination
         0     0 ACCEPT     all  --  *      virbr0  0.0.0.0/0            192.168.122.0/24     ctstate RELATED,ESTABLISHED
         0     0 REJECT     all  --  *      virbr0  0.0.0.0/0            0.0.0.0/0            reject-with icmp-port-unreachable

      Chain LIBVIRT_FWX (1 references)
      pkts bytes target     prot opt in     out     source               destination
         0     0 ACCEPT     all  --  virbr0 virbr0  0.0.0.0/0            0.0.0.0/0
      ```
   8. 옵션 추가하기
      ```sh
      cat /etc/sysctl.conf
      # sysctl settings are defined through files in
      # /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
      #
      # Vendors settings live in /usr/lib/sysctl.d/.
      # To override a whole file, create a new file with the same in
      # /etc/sysctl.d/ and put new settings there. To override
      # only specific settings, add a file with a lexically later
      # name in /etc/sysctl.d/ and put new settings there.
      #
      # For more information, see sysctl.conf(5) and sysctl.d(5).
      net.ipv4.ip_forward=1 # 해당 옵션이 추가 되어있어야 함.
      vm.max_map_count=262144
      vm.overcommit_memory=1
      ```
2. vhost-net 비활성화
- vhost-net 모듈은 virtio 네트워크 인터페이스에서 성능을 향상시키기 위해 커널 공간에서 패킷 처리를 수행합니다.
- vhost-net 모듈은 기본적으로 활성화되어 있지만, 특정 상황에서 성능 저하가 발생할 경우 비활성화할 수 있습니다.
- UDP 트래픽의 경우, 호스트가 데이터를 보내는 속도보다 게스트가 처리하는 속도가 느릴 때 vhost-net을 비활성화하는 것이 성능을 개선하는 데 도움이 됩니다.
- 비활성화 방법
```xml
<interface type="network"> 
...
   <model type="virtio"/>
   <driver name="qemu"/> <!-- driver name을 qemu로 변경하면 비활성화 됨. -->
   ...
</interface>
```
3. vhost-net zero-copy 활성화
   1. 활성화 방법
      1. `vim /etc/modprobe.d/vhost-net.conf`
      2. `options vhost_net experimental_zcopytx=1` 추가
   2. 비활성화
      1. `modprobe -r vhost_net`
      2. `modprobe vhost_net experimental_zcopytx=0`
4. Bridge Networking
- 📌 NetworkManager와 호환이 좋지 않으므로 비활성화 해야할 수도 있음
- [브릿지 네트워크 생성방법](https://docs.redhat.com/en/documentation/Red_Hat_Enterprise_Linux/7/html/networking_guide/ch-configure_network_bridging#sec-Configure_Bridging_Using_the_Text_User_Interface_nmtui)

### 7. OverCommitting with KVM
- `Overcommit`(과다할당): 물리적 리소스보다 더 많은 리소스를 할당 하는 것.
  - 장점: 자원 활용 극대화
  - 단점: 
    - 관리 어려움. 
    - 성능 문제 발생 가능성. 
    - 안정성 문제 발생 가능성.
- KVM은 자동으로 overcommit한다.
  - 이것이 가능한 이유는, 대부분의 프로세느는 모든 시간에 100%를 사용하지 않기 때문
- [메모리 overcommit 최적화](https://docs.redhat.com/en/documentation/Red_Hat_Enterprise_Linux/7/html/Virtualization_Tuning_and_Optimization_Guide/chap-KSM.html)
   - overcommit은 최적의 솔루션이 아니므로 더 많은 정보가 필요하다.
- CPU Overcommit도 가능.
  - 구동하고자 하는 애플리케이션에 맞는 vcpu 할당이 중요.
- 리소스를 100% 가까이 사용하는 것은 안정성이 불안해지므로 충분한 테스트를 거치고 프로덕션에 활용해야 함.

### 8. KVM Guest 타이밍 관리 P.64
- **인터럽트**: 컴퓨터 시스템에서 특정 이벤트가 발생했을 때 현재 수행 중인 작업을 일시 중단하고 그 이벤트를 처리하기 위해 CPU에 신호를 보내는 메커니즘
- VM의 인터럽트는 진짜 인터럽트가 아님
- 이 부분은 잘 몰라서 다음에 추가로 더 봐야할 듯

### 9. libvirtfh 네트워크 부팅하기 P.68
`PXE(Preboot eXecution Environment)`는 네트워크 인터페이스를 사용하여 컴퓨터를 부팅하는 프로토콜입니다. 이 환경을 통해 디스크 드라이브나 로컬 저장소 없이도 컴퓨터가 운영 체제를 네트워크를 통해 다운로드하고 실행할 수 있습니다. PXE는 특히 대규모 시스템 배포 및 관리에서 유용하며, 운영 체제를 설치하거나 시스템을 복구하는 데 사용됩니다. PXE의 주요 개념과 동작 방식을 다음과 같이 설명할 수 있습니다:

- PXE의 주요 개념
1. DHCP (Dynamic Host Configuration Protocol)
   1. 설명: PXE는 DHCP를 사용하여 네트워크에서 IP 주소를 얻습니다. 이 과정에서 PXE 클라이언트는 DHCP 서버로부터 부트 서버의 위치와 부팅에 필요한 정보를 받습니다.
   2. 역할: 네트워크에서 IP 주소와 PXE 부트 서버의 위치 정보를 제공합니다.
2. TFTP (Trivial File Transfer Protocol)
   1. 설명: PXE 클라이언트는 TFTP를 사용하여 부팅 이미지와 관련 파일을 네트워크에서 다운로드합니다.
   2. 역할: PXE 클라이언트에 부팅 이미지와 관련 파일을 제공합니다.
3. PXE 클라이언트
   1. 설명: PXE를 통해 네트워크 부팅을 시도하는 컴퓨터입니다. 이 컴퓨터는 네트워크 인터페이스를 통해 부팅 과정을 시작합니다.
   2. 역할: DHCP 서버로부터 부트 서버 정보를 얻고, TFTP 서버에서 부팅 이미지를 다운로드하여 실행합니다.
- PXE의 동작 원리
1. 네트워크 부팅 시도
   1. PXE 클라이언트는 BIOS 또는 UEFI 설정을 통해 네트워크 부팅을 시도합니다.
   2. 클라이언트는 네트워크 인터페이스를 활성화하고, DHCP 서버에 IP 주소를 요청합니다.
2. DHCP 요청 및 응답
   1. PXE 클라이언트는 DHCP 서버에 IP 주소를 요청하는 DHCPDISCOVER 메시지를 보냅니다.
   2. DHCP 서버는 PXE 클라이언트에게 IP 주소와 PXE 부트 서버 정보를 포함한 DHCPOFFER 메시지로 응답합니다.
3. PXE 부트 서버 정보 수신
   1. PXE 클라이언트는 DHCP 서버로부터 받은 정보로 PXE 부트 서버에 접속합니다.
   2. PXE 부트 서버는 클라이언트에게 부팅 이미지의 위치를 알려줍니다.
4. TFTP를 통한 부팅 이미지 다운로드
   1. PXE 클라이언트는 TFTP를 사용하여 PXE 부트 서버로부터 부팅 이미지를 다운로드합니다.
   2. 이 부팅 이미지는 운영 체제의 커널과 초기 램 디스크(initrd)를 포함할 수 있습니다.
5. 부팅 이미지 실행
   1. 다운로드된 부팅 이미지를 메모리에 로드하고 실행합니다.
   2. 이 과정에서 클라이언트는 네트워크를 통해 운영 체제를 실행하거나 설치할 수 있습니다.
- PXE의 장점
  - 중앙 집중식 관리: PXE를 사용하면 네트워크를 통해 여러 시스템에 운영 체제를 일괄적으로 설치 및 관리할 수 있습니다.
  - 디스크리스 부팅: 로컬 디스크 없이도 시스템을 부팅할 수 있어 유지 보수와 관리가 용이합니다.
  - 자동화: 대규모 시스템 배포와 설치 작업을 자동화할 수 있어 인력과 시간을 절약할 수 있습니다.
- PXE의 사용 예시
  - 운영 체제 배포: 새로운 컴퓨터에 운영 체제를 설치할 때 PXE를 사용하여 네트워크를 통해 이미지를 배포합니다.
  - 시스템 복구: 운영 체제가 손상된 컴퓨터를 복구할 때 PXE를 사용하여 복구 이미지를 로드합니다.
  - 서버 설치: 데이터 센터에서 대규모 서버를 설치할 때 PXE를 사용하여 신속하게 운영 체제를 배포합니다.
##### * 예제만을 제공하므로 필요한 경우 PDF 확인

### 10. 하이퍼바이저 및 가상머신 등록

### 11. QEMU agent & SPICE agent로 가상화 개선
[가상화 튜닝 및 최적화 가이드](https://docs.redhat.com/en/documentation/Red_Hat_Enterprise_Linux/7/html/Virtualization_Tuning_and_Optimization_Guide/index.html)

### 12. 중첩된 가상화
- 테스트, 개발, 디버깅에 사용하고 프로덕션에 사용하는 것은 추천하지 않음.

## Part2. Administration