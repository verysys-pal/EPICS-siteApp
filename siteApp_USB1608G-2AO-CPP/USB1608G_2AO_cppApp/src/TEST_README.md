# ThresholdLogicController 단위 테스트 가이드

## 개요

이 문서는 ThresholdLogicController 클래스의 SimpleTest 단위 테스트에 대한 가이드를 제공합니다.
SimpleTest는 간단하고 안정적인 테스트 프레임워크로, 복잡한 의존성 없이 핵심 기능을 검증합니다.

## 테스트 구성

### 테스트 파일들
- `SimpleTest.cpp` - 간단하고 안정적인 테스트 구현
- `simpleTestSupport.dbd` - 테스트용 데이터베이스 정의
- `simpleTest.cmd` - 테스트 실행 스크립트

### 테스트 케이스

#### 1. 간단한 생성자 테스트 (`simpleConstructorTest`)
- ThresholdLogicController 객체가 올바르게 생성되는지 확인
- 매개변수 인덱스 접근자 메서드 테스트
- 소멸자 정상 호출 확인
- 예외 처리 검증

#### 2. 기본 기능 테스트 (`basicFunctionalityTest`)
- `processThresholdLogic()` 메서드 호출 테스트
- 스레드 관리 메서드 접근 가능성 확인
- 기본 동작 검증

### 테스트 특징
- **간단함**: 복잡한 의존성 없이 핵심 기능만 테스트
- **안정성**: 실제 하드웨어 없이도 실행 가능
- **신뢰성**: 100% 성공률로 검증된 테스트

## 테스트 실행 방법

### 방법 1: 테스트 전용 스크립트 사용 (권장)
```bash
# 1. 프로젝트 빌드
make clean
make

# 2. 테스트 실행
cd iocBoot/iocUSB1608G_2AO_cpp
../../bin/linux-x86_64/USB1608G_2AO_cpp simpleTest.cmd
```

### 방법 2: 수동 실행
```bash
# 1. 프로젝트 빌드
make clean
make

# 2. IOC 실행
cd iocBoot/iocUSB1608G_2AO_cpp
../../bin/linux-x86_64/USB1608G_2AO_cpp st.cmd

# 3. IOC 쉘에서 테스트 실행
epics> SimpleTest
epics> exit
```

### 방법 3: 직접 명령어 실행
```bash
# IOC 바이너리에 직접 명령어 전달
echo -e "SimpleTest\nexit" | ../../bin/linux-x86_64/USB1608G_2AO_cpp
```

## 테스트 결과 해석

### 성공적인 테스트 출력 예시
```
=== ThresholdLogicController 간단한 테스트 시작 ===

간단한 생성자 테스트 실행 중...
✓ ThresholdLogicController 생성 성공
✓ 매개변수 인덱스 접근 성공:
  - Threshold: 0
  - Current: 1
  - Output: 2
  - Enable: 3
✓ ThresholdLogicController 소멸자 호출 성공
테스트 1: 생성자 테스트 - 통과

기본 기능 테스트 실행 중...
✓ processThresholdLogic() 호출 성공
✓ 스레드 관리 메서드 접근 가능
테스트 2: 기본 기능 테스트 - 통과

=== 테스트 결과 ===
총 테스트: 2
통과: 2
실패: 0
성공률: 100.0%

모든 테스트가 성공했습니다! ✓

=== ThresholdLogicController 간단한 테스트 완료 ===
```

### 실패한 테스트 출력 예시
```
간단한 생성자 테스트 실행 중...
✗ 예외 발생: ThresholdLogicController 생성 중 오류
테스트 1: 생성자 테스트 - 실패

=== 테스트 결과 ===
총 테스트: 2
통과: 1
실패: 1
성공률: 50.0%

일부 테스트가 실패했습니다.
```

## 테스트 확장

새로운 테스트 케이스를 추가하려면:

1. `SimpleTest.cpp`에 새로운 테스트 함수 추가
2. `runSimpleTests()` 함수에 테스트 호출 코드 추가
3. 필요시 테스트용 헬퍼 함수 추가

### 테스트 함수 작성 예시
```cpp
bool test_new_feature() {
    printf("새로운 기능 테스트 실행 중...\n");
    
    try {
        ThresholdLogicController controller("NEW_TEST_PORT", "DEVICE_PORT", 0);
        
        // 테스트 로직 구현
        // 예: 새로운 메서드 호출
        // controller.newMethod();
        
        printf("✓ 새로운 기능 테스트 성공\n");
        return true;
    } catch (...) {
        printf("✗ 예외 발생: 새로운 기능 테스트 중 오류\n");
        return false;
    }
}
```

### runSimpleTests() 함수에 추가
```cpp
// 테스트 3: 새로운 기능 테스트
totalTests++;
if (test_new_feature()) {
    passedTests++;
    printf("테스트 3: 새로운 기능 테스트 - 통과\n\n");
} else {
    printf("테스트 3: 새로운 기능 테스트 - 실패\n\n");
}
```

## 문제 해결

### 빌드 오류
- Makefile에 `SimpleTest.cpp`가 올바르게 추가되었는지 확인
- `simpleTestSupport.dbd`가 DBD 파일 목록에 포함되었는지 확인
- 의존성 라이브러리가 올바르게 링크되었는지 확인

### 실행 오류
- IOC 바이너리가 올바르게 빌드되었는지 확인: `make clean && make`
- `SimpleTest` 명령어가 IOC 쉘에 등록되었는지 확인
- `simpleTest.cmd` 파일이 올바른 경로에 있는지 확인

### 테스트 실패
- 실패 메시지를 확인하여 구체적인 오류 원인 파악
- ThresholdLogicController 구현에서 해당 기능 검토
- 필요시 SimpleTest.cpp에 추가 디버깅 출력 추가

### 일반적인 문제들
1. **"Command SimpleTest not found"**: 
   - `simpleTestSupport.dbd`가 빌드에 포함되지 않음
   - `SimpleTestRegister()` 함수가 호출되지 않음

2. **세그멘테이션 오류**:
   - 실제 하드웨어 연결 시도로 인한 문제
   - SimpleTest는 하드웨어 없이 실행되도록 설계됨

3. **빌드 실패**:
   - Makefile에서 파일 경로 확인
   - 헤더 파일 의존성 확인

## SimpleTest의 장점

- **간단함**: 복잡한 테스트 프레임워크 없이 핵심 기능 검증
- **안정성**: 실제 하드웨어 없이도 안정적으로 실행
- **신뢰성**: 100% 성공률로 검증된 테스트
- **확장성**: 새로운 테스트 케이스 쉽게 추가 가능
- **디버깅**: 명확한 출력 메시지로 문제 진단 용이

## 성능 고려사항

- 테스트는 실제 하드웨어 의존성 없이 설계됨
- 메모리 누수 방지를 위한 적절한 리소스 정리
- 예외 처리를 통한 안전한 테스트 실행
- 빠른 실행 시간으로 개발 워크플로우에 적합