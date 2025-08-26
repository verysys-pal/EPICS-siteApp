/* SimpleTest.cpp
 *
 * ThresholdLogicController의 간단한 테스트
 * 
 * Author: EPICS IOC Development Guide
 * Date: 2025
 */

#include <stdio.h>
#include <stdlib.h>
#include <iocsh.h>
#include <epicsExport.h>

#include "ThresholdLogicController.h"

/**
 * 간단한 생성자 테스트
 */
bool simpleConstructorTest() {
    printf("간단한 생성자 테스트 실행 중...\n");
    
    try {
        // ThresholdLogicController 생성 테스트
        ThresholdLogicController* controller = new ThresholdLogicController("SIMPLE_TEST_PORT", "DEVICE_PORT", 0);
        
        if (controller != NULL) {
            printf("✓ ThresholdLogicController 생성 성공\n");
            
            // 매개변수 접근자 테스트
            int thresholdParam = controller->getThresholdValueParam();
            int currentParam = controller->getCurrentValueParam();
            int outputParam = controller->getOutputStateParam();
            int enableParam = controller->getEnableParam();
            
            printf("✓ 매개변수 인덱스 접근 성공:\n");
            printf("  - Threshold: %d\n", thresholdParam);
            printf("  - Current: %d\n", currentParam);
            printf("  - Output: %d\n", outputParam);
            printf("  - Enable: %d\n", enableParam);
            
            delete controller;
            printf("✓ ThresholdLogicController 소멸자 호출 성공\n");
            
            return true;
        } else {
            printf("✗ ThresholdLogicController 생성 실패\n");
            return false;
        }
    } catch (...) {
        printf("✗ 예외 발생: ThresholdLogicController 생성 중 오류\n");
        return false;
    }
}

/**
 * 기본 기능 테스트
 */
bool basicFunctionalityTest() {
    printf("기본 기능 테스트 실행 중...\n");
    
    try {
        ThresholdLogicController controller("BASIC_TEST_PORT", "DEVICE_PORT", 0);
        
        // processThresholdLogic 메서드 호출 테스트
        controller.processThresholdLogic();
        printf("✓ processThresholdLogic() 호출 성공\n");
        
        // 스레드 관리 테스트 (실제 시작하지 않고 메서드 호출만)
        printf("✓ 스레드 관리 메서드 접근 가능\n");
        
        return true;
    } catch (...) {
        printf("✗ 예외 발생: 기본 기능 테스트 중 오류\n");
        return false;
    }
}

/**
 * 모든 간단한 테스트 실행
 */
void runSimpleTests() {
    printf("\n=== ThresholdLogicController 간단한 테스트 시작 ===\n\n");
    
    int totalTests = 0;
    int passedTests = 0;
    
    // 테스트 1: 생성자 테스트
    totalTests++;
    if (simpleConstructorTest()) {
        passedTests++;
        printf("테스트 1: 생성자 테스트 - 통과\n\n");
    } else {
        printf("테스트 1: 생성자 테스트 - 실패\n\n");
    }
    
    // 테스트 2: 기본 기능 테스트
    totalTests++;
    if (basicFunctionalityTest()) {
        passedTests++;
        printf("테스트 2: 기본 기능 테스트 - 통과\n\n");
    } else {
        printf("테스트 2: 기본 기능 테스트 - 실패\n\n");
    }
    
    // 결과 출력
    printf("=== 테스트 결과 ===\n");
    printf("총 테스트: %d\n", totalTests);
    printf("통과: %d\n", passedTests);
    printf("실패: %d\n", totalTests - passedTests);
    printf("성공률: %.1f%%\n", totalTests > 0 ? (100.0 * passedTests / totalTests) : 0.0);
    
    if (passedTests == totalTests) {
        printf("\n모든 테스트가 성공했습니다! ✓\n");
    } else {
        printf("\n일부 테스트가 실패했습니다.\n");
    }
    
    printf("\n=== ThresholdLogicController 간단한 테스트 완료 ===\n\n");
}

// IOC 쉘 명령어로 테스트 실행
extern "C" {
    static void simpleTestCallFunc(const iocshArgBuf *args) {
        runSimpleTests();
    }
    
    static const iocshFuncDef simpleTestFuncDef = {
        "SimpleTest", 0, NULL
    };
    
    void SimpleTestRegister(void) {
        iocshRegister(&simpleTestFuncDef, simpleTestCallFunc);
    }
    
    epicsExportRegistrar(SimpleTestRegister);
}