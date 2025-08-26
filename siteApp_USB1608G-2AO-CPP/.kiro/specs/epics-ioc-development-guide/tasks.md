# 구현 계획

- [x] 1. ThresholdLogicController 헤더 파일 생성
  - ThresholdLogicController.h 파일을 생성하여 클래스 선언과 인터페이스를 정의
  - asynPortDriver 상속 구조와 필요한 매개변수 인덱스 정의
  - 스레드 관리와 임계값 로직을 위한 private 멤버 변수 선언
  - _요구사항: 4.1, 4.2_

- [x] 2. ThresholdLogicController 기본 구현
  - ThresholdLogicController.cpp 파일을 생성하여 기본 생성자와 소멸자 구현
  - asynPortDriver 초기화 및 매개변수 생성 코드 작성
  - 기본적인 읽기/쓰기 메서드 스켈레톤 구현
  - _요구사항: 4.1, 4.2_

- [x] 3. 임계값 로직 알고리즘 구현
  - processThresholdLogic() 메서드에서 임계값 비교 및 히스테리시스 로직 구현
  - 상태 변화 감지 및 출력 제어 로직 작성
  - 알람 상태 설정 및 타임스탬프 업데이트 기능 구현
  - _요구사항: 4.1, 4.2_

- [x] 4. 실시간 모니터링 스레드 구현
  - epicsThread를 사용한 모니터링 스레드 생성 및 관리
  - monitorThreadFunc() 정적 메서드 구현으로 주기적 데이터 수집
  - 스레드 시작/정지 제어 메서드 구현
  - _요구사항: 4.2_

- [x] 5. asyn 매개변수 읽기/쓰기 메서드 구현
  - writeFloat64() 및 readFloat64() 메서드에서 임계값 및 현재값 처리
  - writeInt32() 및 readInt32() 메서드에서 활성화 상태 및 출력 상태 처리
  - 매개변수 유효성 검사 및 오류 처리 로직 추가
  - _요구사항: 4.1, 4.3_

- [x] 6. IOC 쉘 명령어 등록 구현
  - ThresholdLogicConfig() 함수 구현으로 포트 구성 기능 제공
  - iocsh 명령어 등록 함수 작성 및 매개변수 정의
  - 명령어 도움말 및 사용법 문서화
  - _요구사항: 4.3_

- [x] 7. 오류 처리 및 로깅 시스템 구현
  - ErrorHandler 클래스 구현으로 오류 분류 및 로깅 기능 제공
  - EPICS 알람 시스템과 통합된 상태 보고 기능 구현
  - 구성 유효성 검사 및 런타임 오류 처리 로직 작성
  - _요구사항: 5.3_

- [x] 8. ThresholdLogic 데이터베이스 템플릿 생성
  - ThresholdLogic.template 파일을 생성하여 임계값 제어용 EPICS 레코드 정의
  - 아날로그 입출력, 바이너리 입출력 레코드를 사용한 인터페이스 구현
  - 매개변수 치환을 위한 매크로 정의 및 기본값 설정
  - _요구사항: 6.1, 6.2_

- [x] 9. IOC 시작 스크립트 통합
  - st.cmd 파일에 ThresholdLogicConfig 명령어 추가
  - 환경 변수 설정 및 데이터베이스 로드 구성
  - 자동 저장/복원 기능을 위한 설정 파일 통합
  - _요구사항: 7.1, 7.2_

- [x] 10. 설정 저장 및 복원 기능 구현
  - threshold_logic_settings.req 파일 생성으로 중요 매개변수 자동 저장 설정
  - auto_settings.req 파일에 임계값 로직 설정 통합
  - EPICS autosave 모듈과 연동하여 IOC 재시작 시 설정 복원
  - _요구사항: 7.2_

- [x] 11. 데이터베이스 치환 파일 생성
  - USB1608G_2AO_cpp.substitutions 파일에 임계값 로직 인스턴스 추가
  - 매크로 치환을 통한 다중 임계값 로직 컨트롤러 지원
  - 포트 이름 및 주소 매핑 구성
  - _요구사항: 6.2_

- [x] 12. 빌드 시스템 통합
  - Makefile에 ThresholdLogicController 소스 파일 추가
  - thresholdLogicSupport.dbd 파일 생성 및 등록
  - 의존성 라이브러리 및 헤더 파일 경로 설정
  - _요구사항: 8.1_

- [x] 13. 단위 테스트 작성
  - ThresholdLogicController 클래스의 핵심 메서드에 대한 단위 테스트 작성
  - 임계값 로직 알고리즘의 다양한 시나리오 테스트 케이스 구현
  - 오류 처리 및 경계 조건 테스트 추가
  - SimpleTest.cpp 파일로 간단하고 안정적인 테스트 프레임워크 구현
  - simpleTestSupport.dbd 및 simpleTest.cmd 파일로 테스트 실행 환경 구성
  - TEST_README.md 파일로 테스트 가이드 문서 작성
  - _요구사항: 3.3_


- [x] 14. 통합 테스트 및 검증
  - 실제 IOC 환경에서 ThresholdLogicController 동작 검증
  - EPICS 레코드와 드라이버 간 통신 테스트 수행
  - Channel Access 클라이언트를 통한 원격 제어 테스트
  - _요구사항: 3.3_

- [x] 15. 문서화 및 사용 가이드 작성
  - 사용자 매뉴얼 및 설치 가이드 작성
  - API 문서 및 예제 코드 제공
  - 문제 해결 가이드 작성
  - _요구사항: 8.2_
  - ThresholdLogicController 사용법 및 구성 방법 문서화
  - 예제 구성 파일 및 테스트 스크립트 제공
  - 문제 해결 가이드 및 FAQ 작성
  - _요구사항: 1.1, 2.2, 3.1_


  