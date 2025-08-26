#!/bin/bash
# ThresholdLogic 통합 테스트 실행 스크립트

echo "=== ThresholdLogic 통합 테스트 실행 ==="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# IOC 프로세스 확인
check_ioc_running() {
    log_info "IOC 프로세스 확인 중..."
    if pgrep -f "USB1608G_2AO_cpp" > /dev/null; then
        log_info "IOC가 실행 중입니다."
        return 0
    else
        log_warn "IOC가 실행 중이지 않습니다."
        return 1
    fi
}

# IOC 시작
start_ioc() {
    log_info "통합 테스트용 IOC 시작 중..."
    
    # 기존 IOC 프로세스 종료
    pkill -f "USB1608G_2AO_cpp" 2>/dev/null
    sleep 2
    
    # IOC 백그라운드 실행
    cd "$(dirname "$0")"
    nohup ./integration_test.cmd > integration_test.log 2>&1 &
    IOC_PID=$!
    
    log_info "IOC PID: $IOC_PID"
    
    # IOC 초기화 대기
    log_info "IOC 초기화 대기 중 (10초)..."
    sleep 10
    
    # IOC 상태 확인
    if check_ioc_running; then
        log_info "IOC가 성공적으로 시작되었습니다."
        return 0
    else
        log_error "IOC 시작에 실패했습니다."
        return 1
    fi
}

# 테스트 1: Channel Access 기본 테스트
test_channel_access() {
    log_info "테스트 1: Channel Access 기본 테스트"
    
    if command -v caget > /dev/null; then
        ./ca_integration_test.sh
        if [ $? -eq 0 ]; then
            log_info "Channel Access 테스트 성공"
            return 0
        else
            log_error "Channel Access 테스트 실패"
            return 1
        fi
    else
        log_warn "caget 명령어를 찾을 수 없습니다. EPICS 환경을 확인하세요."
        return 1
    fi
}

# 테스트 2: Python 자동화 테스트
test_python_automation() {
    log_info "테스트 2: Python 자동화 테스트"
    
    if command -v python3 > /dev/null; then
        python3 record_driver_test.py
        if [ $? -eq 0 ]; then
            log_info "Python 자동화 테스트 성공"
            return 0
        else
            log_error "Python 자동화 테스트 실패"
            return 1
        fi
    else
        log_warn "python3를 찾을 수 없습니다."
        return 1
    fi
}

# 테스트 3: 성능 및 안정성 테스트
test_performance() {
    log_info "테스트 3: 성능 및 안정성 테스트"
    
    PREFIX="USB1608G_2AO_cpp:"
    
    if command -v caget > /dev/null; then
        log_info "연속 읽기 테스트 (30초간)..."
        
        start_time=$(date +%s)
        count=0
        errors=0
        
        while [ $(($(date +%s) - start_time)) -lt 30 ]; do
            if caget ${PREFIX}ThresholdLogic1CurrentValue > /dev/null 2>&1; then
                count=$((count + 1))
            else
                errors=$((errors + 1))
            fi
            sleep 0.1
        done
        
        log_info "성능 테스트 결과:"
        log_info "  총 읽기 횟수: $count"
        log_info "  오류 횟수: $errors"
        log_info "  성공률: $(echo "scale=2; $count * 100 / ($count + $errors)" | bc -l)%"
        
        if [ $errors -lt $((count / 10)) ]; then  # 오류율 10% 미만
            log_info "성능 테스트 성공"
            return 0
        else
            log_error "성능 테스트 실패 (오류율이 너무 높음)"
            return 1
        fi
    else
        log_warn "caget 명령어를 찾을 수 없습니다."
        return 1
    fi
}

# IOC 정리
cleanup_ioc() {
    log_info "IOC 프로세스 정리 중..."
    pkill -f "USB1608G_2AO_cpp" 2>/dev/null
    sleep 2
    log_info "정리 완료"
}

# 메인 테스트 실행
main() {
    log_info "통합 테스트 시작"
    
    # 테스트 결과 추적
    test_results=()
    
    # IOC가 실행 중인지 확인
    if ! check_ioc_running; then
        log_info "테스트용 IOC를 시작합니다..."
        if ! start_ioc; then
            log_error "IOC 시작 실패. 테스트를 중단합니다."
            exit 1
        fi
        IOC_STARTED_BY_TEST=true
    else
        log_info "기존 IOC를 사용합니다."
        IOC_STARTED_BY_TEST=false
    fi
    
    # 테스트 실행
    echo ""
    test_channel_access
    test_results+=($?)
    
    echo ""
    test_python_automation  
    test_results+=($?)
    
    echo ""
    test_performance
    test_results+=($?)
    
    # 테스트용 IOC 정리
    if [ "$IOC_STARTED_BY_TEST" = true ]; then
        cleanup_ioc
    fi
    
    # 결과 요약
    echo ""
    log_info "=== 통합 테스트 결과 요약 ==="
    
    passed=0
    total=${#test_results[@]}
    
    for result in "${test_results[@]}"; do
        if [ $result -eq 0 ]; then
            passed=$((passed + 1))
        fi
    done
    
    log_info "총 테스트: $total"
    log_info "통과: $passed"
    log_info "실패: $((total - passed))"
    
    if [ $passed -eq $total ]; then
        log_info "모든 통합 테스트가 성공했습니다! ✓"
        exit 0
    else
        log_error "일부 통합 테스트가 실패했습니다. ✗"
        exit 1
    fi
}

# 스크립트 실행
main "$@"