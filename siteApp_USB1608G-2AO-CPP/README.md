# ThresholdLogicController 문서

이 디렉토리는 ThresholdLogicController의 포괄적인 문서를 포함합니다.


## kiro 스팩문서

### .kiro/steering
---
1. [한국어 규칙](./.kiro/steering/korean-language.md)

2. [Product Overview](./.kiro/steering/product.md)
    - **Key Features**
      - Multi-function USB DAQ device support (USB1608G-2AO)
      - Analog input/output channels
      - Digital I/O capabilities  
      - Counter/timer functionality
      - Waveform generation and digitization
      - Temperature measurement support
      - EPICS Channel Access integration

3. [Project Structure](./.kiro/steering/structure.md)
      ```
      ├── configure/          # Build configuration and dependencies
      ├── USB1608G_2AO_cppApp/ # Main application directory
      ├── db/                 # Database templates (top-level copies)
      ├── dbd/                # Database definitions
      ├── iocBoot/            # IOC boot configurations
      ├── bin/                # Compiled executables
      └── lib/                # Compiled libraries
      ```

4. [Technology Stack](./.kiro/steering/tech.md)    
    - **EPICS Base**: `/usr/local/epics/EPICS_R7.0/base`
    - **synApps Support Modules**:
      - asyn-R4-44-2 (Asynchronous driver support)
      - calc-R3-7-5 (Calculation records)
      - scaler-4-1 (Scaler support)
      - mca-R7-10 (Multi-channel analyzer)
      - busy-R1-7-4 (Busy record)
      - sscan-R2-11-6 (Scanning support)
      - autosave-R5-11 (Settings persistence)
      - sequencer-mirror-R2-2-9 (State notation language)
      - measComp-R4-2 (Measurement Computing driver support)

### .kiro/specs
---
1. [Requirements](./.kiro/specs/epics-ioc-development-guide/requirements.md)
    - 요구사항 1: 프로젝트 구조 가이드
    - 요구사항 2: 파일 의존성 관계 문서화
    - 요구사항 3: 개발 명세서 작성
    - 요구사항 4: 자동 임계값 로직 제어 구현 가이드
    - 요구사항 5: 빌드 시스템 최적화 가이드
    - 요구사항 6: 데이터베이스 템플릿 설계 가이드
    - 요구사항 7: 파일변경 범위
    - 요구사항 8: MEDM 생성 및 시험용 스크립트 작성

2. [Design](./.kiro/specs/epics-ioc-development-guide/design.md)
    - 전체 시스템 아키텍처
    - 구성 요소 및 인터페이스
    - 데이터 모델
    - 오류 처리
    - 테스트 전략
    - 배포 및 설치

3. [tasks](./.kiro/specs/epics-ioc-development-guide/tasks.md)
    - ThresholdLogicController 헤더 파일 생성
    - ThresholdLogicController 기본 구현
    - 임계값 로직 알고리즘 구현
    - 실시간 모니터링 스레드 구현
    - asyn 매개변수 읽기/쓰기 메서드 구현
    - IOC 쉘 명령어 등록 구현
    - 오류 처리 및 로깅 시스템 구현
    - ThresholdLogic 데이터베이스 템플릿 생성
    - IOC 시작 스크립트 통합
    -  설정 저장 및 복원 기능 구현
    -  데이터베이스 치환 파일 생성
    -  빌드 시스템 통합
    -  단위 테스트 작성
    -  통합 테스트 및 검증
    -  문서화 및 사용 가이드 작성


<br/>  
<br/>  
<br/>  

## 문서 목록

### 1. [사용자 매뉴얼](./docs/ThresholdLogicController_User_Manual.md)
- 설치 가이드
- 기본 사용법
- 고급 설정
- 모니터링 및 제어
- 문제 해결

### 2. [API 문서](./docs/ThresholdLogicController_API_Documentation.md)
- 클래스 개요 및 상속 관계
- 생성자 및 소멸자
- 공개 메서드 상세 설명
- 매개변수 정의
- IOC 쉘 명령어
- 데이터베이스 인터페이스
- 예제 코드
- 오류 처리

### 3. [문제 해결 가이드](./docs/ThresholdLogicController_Troubleshooting_Guide.md)
- 일반적인 문제 및 해결 방법
- 설치 및 빌드 문제
- IOC 시작 문제
- 통신 및 연결 문제
- 성능 및 안정성 문제
- 하드웨어 관련 문제
- 디버깅 도구 및 기법
- FAQ

### 4. [예제 구성 가이드](./docs/ThresholdLogicController_Examples.md)
- 기본 예제
- 온도 모니터링 시스템
- 압력 안전 시스템
- 다중 채널 모니터링
- 자동화 스크립트
- 고급 구성

<br/>  
<br/>  
<br/>  

## 빠른 시작

### 1. 기본 설치 및 실행
```bash
# 프로젝트 빌드
make clean
make

# IOC 시작
cd iocBoot/iocUSB1608G_2AO_cpp
../../bin/linux-x86_64/USB1608G_2AO_cpp st.cmd

# 기본 설정 (별도 터미널)
caput USB1608G_2AO_cpp:ThresholdLogic1Threshold 2.5
caput USB1608G_2AO_cpp:ThresholdLogic1Enable 1
```

### 2. 상태 모니터링
```bash
# 실시간 모니터링
camonitor USB1608G_2AO_cpp:ThresholdLogic1CurrentValue USB1608G_2AO_cpp:ThresholdLogic1OutputState
```

<br/>  
<br/>  
<br/>  

## 주요 기능

- **실시간 임계값 비교**: 아날로그 입력을 지속적으로 모니터링
- **히스테리시스 지원**: 출력 진동 방지
- **다중 컨트롤러**: 여러 개의 독립적인 임계값 로직 컨트롤러
- **EPICS 통합**: Channel Access를 통한 원격 제어 및 모니터링
- **실시간 알람**: 상태 변화 및 오류에 대한 즉각적인 알림

## 시스템 요구사항

- EPICS Base R7.0 이상
- Linux x86_64 운영체제
- USB1608G-2AO 하드웨어 (또는 호환 장치)
- measComp 드라이버 모듈

## 지원 및 문의

문제가 발생하거나 추가 지원이 필요한 경우:

1. [문제 해결 가이드](ThresholdLogicController_Troubleshooting_Guide.md)를 먼저 확인
2. IOC 로그 및 asyn 추적 정보 수집
3. 기술 지원팀에 문의

## 라이선스

이 소프트웨어는 EPICS 라이선스 하에 배포됩니다.

## 버전 정보

- 현재 버전: 1.0.0
- 최종 업데이트: 2025년 8월 20일
- EPICS Base 호환성: R7.0+