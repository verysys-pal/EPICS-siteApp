#!/usr/bin/env python3
"""
EPICS 레코드와 드라이버 간 통신 테스트 스크립트
Python Channel Access 클라이언트를 사용한 자동화된 테스트
"""

import epics
import time
import sys

class ThresholdLogicIntegrationTest:
    def __init__(self, prefix="USB1608G_2AO_cpp:"):
        self.prefix = prefix
        self.test_results = []
        
    def log_test(self, test_name, result, message=""):
        """테스트 결과 로깅"""
        status = "PASS" if result else "FAIL"
        print(f"[{status}] {test_name}: {message}")
        self.test_results.append((test_name, result, message))
        
    def test_pv_connection(self):
        """PV 연결 테스트"""
        print("\n=== PV 연결 테스트 ===")
        
        test_pvs = [
            "ThresholdLogic1Enable",
            "ThresholdLogic1Threshold", 
            "ThresholdLogic1CurrentValue",
            "ThresholdLogic1OutputState",
            "ThresholdLogic1Hysteresis"
        ]
        
        for pv_name in test_pvs:
            full_pv = self.prefix + pv_name
            pv = epics.PV(full_pv)
            connected = pv.wait_for_connection(timeout=5.0)
            self.log_test(f"PV 연결: {pv_name}", connected, 
                         f"PV: {full_pv}")
            
    def test_threshold_logic_functionality(self):
        """임계값 로직 기능 테스트"""
        print("\n=== 임계값 로직 기능 테스트 ===")
        
        # PV 객체 생성
        enable_pv = epics.PV(self.prefix + "ThresholdLogic1Enable")
        threshold_pv = epics.PV(self.prefix + "ThresholdLogic1Threshold")
        hysteresis_pv = epics.PV(self.prefix + "ThresholdLogic1Hysteresis")
        current_pv = epics.PV(self.prefix + "ThresholdLogic1CurrentValue")
        output_pv = epics.PV(self.prefix + "ThresholdLogic1OutputState")
        
        # 연결 대기
        time.sleep(1)
        
        # 1. 활성화 테스트
        enable_pv.put(1)
        time.sleep(0.5)
        enable_value = enable_pv.get()
        self.log_test("활성화 설정", enable_value == 1, 
                     f"설정값: {enable_value}")
        
        # 2. 임계값 설정 테스트
        test_threshold = 2.5
        threshold_pv.put(test_threshold)
        time.sleep(0.5)
        threshold_value = threshold_pv.get()
        threshold_ok = abs(threshold_value - test_threshold) < 0.01
        self.log_test("임계값 설정", threshold_ok,
                     f"설정값: {test_threshold}, 읽은값: {threshold_value}")
        
        # 3. 히스테리시스 설정 테스트
        test_hysteresis = 0.1
        hysteresis_pv.put(test_hysteresis)
        time.sleep(0.5)
        hysteresis_value = hysteresis_pv.get()
        hysteresis_ok = abs(hysteresis_value - test_hysteresis) < 0.01
        self.log_test("히스테리시스 설정", hysteresis_ok,
                     f"설정값: {test_hysteresis}, 읽은값: {hysteresis_value}")
        
        # 4. 현재값 읽기 테스트
        current_value = current_pv.get()
        current_ok = current_value is not None
        self.log_test("현재값 읽기", current_ok,
                     f"현재값: {current_value}")
        
        # 5. 출력 상태 읽기 테스트
        output_value = output_pv.get()
        output_ok = output_value is not None
        self.log_test("출력 상태 읽기", output_ok,
                     f"출력 상태: {output_value}")
                     
    def test_real_time_monitoring(self):
        """실시간 모니터링 테스트"""
        print("\n=== 실시간 모니터링 테스트 ===")
        
        current_pv = epics.PV(self.prefix + "ThresholdLogic1CurrentValue")
        output_pv = epics.PV(self.prefix + "ThresholdLogic1OutputState")
        
        # 콜백 함수 정의
        self.callback_count = 0
        def value_callback(pvname=None, value=None, **kwargs):
            self.callback_count += 1
            print(f"  콜백 수신: {pvname} = {value}")
            
        # 콜백 등록
        current_pv.add_callback(value_callback)
        output_pv.add_callback(value_callback)
        
        print("  5초간 콜백 모니터링...")
        time.sleep(5)
        
        # 콜백 해제
        current_pv.clear_callbacks()
        output_pv.clear_callbacks()
        
        callback_ok = self.callback_count > 0
        self.log_test("실시간 콜백", callback_ok,
                     f"수신된 콜백 수: {self.callback_count}")
                     
    def test_multiple_controllers(self):
        """다중 컨트롤러 테스트"""
        print("\n=== 다중 컨트롤러 테스트 ===")
        
        controllers = ["ThresholdLogic1", "ThresholdLogic2"]
        
        for controller in controllers:
            enable_pv = epics.PV(self.prefix + controller + "Enable")
            threshold_pv = epics.PV(self.prefix + controller + "Threshold")
            
            # 연결 테스트
            connected = enable_pv.wait_for_connection(timeout=3.0)
            self.log_test(f"{controller} 연결", connected)
            
            if connected:
                # 기본 기능 테스트
                enable_pv.put(1)
                threshold_pv.put(1.0 + controllers.index(controller))
                time.sleep(0.5)
                
                enable_val = enable_pv.get()
                threshold_val = threshold_pv.get()
                
                self.log_test(f"{controller} 기능", 
                             enable_val == 1 and threshold_val is not None,
                             f"Enable: {enable_val}, Threshold: {threshold_val}")
                             
    def test_error_conditions(self):
        """오류 조건 테스트"""
        print("\n=== 오류 조건 테스트 ===")
        
        threshold_pv = epics.PV(self.prefix + "ThresholdLogic1Threshold")
        
        # 잘못된 값 설정 테스트 (매우 큰 값)
        original_value = threshold_pv.get()
        threshold_pv.put(1e10)  # 매우 큰 값
        time.sleep(0.5)
        
        new_value = threshold_pv.get()
        # 드라이버가 값을 제한했는지 확인
        value_limited = new_value != 1e10
        self.log_test("큰 값 제한", value_limited,
                     f"설정 시도: 1e10, 실제값: {new_value}")
        
        # 원래 값으로 복원
        threshold_pv.put(original_value)
        
    def run_all_tests(self):
        """모든 테스트 실행"""
        print("ThresholdLogic 통합 테스트 시작")
        print(f"PV 접두사: {self.prefix}")
        
        self.test_pv_connection()
        self.test_threshold_logic_functionality()
        self.test_real_time_monitoring()
        self.test_multiple_controllers()
        self.test_error_conditions()
        
        # 결과 요약
        print("\n=== 테스트 결과 요약 ===")
        passed = sum(1 for _, result, _ in self.test_results if result)
        total = len(self.test_results)
        
        print(f"총 테스트: {total}")
        print(f"통과: {passed}")
        print(f"실패: {total - passed}")
        print(f"성공률: {passed/total*100:.1f}%")
        
        if passed == total:
            print("모든 테스트가 성공했습니다! ✓")
            return True
        else:
            print("일부 테스트가 실패했습니다. ✗")
            return False

if __name__ == "__main__":
    # epics 모듈 확인
    try:
        import epics
    except ImportError:
        print("pyepics 모듈이 필요합니다: pip install pyepics")
        sys.exit(1)
    
    # 테스트 실행
    tester = ThresholdLogicIntegrationTest()
    success = tester.run_all_tests()
    
    sys.exit(0 if success else 1)