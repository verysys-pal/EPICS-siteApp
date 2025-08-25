## 🧰 EPICS IOC 자동 생성 스크립트

### `siteApp_USB1608G_2AO.sh`

본 스크립트는 EPICS 환경에서 USB1608G_2AO 디바이스용 IOC 애플리케이션을 자동으로 생성, 구성, 빌드, 실행하는 목적으로 작성되었다.

---

### 📦 주요 정보

| 항목 | 내용 |
|------|------|
| **스크립트명** | `siteApp_USB1608G_2AO.sh` |
| **타겟 디바이스** | USB1608G_2AO (Measurement Computing) |
| **EPICS 버전** | EPICS R7.0 |
| **지원 모듈** | measComp, asyn, autosave, calc, sscan 등 |
| **로그 경로** | `/root/log/siteApp_USB1608G_2AO_*.log` |

---

# 프로젝트 구조 및 폴더 조직

## 최상위 디렉토리 구조
```
USB1608G_2AO/
├── configure/          # 빌드 설정 및 의존성 정의
├── USB1608G_2AOApp/    # 메인 애플리케이션 코드
├── iocBoot/            # IOC 부팅 스크립트 및 설정
├── bin/                # 컴파일된 실행 파일
├── lib/                # 컴파일된 라이브러리
├── db/                 # 데이터베이스 템플릿 파일 (중복, App/Db 사용 권장)
├── dbd/                # 데이터베이스 정의 파일
└── Makefile           # 최상위 빌드 파일
```

## 애플리케이션 구조 (USB1608G_2AOApp/)
```
USB1608G_2AOApp/
├── src/                # C/C++ 소스 코드
│   ├── Makefile       # 소스 빌드 설정
│   ├── *Main.cpp      # IOC 메인 진입점
│   ├── drv*.cpp       # 디바이스 드라이버
│   ├── *.st           # State Notation Language 파일
│   └── O.linux-x86_64/ # 아키텍처별 빌드 출력
├── Db/                 # 데이터베이스 템플릿 및 치환 파일
│   ├── *.template     # EPICS 레코드 템플릿
│   ├── *.substitutions # 템플릿 인스턴스화 파일
│   └── *_settings.req # autosave 설정 파일
└── op/                 # 운영자 인터페이스 (MEDM 화면)
    └── *.adl          # MEDM 디스플레이 파일
```

## IOC 부팅 구조 (iocBoot/)
```
iocBoot/
├── iocUSB1608G_2AO/   # 특정 IOC 인스턴스
│   ├── st.cmd         # 시작 스크립트
│   ├── envPaths       # 환경 경로 설정
│   ├── auto_settings.req # autosave 요청 파일
│   ├── autosave/      # 저장된 설정 파일들
│   └── *.sh           # 유틸리티 스크립트
```

## 파일 명명 규칙
- **템플릿 파일**: `measComp*.template` - 기능별 EPICS 레코드 정의
- **치환 파일**: `*.substitutions` - 템플릿 인스턴스화
- **드라이버 파일**: `drv*.cpp` - 하드웨어 드라이버 구현
- **DBD 파일**: `*.dbd` - 데이터베이스 정의
- **설정 파일**: `*_settings.req` - autosave용 PV 목록

## 빌드 출력 디렉토리
- `O.Common/`: 아키텍처 독립적 파일
- `O.linux-x86_64/`: Linux x86_64 아키텍처 특정 파일
- 각 하위 디렉토리마다 해당 아키텍처의 빌드 출력 포함


### 🏗️ 전체 프로젝트 구조 개요
```
USB1608G_2AO/                          # 📁 프로젝트 루트 디렉토리
├── 📁 configure/                       # ⚙️ 빌드 설정 (최우선 수정)
│   ├── 📄 CONFIG                      # 기본 빌드 설정
│   ├── 📄 RELEASE                     # 외부 라이브러리 경로 정의
│   ├── 📄 CONFIG_SITE                 # 사이트별 컴파일 옵션
│   └── 📄 RULES_TOP                   # 최상위 빌드 규칙
├── 📁 USB1608G_2AOApp/                # 🎯 메인 애플리케이션
│   ├── 📁 src/                        # 💻 C/C++ 소스 코드
│   │   ├── 📄 Makefile               # 소스 빌드 설정
│   │   ├── 📄 USB1608G_2AOMain.cpp   # IOC 메인 진입점
│   │   ├── 📄 ThresholdLogicController.h  # 임계값 로직 헤더
│   │   ├── 📄 ThresholdLogicController.cpp # 임계값 로직 구현
│   │   ├── 📄 drvMultiFunction.cpp   # 다기능 드라이버
│   │   ├── 📄 drvUSBCTR.cpp         # USB 카운터 드라이버
│   │   ├── 📄 measCompDiscover.cpp   # 장치 검색 기능
│   │   └── 📄 USBCTR_SNL.st         # State Notation Language
│   ├── 📁 Db/                        # 🗄️ 데이터베이스 템플릿
│   │   ├── 📄 USB1608G_2AO.substitutions    # 메인 치환 파일
│   │   ├── 📄 thresholdController.template  # 컨트롤러 템플릿
│   │   ├── 📄 thresholdLogic.template       # 로직 규칙 템플릿
│   │   ├── 📄 measCompAnalogIn.template     # 아날로그 입력
│   │   ├── 📄 measCompAnalogOut.template    # 아날로그 출력
│   │   ├── 📄 measCompBinaryOut.template    # 디지털 출력
│   │   └── 📄 [기타 measComp 템플릿들]
│   └── 📁 op/                        # 🖥️ 운영자 인터페이스 (선택사항)
│       └── 📁 adl/                   # MEDM 화면 파일
├── 📁 iocBoot/                       # 🚀 IOC 부팅 스크립트
│   └── 📁 iocUSB1608G_2AO/
│       ├── 📄 st.cmd                # 시작 스크립트
│       ├── 📄 envPaths              # 환경 경로 설정
│       ├── 📄 save_restore.cmd      # 자동 저장 설정
│       └── 📄 auto_settings.req     # 저장할 PV 목록
├── 📁 bin/                          # 🔧 컴파일된 실행 파일 (자동 생성)
│   └── 📁 linux-x86_64/
│       └── 📄 USB1608G_2AO          # IOC 실행 파일
├── 📁 lib/                          # 📚 컴파일된 라이브러리 (자동 생성)
├── 📁 db/                           # 🗃️ 설치된 데이터베이스 파일 (자동 생성)
├── 📁 dbd/                          # 📋 데이터베이스 정의 파일 (자동 생성)
├── 📄 Makefile                      # 🔨 최상위 빌드 파일
└── 📄 README.md                     # 📖 프로젝트 설명서
```

