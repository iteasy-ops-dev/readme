#!/bin/bash

# 기본 구성
set -e

source ./000.log.sh

PATH_VMS=/data/vms
PATH_IMAGES=/data/images
IMAGE=Rocky-8-GenericCloud.latest.x86_64.qcow2.10 # rocky8.10
# IMAGE=Rocky-8-GenericCloud.latest.x86_64.qcow2 # rocky8
# IMAGE=Rocky-9-GenericCloud.latest.x86_64.qcow2 # rocky9

if [ -e "./000.log.sh" ]; then
  log "SUCCESS" "기본 구성 파일이 존재 확인."
else
  log "ERROR" "기본 구성 파일이 존재하지 않습니다."
  exit 1
fi

for i in vms{0..3}
do
    log "INFO" "${i} 이미지 생성 중."
    qemu-img create -f qcow2 $PATH_VMS/${i}.qcow2 100G
    log "INFO" "${i} 이미지 리사이징 중."
    virt-resize --expand /dev/sda5 $PATH_IMAGES/$IMAGE $PATH_VMS/${i}.qcow2
done

log "INFO" "폴더 확인."
ls -alh $PATH_VMS

for i in vms{0..3}
do
    log "INFO" "이미지 확인: ${i}"
    qemu-img info $PATH_VMS/${i}.qcow2
done

for i in vms{0..3}
do
    log "INFO" "가상 머신 생성: ${i}"
    virt-install  \
    --name ${i}  \
    --os-type linux \
    --os-variant rocky9 \
    --vcpus 4  \
    --memory 4096 \
    --disk path=$PATH_VMS/${i}.qcow2,device=disk,bus=virtio,format=qcow2 \
    --network default \
    --network bridge=br0 \
    --graphics none  \
    --noautoconsole  \
    --import
done

