# 🧰 EPICS IOC 자동 생성 스크립트: `siteApp_USB1608G_2AO.sh`

본 스크립트는 EPICS 환경에서 USB1608G_2AO 디바이스용 IOC 애플리케이션을 자동으로 생성, 구성, 빌드, 실행하는 목적으로 작성되었습니다.

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

### ✅ 실행 방법

```bash
# 실행 전 환경 변수 설정 필요
export EPICS_PATH=/usr/local/epics/EPICS_R7.0
export EPICS_BASE=${EPICS_PATH}/base
export EPICS_EXTENSIONS=${EPICS_PATH}/extensions
export EPICS_SYNAPPS=${EPICS_PATH}/modules/synApps/support
export EPICS_HOST_ARCH=$(${EPICS_BASE}/startup/EpicsHostArch)

# 실행
cd /usr/local/epics/EPICS_R7.0/siteApp/USB1608G_2AO/iocBoot/iocUSB1608G_2AO
chmod +x siteApp_USB1608G_2AO.sh
./siteApp_USB1608G_2AO.sh
```

---

### 📝 주의사항
- measComp-R4-2 및 Git repo의 경로는 사전에 존재해야 하며, 필요한 파일이 없을 경우 복사 오류 발생 가능
- user.db, user.proto, user.substitutions, Main.cpp 등은 생성만 하고 내용은 비워두므로 수동 작성 필요
- EPICS_HOST_ARCH=linux-x86_64 기준으로 작성됨