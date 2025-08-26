# ThresholdLogicController 예제 구성 가이드

## 목차
1. [기본 예제](#기본-예제)
2. [온도 모니터링 시스템](#온도-모니터링-시스템)
3. [압력 안전 시스템](#압력-안전-시스템)
4. [다중 채널 모니터링](#다중-채널-모니터링)
5. [자동화 스크립트](#자동화-스크립트)
6. [고급 구성](#고급-구성)

## 기본 예제

### 1. 단일 ThresholdLogic 컨트롤러

#### st.cmd 구성
```bash
#!../../bin/linux-x86_64/USB1608G_2AO_cpp

# EPICS 환경 설정
< envPaths

# 데이터베이스 정의 등록
dbLoadDatabase("dbd/USB1608G_2AO_cpp.dbd")
USB1608G_2AO_cpp_registerRecordDeviceDriver(pdbbase)

# 하드웨어 드라이버 설정
measCompConfig("USB1608G_2AO_cpp_PORT", "USB1608G-2AO", 0)

# ThresholdLogic 컨트롤러 생성
ThresholdLogicConfig("THRESHOLD_LOGIC_PORT", "USB1608G_2AO_cpp_PORT", 0)

# 데이터베이스 로드
dbLoadRecords("db/threshold_logic.template", "P=USB1608G_2AO_cpp:,R=ThresholdLogic1,PORT=THRESHOLD_LOGIC_PORT,ADDR=0,THRESHOLD=2.5,HYSTERESIS=0.1")

# IOC 초기화
iocInit()

# 자동 저장 설정
create_monitor_set("auto_settings.req", 30)
```

#### 기본 사용법
```bash
# IOC 시작
cd iocBoot/iocUSB1608G_2AO_cpp
../../bin/linux-x86_64/USB1608G_2AO_cpp st.cmd

# 별도 터미널에서 제어
# 임계값 설정
caput USB1608G_2AO_cpp:ThresholdLogic1Threshold 2.5

# 히스테리시스 설정
caput USB1608G_2AO_cpp:ThresholdLogic1Hysteresis 0.1

# 컨트롤러 활성화
caput USB1608G_2AO_cpp:ThresholdLogic1Enable 1

# 상태 모니터링
camonitor USB1608G_2AO_cpp:ThresholdLogic1CurrentValue USB1608G_2AO_cpp:ThresholdLogic1OutputState
```

### 2. 자동 저장 설정

#### auto_settings.req 파일
```
# ThresholdLogic 설정 자동 저장
USB1608G_2AO_cpp:ThresholdLogic1Threshold
USB1608G_2AO_cpp:ThresholdLogic1Hysteresis
USB1608G_2AO_cpp:ThresholdLogic1Enable
USB1608G_2AO_cpp:ThresholdLogic1UpdateRate
```

## 온도 모니터링 시스템

### 시나리오
온도 센서(10V/100°C)를 모니터링하여 25°C를 초과하면 냉각 팬을 작동시키는 시스템

### 구성

#### st.cmd 설정
```bash
# 온도 모니터링용 ThresholdLogic 설정
ThresholdLogicConfig("TEMP_MONITOR_PORT", "USB1608G_2AO_cpp_PORT", 0)

# 온도 센서용 데이터베이스 로드
dbLoadRecords("db/threshold_logic.template", 
    "P=TempControl:,R=CoolingFan,PORT=TEMP_MONITOR_PORT,ADDR=0,THRESHOLD=2.5,HYSTERESIS=0.1,EGU=C,PREC=1")

# 온도 변환을 위한 calc 레코드
dbLoadRecords("db/temperature_conversion.db", "P=TempControl:")
```

#### temperature_conversion.db 파일
```
# 전압을 온도로 변환 (10V = 100°C)
record(calc, "$(P)Temperature") {
    field(DESC, "Temperature in Celsius")
    field(INPA, "$(P)CoolingFanCurrentValue CP")
    field(CALC, "A*10")  # 10V/100°C = 0.1V/°C
    field(EGU,  "°C")
    field(PREC, "1")
    field(HIHI, "80")    # 80°C에서 주요 알람
    field(HIGH, "60")    # 60°C에서 경고 알람
    field(HHSV, "MAJOR")
    field(HSV,  "MINOR")
}

# 팬 상태 표시
record(calc, "$(P)FanStatus") {
    field(DESC, "Cooling Fan Status")
    field(INPA, "$(P)CoolingFanOutputState CP")
    field(CALC, "A")
    field(ONAM, "Fan ON")
    field(ZNAM, "Fan OFF")
}
```

#### 설정 스크립트 (temp_setup.sh)
```bash
#!/bin/bash
# 온도 모니터링 시스템 설정

echo "온도 모니터링 시스템 설정 중..."

# 임계값: 25°C = 2.5V (10V/100°C 센서)
caput TempControl:CoolingFanThreshold 2.5

# 히스테리시스: 2°C = 0.2V
caput TempControl:CoolingFanHysteresis 0.2

# 빠른 응답을 위한 높은 업데이트 주기 (20Hz)
caput TempControl:CoolingFanUpdateRate 20.0

# 시스템 활성화
caput TempControl:CoolingFanEnable 1

echo "설정 완료!"
echo "현재 온도: $(caget -t TempControl:Temperature) °C"
echo "팬 상태: $(caget -t TempControl:FanStatus)"
```

#### 모니터링 스크립트 (temp_monitor.py)
```python
#!/usr/bin/env python3
import epics
import time
import datetime

class TemperatureMonitor:
    def __init__(self):
        self.temp_pv = epics.PV('TempControl:Temperature')
        self.fan_pv = epics.PV('TempControl:FanStatus')
        self.threshold_pv = epics.PV('TempControl:CoolingFanThreshold')
        
    def log_status(self):
        temp = self.temp_pv.get()
        fan_status = self.fan_pv.get()
        threshold = self.threshold_pv.get() * 10  # 전압을 온도로 변환
        
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        status = "ON" if fan_status else "OFF"
        
        print(f"[{timestamp}] 온도: {temp:.1f}°C, 임계값: {threshold:.1f}°C, 팬: {status}")
        
        # 로그 파일에 기록
        with open("temperature_log.txt", "a") as f:
            f.write(f"{timestamp},{temp:.1f},{threshold:.1f},{status}\n")
    
    def monitor(self, interval=10):
        print("온도 모니터링 시작...")
        print("Ctrl+C로 중지")
        
        try:
            while True:
                self.log_status()
                time.sleep(interval)
        except KeyboardInterrupt:
            print("\n모니터링 중지")

if __name__ == "__main__":
    monitor = TemperatureMonitor()
    monitor.monitor()
```

## 압력 안전 시스템

### 시나리오
압력 센서(5V 만압)를 모니터링하여 80% 압력을 초과하면 안전 밸브를 작동시키는 시스템

### 구성

#### st.cmd 설정
```bash
# 압력 안전 시스템용 ThresholdLogic 설정
ThresholdLogicConfig("PRESSURE_SAFETY_PORT", "USB1608G_2AO_cpp_PORT", 1)

# 압력 센서용 데이터베이스 로드
dbLoadRecords("db/threshold_logic.template", 
    "P=PressureSafety:,R=SafetyValve,PORT=PRESSURE_SAFETY_PORT,ADDR=1,THRESHOLD=4.0,HYSTERESIS=0.1,EGU=bar,PREC=2")

# 압력 변환 및 안전 로직
dbLoadRecords("db/pressure_safety.db", "P=PressureSafety:")
```

#### pressure_safety.db 파일
```
# 전압을 압력으로 변환 (5V = 100bar)
record(calc, "$(P)Pressure") {
    field(DESC, "Pressure in bar")
    field(INPA, "$(P)SafetyValveCurrentValue CP")
    field(CALC, "A*20")  # 5V/100bar = 0.05V/bar
    field(EGU,  "bar")
    field(PREC, "2")
    field(HIHI, "95")    # 95bar에서 주요 알람
    field(HIGH, "85")    # 85bar에서 경고 알람
    field(HHSV, "MAJOR")
    field(HSV,  "MINOR")
}

# 압력 백분율 계산
record(calc, "$(P)PressurePercent") {
    field(DESC, "Pressure Percentage")
    field(INPA, "$(P)Pressure CP")
    field(CALC, "A")  # 이미 bar 단위이므로 그대로 사용
    field(EGU,  "%")
    field(PREC, "1")
}

# 안전 밸브 상태
record(calc, "$(P)ValveStatus") {
    field(DESC, "Safety Valve Status")
    field(INPA, "$(P)SafetyValveOutputState CP")
    field(CALC, "A")
    field(ONAM, "OPEN")
    field(ZNAM, "CLOSED")
    field(OSV,  "MAJOR")  # 밸브 열림 시 주요 알람
}

# 안전 상태 종합
record(calc, "$(P)SafetyStatus") {
    field(DESC, "Overall Safety Status")
    field(INPA, "$(P)Pressure CP")
    field(INPB, "$(P)SafetyValveOutputState CP")
    field(CALC, "(A<80)?0:(B?2:1)")  # 0:안전, 1:경고, 2:안전밸브작동
    field(ZRST, "SAFE")
    field(ONST, "WARNING")
    field(TWST, "VALVE_OPEN")
    field(ZRSV, "NO_ALARM")
    field(ONSV, "MINOR")
    field(TWSV, "MAJOR")
}
```

#### 안전 시스템 설정 (pressure_setup.sh)
```bash
#!/bin/bash
# 압력 안전 시스템 설정

echo "압력 안전 시스템 설정 중..."

# 임계값: 80bar = 4.0V (5V/100bar 센서)
caput PressureSafety:SafetyValveThreshold 4.0

# 작은 히스테리시스: 1bar = 0.05V
caput PressureSafety:SafetyValveHysteresis 0.05

# 안전을 위한 높은 업데이트 주기 (100Hz)
caput PressureSafety:SafetyValveUpdateRate 100.0

# 시스템 활성화
caput PressureSafety:SafetyValveEnable 1

echo "설정 완료!"
echo "현재 압력: $(caget -t PressureSafety:Pressure) bar"
echo "안전 상태: $(caget -t PressureSafety:SafetyStatus)"
```

## 다중 채널 모니터링

### 시나리오
4개의 센서를 동시에 모니터링하는 시스템 (온도, 압력, 유량, 레벨)

### 구성

#### st.cmd 설정
```bash
# 4개의 ThresholdLogic 컨트롤러 생성
ThresholdLogicConfig("TEMP_PORT", "USB1608G_2AO_cpp_PORT", 0)
ThresholdLogicConfig("PRESSURE_PORT", "USB1608G_2AO_cpp_PORT", 1)
ThresholdLogicConfig("FLOW_PORT", "USB1608G_2AO_cpp_PORT", 2)
ThresholdLogicConfig("LEVEL_PORT", "USB1608G_2AO_cpp_PORT", 3)

# 각 센서별 데이터베이스 로드
dbLoadRecords("db/threshold_logic.template", 
    "P=MultiSensor:,R=Temperature,PORT=TEMP_PORT,ADDR=0,THRESHOLD=2.5,HYSTERESIS=0.1")
dbLoadRecords("db/threshold_logic.template", 
    "P=MultiSensor:,R=Pressure,PORT=PRESSURE_PORT,ADDR=1,THRESHOLD=4.0,HYSTERESIS=0.1")
dbLoadRecords("db/threshold_logic.template", 
    "P=MultiSensor:,R=Flow,PORT=FLOW_PORT,ADDR=2,THRESHOLD=3.0,HYSTERESIS=0.2")
dbLoadRecords("db/threshold_logic.template", 
    "P=MultiSensor:,R=Level,PORT=LEVEL_PORT,ADDR=3,THRESHOLD=1.5,HYSTERESIS=0.1")

# 종합 상태 모니터링
dbLoadRecords("db/multi_sensor_status.db", "P=MultiSensor:")
```

#### multi_sensor_status.db 파일
```
# 전체 시스템 상태
record(calc, "$(P)SystemStatus") {
    field(DESC, "Overall System Status")
    field(INPA, "$(P)TemperatureOutputState CP")
    field(INPB, "$(P)PressureOutputState CP")
    field(INPC, "$(P)FlowOutputState CP")
    field(INPD, "$(P)LevelOutputState CP")
    field(CALC, "A+B+C+D")  # 활성화된 알람 개수
    field(ZRST, "ALL_NORMAL")
    field(ONST, "ONE_ALARM")
    field(TWST, "TWO_ALARMS")
    field(THST, "THREE_ALARMS")
    field(FRST, "ALL_ALARMS")
    field(ZRSV, "NO_ALARM")
    field(ONSV, "MINOR")
    field(TWSV, "MAJOR")
    field(THSV, "MAJOR")
    field(FRSV, "MAJOR")
}

# 알람 카운터
record(calc, "$(P)AlarmCount") {
    field(DESC, "Number of Active Alarms")
    field(INPA, "$(P)SystemStatus CP")
    field(CALC, "A")
    field(EGU,  "alarms")
}
```

#### 다중 채널 설정 스크립트 (multi_setup.sh)
```bash
#!/bin/bash
# 다중 채널 모니터링 시스템 설정

echo "다중 채널 모니터링 시스템 설정 중..."

# 온도 센서 (25°C 임계값)
caput MultiSensor:TemperatureThreshold 2.5
caput MultiSensor:TemperatureHysteresis 0.1
caput MultiSensor:TemperatureUpdateRate 10.0

# 압력 센서 (80bar 임계값)
caput MultiSensor:PressureThreshold 4.0
caput MultiSensor:PressureHysteresis 0.1
caput MultiSensor:PressureUpdateRate 20.0

# 유량 센서 (60% 임계값)
caput MultiSensor:FlowThreshold 3.0
caput MultiSensor:FlowHysteresis 0.2
caput MultiSensor:FlowUpdateRate 5.0

# 레벨 센서 (30% 임계값)
caput MultiSensor:LevelThreshold 1.5
caput MultiSensor:LevelHysteresis 0.1
caput MultiSensor:LevelUpdateRate 2.0

# 모든 채널 활성화
for sensor in Temperature Pressure Flow Level; do
    caput MultiSensor:${sensor}Enable 1
    echo "${sensor} 센서 활성화됨"
done

echo "설정 완료!"
echo "시스템 상태: $(caget -t MultiSensor:SystemStatus)"
echo "활성 알람 수: $(caget -t MultiSensor:AlarmCount)"
```

#### 다중 채널 모니터링 스크립트 (multi_monitor.py)
```python
#!/usr/bin/env python3
import epics
import time
import datetime

class MultiSensorMonitor:
    def __init__(self):
        self.sensors = {
            'Temperature': {
                'current': epics.PV('MultiSensor:TemperatureCurrentValue'),
                'output': epics.PV('MultiSensor:TemperatureOutputState'),
                'threshold': epics.PV('MultiSensor:TemperatureThreshold'),
                'unit': '°C',
                'scale': 10  # 10V/100°C
            },
            'Pressure': {
                'current': epics.PV('MultiSensor:PressureCurrentValue'),
                'output': epics.PV('MultiSensor:PressureOutputState'),
                'threshold': epics.PV('MultiSensor:PressureThreshold'),
                'unit': 'bar',
                'scale': 20  # 5V/100bar
            },
            'Flow': {
                'current': epics.PV('MultiSensor:FlowCurrentValue'),
                'output': epics.PV('MultiSensor:FlowOutputState'),
                'threshold': epics.PV('MultiSensor:FlowThreshold'),
                'unit': '%',
                'scale': 20  # 5V/100%
            },
            'Level': {
                'current': epics.PV('MultiSensor:LevelCurrentValue'),
                'output': epics.PV('MultiSensor:LevelOutputState'),
                'threshold': epics.PV('MultiSensor:LevelThreshold'),
                'unit': '%',
                'scale': 20  # 5V/100%
            }
        }
        
        self.system_status_pv = epics.PV('MultiSensor:SystemStatus')
        self.alarm_count_pv = epics.PV('MultiSensor:AlarmCount')
    
    def get_sensor_data(self, sensor_name):
        sensor = self.sensors[sensor_name]
        current_voltage = sensor['current'].get()
        current_value = current_voltage * sensor['scale']
        threshold_voltage = sensor['threshold'].get()
        threshold_value = threshold_voltage * sensor['scale']
        alarm_state = bool(sensor['output'].get())
        
        return {
            'current': current_value,
            'threshold': threshold_value,
            'alarm': alarm_state,
            'unit': sensor['unit']
        }
    
    def print_status(self):
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"\n[{timestamp}] 다중 센서 상태")
        print("-" * 60)
        
        for sensor_name in self.sensors.keys():
            data = self.get_sensor_data(sensor_name)
            alarm_str = "🚨 ALARM" if data['alarm'] else "✅ OK"
            print(f"{sensor_name:12}: {data['current']:6.1f}{data['unit']} "
                  f"(임계값: {data['threshold']:6.1f}{data['unit']}) {alarm_str}")
        
        system_status = self.system_status_pv.get(as_string=True)
        alarm_count = self.alarm_count_pv.get()
        print(f"\n시스템 상태: {system_status} (활성 알람: {alarm_count}개)")
    
    def monitor(self, interval=5):
        print("다중 센서 모니터링 시작...")
        print("Ctrl+C로 중지")
        
        try:
            while True:
                self.print_status()
                time.sleep(interval)
        except KeyboardInterrupt:
            print("\n\n모니터링 중지")

if __name__ == "__main__":
    monitor = MultiSensorMonitor()
    monitor.monitor()
```

## 자동화 스크립트

### 1. 시스템 시작 스크립트 (system_startup.sh)
```bash
#!/bin/bash
# ThresholdLogic 시스템 자동 시작 스크립트

IOC_DIR="/path/to/USB1608G_2AO_cpp"
IOC_BOOT_DIR="$IOC_DIR/iocBoot/iocUSB1608G_2AO_cpp"
LOG_FILE="$IOC_BOOT_DIR/ioc_startup.log"

echo "$(date): ThresholdLogic IOC 시작 중..." | tee -a $LOG_FILE

# IOC 디렉토리로 이동
cd $IOC_BOOT_DIR

# 기존 IOC 프로세스 확인 및 종료
if pgrep -f "USB1608G_2AO_cpp" > /dev/null; then
    echo "기존 IOC 프로세스 종료 중..." | tee -a $LOG_FILE
    pkill -f "USB1608G_2AO_cpp"
    sleep 2
fi

# IOC 시작
echo "IOC 시작..." | tee -a $LOG_FILE
nohup ../../bin/linux-x86_64/USB1608G_2AO_cpp st.cmd > ioc.log 2>&1 &

# IOC 시작 확인
sleep 5
if pgrep -f "USB1608G_2AO_cpp" > /dev/null; then
    echo "$(date): IOC 시작 성공" | tee -a $LOG_FILE
    
    # 기본 설정 적용
    sleep 2
    echo "기본 설정 적용 중..." | tee -a $LOG_FILE
    
    # ThresholdLogic 기본 설정
    caput USB1608G_2AO_cpp:ThresholdLogic1Threshold 2.5
    caput USB1608G_2AO_cpp:ThresholdLogic1Hysteresis 0.1
    caput USB1608G_2AO_cpp:ThresholdLogic1UpdateRate 10.0
    caput USB1608G_2AO_cpp:ThresholdLogic1Enable 1
    
    echo "$(date): 시스템 시작 완료" | tee -a $LOG_FILE
else
    echo "$(date): IOC 시작 실패" | tee -a $LOG_FILE
    exit 1
fi
```

### 2. 시스템 상태 점검 스크립트 (system_check.sh)
```bash
#!/bin/bash
# ThresholdLogic 시스템 상태 점검 스크립트

echo "=== ThresholdLogic 시스템 상태 점검 ==="
echo "점검 시간: $(date)"
echo

# IOC 프로세스 확인
echo "1. IOC 프로세스 상태:"
if pgrep -f "USB1608G_2AO_cpp" > /dev/null; then
    echo "   ✅ IOC 프로세스 실행 중"
    echo "   PID: $(pgrep -f USB1608G_2AO_cpp)"
else
    echo "   ❌ IOC 프로세스 실행되지 않음"
    exit 1
fi

# PV 연결 상태 확인
echo
echo "2. PV 연결 상태:"
pvs=(
    "USB1608G_2AO_cpp:ThresholdLogic1Enable"
    "USB1608G_2AO_cpp:ThresholdLogic1Threshold"
    "USB1608G_2AO_cpp:ThresholdLogic1CurrentValue"
    "USB1608G_2AO_cpp:ThresholdLogic1OutputState"
)

for pv in "${pvs[@]}"; do
    if timeout 5 caget $pv > /dev/null 2>&1; then
        echo "   ✅ $pv"
    else
        echo "   ❌ $pv (연결 실패)"
    fi
done

# 시스템 설정 확인
echo
echo "3. 현재 설정:"
echo "   임계값: $(caget -t USB1608G_2AO_cpp:ThresholdLogic1Threshold) V"
echo "   히스테리시스: $(caget -t USB1608G_2AO_cpp:ThresholdLogic1Hysteresis) V"
echo "   업데이트 주기: $(caget -t USB1608G_2AO_cpp:ThresholdLogic1UpdateRate) Hz"
echo "   활성화 상태: $(caget -t USB1608G_2AO_cpp:ThresholdLogic1Enable)"

# 현재 상태 확인
echo
echo "4. 현재 상태:"
echo "   현재값: $(caget -t USB1608G_2AO_cpp:ThresholdLogic1CurrentValue) V"
echo "   출력 상태: $(caget -t USB1608G_2AO_cpp:ThresholdLogic1OutputState)"

# 시스템 리소스 확인
echo
echo "5. 시스템 리소스:"
if pgrep -f "USB1608G_2AO_cpp" > /dev/null; then
    pid=$(pgrep -f USB1608G_2AO_cpp)
    cpu_usage=$(ps -p $pid -o %cpu --no-headers)
    mem_usage=$(ps -p $pid -o %mem --no-headers)
    echo "   CPU 사용률: ${cpu_usage}%"
    echo "   메모리 사용률: ${mem_usage}%"
fi

echo
echo "=== 점검 완료 ==="
```

### 3. 자동 백업 스크립트 (backup_settings.sh)
```bash
#!/bin/bash
# ThresholdLogic 설정 자동 백업 스크립트

BACKUP_DIR="/backup/threshold_logic"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/threshold_settings_$DATE.txt"

# 백업 디렉토리 생성
mkdir -p $BACKUP_DIR

echo "ThresholdLogic 설정 백업 - $DATE" > $BACKUP_FILE
echo "========================================" >> $BACKUP_FILE

# 현재 설정 백업
echo >> $BACKUP_FILE
echo "현재 설정:" >> $BACKUP_FILE
echo "임계값: $(caget -t USB1608G_2AO_cpp:ThresholdLogic1Threshold)" >> $BACKUP_FILE
echo "히스테리시스: $(caget -t USB1608G_2AO_cpp:ThresholdLogic1Hysteresis)" >> $BACKUP_FILE
echo "업데이트 주기: $(caget -t USB1608G_2AO_cpp:ThresholdLogic1UpdateRate)" >> $BACKUP_FILE
echo "활성화 상태: $(caget -t USB1608G_2AO_cpp:ThresholdLogic1Enable)" >> $BACKUP_FILE

# 현재 상태 백업
echo >> $BACKUP_FILE
echo "현재 상태:" >> $BACKUP_FILE
echo "현재값: $(caget -t USB1608G_2AO_cpp:ThresholdLogic1CurrentValue)" >> $BACKUP_FILE
echo "출력 상태: $(caget -t USB1608G_2AO_cpp:ThresholdLogic1OutputState)" >> $BACKUP_FILE

# 자동 저장 파일 백업
if [ -f "iocBoot/iocUSB1608G_2AO_cpp/autosave/auto_settings.sav" ]; then
    cp "iocBoot/iocUSB1608G_2AO_cpp/autosave/auto_settings.sav" "$BACKUP_DIR/auto_settings_$DATE.sav"
fi

echo "백업 완료: $BACKUP_FILE"

# 오래된 백업 파일 정리 (30일 이상)
find $BACKUP_DIR -name "threshold_settings_*.txt" -mtime +30 -delete
find $BACKUP_DIR -name "auto_settings_*.sav" -mtime +30 -delete
```

## 고급 구성

### 1. 조건부 로직 구성

#### 복합 조건 데이터베이스 (complex_logic.db)
```
# 두 개의 센서를 모두 고려한 복합 로직
record(calc, "$(P)ComplexLogic") {
    field(DESC, "Complex Threshold Logic")
    field(INPA, "$(P)ThresholdLogic1OutputState CP")
    field(INPB, "$(P)ThresholdLogic2OutputState CP")
    field(INPC, "$(P)ThresholdLogic1CurrentValue CP")
    field(INPD, "$(P)ThresholdLogic2CurrentValue CP")
    field(CALC, "(A&&B)||(C>5.0)||(D<1.0)")  # 복합 조건
    field(ONAM, "ACTIVE")
    field(ZNAM, "INACTIVE")
}

# 시간 지연 로직
record(calcout, "$(P)DelayedAction") {
    field(DESC, "Delayed Action Logic")
    field(INPA, "$(P)ComplexLogic CP")
    field(CALC, "A")
    field(ODLY, "5.0")  # 5초 지연
    field(OUT,  "$(P)FinalOutput PP")
    field(OOPT, "On Change")
}
```

### 2. 데이터 로깅 구성

#### 데이터 로거 설정 (data_logger.db)
```
# 데이터 로깅을 위한 waveform 레코드
record(waveform, "$(P)DataLog") {
    field(DESC, "Threshold Logic Data Log")
    field(NELM, "1000")
    field(FTVL, "DOUBLE")
}

# 로깅 트리거
record(calcout, "$(P)LogTrigger") {
    field(DESC, "Data Logging Trigger")
    field(INPA, "$(P)ThresholdLogic1CurrentValue CP")
    field(CALC, "A")
    field(OUT,  "$(P)DataLog PP")
    field(SCAN, "1 second")
}
```

### 3. 웹 인터페이스 구성

#### CSS/Phoebus OPI 파일 예제 (threshold_logic.opi)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<display version="2.0.0">
  <name>ThresholdLogic Control</name>
  <width>800</width>
  <height>600</height>
  
  <!-- 임계값 설정 -->
  <widget type="textupdate" version="2.0.0">
    <name>Threshold Display</name>
    <pv_name>USB1608G_2AO_cpp:ThresholdLogic1Threshold</pv_name>
    <x>100</x>
    <y>50</y>
    <width>100</width>
    <height>30</height>
  </widget>
  
  <widget type="textentry" version="2.0.0">
    <name>Threshold Entry</name>
    <pv_name>USB1608G_2AO_cpp:ThresholdLogic1Threshold</pv_name>
    <x>220</x>
    <y>50</y>
    <width>100</width>
    <height>30</height>
  </widget>
  
  <!-- 현재값 표시 -->
  <widget type="meter" version="2.0.0">
    <name>Current Value Meter</name>
    <pv_name>USB1608G_2AO_cpp:ThresholdLogic1CurrentValue</pv_name>
    <x>100</x>
    <y>150</y>
    <width>200</width>
    <height>200</height>
    <minimum>0</minimum>
    <maximum>10</maximum>
  </widget>
  
  <!-- 출력 상태 LED -->
  <widget type="led" version="2.0.0">
    <name>Output State LED</name>
    <pv_name>USB1608G_2AO_cpp:ThresholdLogic1OutputState</pv_name>
    <x>400</x>
    <y>200</y>
    <width>50</width>
    <height>50</height>
  </widget>
  
  <!-- 활성화 버튼 -->
  <widget type="bool_button" version="2.0.0">
    <name>Enable Button</name>
    <pv_name>USB1608G_2AO_cpp:ThresholdLogic1Enable</pv_name>
    <x>400</x>
    <y>300</y>
    <width>100</width>
    <height>40</height>
    <labels>
      <text>Disabled</text>
      <text>Enabled</text>
    </labels>
  </widget>
</display>
```

이 예제 구성 가이드를 통해 다양한 실제 응용 시나리오에서 ThresholdLogicController를 효과적으로 활용할 수 있습니다. 각 예제는 실제 산업 환경에서 사용할 수 있도록 구체적이고 실용적인 구성을 제공합니다.