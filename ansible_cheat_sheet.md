# Ansible Cheat Sheet

Ansible은 플랫폼 간 컴퓨터 지원을 위한 간단하지만 강력한 자동화를 제공합니다. Ansible 플레이북은 YAML로 작성되며 로컬 또는 원격에서 실행할 수 있습니다.

## 명령어
- `ansible-playbook file.yaml`: Ansible 플레이북 file.yaml 실행

## 인증 옵션
- `--user, -u <사용자 이름>`: 사용자 이름으로 로그인
- `--private-key, --key-file <키>`: SSH 키(보통 ~/.ssh에 있음)를 사용하여 로그인
- `--ssh-extra-args`: SSH에 추가 명령 옵션 전달
- `--vault-id <id>`: 금고 아이덴티티 ID 사용
- `--vault-password-file <키>`: 금고 비밀번호 파일 키 사용
- `--ask-vault-pass`: 금고 비밀번호를 묻기
- `--become`: 권한 상승
- `--ask-become-pass`: 권한 상승 비밀번호 묻기
- `--become-method`: 특정 방법을 사용하여 권한 상승
- `ansible-doc –-type foo --list`: become, connection 및 기타 Ansible 옵션의 선택 목록

## 제어 옵션
- `--syntax-check`: 플레이북의 구문 확인(실행하지 않음)
- `--list-hosts`: 플레이북에 나열된 호스트 표시
- `--list-tasks`: 플레이북에 정의된 작업 표시
- `--start-at-task <작업 이름>`: 지정된 작업부터 플레이북 실행
- `--check`: 변경하지 않고 플레이북 실행
- `--diff`: 변경된 내용을 diff로 표시
- `--module-path`: 기본 경로에 콜론으로 구분된 경로 추가
- `--connection <방법>`: 방법을 통해 연결

## 플레이북 및 YAML
```yml
--- # YAML 파일은 세 개의 대시로 시작함
- name: “My play” # 플레이에 이름을 붙이기 위해 name 매핑 사용
  hosts: all # 들여쓰고, 플레이가 실행될 호스트 정의. etc/ansible/hosts에 타겟 호스트 나열
  tasks: # 시퀀스를 포함하는 작업 매핑 열기
  - name: “My task” # name 매핑으로 작업에 이름 지정
      some_module: # 시퀀스 매개변수를 포함하는 새 매핑으로 모듈 가져오기. 모듈 문서에서 필수 및 선택 매개변수 찾기.
      path: ‘/example/’ # 매개변수는 일반적으로 명령 옵션을 키로, 인수를 값으로 사용하는 매핑
  - name: “My other task” # 하나의 플레이는 여러 작업을 포함할 수 있음
      other_module:
      foo: ‘bar’ # 작업은 일반적으로 모듈을 가져옴
  ```

##### 출처 
Open Source - Seth Kenlon