#### 의존성 계층 구조
```
Level 0: 외부 의존성 (EPICS Base, synApps)
    ↓
Level 1: 프로젝트 설정 (configure/)
    ↓
Level 2: 빌드 설정 (Makefile)
    ↓
Level 3: 소스 코드 (*.h, *.cpp)
    ↓
Level 4: 데이터베이스 (*.template, *.substitutions)
    ↓
Level 5: IOC 설정 (st.cmd, 설정 파일)
```

### ⚙️ 수행 순서 요약

1. 환경 변수 검사
2. 기존 앱 폴더 삭제 및 재생성
3. makeBaseApp 기반 IOC 생성
4. 필수 파일 및 디렉토리 자동 구성
5. measComp 및 git repo에서 템플릿, 소스, 화면 복사
6. RELEASE / Makefile / st.cmd 자동 삽입 및 수정
7. autosave 설정 및 substitutions 등록
8. IOC 빌드 및 오류 체크
9. IOC 자동 실행


---

### 📁 주요 파일 자동 수정

| 파일 경로 | 설명 |
|-----------|------|
| `configure/RELEASE` | 외부 모듈 경로 등록 (`measComp`, `asyn`, 등) |
| `src/Makefile` | .cpp, .st 파일 빌드 설정 |
| `Db/Makefile` | *.template, *.substitutions 자동 탐색 및 설치 |
| `st.cmd` | EPICS 실행 스크립트 전체 구성 |
| `save_restore.cmd` | autosave 설정 구성 |
| `auto_settings.req` | 복구 설정 등록 |


# ✅ 필수 설정
EPICS_BASE = /usr/local/epics/EPICS_R7.0/base
SUPPORT = /usr/local/epics/EPICS_R7.0/modules/synApps/support

# ✅ synApps 모듈 경로 (의존성 순서 중요!)
ASYN = $(SUPPORT)/asyn-R4-44-2          # 기본 비동기 드라이버
CALC = $(SUPPORT)/calc-R3-7-5           # 계산 레코드
SCALER = $(SUPPORT)/scaler-4-1          # 스케일러 지원
MCA = $(SUPPORT)/mca-R7-10              # 멀티채널 분석기
BUSY = $(SUPPORT)/busy-R1-7-4           # Busy 레코드
SSCAN = $(SUPPORT)/sscan-R2-11-6        # 스캔 레코드
AUTOSAVE = $(SUPPORT)/autosave-R5-11    # 자동 저장/복원
SNCSEQ = $(SUPPORT)/sequencer-mirror-R2-2-9  # State Notation Language
MEASCOMP = $(SUPPORT)/measComp-R4-2     # Measurement Computing 지원

---

### 🔄 복사되는 주요 파일

- **From `measComp-R4-2`**
  - 템플릿, .cpp, .dbd, .st, ADL 화면 등

- **From Local Git Repo**
  - `threshold_logic.template` : 추가된 템플릿 파일
  - `USB1608G_2AO_my.substitutions` : USB1608G_2AO.substitutions 파일로 이름 변경해서 복사  
  - `USB1608G_2AO_my.adl` : USB1608G_2AO.adl 파일로 이름 변경해서 복사
  - `medm_USB1608G_2AO.sh` : USB1608G_2AO.adl 실행 스크립트
  - `catest_USB1608G_2AO.sh` : Ao1 의 출력전압값을 sinewave로 출력
  

---

### 🛠️ 설치 방법

1. `/root/git_repo/` 디렉토리를 생성.

```bash
mkdir -p /root/git_repo/
```
2. GitHub 저장소 클론
``` bash
cd /root/git_repo/
git clone https://github.com/verysys-pal/EPICS-siteApp.git
```

---

### ✅ 실행 방법

```bash
# 실행 전 환경 변수 설정 필요
export EPICS_PATH=/usr/local/epics/EPICS_R7.0
export EPICS_BASE=${EPICS_PATH}/base
export EPICS_EXTENSIONS=${EPICS_PATH}/extensions
export EPICS_SYNAPPS=${EPICS_PATH}/modules/synApps/support
export EPICS_HOST_ARCH=$(${EPICS_BASE}/startup/EpicsHostArch)

# 실행
cd /root/git_repo/EPICS-siteApp/siteApp_USB1608G-2AO
chmod +x siteApp_USB1608G_2AO.sh
./siteApp_USB1608G_2AO.sh
```

---

### 📝 주의사항
- measComp-R4-2 및 Git repo의 경로는 사전에 존재해야 하며, 필요한 파일이 없을 경우 복사 오류 발생 가능
- user.db, user.proto, user.substitutions, Main.cpp 등은 생성만 하고 내용은 비워두므로 수동 작성 필요
- EPICS_HOST_ARCH=linux-x86_64 기준으로 작성됨