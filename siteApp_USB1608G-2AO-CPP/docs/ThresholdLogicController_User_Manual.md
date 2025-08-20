# ThresholdLogicController 사용자 매뉴얼

## 목차
1. [개요](#개요)
2. [설치 가이드](#설치-가이드)
3. [기본 사용법](#기본-사용법)
4. [고급 설정](#고급-설정)
5. [모니터링 및 제어](#모니터링-및-제어)
6. [예제 구성](#예제-구성)
7. [문제 해결](#문제-해결)

## 개요

ThresholdLogicController는 EPICS IOC 환경에서 아날로그 입력 값을 실시간으로 모니터링하고, 설정된 임계값과 비교하여 디지털 출력을 자동으로 제어하는 드라이버입니다.

### 주요 기능
- **실시간 임계값 비교**: 아날로그 입력을 지속적으로 모니터링
- **히스테리시스 지원**: 출력 진동 방지를 위한 히스테리시스 기능
- **다중 컨트롤러**: 여러 개의 독립적인 임계값 로직 컨트롤러 지원
- **EPICS 통합**: Channel Access를 통한 원격 제어 및 모니터링
- **실시간 알람**: 상태 변화 및 오류에 대한 즉각적인 알림

### 시스템 요구사항
- EPICS Base R7.0 이상
- Linux x86_64 운영체제
- USB1608G-2AO 하드웨어 (또는 호환 장치)
- measComp 드라이버 모듈

## 설치 가이드

### 1. 전제 조건 확인

#### EPICS Base 설치 확인
```bash
echo $EPICS_BASE
# 출력 예시: /usr/local/epics/EPICS_R7.0/base
```

#### 필요한 synApps 모듈 확인
```bash
ls $SUPPORT
# 다음 모듈들이 있어야 함:
# - asyn-R4-44-2
# - measComp-R4-2
# - autosave-R5-11
```

### 2. 프로젝트 빌드

#### 소스 코드 준비
```bash
cd /path/to/USB1608G_2AO_cpp
```

#### 의존성 설정 확인
`configure/RELEASE` 파일에서 다음 경로들이 올바르게 설정되어 있는지 확인:
```makefile
SUPPORT=/usr/local/epics/synApps/support
ASYN=$(SUPPORT)/asyn-R4-44-2
CALC=$(SUPPORT)/calc-R3-7-5
MEASCOMP=$(SUPPORT)/measComp-R4-2
AUTOSAVE=$(SUPPORT)/autosave-R5-11
EPICS_BASE=/usr/local/epics/EPICS_R7.0/base
```

#### 빌드 실행
```bash
make clean uninstall
make
```

#### 빌드 성공 확인
```bash
ls bin/linux-x86_64/
# USB1608G_2AO_cpp 실행 파일이 생성되어야 함

ls lib/linux-x86_64/
# 필요한 라이브러리 파일들이 생성되어야 함
```

### 3. IOC 구성

#### 시작 스크립트 설정
`iocBoot/iocUSB1608G_2AO_cpp/st.cmd` 파일에서 ThresholdLogic 설정 확인:
```bash
# ThresholdLogic 컨트롤러 설정
ThresholdLogicConfig("THRESHOLD_LOGIC_PORT", "USB1608G_2AO_cpp_PORT", 0)

# 데이터베이스 로드
dbLoadRecords("db/threshold_logic.template", "P=USB1608G_2AO_cpp:,R=ThresholdLogic1,PORT=THRESHOLD_LOGIC_PORT,ADDR=0")
```

#### 자동 저장 설정
`auto_settings.req` 파일에 ThresholdLogic 설정 추가:
```
USB1608G_2AO_cpp:ThresholdLogic1Threshold
USB1608G_2AO_cpp:ThresholdLogic1Hysteresis
USB1608G_2AO_cpp:ThresholdLogic1Enable
USB1608G_2AO_cpp:ThresholdLogic1UpdateRate
```

## 기본 사용법

### 1. IOC 시작

```bash
cd iocBoot/iocUSB1608G_2AO_cpp
../../bin/linux-x86_64/USB1608G_2AO_cpp st.cmd
```

성공적인 시작 시 다음과 같은 메시지가 출력됩니다:
```
ThresholdLogicController::ThresholdLogicController: 포트=THRESHOLD_LOGIC_PORT, 장치포트=USB1608G_2AO_cpp_PORT, 주소=0로 ThresholdLogicController 생성됨
```

### 2. 기본 설정

#### 임계값 설정
```bash
caput USB1608G_2AO_cpp:ThresholdLogic1Threshold 2.5
```

#### 히스테리시스 설정
```bash
caput USB1608G_2AO_cpp:ThresholdLogic1Hysteresis 0.1
```

#### 컨트롤러 활성화
```bash
caput USB1608G_2AO_cpp:ThresholdLogic1Enable 1
```

### 3. 상태 모니터링

#### 현재 값 확인
```bash
caget USB1608G_2AO_cpp:ThresholdLogic1CurrentValue
```

#### 출력 상태 확인
```bash
caget USB1608G_2AO_cpp:ThresholdLogic1OutputState
```

#### 실시간 모니터링
```bash
camonitor USB1608G_2AO_cpp:ThresholdLogic1CurrentValue USB1608G_2AO_cpp:ThresholdLogic1OutputState
```

## 고급 설정

### 1. 업데이트 주기 조정

기본 업데이트 주기는 10Hz입니다. 필요에 따라 조정할 수 있습니다:

```bash
# 1Hz로 설정 (느린 신호용)
caput USB1608G_2AO_cpp:ThresholdLogic1UpdateRate 1.0

# 100Hz로 설정 (빠른 신호용)
caput USB1608G_2AO_cpp:ThresholdLogic1UpdateRate 100.0
```

**주의사항**: 
- 최소값: 0.1Hz
- 최대값: 1000Hz
- 높은 주기는 CPU 사용률을 증가시킬 수 있습니다

### 2. 다중 컨트롤러 설정

여러 개의 ThresholdLogic 컨트롤러를 동시에 사용할 수 있습니다:

#### st.cmd에서 다중 컨트롤러 설정
```bash
# 첫 번째 컨트롤러
ThresholdLogicConfig("THRESHOLD_LOGIC_PORT1", "USB1608G_2AO_cpp_PORT", 0)
dbLoadRecords("db/threshold_logic.template", "P=USB1608G_2AO_cpp:,R=ThresholdLogic1,PORT=THRESHOLD_LOGIC_PORT1,ADDR=0")

# 두 번째 컨트롤러
ThresholdLogicConfig("THRESHOLD_LOGIC_PORT2", "USB1608G_2AO_cpp_PORT", 1)
dbLoadRecords("db/threshold_logic.template", "P=USB1608G_2AO_cpp:,R=ThresholdLogic2,PORT=THRESHOLD_LOGIC_PORT2,ADDR=1")
```

#### 각 컨트롤러 독립 설정
```bash
# ThresholdLogic1 설정
caput USB1608G_2AO_cpp:ThresholdLogic1Threshold 2.0
caput USB1608G_2AO_cpp:ThresholdLogic1Enable 1

# ThresholdLogic2 설정
caput USB1608G_2AO_cpp:ThresholdLogic2Threshold 3.5
caput USB1608G_2AO_cpp:ThresholdLogic2Enable 1
```

### 3. 알람 설정

#### 입력 값 범위 알람
데이터베이스 템플릿에서 알람 임계값을 설정할 수 있습니다:
```
# 높은 값 알람
HIHI=9.0    # 주요 알람 (MAJOR)
HIGH=8.0    # 경고 알람 (MINOR)

# 낮은 값 알람  
LOW=-8.0    # 경고 알람 (MINOR)
LOLO=-9.0   # 주요 알람 (MAJOR)
```

#### 알람 상태 모니터링
```bash
camonitor USB1608G_2AO_cpp:ThresholdLogic1CurrentValue.SEVR
```

## 모니터링 및 제어

### 1. 웹 기반 모니터링

#### CSS/Phoebus를 사용한 GUI
CSS 또는 Phoebus에서 다음 PV들을 모니터링할 수 있습니다:

**입력 매개변수**:
- `USB1608G_2AO_cpp:ThresholdLogic1Threshold` - 임계값 설정
- `USB1608G_2AO_cpp:ThresholdLogic1Hysteresis` - 히스테리시스 설정
- `USB1608G_2AO_cpp:ThresholdLogic1Enable` - 활성화 제어
- `USB1608G_2AO_cpp:ThresholdLogic1UpdateRate` - 업데이트 주기

**출력 매개변수**:
- `USB1608G_2AO_cpp:ThresholdLogic1CurrentValue` - 현재 입력 값
- `USB1608G_2AO_cpp:ThresholdLogic1OutputState` - 출력 상태
- `USB1608G_2AO_cpp:ThresholdLogic1AlarmState` - 알람 상태

### 2. 스크립트를 통한 자동화

#### Python을 사용한 자동 제어
```python
import epics
import time

# PV 연결
threshold_pv = epics.PV('USB1608G_2AO_cpp:ThresholdLogic1Threshold')
current_pv = epics.PV('USB1608G_2AO_cpp:ThresholdLogic1CurrentValue')
output_pv = epics.PV('USB1608G_2AO_cpp:ThresholdLogic1OutputState')
enable_pv = epics.PV('USB1608G_2AO_cpp:ThresholdLogic1Enable')

# 임계값 설정
threshold_pv.put(2.5)
enable_pv.put(1)

# 상태 모니터링
while True:
    current_val = current_pv.get()
    output_state = output_pv.get()
    print(f"현재값: {current_val:.3f}V, 출력: {'High' if output_state else 'Low'}")
    time.sleep(1)
```

#### Bash 스크립트를 사용한 배치 설정
```bash
#!/bin/bash
# threshold_setup.sh

echo "ThresholdLogic 컨트롤러 설정 중..."

# 기본 설정
caput USB1608G_2AO_cpp:ThresholdLogic1Threshold 2.5
caput USB1608G_2AO_cpp:ThresholdLogic1Hysteresis 0.1
caput USB1608G_2AO_cpp:ThresholdLogic1UpdateRate 10.0

# 활성화
caput USB1608G_2AO_cpp:ThresholdLogic1Enable 1

echo "설정 완료!"

# 상태 확인
echo "현재 설정:"
caget USB1608G_2AO_cpp:ThresholdLogic1Threshold
caget USB1608G_2AO_cpp:ThresholdLogic1Hysteresis
caget USB1608G_2AO_cpp:ThresholdLogic1Enable
```

### 3. 로그 모니터링

#### IOC 로그 확인
```bash
tail -f /path/to/ioc.log
```

#### asyn 디버깅
IOC 쉘에서 디버깅 레벨 설정:
```
asynSetTraceMask("THRESHOLD_LOGIC_PORT", 0, 0x9)
asynSetTraceIOMask("THRESHOLD_LOGIC_PORT", 0, 0x2)
```

## 예제 구성

### 1. 온도 모니터링 시스템

#### 시나리오
온도 센서의 출력을 모니터링하여 25°C를 초과하면 냉각 팬을 작동시키는 시스템

#### 설정
```bash
# 임계값: 25°C (2.5V, 10V/100°C 센서 가정)
caput USB1608G_2AO_cpp:ThresholdLogic1Threshold 2.5

# 히스테리시스: 1°C (0.1V)
caput USB1608G_2AO_cpp:ThresholdLogic1Hysteresis 0.1

# 빠른 응답을 위한 높은 업데이트 주기
caput USB1608G_2AO_cpp:ThresholdLogic1UpdateRate 50.0

# 활성화
caput USB1608G_2AO_cpp:ThresholdLogic1Enable 1
```

#### 모니터링
```bash
# 실시간 온도 및 팬 상태 모니터링
camonitor USB1608G_2AO_cpp:ThresholdLogic1CurrentValue USB1608G_2AO_cpp:ThresholdLogic1OutputState
```

### 2. 압력 안전 시스템

#### 시나리오
압력 센서를 모니터링하여 안전 압력을 초과하면 안전 밸브를 작동시키는 시스템

#### 설정
```bash
# 임계값: 80% 압력 (4.0V, 5V 만압 센서 가정)
caput USB1608G_2AO_cpp:ThresholdLogic1Threshold 4.0

# 작은 히스테리시스: 2% (0.1V)
caput USB1608G_2AO_cpp:ThresholdLogic1Hysteresis 0.1

# 안전을 위한 높은 업데이트 주기
caput USB1608G_2AO_cpp:ThresholdLogic1UpdateRate 100.0

# 활성화
caput USB1608G_2AO_cpp:ThresholdLogic1Enable 1
```

#### 알람 설정
```bash
# 압력 센서에 알람 설정 (데이터베이스 템플릿에서)
# HIGH=4.5V (90% 압력에서 경고)
# HIHI=4.8V (96% 압력에서 주요 알람)
```

### 3. 다중 채널 모니터링

#### 시나리오
4개의 센서를 동시에 모니터링하는 시스템

#### st.cmd 설정
```bash
# 4개의 ThresholdLogic 컨트롤러 생성
ThresholdLogicConfig("THRESHOLD_LOGIC_PORT1", "USB1608G_2AO_cpp_PORT", 0)
ThresholdLogicConfig("THRESHOLD_LOGIC_PORT2", "USB1608G_2AO_cpp_PORT", 1)
ThresholdLogicConfig("THRESHOLD_LOGIC_PORT3", "USB1608G_2AO_cpp_PORT", 2)
ThresholdLogicConfig("THRESHOLD_LOGIC_PORT4", "USB1608G_2AO_cpp_PORT", 3)

# 각각에 대한 데이터베이스 로드
dbLoadRecords("db/threshold_logic.template", "P=USB1608G_2AO_cpp:,R=ThresholdLogic1,PORT=THRESHOLD_LOGIC_PORT1,ADDR=0")
dbLoadRecords("db/threshold_logic.template", "P=USB1608G_2AO_cpp:,R=ThresholdLogic2,PORT=THRESHOLD_LOGIC_PORT2,ADDR=1")
dbLoadRecords("db/threshold_logic.template", "P=USB1608G_2AO_cpp:,R=ThresholdLogic3,PORT=THRESHOLD_LOGIC_PORT3,ADDR=2")
dbLoadRecords("db/threshold_logic.template", "P=USB1608G_2AO_cpp:,R=ThresholdLogic4,PORT=THRESHOLD_LOGIC_PORT4,ADDR=3")
```

#### 배치 설정 스크립트
```bash
#!/bin/bash
# multi_channel_setup.sh

echo "다중 채널 ThresholdLogic 설정 중..."

# 각 채널별 다른 임계값 설정
caput USB1608G_2AO_cpp:ThresholdLogic1Threshold 2.0  # 채널 1: 2.0V
caput USB1608G_2AO_cpp:ThresholdLogic2Threshold 2.5  # 채널 2: 2.5V
caput USB1608G_2AO_cpp:ThresholdLogic3Threshold 3.0  # 채널 3: 3.0V
caput USB1608G_2AO_cpp:ThresholdLogic4Threshold 3.5  # 채널 4: 3.5V

# 모든 채널 동일한 히스테리시스
for i in {1..4}; do
    caput USB1608G_2AO_cpp:ThresholdLogic${i}Hysteresis 0.1
    caput USB1608G_2AO_cpp:ThresholdLogic${i}UpdateRate 10.0
    caput USB1608G_2AO_cpp:ThresholdLogic${i}Enable 1
done

echo "설정 완료!"

# 모든 채널 상태 확인
echo "현재 상태:"
for i in {1..4}; do
    echo "채널 $i:"
    caget USB1608G_2AO_cpp:ThresholdLogic${i}CurrentValue
    caget USB1608G_2AO_cpp:ThresholdLogic${i}OutputState
done
```

## 문제 해결

### 1. 일반적인 문제

#### IOC 시작 실패
**증상**: IOC가 시작되지 않거나 오류 메시지 출력
**해결 방법**:
1. EPICS 환경 변수 확인:
   ```bash
   echo $EPICS_BASE
   echo $EPICS_HOST_ARCH
   ```
2. 의존성 모듈 경로 확인:
   ```bash
   cat configure/RELEASE
   ```
3. 빌드 상태 확인:
   ```bash
   make clean
   make
   ```

#### PV 연결 실패
**증상**: `Channel connect timed out` 또는 `Channel never connected`
**해결 방법**:
1. IOC가 실행 중인지 확인
2. PV 이름이 정확한지 확인:
   ```bash
   # IOC 쉘에서 데이터베이스 레코드 확인
   dbl | grep ThresholdLogic
   ```
3. 네트워크 설정 확인:
   ```bash
   echo $EPICS_CA_ADDR_LIST
   echo $EPICS_CA_AUTO_ADDR_LIST
   ```

#### 드라이버 통신 오류
**증상**: 현재값이 업데이트되지 않거나 출력 상태가 변경되지 않음
**해결 방법**:
1. asyn 포트 상태 확인:
   ```
   # IOC 쉘에서
   asynReport 1
   ```
2. 디버깅 활성화:
   ```
   asynSetTraceMask("THRESHOLD_LOGIC_PORT", 0, 0x9)
   asynSetTraceIOMask("THRESHOLD_LOGIC_PORT", 0, 0x2)
   ```
3. 하드웨어 연결 확인

### 2. 성능 문제

#### 높은 CPU 사용률
**원인**: 업데이트 주기가 너무 높게 설정됨
**해결 방법**:
```bash
# 업데이트 주기를 낮춤
caput USB1608G_2AO_cpp:ThresholdLogic1UpdateRate 1.0
```

#### 응답 지연
**원인**: 네트워크 지연 또는 IOC 과부하
**해결 방법**:
1. 네트워크 상태 확인
2. IOC 리소스 사용량 확인
3. 불필요한 모니터링 중지

### 3. 하드웨어 관련 문제

#### USB 장치 인식 실패
**증상**: `Device not found` 또는 연결 오류
**해결 방법**:
1. USB 연결 확인
2. 장치 권한 확인:
   ```bash
   lsusb
   ls -l /dev/usb*
   ```
3. udev 규칙 설정 (필요시)

#### 측정값 이상
**증상**: 현재값이 예상 범위를 벗어남
**해결 방법**:
1. 센서 연결 확인
2. 캘리브레이션 확인
3. 하드웨어 설정 검토

### 4. 디버깅 도구

#### 로그 분석
```bash
# IOC 로그 실시간 모니터링
tail -f ioc.log | grep -i threshold

# 오류 메시지만 필터링
tail -f ioc.log | grep -i error
```

#### 성능 모니터링
```bash
# CPU 사용률 확인
top -p $(pgrep USB1608G_2AO_cpp)

# 메모리 사용량 확인
ps aux | grep USB1608G_2AO_cpp
```

#### 네트워크 진단
```bash
# Channel Access 연결 테스트
caget -w 5 USB1608G_2AO_cpp:ThresholdLogic1Enable

# 네트워크 지연 측정
camonitor -# 10 USB1608G_2AO_cpp:ThresholdLogic1CurrentValue
```

이 사용자 매뉴얼을 통해 ThresholdLogicController를 효과적으로 설치, 설정, 운영할 수 있습니다. 추가적인 질문이나 문제가 발생하면 문제 해결 섹션을 참조하거나 기술 지원팀에 문의하시기 바랍니다.