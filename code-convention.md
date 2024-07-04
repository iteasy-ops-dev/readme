# Golang Code convention
문서 마지막 작성일: 2024/07/04

모든 코드는 **golint** 및 **go vet**를 실행할 때 오류가 없어야 한다. 

## Panic
- init에서만 사용 - 프로그램 실행 및 초기화시 빠른 실패를 위해
- panic을 발생시키는 함수는 Must prefix로 래핑하여 사용
- 테스트에서 스택 트레이스를 위해 사용

## Goroutin
### 고루틴내에서의 panic은 recover()가 안되기 때문에 **panic safe**를 위해 래핑함수 사용
```go
package main

import (
	"fmt"
	"sync"
)

// PanicSafeGroup 구조체 정의
type PanicSafeGroup struct {
	mu     sync.Mutex     // 데이터 보호를 위한 뮤텍스
	// *multierror 구조체가 없기 때문에 임의로 설정
	errors []error        // 발생한 모든 에러를 저장할 슬라이스
	wg     sync.WaitGroup // 고루틴 완료 대기를 위한 WaitGroup
}

// Go 메서드는 주어진 함수를 고루틴으로 실행하고, 패닉이 발생하면 적절히 처리합니다.
func (g *PanicSafeGroup) Go(f func() error) {
	g.wg.Add(1) // WaitGroup에 고루틴을 추가합니다.

	go func() {
		defer g.wg.Done() // 고루틴 종료 시 WaitGroup을 감소시킵니다.
		defer func() {
			if r := recover(); r != nil { // 패닉 복구 처리
				err := fmt.Errorf("panic occurred: %v", r)
				g.mu.Lock()
				g.errors = append(g.errors, err) // 복구된 에러를 슬라이스에 추가합니다.
				g.mu.Unlock()
			}
		}()

		// 주어진 함수를 실행하고 반환된 에러를 처리합니다.
		if err := f(); err != nil {
			g.mu.Lock()
			// 에러를 슬라이스에 추가합니다. 
			// *multierror 구조체가 없기 때문에 임의로 설정
			g.errors = append(g.errors, err) 
			g.mu.Unlock()
		}
	}()
}

// Wait 메서드는 모든 고루틴이 완료될 때까지 기다린 후, 발생한 모든 에러를 반환합니다.
func (g *PanicSafeGroup) Wait() []error {
	g.wg.Wait() // 모든 고루틴이 완료될 때까지 대기합니다.
	g.mu.Lock()
	defer g.mu.Unlock()
	// 발생한 모든 에러를 반환합니다. 
	// *multierror 구조체가 없기 때문에 임의로 설정
	return g.errors 
}

func main() {
	var wg sync.WaitGroup
	pg := PanicSafeGroup{}

	// 고루틴 1: 패닉 발생 예시
	wg.Add(1)
	pg.Go(func() error {
		defer wg.Done()
		fmt.Println("Goroutine 1 started")
		panic("oops! something went wrong") // 의도적인 패닉 발생
	})

	// 고루틴 2: 정상 동작 예시
	wg.Add(1)
	pg.Go(func() error {
		defer wg.Done()
		fmt.Println("Goroutine 2 started")
		return fmt.Errorf("some error occurred") // 에러 발생
	})

	wg.Wait() // 모든 고루틴이 완료될 때까지 대기

	// PanicSafeGroup을 사용하여 발생한 모든 에러를 출력
	errors := pg.Wait()
	if len(errors) > 0 {
		fmt.Println("Errors occurred:")
		for _, err := range errors {
			fmt.Printf("- %v\n", err)
		}
	} else {
		fmt.Println("No errors")
	}
}
```
### 고루틴에서 생성된 결과 안전하게 모으기
#### 1. Mutex
- 동시 접근 가능한 공유 자원을 보호하는데 유용
- 쉽다
- 성능이 낮을 수 있음
```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	var mu sync.Mutex
	results := make([]int, 5)

	for i := 0; i < 5; i++ {
		wg.Add(1)
		go func(index int) {
			defer wg.Done()
			result := index * 2 // 예시로 임의의 결과 생성
			mu.Lock()
			results[index] = result
			mu.Unlock()
		}(i)
	}

	wg.Wait()

	fmt.Println("Results:", results)
}
```
#### 2. Channel
```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	results := make(chan int, 5) // 버퍼링된 채널 설정

	for i := 0; i < 5; i++ {
		wg.Add(1)
		go func(index int) {
			defer wg.Done()
			result := index * 2 // 예시로 임의의 결과 생성
			results <- result   // 채널에 결과 전송
		}(i)
	}

	go func() {
		wg.Wait()
		close(results) // 모든 고루틴이 작업을 완료하면 채널을 닫음
	}()

	var finalResults []int
	for result := range results {
		finalResults = append(finalResults, result)
	}

	fmt.Println("Results:", finalResults)
}
```
- 채널의 크기(Channel Size)는 하나(One) 혹은 제로(None)
```go
// 사이즈 1
c := make(chan int, 1) // 혹은
// 버퍼링 되지 않는 채널, 사이즈 0
c := make(chan int)
```

