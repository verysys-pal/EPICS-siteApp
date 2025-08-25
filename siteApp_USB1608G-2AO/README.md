# 🧰 EPICS IOC 자동 생성 스크립트 정리본

## 📄 스크립트 개요
- **스크립트명**: `siteApp_USB1608G_2AO.sh`  
- **목적**: EPICS 환경에서 **USB1608G_2AO** 디바이스용 IOC 애플리케이션을 자동 생성·구성·빌드·실행  
- **타겟 디바이스**: USB1608G_2AO (Measurement Computing)  
- **EPICS 버전**: R7.0  
- **지원 모듈**: measComp, asyn, autosave, calc, sscan 등  
- **로그 경로**: `/root/log/siteApp_USB1608G_2AO_*.log`

---

## 📁 프로젝트 구조

### 최상위 디렉토리
```
USB1608G_2AO/
├── configure/        # 빌드 설정 및 의존성 정의
├── USB1608G_2AOApp/  # 메인 애플리케이션
├── iocBoot/          # IOC 부팅 스크립트
├── bin/              # 실행 파일
├── lib/              # 라이브러리
├── db/               # DB 템플릿 (중복, App/Db 권장)
├── dbd/              # DB 정의 파일
└── Makefile          # 최상위 빌드 파일
```

### 애플리케이션 (`USB1608G_2AOApp/`)
```
src/   → C/C++ 소스, 드라이버, SNL 파일
Db/    → DB 템플릿 및 substitutions
op/    → 운영자 인터페이스 (MEDM 화면)
```

### IOC 부팅 (`iocBoot/`)
```
iocUSB1608G_2AO/
├── st.cmd            # IOC 시작 스크립트
├── envPaths          # 환경 경로 설정
├── auto_settings.req # autosave 요청 파일
└── autosave/         # 저장된 설정 파일
```

---

## ⚙️ 수행 절차

1. 환경 변수 검사  
2. 기존 앱 폴더 삭제 및 재생성  
3. `makeBaseApp` 기반 IOC 생성  
4. 필수 디렉토리/파일 자동 구성  
5. measComp 및 Git repo에서 소스/템플릿 복사  
6. RELEASE / Makefile / st.cmd 자동 수정  
7. autosave 설정 및 substitutions 등록  
8. IOC 빌드 및 오류 체크  
9. IOC 자동 실행  

---

## 📂 주요 자동 수정 파일

| 파일 경로 | 설명 |
|-----------|------|
| `configure/RELEASE` | 외부 모듈 경로 등록 |
| `src/Makefile`      | .cpp, .st 빌드 설정 |
| `Db/Makefile`       | template/substitutions 설치 설정 |
| `st.cmd`            | IOC 실행 스크립트 구성 |
| `save_restore.cmd`  | autosave 설정 |
| `auto_settings.req` | PV 복구 목록 |

---

## ✅ 필수 설정

```bash
EPICS_BASE = /usr/local/epics/EPICS_R7.0/base
SUPPORT    = /usr/local/epics/EPICS_R7.0/modules/synApps/support

ASYN       = $(SUPPORT)/asyn-R4-44-2
CALC       = $(SUPPORT)/calc-R3-7-5
SCALER     = $(SUPPORT)/scaler-4-1
MCA        = $(SUPPORT)/mca-R7-10
BUSY       = $(SUPPORT)/busy-R1-7-4
SSCAN      = $(SUPPORT)/sscan-R2-11-6
AUTOSAVE   = $(SUPPORT)/autosave-R5-11
SNCSEQ     = $(SUPPORT)/sequencer-mirror-R2-2-9
MEASCOMP   = $(SUPPORT)/measComp-R4-2
```

---

## 🔄 복사되는 주요 파일

- **From measComp-R4-2**: 템플릿, .cpp, .dbd, .st, ADL 화면 등  
- **From Local Git Repo**:  
  - `threshold_logic.template`  
  - `USB1608G_2AO_my.substitutions` → `USB1608G_2AO.substitutions`  
  - `USB1608G_2AO_my.adl` → `USB1608G_2AO.adl`  
  - `medm_USB1608G_2AO.sh` (MEDM 실행 스크립트)  
  - `catest_USB1608G_2AO.sh` (Ao1 출력전압 sinewave 테스트)  

---

## 🛠️ 설치 방법

```bash
mkdir -p /root/git_repo/
cd /root/git_repo/
git clone https://github.com/verysys-pal/EPICS-siteApp.git
```

---

## ▶️ 실행 방법

```bash
# 환경 변수 설정
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

## ⚠️ 주의사항

- measComp-R4-2 및 Git repo 경로가 사전에 존재해야 함  
- 일부 파일(Main.cpp, user.db 등)은 비어 있으므로 수동 작성 필요  
- EPICS_HOST_ARCH=linux-x86_64 기준  
