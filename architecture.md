# Architecture

## 각 저장소의 역할
### ansible.roles.*
- ansible playbook을 roles로 관리
- 해당 기능이 추가가 되면 wrappedAnsible에 추가

### wrappedAnsible
- was on golang
- api로 ansible 쉽게 호출
- 기능은 ansible 폴더안에 파일로 추가시키면됨

### nocssFrontWithReact
- 프론트엔드 담당
- nginx로 리버스 프록시 할 예정
- ansible.roles.* 기능이 추가되면
  - 해당 추가 옵션에 맞는 추가 옵션 폼을 만들어줘야함.
