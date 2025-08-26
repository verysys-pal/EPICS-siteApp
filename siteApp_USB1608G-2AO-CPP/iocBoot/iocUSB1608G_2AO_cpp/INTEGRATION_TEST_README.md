# ThresholdLogic 통합 테스트 가이드

## 개요

이 문서는 ThresholdLogicController의 통합 테스트 수행 방법을 설명합니다. 통합 테스트는 실제 IOC 환경에서 ThresholdLogicController의 동작을 검증하고, EPICS 레코드와 드라이버 간 통신을 테스트하며, Channel Access 클라이언트를 통한 원격 제어를 확인합니다.

## 테스트 구성 요소

### 1. 테스트 스크립트

- **`integration_test.cmd`**: 통합 테스트용 IOC 시작 스크립트
- **`ca_integration_test.sh`**: Channel Access 클라이언트 테스트 스크립트
- **`record_driver_test.py`**: Python을 사용한 자동화된 레코드-드라이버 통신 테스트
- **`run_integration_tests.sh`**: 모든 통합 테스트를 실행하는 메인 스크립트

### 2. 테스트 범위

#### 2.1 IOC 환경 테스트
- ThresholdLogicController 초기화 검증
- EPICS 데이터베이스 로딩 확인
- 포트 드라이버 상태 검증

#### 2.2 레코드-드라이버 통신 테스트
- 매개변수 읽기/쓰기 동작 확인
- 실시간 데이터 업데이트 검증
- 콜백 메커니즘 테스트

#### 2.3 Channel Access 원격 제어 테스트
- PV 연결 상태 확인
- 원격 매개변수 설정 테스트
- 실시간 모니터링 기능 검증

## 테스트 실행 방법

### 1. 전체 통합 테스트 실행

```bash
cd iocBoot/iocUSB1608G_2AO_cpp
./run_integration_tests.sh
```

이 스크립트는 다음 작업을 자동으로 수행합니다:
- IOC 상태 확인 및 필요시 시작
- Channel Access 기본 테스트 실행
- Python 자동화 테스트 실행
- 성능 및 안정성 테스트 실행
- 테스트 결과 요약 출력

### 2. 개별 테스트 실행

#### 2.1 IOC 시작 (테스트용)
```bash
./integration_test.cmd
```

#### 2.2 Channel Access 테스트
```bash
./ca_integration_test.sh
```

#### 2.3 Python 자동화 테스트
```bash
python3 record_driver_test.py
```

## 테스트 시나리오

### 1. 기본 기능 테스트

#### 1.1 ThresholdLogic 활성화
```bash
caput USB1608G_2AO_cpp:ThresholdLogic1Enable 1
caget USB1608G_2AO_cpp:ThresholdLogic1Enable
```

#### 1.2 임계값 설정
```bash
caput USB1608G_2AO_cpp:ThresholdLogic1Threshold 2.5
caget USB1608G_2AO_cpp:ThresholdLogic1Threshold
```

#### 1.3 히스테리시스 설정
```bash
caput USB1608G_2AO_cpp:ThresholdLogic1Hysteresis 0.1
caget USB1608G_2AO_cpp:ThresholdLogic1Hysteresis
```

### 2. 실시간 모니터링 테스트

#### 2.1 현재값 모니터링
```bash
camonitor USB1608G_2AO_cpp:ThresholdLogic1CurrentValue
```

#### 2.2 출력 상태 모니터링
```bash
camonitor USB1608G_2AO_cpp:ThresholdLogic1OutputState
```

### 3. 다중 컨트롤러 테스트

```bash
# ThresholdLogic1 설정
caput USB1608G_2AO_cpp:ThresholdLogic1Enable 1
caput USB1608G_2AO_cpp:ThresholdLogic1Threshold 2.0

# ThresholdLogic2 설정
caput USB1608G_2AO_cpp:ThresholdLogic2Enable 1
caput USB1608G_2AO_cpp:ThresholdLogic2Threshold 3.0

# 상태 확인
caget USB1608G_2AO_cpp:ThresholdLogic1*
caget USB1608G_2AO_cpp:ThresholdLogic2*
```

## 예상 테스트 결과

### 1. 성공적인 테스트 출력 예시

