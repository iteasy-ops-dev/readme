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

log "INFO" "이미지 변환 중."
virt-customize -a $PATH_IMAGES/$IMAGE --root-password password:thddlsrbsjdlaak
virt-customize -a $PATH_IMAGES/$IMAGE --run-command 'yum remove cloud-init* -y'
log "SUCCESS" "이미지 변환 완료."

log "INFO" "파일 시스템 확인."
virt-filesystems -a $PATH_IMAGES/$IMAGE -l