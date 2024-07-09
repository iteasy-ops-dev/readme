#!/bin/bash

set -e

NC='\033[0m'
ERROR='\033[1;91m'        # Red: 오류
WARNING='\033[1;93m'      # Yellow: 경고
SUCCESS='\033[1;92m'      # Green: 성공
INFO='\033[1;94m'         # Blue: 정보

log() {
  local log_type="$1"
  local message="$2"
  local color_code=""
  
  case $log_type in
    "INFO")
      color_code=$INFO
      ;;
    "SUCCESS")
      color_code=$SUCCESS
      ;;
    "WARNING")
      color_code=$WARNING
      ;;
    "ERROR")
      color_code=$ERROR
      ;;
    *)
      # 기본적으로는 INFO 로그 유형과 파란색을 사용
      color_code=$INFO
      ;;
  esac
  
  echo -e "${color_code}[${log_type}] $message${NC}"
}

# 루트 사용자인지 확인
if [ "$(id -u)" != "0" ]; then
  log "ERROR" "이 스크립트는 루트 사용자로 실행해야 합니다."
  exit 1
fi

log "WARNING" "이 스크립트는 루트 사용자로 실행 중입니다."