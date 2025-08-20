# ThresholdLogicController API 문서

## 목차
1. [클래스 개요](#클래스-개요)
2. [생성자 및 소멸자](#생성자-및-소멸자)
3. [공개 메서드](#공개-메서드)
4. [매개변수 정의](#매개변수-정의)
5. [IOC 쉘 명령어](#ioc-쉘-명령어)
6. [데이터베이스 인터페이스](#데이터베이스-인터페이스)
7. [예제 코드](#예제-코드)
8. [오류 처리](#오류-처리)

## 클래스 개요

### ThresholdLogicController
```cpp
class ThresholdLogicController : public asynPortDriver, public epicsThreadRunable
```

ThresholdLogicController는 EPICS asynPortDriver를 상속받아 구현된 드라이버 클래스로, 아날로그 입력 값을 실시간으로 모니터링하고 설정된 임계값과 비교하여 디지털 출력을 제어합니다.

#### 상속 관계
- **asynPortDriver**: EPICS asyn 프레임워크의 기본 드라이버 클래스
- **epicsThreadRunable**: EPICS 스레드 실행 인터페이스

#### 주요 특징
- 실시간 임계값 비교 로직
- 히스테리시스 기능으로 출력 진동 방지
- 다중 스레드 안전성
- EPICS Channel Access 완전 지원
- 포괄적인 오류 처리 및 로깅

## 생성자 및 소멸자

### 생성자
```cpp
ThresholdLogicController(const char* portName, const char* devicePort, int deviceAddr);
```

새로운 ThresholdLogicController 인스턴스를 생성합니다.

#### 매개변수
- **portName** (const char*): 이 드라이버의 asyn 포트 이름
- **devicePort** (const char*): 연결할 장치 포트 이름
- **deviceAddr** (int): 장치 주소 (0-255)

#### 예제
```cpp
ThresholdLogicController* controller = new ThresholdLogicController(
    "THRESHOLD_LOGIC_PORT",     // 포트 이름
    "USB1608G_2AO_cpp_PORT",    // 장치 포트
    0                           // 장치 주소
);
```

#### 초기화 과정
1. asynPortDriver 기본 클래스 초기화
2. 9개의 매개변수 생성 및 등록
3. 초기값 설정 (임계값: 0.0V, 히스테리시스: 0.1V, 업데이트 주기: 10Hz)
4. 스레드 관리 변수 초기화
5. 구성 유효성 검사 수행

### 소멸자
```cpp
virtual ~ThresholdLogicController();
```

ThresholdLogicController 인스턴스를 안전하게 소멸시킵니다.

#### 소멸 과정
1. 모니터링 스레드 중지
2. 리소스 정리
3. 메모리 해제

## 공개 메서드

### asynPortDriver 오버라이드 메서드

#### writeFloat64
```cpp
virtual asynStatus writeFloat64(asynUser *pasynUser, epicsFloat64 value);
```

부동소수점 매개변수를 설정합니다.

**지원하는 매개변수**:
- `P_ThresholdValue`: 임계값 설정 (-10.0V ~ +10.0V)
- `P_Hysteresis`: 히스테리시스 값 설정 (0.0V ~ 5.0V)
- `P_UpdateRate`: 업데이트 주기 설정 (0.1Hz ~ 1000Hz)

**반환값**: 
- `asynSuccess`: 성공
- `asynError`: 실패 (유효성 검사 실패, 읽기 전용 매개변수 등)

**예제**:
```cpp
// 임계값을 2.5V로 설정
asynUser* pasynUser = /* asyn 사용자 구조체 */;
asynStatus status = controller->writeFloat64(pasynUser, 2.5);
if (status != asynSuccess) {
    printf("임계값 설정 실패\n");
}
```

#### readFloat64
```cpp
virtual asynStatus readFloat64(asynUser *pasynUser, epicsFloat64 *value);
```

부동소수점 매개변수를 읽습니다.

**지원하는 매개변수**:
- `P_ThresholdValue`: 현재 설정된 임계값
- `P_CurrentValue`: 실시간 측정값
- `P_Hysteresis`: 현재 설정된 히스테리시스 값
- `P_UpdateRate`: 현재 설정된 업데이트 주기

**반환값**:
- `asynSuccess`: 성공
- `asynError`: 실패 (NULL 포인터, 알 수 없는 매개변수 등)

#### writeInt32
```cpp
virtual asynStatus writeInt32(asynUser *pasynUser, epicsInt32 value);
```

정수 매개변수를 설정합니다.

**지원하는 매개변수**:
- `P_Enable`: 활성화 상태 제어 (0: 비활성화, 1: 활성화)
- `P_DeviceAddr`: 장치 주소 설정 (0-255, 비활성화 상태에서만 변경 가능)

**특별 동작**:
- 활성화 시 자동으로 모니터링 스레드 시작
- 비활성화 시 자동으로 모니터링 스레드 중지
- 출력 상태 및 알람 상태는 읽기 전용

#### readInt32
```cpp
virtual asynStatus readInt32(asynUser *pasynUser, epicsInt32 *value);
```

정수 매개변수를 읽습니다.

**지원하는 매개변수**:
- `P_Enable`: 현재 활성화 상태
- `P_OutputState`: 현재 출력 상태 (0: Low, 1: High)
- `P_AlarmStatus`: 현재 알람 상태 (0: 정상, 1: 경고, 2: 주요, 3: 치명적)
- `P_DeviceAddr`: 현재 장치 주소

### 임계값 로직 메서드

#### processThresholdLogic
```cpp
void processThresholdLogic();
```

임계값 로직의 핵심 처리를 수행합니다.

**처리 과정**:
1. 장치에서 현재 값 읽기
2. 임계값과 히스테리시스를 고려한 비교 로직 수행
3. 출력 상태 변화 감지 및 제어
4. 알람 상태 설정 및 타임스탬프 업데이트

**로직 알고리즘**:
```cpp
if (!outputState_) {
    // 현재 출력이 LOW인 경우
    if (currentValue_ > thresholdValue_) {
        outputState_ = true;  // HIGH로 변경
    }
} else {
    // 현재 출력이 HIGH인 경우
    double lowerThreshold = thresholdValue_ - hysteresis_;
    if (currentValue_ < lowerThreshold) {
        outputState_ = false; // LOW로 변경
    }
}
```

### 스레드 관리 메서드

#### startMonitoring
```cpp
void startMonitoring();
```

실시간 모니터링 스레드를 시작합니다.

**동작**:
- epicsThread 객체 생성
- 스레드 시작 및 상태 플래그 설정
- 오류 발생 시 적절한 정리 작업 수행

**예외 처리**:
- 이미 실행 중인 경우 중복 시작 방지
- 스레드 생성 실패 시 오류 로깅
- 리소스 정리를 통한 메모리 누수 방지

#### stopMonitoring
```cpp
void stopMonitoring();
```

실시간 모니터링 스레드를 중지합니다.

**동작**:
- 스레드 종료 신호 설정
- 최대 5초간 정상 종료 대기
- 필요시 강제 종료 수행
- 스레드 객체 삭제 및 상태 초기화

#### run (epicsThreadRunable 구현)
```cpp
virtual void run();
```

모니터링 스레드의 메인 루프를 구현합니다.

**루프 동작**:
1. 활성화 상태 확인
2. `processThresholdLogic()` 호출
3. 매개변수 콜백 호출
4. 업데이트 주기에 따른 대기
5. 성능 모니터링 및 리포팅

**성능 최적화**:
- 정확한 주기 유지를 위한 처리 시간 보상
- 주기적 성능 리포트 (1000 사이클마다)
- 예외 처리를 통한 안정성 보장

## 매개변수 정의

### 매개변수 문자열 상수
```cpp
#define THRESHOLD_VALUE_STRING      "THRESHOLD_VALUE"
#define CURRENT_VALUE_STRING        "CURRENT_VALUE"
#define OUTPUT_STATE_STRING         "OUTPUT_STATE"
#define ENABLE_STRING               "ENABLE"
#define HYSTERESIS_STRING           "HYSTERESIS"
#define UPDATE_RATE_STRING          "UPDATE_RATE"
#define ALARM_STATUS_STRING         "ALARM_STATUS"
#define DEVICE_PORT_STRING          "DEVICE_PORT"
#define DEVICE_ADDR_STRING          "DEVICE_ADDR"
```

### 매개변수 상세 정보

| 매개변수 | 타입 | 접근 | 범위 | 기본값 | 설명 |
|---------|------|------|------|--------|------|
| THRESHOLD_VALUE | Float64 | R/W | -10.0 ~ +10.0V | 0.0V | 임계값 설정 |
| CURRENT_VALUE | Float64 | R | -10.0 ~ +10.0V | 0.0V | 현재 측정값 |
| OUTPUT_STATE | Int32 | R | 0, 1 | 0 | 출력 상태 (0:Low, 1:High) |
| ENABLE | Int32 | R/W | 0, 1 | 0 | 활성화 상태 |
| HYSTERESIS | Float64 | R/W | 0.0 ~ 5.0V | 0.1V | 히스테리시스 값 |
| UPDATE_RATE | Float64 | R/W | 0.1 ~ 1000Hz | 10.0Hz | 업데이트 주기 |
| ALARM_STATUS | Int32 | R | 0-3 | 0 | 알람 상태 |
| DEVICE_PORT | Octet | R | - | - | 장치 포트 이름 |
| DEVICE_ADDR | Int32 | R/W | 0-255 | 0 | 장치 주소 |

### 매개변수 접근자 메서드 (테스트용)
```cpp
int getThresholdValueParam() const { return P_ThresholdValue; }
int getCurrentValueParam() const { return P_CurrentValue; }
int getOutputStateParam() const { return P_OutputState; }
int getEnableParam() const { return P_Enable; }
int getHysteresisParam() const { return P_Hysteresis; }
int getUpdateRateParam() const { return P_UpdateRate; }
int getAlarmStatusParam() const { return P_AlarmStatus; }
```

## IOC 쉘 명령어

### ThresholdLogicConfig
```cpp
int ThresholdLogicConfig(const char* portName, const char* devicePort, int deviceAddr);
```

새로운 ThresholdLogicController 인스턴스를 생성하고 IOC에 등록합니다.

#### 사용법
```bash
# IOC 쉘에서
ThresholdLogicConfig("THRESHOLD_LOGIC_PORT", "USB1608G_2AO_cpp_PORT", 0)
```

#### 매개변수
- **portName**: 생성할 asyn 포트 이름
- **devicePort**: 연결할 장치 포트 이름
- **deviceAddr**: 장치 주소

#### 반환값
- **0**: 성공
- **-1**: 실패

### ThresholdLogicHelp
```cpp
void ThresholdLogicHelp(void);
```

ThresholdLogic 관련 명령어의 도움말을 출력합니다.

#### 사용법
```bash
# IOC 쉘에서
ThresholdLogicHelp
```

### ThresholdLogicRegister
```cpp
void ThresholdLogicRegister(void);
```

ThresholdLogic 관련 IOC 쉘 명령어를 등록합니다. (내부적으로 호출됨)

## 데이터베이스 인터페이스

### EPICS 레코드 템플릿

ThresholdLogicController는 다음 EPICS 레코드 타입들과 인터페이스합니다:

#### 아날로그 출력 레코드 (ao)
```
record(ao, "$(P)$(R)Threshold") {
    field(DTYP, "asynFloat64")
    field(OUT,  "@asyn($(PORT),$(ADDR))THRESHOLD_VALUE")
    field(PREC, "3")
    field(EGU,  "V")
}
```

#### 아날로그 입력 레코드 (ai)
```
record(ai, "$(P)$(R)CurrentValue") {
    field(DTYP, "asynFloat64")
    field(INP,  "@asyn($(PORT),$(ADDR))CURRENT_VALUE")
    field(SCAN, "I/O Intr")
    field(PREC, "3")
    field(EGU,  "V")
}
```

#### 바이너리 출력 레코드 (bo)
```
record(bo, "$(P)$(R)Enable") {
    field(DTYP, "asynInt32")
    field(OUT,  "@asyn($(PORT),$(ADDR))ENABLE")
    field(ZNAM, "Disabled")
    field(ONAM, "Enabled")
}
```

#### 바이너리 입력 레코드 (bi)
```
record(bi, "$(P)$(R)OutputState") {
    field(DTYP, "asynInt32")
    field(INP,  "@asyn($(PORT),$(ADDR))OUTPUT_STATE")
    field(SCAN, "I/O Intr")
    field(ZNAM, "Low")
    field(ONAM, "High")
}
```

### 매크로 치환 매개변수

| 매크로 | 설명 | 예제 값 |
|--------|------|---------|
| P | PV 접두사 | "USB1608G_2AO_cpp:" |
| R | 레코드 이름 접미사 | "ThresholdLogic1" |
| PORT | asyn 포트 이름 | "THRESHOLD_LOGIC_PORT" |
| ADDR | asyn 주소 | 0 |
| PREC | 소수점 자릿수 | 3 |
| EGU | 엔지니어링 단위 | "V" |

## 예제 코드

### 1. 기본 사용 예제

#### C++ 코드
```cpp
#include "ThresholdLogicController.h"

int main() {
    // 컨트롤러 생성
    ThresholdLogicController* controller = new ThresholdLogicController(
        "THRESHOLD_LOGIC_PORT",
        "USB1608G_2AO_cpp_PORT", 
        0
    );
    
    // 임계값 설정 (asynUser 구조체 필요)
    asynUser* pasynUser = /* 초기화 */;
    pasynUser->reason = controller->getThresholdValueParam();
    controller->writeFloat64(pasynUser, 2.5);
    
    // 활성화
    pasynUser->reason = controller->getEnableParam();
    controller->writeInt32(pasynUser, 1);
    
    // 현재 값 읽기
    pasynUser->reason = controller->getCurrentValueParam();
    epicsFloat64 currentValue;
    controller->readFloat64(pasynUser, &currentValue);
    printf("현재 값: %.3f V\n", currentValue);
    
    // 정리
    delete controller;
    return 0;
}
```

#### IOC 시작 스크립트 (st.cmd)
```bash
#!../../bin/linux-x86_64/USB1608G_2AO_cpp

# EPICS 환경 설정
< envPaths

# 데이터베이스 정의 등록
dbLoadDatabase("dbd/USB1608G_2AO_cpp.dbd")
USB1608G_2AO_cpp_registerRecordDeviceDriver(pdbbase)

# 장치 드라이버 설정
measCompConfig("USB1608G_2AO_cpp_PORT", "USB1608G-2AO", 0)

# ThresholdLogic 컨트롤러 설정
ThresholdLogicConfig("THRESHOLD_LOGIC_PORT", "USB1608G_2AO_cpp_PORT", 0)

# 데이터베이스 로드
dbLoadRecords("db/threshold_logic.template", "P=USB1608G_2AO_cpp:,R=ThresholdLogic1,PORT=THRESHOLD_LOGIC_PORT,ADDR=0")

# IOC 초기화
iocInit()

# 자동 저장 시작
create_monitor_set("auto_settings.req", 30)
```

### 2. 다중 컨트롤러 예제

```bash
# 4개의 ThresholdLogic 컨트롤러 설정
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

### 3. Python 클라이언트 예제

```python
import epics
import time

class ThresholdLogicClient:
    def __init__(self, prefix="USB1608G_2AO_cpp:", controller="ThresholdLogic1"):
        self.prefix = prefix
        self.controller = controller
        
        # PV 연결
        self.threshold_pv = epics.PV(f"{prefix}{controller}Threshold")
        self.current_pv = epics.PV(f"{prefix}{controller}CurrentValue")
        self.output_pv = epics.PV(f"{prefix}{controller}OutputState")
        self.enable_pv = epics.PV(f"{prefix}{controller}Enable")
        self.hysteresis_pv = epics.PV(f"{prefix}{controller}Hysteresis")
        
    def configure(self, threshold, hysteresis=0.1):
        """컨트롤러 설정"""
        self.threshold_pv.put(threshold)
        self.hysteresis_pv.put(hysteresis)
        print(f"설정 완료: 임계값={threshold}V, 히스테리시스={hysteresis}V")
        
    def enable(self, state=True):
        """컨트롤러 활성화/비활성화"""
        self.enable_pv.put(1 if state else 0)
        print(f"컨트롤러 {'활성화' if state else '비활성화'}")
        
    def get_status(self):
        """현재 상태 반환"""
        return {
            'threshold': self.threshold_pv.get(),
            'current_value': self.current_pv.get(),
            'output_state': bool(self.output_pv.get()),
            'enabled': bool(self.enable_pv.get()),
            'hysteresis': self.hysteresis_pv.get()
        }
        
    def monitor(self, duration=60):
        """지정된 시간 동안 모니터링"""
        print(f"{duration}초 동안 모니터링 시작...")
        start_time = time.time()
        
        while time.time() - start_time < duration:
            status = self.get_status()
            print(f"현재값: {status['current_value']:.3f}V, "
                  f"출력: {'High' if status['output_state'] else 'Low'}")
            time.sleep(1)

# 사용 예제
if __name__ == "__main__":
    # 클라이언트 생성
    client = ThresholdLogicClient()
    
    # 설정
    client.configure(threshold=2.5, hysteresis=0.1)
    client.enable(True)
    
    # 모니터링
    client.monitor(30)
```

## 오류 처리

### 오류 분류

#### 1. 구성 오류 (Configuration Errors)
- **원인**: 잘못된 매개변수, 포트 연결 실패
- **처리**: ErrorHandler::validateParameter() 사용
- **예제**:
```cpp
if (!ErrorHandler::validateParameter("thresholdValue", value, -10.0, 10.0, functionName)) {
    ErrorHandler::logError(ErrorHandler::ERROR, functionName, 
                          "임계값이 유효 범위를 벗어났습니다", pasynUser);
    return asynError;
}
```

#### 2. 통신 오류 (Communication Errors)
- **원인**: 장치 통신 실패, 타임아웃
- **처리**: ErrorHandler::handleCommunicationError() 사용
- **예제**:
```cpp
status = readCurrentValueFromDevice();
if (status != asynSuccess) {
    ErrorHandler::handleCommunicationError(functionName, devicePortName_, deviceAddr_, 
                                          "현재값 읽기", pasynUserSelf);
    alarmStatus_ = 2; // MAJOR 알람
    return;
}
```

#### 3. 스레드 오류 (Thread Errors)
- **원인**: 스레드 생성 실패, 메모리 부족
- **처리**: ErrorHandler::handleThreadError() 사용
- **예제**:
```cpp
try {
    monitorThread_ = new epicsThread(*this, threadName, stackSize, priority);
} catch (std::exception& e) {
    ErrorHandler::handleThreadError(functionName, threadName, e.what(), pasynUserSelf);
    return;
}
```

### 알람 상태 코드

| 코드 | 상태 | 설명 |
|------|------|------|
| 0 | NO_ALARM | 정상 동작 |
| 1 | MINOR_ALARM | 경고 상태 |
| 2 | MAJOR_ALARM | 주요 오류 |
| 3 | INVALID_ALARM | 치명적 오류 |

### 디버깅 지원

#### asyn 추적 활성화
```cpp
// IOC 쉘에서
asynSetTraceMask("THRESHOLD_LOGIC_PORT", 0, 0x9)
asynSetTraceIOMask("THRESHOLD_LOGIC_PORT", 0, 0x2)
```

#### 로그 레벨 설정
```cpp
// 코드에서
asynPrint(pasynUserSelf, ASYN_TRACE_ERROR, "오류 메시지");
asynPrint(pasynUserSelf, ASYN_TRACE_WARNING, "경고 메시지");
asynPrint(pasynUserSelf, ASYN_TRACE_FLOW, "흐름 추적");
asynPrint(pasynUserSelf, ASYN_TRACEIO_DRIVER, "드라이버 I/O");
```

### 예외 처리 패턴

#### 안전한 리소스 관리
```cpp
ThresholdLogicController::~ThresholdLogicController() {
    try {
        stopMonitoring();  // 스레드 중지
        // 기타 정리 작업
    } catch (...) {
        // 소멸자에서는 예외를 던지지 않음
        asynPrint(pasynUserSelf, ASYN_TRACE_ERROR, 
                  "소멸자에서 예외 발생");
    }
}
```

#### 스레드 안전성
```cpp
void ThresholdLogicController::run() {
    while (!threadExit_) {
        try {
            processThresholdLogic();
        } catch (std::exception& e) {
            asynPrint(pasynUserSelf, ASYN_TRACE_ERROR,
                      "스레드 루프 중 예외: %s", e.what());
            epicsThreadSleep(1.0);  // 오류 후 잠시 대기
        } catch (...) {
            asynPrint(pasynUserSelf, ASYN_TRACE_ERROR,
                      "알 수 없는 예외 발생");
            epicsThreadSleep(1.0);
        }
    }
}
```

이 API 문서는 ThresholdLogicController의 모든 공개 인터페이스와 사용 방법을 상세히 설명합니다. 개발자는 이 문서를 참조하여 ThresholdLogicController를 효과적으로 활용할 수 있습니다.