#!/bin/bash
# Channel Access 통합 테스트 스크립트

PREFIX="USB1608G_2AO_cpp:"

echo "=== Channel Access 통합 테스트 시작 ==="

# 테스트 함수 정의
test_ca_connection() {
    echo "1. Channel Access 연결 테스트"
    caget ${PREFIX}ThresholdLogic1Enable
    if [ $? -eq 0 ]; then
        echo "   ✓ Channel Access 연결 성공"
    else
        echo "   ✗ Channel Access 연결 실패"
        return 1
    fi
}

test_threshold_logic_control() {
    echo "2. ThresholdLogic 제어 테스트"
    
    # 임계값 설정 테스트
    echo "   2.1 임계값 설정 테스트"
    caput ${PREFIX}ThresholdLogic1Threshold 3.0
    THRESHOLD=$(caget -t ${PREFIX}ThresholdLogic1Threshold)
    echo "   설정된 임계값: $THRESHOLD"
    
    # 히스테리시스 설정 테스트
    echo "   2.2 히스테리시스 설정 테스트"
    caput ${PREFIX}ThresholdLogic1Hysteresis 0.2
    HYSTERESIS=$(caget -t ${PREFIX}ThresholdLogic1Hysteresis)
    echo "   설정된 히스테리시스: $HYSTERESIS"
    
    # 활성화 상태 제어 테스트
    echo "   2.3 활성화 상태 제어 테스트"
    caput ${PREFIX}ThresholdLogic1Enable 1
    ENABLE=$(caget -t ${PREFIX}ThresholdLogic1Enable)
    echo "   활성화 상태: $ENABLE"
}

test_monitoring() {
    echo "3. 실시간 모니터링 테스트"
    
    # 현재 값 모니터링
    echo "   3.1 현재 값 모니터링 (5초간)"
    camonitor -# 5 ${PREFIX}ThresholdLogic1CurrentValue &
    MONITOR_PID=$!
    sleep 5
    kill $MONITOR_PID 2>/dev/null
    
    # 출력 상태 확인
    echo "   3.2 출력 상태 확인"
    OUTPUT_STATE=$(caget -t ${PREFIX}ThresholdLogic1OutputState)
    echo "   현재 출력 상태: $OUTPUT_STATE"
}

test_record_communication() {
    echo "4. EPICS 레코드 통신 테스트"
    
    # 모든 ThresholdLogic 관련 레코드 확인
    echo "   4.1 ThresholdLogic 레코드 목록"
    caget ${PREFIX}ThresholdLogic1*
    
    echo "   4.2 ThresholdLogic2 레코드 목록"
    caget ${PREFIX}ThresholdLogic2*
}

test_alarm_handling() {
    echo "5. 알람 처리 테스트"
    
    # 알람 상태 확인
    echo "   5.1 알람 상태 확인"
    caget -a ${PREFIX}ThresholdLogic1CurrentValue
    caget -a ${PREFIX}ThresholdLogic1OutputState
}

# 테스트 실행
echo "IOC가 실행 중인지 확인하세요..."
sleep 2

test_ca_connection
if [ $? -ne 0 ]; then
    echo "Channel Access 연결에 실패했습니다. IOC가 실행 중인지 확인하세요."
    exit 1
fi

test_threshold_logic_control
test_monitoring
test_record_communication
test_alarm_handling

echo ""
echo "=== Channel Access 통합 테스트 완료 ==="
echo "모든 테스트가 완료되었습니다."