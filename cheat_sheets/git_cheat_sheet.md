# Git Cheat Sheet

## 설치 및 GUI

GitHub는 플랫폼별 Git 설치 프로그램을 제공하며, 명령줄 도구의 최신 릴리스를 유지하면서 일상적인 상호작용, 검토 및 저장소 동기화를 위한 그래픽 사용자 인터페이스를 제공합니다.

- GitHub for Windows: https://windows.github.com
- GitHub for Mac: https://mac.github.com
- 모든 플랫폼을 위한 Git: http://git-scm.com

## 설정

모든 로컬 저장소에 사용되는 사용자 정보 설정

- `git config --global user.name “[이름]”`: 버전 기록 검토 시 식별 가능한 이름 설정
- `git config --global user.email “[유효 이메일]”`: 각 기록 마커와 연관될 이메일 주소 설정
- `git config --global color.ui auto`: 명령줄 색상 자동 설정

## 설정 및 초기화

사용자 정보 설정, 저장소 초기화 및 클로닝

- `git init`: 기존 디렉토리를 Git 저장소로 초기화
- `git clone [URL]`: URL을 통해 호스팅된 위치에서 전체 저장소를 가져오기

## Stage 및 스냅샷

스냅샷과 Git 스테이징 영역 작업

- `git status`: 작업 디렉토리에서 수정된 파일을 보여주고, 다음 커밋을 위해 스테이지됨
- `git add [파일]`: 현재 상태의 파일을 다음 커밋에 추가(스테이지)
- `git reset [파일]`: 작업 디렉토리에서 변경 사항을 유지하며 파일을 스테이지에서 제거
- `git revert [커밋해시]`: 이전 버전으로 되돌리기
- `git diff`: 스테이지되지 않은 변경 사항의 차이점 표시
- `git diff --staged`: 스테이지되었지만 아직 커밋되지 않은 변경 사항의 차이점 표시
- `git commit -m “[설명 메시지]”`: 스테이지된 내용을 새로운 커밋 스냅샷으로 커밋

## 브랜치 및 병합

브랜치에서 작업을 분리하고, 컨텍스트를 변경하며, 변경 사항 통합

- `git branch`: 브랜치 목록 표시. 현재 활성 브랜치 옆에 * 표시
- `git branch [브랜치 이름]`: 현재 커밋에서 새 브랜치 생성
- `git checkout [브랜치 이름]`: 다른 브랜치로 전환하고 작업 디렉토리에 체크아웃
- `git merge [브랜치]`: 지정된 브랜치의 기록을 현재 브랜치로 병합
- `git log`: 현재 브랜치의 모든 커밋 표시

## 검사 및 비교
로그, 차이점 및 객체 정보 검사

- `git log`: 현재 활성 브랜치의 커밋 기록 표시
- `git log branchB..branchA`: branchA에 있고 branchB에 없는 커밋 표시
- `git log --follow [파일]`: 파일을 변경한 커밋 표시, 이름 변경 시에도
- `git diff branchB...branchA`: branchA에 있고 branchB에 없는 변경 사항의 차이점 표시
- `git show [SHA]`: Git의 모든 객체를 사람이 읽을 수 있는 형식으로 표시

## 경로 변경 추적

파일 삭제 및 경로 변경 버전 관리

- `git rm [파일]`: 프로젝트에서 파일을 삭제하고 커밋을 위해 제거를 스테이지
- `git mv [기존 경로] [새 경로]`: 기존 파일 경로 변경 및 이동을 스테이지
- `git log --stat -M`: 경로 이동을 표시하는 모든 커밋 로그 표시

## 패턴 무시

파일의 의도하지 않은 스테이징 또는 커밋 방지

- `git config --global core.excludesfile [파일]`: 모든 로컬 저장소에 대한 시스템 전체 무시 패턴 설정
- .gitignore 파일에 직접 문자열 매치 또는 와일드카드 글로브 패턴을 저장합니다.

## 공유 및 업데이트

다른 저장소에서 업데이트를 가져오고 로컬 저장소 업데이트

- `git remote add [별명] [URL]`: Git URL을 별명으로 추가
- `git fetch [별명]`: 해당 Git 원격에서 모든 브랜치를 가져오기
- `git merge [별명]/[브랜치]`: 원격 브랜치를 현재 브랜치에 병합하여 최신 상태로 유지
- `git push [별명] [브랜치]`: 로컬 브랜치 커밋을 원격 저장소 브랜치로 전송
- `git pull`: 추적 중인 원격 브랜치에서 커밋을 가져와 병합

## 기록 재작성

브랜치 재작성, 커밋 업데이트 및 기록 삭제

- `git rebase [브랜치]`: 현재 브랜치의 커밋을 지정된 브랜치 앞에 적용
- `git reset --hard [커밋]`: 스테이징 영역 지우기, 지정된 커밋에서 작업 트리 재작성

## 임시 커밋

브랜치를 변경하기 위해 수정된 추적 파일을 임시로 저장

- `git stash`: 수정되고 스테이지된 변경 사항 저장
- `git stash list`: 스태시된 파일 변경 사항의 스택 순서 목록
- `git stash pop`: 스태시 스택의 맨 위에서 작업 기록 작성
- `git stash drop`: 스태시 스택의 맨 위 변경 사항 삭제

## 원격 저장소 파일 삭제
- `git rm --cached -r [파일]`
- 커밋 후 푸시


##### 출처
[GitHub Education](education.github.com)