```
=== ThresholdLogic 통합 테스트 실행 ===
[INFO] IOC 프로세스 확인 중...
[INFO] IOC가 실행 중입니다.

테스트 1: Channel Access 기본 테스트
=== Channel Access 통합 테스트 시작 ===
1. Channel Access 연결 테스트
   ✓ Channel Access 연결 성공
2. ThresholdLogic 제어 테스트
   2.1 임계값 설정 테스트
   설정된 임계값: 3.0
   2.2 히스테리시스 설정 테스트
   설정된 히스테리시스: 0.2
   2.3 활성화 상태 제어 테스트
   활성화 상태: 1
[INFO] Channel Access 테스트 성공

테스트 2: Python 자동화 테스트
=== PV 연결 테스트 ===
[PASS] PV 연결: ThresholdLogic1Enable: PV: USB1608G_2AO_cpp:ThresholdLogic1Enable
[PASS] PV 연결: ThresholdLogic1Threshold: PV: USB1608G_2AO_cpp:ThresholdLogic1Threshold
=== 테스트 결과 요약 ===
총 테스트: 15
통과: 15
실패: 0
성공률: 100.0%
모든 테스트가 성공했습니다! ✓
[INFO] Python 자동화 테스트 성공

[INFO] === 통합 테스트 결과 요약 ===
[INFO] 총 테스트: 3
[INFO] 통과: 3
[INFO] 실패: 0
[INFO] 모든 통합 테스트가 성공했습니다! ✓
```

### 2. 테스트 실패 시 문제 해결

#### 2.1 IOC 연결 실패
```
[ERROR] Channel Access 연결에 실패했습니다. IOC가 실행 중인지 확인하세요.
```
**해결 방법**: IOC가 실행 중인지 확인하고, 필요시 재시작

#### 2.2 PV 연결 실패
```
[FAIL] PV 연결: ThresholdLogic1Enable: PV: USB1608G_2AO_cpp:ThresholdLogic1Enable
```
**해결 방법**: 
- 데이터베이스 템플릿이 올바르게 로드되었는지 확인
- PV 이름이 정확한지 확인
- IOC 로그에서 오류 메시지 확인

#### 2.3 드라이버 통신 실패
```
[FAIL] 임계값 설정: 설정값: 2.5, 읽은값: None
```
**해결 방법**:
- ThresholdLogicController 드라이버가 올바르게 초기화되었는지 확인
- asyn 포트 연결 상태 확인
- 드라이버 로그에서 오류 메시지 확인

## 성능 기준

### 1. 응답 시간
- PV 읽기/쓰기: < 100ms
- 실시간 업데이트: < 1초

### 2. 안정성
- 연속 동작 오류율: < 1%
- 메모리 누수: 없음

### 3. 동시성
- 다중 클라이언트 지원: 최소 10개
- 동시 PV 액세스: 문제없음

## 문제 해결 가이드

### 1. 일반적인 문제

#### 1.1 "Command not found" 오류
EPICS 환경 변수가 설정되지 않은 경우:
```bash
source /usr/local/epics/EPICS_R7.0/base/bin/linux-x86_64/epicsEnv.sh
```

#### 1.2 Python 모듈 누락
```bash
pip install pyepics
```

#### 1.3 권한 문제
```bash
chmod +x *.sh
chmod +x *.py
```

### 2. 디버깅 도구

#### 2.1 IOC 로그 확인
```bash
tail -f integration_test.log
```

#### 2.2 asyn 포트 상태 확인
IOC 쉘에서:
```
asynReport 1
```

#### 2.3 데이터베이스 레코드 확인
IOC 쉘에서:
```
dbl
dbpr USB1608G_2AO_cpp:ThresholdLogic1Enable
```

## 테스트 확장

### 1. 추가 테스트 시나리오
- 장시간 안정성 테스트
- 부하 테스트 (다중 클라이언트)
- 오류 복구 테스트

### 2. 자동화 개선
- CI/CD 파이프라인 통합
- 테스트 결과 리포팅
- 성능 메트릭 수집

이 통합 테스트 가이드를 통해 ThresholdLogicController의 모든 기능이 실제 환경에서 올바르게 동작하는지 체계적으로 검증할 수 있습니다.