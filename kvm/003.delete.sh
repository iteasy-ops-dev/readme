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

log "INFO" "가상머신 확인."
virsh list

log "INFO" "가상머신 정지."
for i in vms{0..3}
do
    log "WARNING" "가상머신 ${i} 정지 중."
    virsh destroy ${i}
done

log "INFO" "가상머신 삭제."
for i in vms{0..3}
do
    log "WARNING" "가상머신 ${i} 삭제 중."
    virsh undefine ${i}
done

log "INFO" "이미지 삭제."
rm -rf $PATH_VMS/*.qcow2
log "SUCCESS" "이미지 삭제 완료."

log "INFO" "${PATH_VMS} 폴더 확인"
ls -alh $PATH_VMS