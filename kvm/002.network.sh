#!/bin/bash

# 기본 구성
set -e

source ./000.log.sh

PATH_VMS=/data/vms
PATH_IMAGES=/data/images

if [ -e "./000.log.sh" ]; then
  log "SUCCESS" "기본 구성 파일이 존재 확인."
else
  log "ERROR" "기본 구성 파일이 존재하지 않습니다."
  exit 1
fi

for i in vms{0..3}
do
    log "WARNING" "${i} 가상 머신 종료 중."
    virsh destroy ${i}
    log "INFO" "${i} 네트워크 설정 중."
    virt-copy-in -d ${i} nic/${i}/* /etc/sysconfig/network-scripts
    log "INFO" "${i} 가상 머신 재시작."
    virsh start ${i}
done