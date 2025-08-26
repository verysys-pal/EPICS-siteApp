# ThresholdLogicController 문제 해결 가이드

## 목차
1. [일반적인 문제](#일반적인-문제)
2. [설치 및 빌드 문제](#설치-및-빌드-문제)
3. [IOC 시작 문제](#ioc-시작-문제)
4. [통신 및 연결 문제](#통신-및-연결-문제)
5. [성능 및 안정성 문제](#성능-및-안정성-문제)
6. [하드웨어 관련 문제](#하드웨어-관련-문제)
7. [디버깅 도구 및 기법](#디버깅-도구-및-기법)
8. [FAQ](#faq)

## 일반적인 문제

### 1. "Command ThresholdLogicConfig not found" 오류

#### 증상
```
epics> ThresholdLogicConfig("TEST_PORT", "DEVICE_PORT", 0)
Command ThresholdLogicConfig not found
```

#### 원인
- `thresholdLogicSupport.dbd` 파일이 빌드에 포함되지 않음
- `ThresholdLogicRegister()` 함수가 호출되지 않음
- DBD 파일이 올바르게 등록되지 않음

#### 해결 방법

1. **Makefile 확인**:
```makefile
# USB1608G_2AO_cppApp/src/Makefile에서
USB1608G_2AO_cpp_DBD += thresholdLogicSupport.dbd
```

2. **DBD 파일 내용 확인**:
```bash
cat USB1608G_2AO_cppApp/src/thresholdLogicSupport.dbd
```
다음 내용이 있어야 함:
```
registrar(ThresholdLogicRegister)
```

3. **메인 DBD 파일 확인**:
```bash
cat dbd/USB1608G_2AO_cpp.dbd | grep threshold
```

4. **재빌드**:
```bash
make clean
make
```

### 2. "PV connection timeout" 오류

#### 증상
```bash
caget USB1608G_2AO_cpp:ThresholdLogic1Enable
Channel connect timed out: 'USB1608G_2AO_cpp:ThresholdLogic1Enable' not found.
```

#### 원인
- IOC가 실행되지 않음
- 데이터베이스 템플릿이 로드되지 않음
- PV 이름이 잘못됨
- 네트워크 설정 문제

#### 해결 방법

1. **IOC 상태 확인**:
```bash
ps aux | grep USB1608G_2AO_cpp
```

2. **IOC에서 PV 목록 확인**:
```bash
# IOC 쉘에서
dbl | grep ThresholdLogic
```

3. **PV 이름 정확성 확인**:
```bash
# 올바른 형식: PREFIX:RECORD_NAME
# 예: USB1608G_2AO_cpp:ThresholdLogic1Enable
```

4. **네트워크 설정 확인**:
```bash
echo $EPICS_CA_ADDR_LIST
echo $EPICS_CA_AUTO_ADDR_LIST
```

### 3. 임계값 로직이 동작하지 않음

#### 증상
- 현재값이 임계값을 초과해도 출력 상태가 변경되지 않음
- 출력 상태가 항상 Low 또는 High로 고정됨

#### 원인
- ThresholdLogic이 비활성화 상태
- 하드웨어 연결 문제
- 드라이버 통신 오류
- 잘못된 임계값 설정

#### 해결 방법

1. **활성화 상태 확인**:
```bash
caget USB1608G_2AO_cpp:ThresholdLogic1Enable
# 결과가 1(Enabled)이어야 함
```

2. **현재값 모니터링**:
```bash
camonitor USB1608G_2AO_cpp:ThresholdLogic1CurrentValue
# 값이 실시간으로 변화하는지 확인
```

3. **임계값 설정 확인**:
```bash
caget USB1608G_2AO_cpp:ThresholdLogic1Threshold
caget USB1608G_2AO_cpp:ThresholdLogic1Hysteresis
```

4. **IOC 로그 확인**:
```bash
tail -f ioc.log | grep -i threshold
```

## 설치 및 빌드 문제

### 1. 컴파일 오류

#### "ThresholdLogicController.h: No such file or directory"

**원인**: 헤더 파일 경로 문제

**해결 방법**:
```makefile
# Makefile에서 인클루드 경로 확인
USR_INCLUDES += -I$(TOP)/USB1608G_2AO_cppApp/src
```

#### "undefined reference to ThresholdLogicConfig"

**원인**: 링킹 문제

**해결 방법**:
```makefile
# Makefile에서 소스 파일 추가 확인
USB1608G_2AO_cpp_SRCS += ThresholdLogicController.cpp
```

### 2. 의존성 문제

#### "asyn/asynPortDriver.h: No such file or directory"

**원인**: asyn 모듈 경로 설정 문제

**해결 방법**:
1. `configure/RELEASE` 파일 확인:
```makefile
ASYN=$(SUPPORT)/asyn-R4-44-2
```

2. asyn 모듈 설치 확인:
```bash
ls $(SUPPORT)/asyn-R4-44-2/include/
```

#### "measComp 관련 오류"

**원인**: measComp 모듈 의존성 문제

**해결 방법**:
```makefile
# configure/RELEASE에서
MEASCOMP=$(SUPPORT)/measComp-R4-2

# Makefile에서
USB1608G_2AO_cpp_LIBS += measComp
```

### 3. 빌드 시스템 문제

#### "make: *** No rule to make target"

**해결 방법**:
```bash
# 빌드 시스템 초기화
make clean uninstall
make distclean
make
```

## IOC 시작 문제

### 1. IOC 시작 실패

#### "Error loading shared library"

**원인**: 라이브러리 경로 문제

**해결 방법**:
```bash
# LD_LIBRARY_PATH 설정 확인
echo $LD_LIBRARY_PATH

# 필요시 경로 추가
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$EPICS_BASE/lib/$EPICS_HOST_ARCH
```

#### "Database load error"

**원인**: 데이터베이스 파일 문제

**해결 방법**:
1. 템플릿 파일 존재 확인:
```bash
ls db/threshold_logic.template
```

2. 치환 파일 문법 확인:
```bash
# 올바른 형식
dbLoadRecords("db/threshold_logic.template", "P=USB1608G_2AO_cpp:,R=ThresholdLogic1,PORT=THRESHOLD_LOGIC_PORT,ADDR=0")
```

### 2. 드라이버 초기화 실패

#### "ThresholdLogicController creation failed"

**원인**: 
- 장치 포트가 존재하지 않음
- 메모리 부족
- 매개변수 설정 오류

**해결 방법**:
1. 장치 포트 확인:
```bash
# IOC 쉘에서
asynReport 1
```

2. 메모리 사용량 확인:
```bash
free -h
```

3. 로그에서 상세 오류 확인:
```bash
grep -i error ioc.log
```

## 통신 및 연결 문제

### 1. asyn 포트 통신 오류

#### "asynManager:portConnect port not found"

**원인**: asyn 포트가 생성되지 않음

**해결 방법**:
1. 포트 생성 순서 확인:
```bash
# st.cmd에서 순서가 중요함
measCompConfig("USB1608G_2AO_cpp_PORT", "USB1608G-2AO", 0)  # 먼저
ThresholdLogicConfig("THRESHOLD_LOGIC_PORT", "USB1608G_2AO_cpp_PORT", 0)  # 나중
```

2. 포트 상태 확인:
```bash
# IOC 쉘에서
asynReport 1
```

### 2. 하드웨어 통신 문제

#### "Device communication timeout"

**원인**: 
- USB 연결 문제
- 장치 드라이버 문제
- 권한 문제

**해결 방법**:
1. USB 연결 확인:
```bash
lsusb | grep -i measurement
```

2. 장치 권한 확인:
```bash
ls -l /dev/usb*
```

3. udev 규칙 설정 (필요시):
```bash
# /etc/udev/rules.d/99-meascomp.rules
SUBSYSTEM=="usb", ATTR{idVendor}=="09db", MODE="0666"
```

### 3. Channel Access 네트워크 문제

#### "CA beacon anomaly"

**해결 방법**:
```bash
# 네트워크 인터페이스 확인
export EPICS_CA_AUTO_ADDR_LIST=YES
export EPICS_CA_ADDR_LIST=""

# 또는 특정 주소 설정
export EPICS_CA_ADDR_LIST="192.168.1.255"
```

## 성능 및 안정성 문제

### 1. 높은 CPU 사용률

#### 원인
- 업데이트 주기가 너무 높음
- 무한 루프 또는 데드락
- 메모리 누수

#### 해결 방법

1. **업데이트 주기 조정**:
```bash
# 현재 설정 확인
caget USB1608G_2AO_cpp:ThresholdLogic1UpdateRate

# 낮은 주기로 설정
caput USB1608G_2AO_cpp:ThresholdLogic1UpdateRate 1.0
```

2. **CPU 사용률 모니터링**:
```bash
top -p $(pgrep USB1608G_2AO_cpp)
```

3. **스레드 상태 확인**:
```bash
# IOC 쉘에서 스레드 정보 확인
epicsThreadShowAll
```

### 2. 메모리 누수

#### 진단 방법
```bash
# 메모리 사용량 모니터링
while true; do
    ps aux | grep USB1608G_2AO_cpp | grep -v grep
    sleep 10
done
```

#### 해결 방법
1. IOC 재시작
2. 업데이트 주기 조정
3. 불필요한 모니터링 중지

### 3. 응답 지연

#### 원인
- 네트워크 지연
- IOC 과부하
- 하드웨어 응답 지연

#### 해결 방법

1. **네트워크 지연 측정**:
```bash
# PV 응답 시간 측정
time caget USB1608G_2AO_cpp:ThresholdLogic1Enable
```

2. **IOC 부하 확인**:
```bash
# IOC 쉘에서
scanppl
```

3. **하드웨어 응답 확인**:
```bash
# asyn 추적 활성화
asynSetTraceMask("USB1608G_2AO_cpp_PORT", 0, 0x9)
```

## 하드웨어 관련 문제

### 1. USB 장치 인식 실패

#### 증상
```
measCompConfig: Device not found
```

#### 해결 방법

1. **USB 연결 확인**:
```bash
lsusb
# Measurement Computing Corp. 장치가 보여야 함
```

2. **드라이버 설치 확인**:
```bash
# uldaq 라이브러리 확인
ldconfig -p | grep uldaq
```

3. **권한 설정**:
```bash
# 현재 사용자를 dialout 그룹에 추가
sudo usermod -a -G dialout $USER
```

### 2. 측정값 이상

#### 증상
- 현재값이 예상 범위를 벗어남
- 값이 변화하지 않음
- 노이즈가 심함

#### 해결 방법

1. **하드웨어 연결 확인**:
   - 센서 연결 상태
   - 접지 연결
   - 케이블 상태

2. **캘리브레이션 확인**:
```bash
# IOC 쉘에서 원시 값 확인
dbpr USB1608G_2AO_cpp:Ai0 4
```

3. **필터링 설정**:
```bash
# 데이터베이스에서 평균화 설정
# SMOO 필드 사용
```

### 3. 출력 제어 실패

#### 증상
- 출력 상태가 변경되지 않음
- 하드웨어 출력이 동작하지 않음

#### 해결 방법

1. **출력 핀 연결 확인**
2. **출력 전압/전류 사양 확인**
3. **부하 임피던스 확인**

## 디버깅 도구 및 기법

### 1. asyn 추적 활성화

#### 기본 추적
```bash
# IOC 쉘에서
asynSetTraceMask("THRESHOLD_LOGIC_PORT", 0, 0x9)
asynSetTraceIOMask("THRESHOLD_LOGIC_PORT", 0, 0x2)
```

#### 상세 추적
```bash
# 모든 추적 활성화
asynSetTraceMask("THRESHOLD_LOGIC_PORT", 0, 0xFF)
asynSetTraceIOMask("THRESHOLD_LOGIC_PORT", 0, 0xFF)
```

#### 추적 비활성화
```bash
asynSetTraceMask("THRESHOLD_LOGIC_PORT", 0, 0x0)
asynSetTraceIOMask("THRESHOLD_LOGIC_PORT", 0, 0x0)
```

### 2. 로그 분석

#### 실시간 로그 모니터링
```bash
# 오류만 필터링
tail -f ioc.log | grep -i error

# ThresholdLogic 관련만 필터링
tail -f ioc.log | grep -i threshold

# 특정 시간대 로그 확인
grep "2025-08-20 10:" ioc.log
```

#### 로그 레벨별 분석
```bash
# 경고 및 오류
grep -E "(WARNING|ERROR)" ioc.log

# 통신 관련
grep -i "communication\|timeout\|connect" ioc.log
```

### 3. 성능 모니터링

#### IOC 성능 확인
```bash
# IOC 쉘에서
scanppl          # 스캔 성능
epicsThreadShowAll  # 스레드 상태
```

#### 시스템 리소스 모니터링
```bash
# CPU 및 메모리 사용률
htop -p $(pgrep USB1608G_2AO_cpp)

# 네트워크 트래픽
netstat -i
```

### 4. 데이터베이스 디버깅

#### 레코드 상태 확인
```bash
# IOC 쉘에서
dbpr USB1608G_2AO_cpp:ThresholdLogic1Enable 4
dbpr USB1608G_2AO_cpp:ThresholdLogic1CurrentValue 4
```

#### 레코드 처리 추적
```bash
# 특정 레코드의 처리 추적
dbpf USB1608G_2AO_cpp:ThresholdLogic1Enable.TPRO 1
```

## FAQ

### Q1: ThresholdLogic이 활성화되지 않습니다.

**A**: 다음 사항들을 확인하세요:
1. 장치 포트가 올바르게 연결되었는지 확인
2. 필수 매개변수(임계값, 히스테리시스)가 설정되었는지 확인
3. IOC 로그에서 오류 메시지 확인
4. asyn 포트 상태 확인 (`asynReport 1`)

### Q2: 현재값이 업데이트되지 않습니다.

**A**: 
1. 하드웨어 연결 상태 확인
2. 장치 드라이버가 올바르게 초기화되었는지 확인
3. asyn 추적을 활성화하여 통신 상태 확인
4. 센서 전원 및 신호 연결 확인

### Q3: 출력 상태가 변경되지 않습니다.

**A**:
1. 임계값과 현재값을 비교하여 로직이 올바른지 확인
2. 히스테리시스 설정이 적절한지 확인
3. 출력 하드웨어 연결 상태 확인
4. ThresholdLogic이 활성화되어 있는지 확인

### Q4: IOC가 자주 크래시됩니다.

**A**:
1. 메모리 사용량 확인 및 메모리 누수 점검
2. 업데이트 주기를 낮춰서 CPU 부하 감소
3. 하드웨어 연결 상태 확인
4. EPICS Base 및 드라이버 버전 호환성 확인

### Q5: 다중 컨트롤러 설정 시 충돌이 발생합니다.

**A**:
1. 각 컨트롤러마다 고유한 포트 이름 사용
2. 서로 다른 장치 주소 할당
3. PV 이름 중복 방지 (R 매크로 다르게 설정)
4. 리소스 사용량 확인

### Q6: 성능이 느립니다.

**A**:
1. 업데이트 주기 최적화 (필요 이상으로 높지 않게)
2. 불필요한 모니터링 중지
3. 네트워크 설정 최적화
4. IOC 시스템 리소스 확인

### Q7: 알람이 제대로 동작하지 않습니다.

**A**:
1. 데이터베이스 템플릿의 알람 설정 확인
2. 알람 임계값이 올바르게 설정되었는지 확인
3. 알람 심각도 설정 확인
4. Channel Access 클라이언트의 알람 처리 확인

### Q8: 설정이 저장되지 않습니다.

**A**:
1. `auto_settings.req` 파일에 해당 PV가 포함되었는지 확인
2. autosave 모듈이 올바르게 설정되었는지 확인
3. 저장 디렉토리 권한 확인
4. `create_monitor_set` 명령어가 실행되었는지 확인

이 문제 해결 가이드를 통해 ThresholdLogicController 사용 중 발생할 수 있는 대부분의 문제를 해결할 수 있습니다. 추가적인 문제가 발생하면 IOC 로그와 asyn 추적 정보를 수집하여 기술 지원팀에 문의하시기 바랍니다.