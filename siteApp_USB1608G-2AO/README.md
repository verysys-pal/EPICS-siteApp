siteApp_USB1608G_2AO.sh 파일은 EPICS 기반의 IOC 애플리케이션 자동 생성 스크립트입니다.
이 스크립트는 makeBaseApp.pl을 기반으로 특정 디바이스(USB1608G_2AO)에 대한 전체 IOC 환경을 설정하고 빌드하며, 필요한 파일들을 외부 모듈에서 자동 복사하고 RELEASE, Makefile, st.cmd 등의 핵심 파일을 자동 수정합니다.
---
## 1. 📦 기본 설정
APPNAME="USB1608G_2AO"
EPICS 환경변수 사용: EPICS_PATH, EPICS_BASE, EPICS_SYNAPPS
로그는 /root/log/siteApp_USB1608G_2AO_*.log에 기록됨

## 2. 🧱 IOC 구조 생성 단계별 실행
단계	설명
step01~04	환경 변수 체크, 기존 앱 폴더 제거, 새 폴더 생성 및 경로 정의
step10~12	makeBaseApp.pl을 이용해 IOC 기본 구조 생성 및 필수 파일 검사
step15~16	measComp-R4-2 모듈 및 git repo에서 템플릿, .cpp, .adl, .req 등 자동 복사
step20	    configure/RELEASE 오버라이드 설정
step30~31	src/Makefile, Main.cpp 등 소스 설정 자동 구성
step40~52	Db/Makefile, user.db, .proto, .substitutions 파일 생성
step60~61	autosave 설정 및 auto_settings.req 구성
step70	    make -j로 빌드 및 로그 오류 체크
step80	    st.cmd 파일 완전 자동화 구성 (envSet, dbLoad, iocInit 등)
step90	    IOC 자동 실행

