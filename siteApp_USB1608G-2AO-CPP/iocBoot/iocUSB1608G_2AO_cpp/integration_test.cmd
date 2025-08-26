#!../../bin/linux-x86_64/USB1608G_2AO_cpp
# 통합 테스트를 위한 IOC 시작 스크립트

< envPaths

## Register all support components
dbLoadDatabase("$(TOP)/dbd/USB1608G_2AO_cpp.dbd")
USB1608G_2AO_cpp_registerRecordDeviceDriver(pdbbase)

epicsEnvSet("PREFIX", "USB1608G_2AO_cpp:")
epicsEnvSet("PORT", "USB1608G_2AO_cpp_PORT")
epicsEnvSet("WDIG_POINTS", "1048576")
epicsEnvSet("WGEN_POINTS", "1048576")
epicsEnvSet("UNIQUE_ID", "01D97CFA")

## Configure port driver
MultiFunctionConfig("$(PORT)", "$(UNIQUE_ID)", $(WDIG_POINTS), $(WGEN_POINTS))

## Configure threshold logic controller for testing
epicsEnvSet("THRESHOLD_PORT", "THRESHOLD_LOGIC_PORT")
ThresholdLogicConfig("$(THRESHOLD_PORT)", "$(PORT)", 0)

# Load database templates
dbLoadTemplate("$(TOP)/USB1608G_2AO_cppApp/Db/USB1608G_2AO_cpp.substitutions", "P=$(PREFIX),PORT=$(PORT),WDIG_POINTS=$(WDIG_POINTS),WGEN_POINTS=$(WGEN_POINTS)")

# Load autosave configuration
< save_restore.cmd

# Initialize IOC
iocInit

# Create monitor set for autosave
create_monitor_set("auto_settings.req",30,"P=$(PREFIX)")

# 통합 테스트 시작
echo "=== 통합 테스트 시작 ==="

# 1. ThresholdLogicController 초기화 테스트
echo "1. ThresholdLogicController 초기화 테스트"
dbpf $(PREFIX)ThresholdLogic1Enable 1
dbpf $(PREFIX)ThresholdLogic2Enable 1

# 2. 임계값 설정 테스트
echo "2. 임계값 설정 테스트"
dbpf $(PREFIX)ThresholdLogic1Threshold 2.5
dbpf $(PREFIX)ThresholdLogic1Hysteresis 0.1

# 3. 현재 상태 확인
echo "3. 현재 상태 확인"
dbpr $(PREFIX)ThresholdLogic1Threshold
dbpr $(PREFIX)ThresholdLogic1CurrentValue
dbpr $(PREFIX)ThresholdLogic1OutputState
dbpr $(PREFIX)ThresholdLogic1Enable

# 4. 데이터베이스 레코드 목록 출력
echo "4. 데이터베이스 레코드 목록"
dbl

# 5. 포트 드라이버 상태 확인
echo "5. 포트 드라이버 상태 확인"
asynReport 1

echo "=== 통합 테스트 완료 ==="
echo "IOC가 실행 중입니다. Channel Access 클라이언트로 테스트할 수 있습니다."