## Error
- [에러 핸들링 무난하게 하는 방법](https://jacking75.github.io/go-20220227/)
- pkg/errors.Wrap 사용
```go
// ❌
if err != nil {
    return fmt.Errorf("error while reading from file %s: %w", f.Name, err)
}
// ✅
if err != nil {
    return errors.Wrapf(err, "read file %s", f.Name)
}
```
- 항상 반환되는 에러 처리

## HTTP
### 클라이언트 설정
- **MaxIdleConnsPerHost** 기본 값이 2이기 때문에 성능을 위해 커스텀하게 설정하길 권장
- **MaxIdleConns** 기본 값이 100이기에 주로 100으로 맞춰줌
- 메모리 사용량과 트레이싱을 참고해 트래픽에 맞게 조정하길 권장함
### HTTP Connection 재사용
  

## Slice
- len, cap 가급적 설정하기
```go
// ❌
var ids []string
for _, u := range users {
	ids = append(ids, u.id)
}

// ✅
ids := make([]string, len(users))
for i, u := range users {
	ids[i] = u.id
}
```
- empty 체크
```go
// ❌
if results == nil {
	// ...
}

// ✅
if len(results) == 0 {
	// ...
}
```

## Map
```go
// ✅
m := make(map[string]bool{})
if m["key"]{
 // ...
}

// ✅
v := make(map[string]struct{}{})
if _, ok := v["key"]; ok{
    // ...
}
```
- map은 순회하지 않기
  - 반드시 해야한다면 append 후 sort 필수.
  - map은 랜덤순회임
- map 조회시 ok 체크
```go
m := make(map[string]int)
// 그닥
v := m[k]
// 권장
v, ok := m[k]
```

## String
- 문자열은 c 형식의 순회로 하면 인코딩 깨짐
```go
// ❌
s := "안녕"
for i := 0; i < len(s); i++ {
	fmt.Println(i, s[i], string(s[i]))
}
// 0 236 ì
// 1 149 
// 2 136 
// 3 235 ë
// 4 133 
// 5 149

// ✅
s := "안녕"
for i, r := range s {
	fmt.Println(i, r, string(r))
}
// 0 50504 안
// 3 45397 녕
```
- 문자열의 데이터 길이 말고, 문자열 갯수를 구하고 싶으면
- unicode/utf8 패키지의 utf8.RuneCountInString를 사용
```go
// ❌
len("abc") // 3
len("última") // 7
len("世界") // 6
len("안녕") // 6
len("✨🍰✨") // 10

// ✅
utf8.RuneCountInString("abc") // 3
utf8.RuneCountInString("última") // 6
utf8.RuneCountInString("世界") // 2
utf8.RuneCountInString("안녕") // 2
utf8.RuneCountInString("✨🍰✨") // 3
```

## ETC.
- Early return
- flatten
- happy case
- default parameter가 없으므로 필수 파라미터 분리
```go
// ❌
_ = NewAESCipher(key, nil, nil, nil, nil)

// ✅
_ = NewAESCipher(key, WithGCM(nonce))
_ = NewAESCipher(key, WithEncoding(euckr))
```
- Avoid variable shadowing

## [Naming](https://docs.google.com/document/d/1cBxRMfJm43U25akrLLRj6P4O3TsCk2lqYBeK4D9oCWM/mobilebasic)
- 한단어(단수 사용)
- 간단하고 명확한 이름(base, common, lib 등 피해야 함)
- 파일이름: 스네이크 네이밍 사용
- 폴더이름: 소문자 통일
- 리시버: 가능한 짧게하고 반드시 통일
- 에러: Err+__

## Defer
- [runutil](https://pkg.go.dev/github.com/thanos-io/thanos/pkg/runutil) 패키지 사용 -> 타노스에서 만든 util lib
- defer에 대한 에러도 잊지 말자
```go
func writeToFile(...) (err error) {
    f, err := os.Open(...)
    if err != nil {
        return err
    }
    // Now all is handled well.
    // func CloseWithErrCapture(err *error, closer io.Closer, format string, a ...interface{}){}
    defer runutil.CloseWithErrCapture(&err, f, "close file")

    // Write something to file...
    return nil
}
```
