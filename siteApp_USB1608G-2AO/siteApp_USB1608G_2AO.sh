#!/bin/bash
# ===============================================
# Script  : siteApp_xxx.sh
# Purpose : Build EPICS IOC based on current directory name (APPNAME)
# Author  : Seo Min Ho
# email   : mhdev@postech.ac.kr
# ===============================================
# EPICS_HOST_ARCH : linux-x86_64
# EPICS_PATH : /usr/local/epics/EPICS_R7.0
# EPICS_BASE : /usr/local/epics/EPICS_R7.0/base
# EPICS_EXTENSIONS : /usr/local/epics/EPICS_R7.0/extensions
# EPICS_SYNAPPS : /usr/local/epics/EPICS_R7.0/modules/synApps/support



# ========== Global Variables ==========
START_TIME=$(date +%s)

APPNAME="USB1608G_2AO"
TOPDIR="${EPICS_PATH}/siteApp/${APPNAME}"

# 전역 배열 선언 : 배열에 파일 경로를 추가
declare -a EDIT_FILES=()


# ========== Logging ==========
LOG_DIR="/root/log"
LOG_FILE="$LOG_DIR/siteApp_${APPNAME}_$(date +'%m%d_%H').log"

init_log() {
    mkdir -p "$LOG_DIR"
    {
        echo "========================================="
        echo " Log File: $LOG_FILE"
        echo " Created: $(date '+%Y-%m-%d %H:%M:%S')"
        echo " User: $(whoami)"
        echo " Host: $(hostname)"
        echo "========================================="
    } > "$LOG_FILE"
}

log_block() {
    echo -e ""
    echo -e "✅ $1"
    echo -e "===================================================="
}

log() {
    echo -e "$1"
}



















# ========== Common function ==========
abort_on_error() {
    echo "❌ ERROR: $1"
    echo " - Check the log file for more details: $LOG_FILE"
    echo "-------------"
    #exit 1
}

dir_tree() {
    local target_dir="$1"
    echo "📂 Directory Tree"
    tree "$target_dir"
}

dir_file() {
    echo "-------------"
    ls -alF --color=auto "$TOPDIR"
}

copy2paste_file() {
    local DEST_DIR="$1"     # 대상 디렉토리
    local SRC="$2"          # 소스 파일

    if [[ ! -f "$SRC" ]]; then
        echo " ❌ Source file not found: $SRC"
        return 1
    fi

    if [[ ! -d "$DEST_DIR" ]]; then
        echo " ❌ Failed to create directory: $DEST_DIR"
        return 1
    fi

    #cp -v "$SRC" "$DEST_DIR"/ 2>&1
    cp "$SRC" "$DEST_DIR"/
    echo " - Copied $(basename "$SRC") to $DEST_DIR"
}






insert_once_after_line() {
    local target_file="$1"
    local match_line="$2"
    local insert_block="$3"
    local override="$4"  # "override", "bypass", or default (insert)

    EDIT_FILES+=("$target_file")
    echo " - cd $target_file"
    echo " "

    # 파일이 없으면 생성
    if [ ! -f "$target_file" ]; then
        echo " - File not found. Creating new empty file."
        touch "$target_file"
    fi

    case "$override" in
        override)
            echo "$insert_block" > "$target_file"
            echo " - Override mode: File overwritten with insert_block."
            return
            ;;
        bypass)
            echo " - Bypass mode: No changes made to file."
            return
            ;;
    esac

    # 줄 단위로 insert_block이 모두 있는지 확인
    local block_found=true
    while IFS= read -r line; do
        if ! grep -Fxq "$line" "$target_file"; then
            block_found=false
            break
        fi
    done <<< "$insert_block"

    if $block_found; then
        echo " - Block already exists. Skipping insertion."
        return
    fi

    # 기준 줄 존재 시 그 아래에 삽입
    if grep -qF "$match_line" "$target_file"; then
        local tmpfile
        tmpfile=$(mktemp)

        while IFS= read -r line; do
            echo "$line" >> "$tmpfile"
            if [[ "$line" == *"$match_line"* ]]; then
                echo "$insert_block" >> "$tmpfile"
            fi
        done < "$target_file"

        mv "$tmpfile" "$target_file"
        echo " - Block inserted after: '$match_line'"
    else
        echo "$insert_block" >> "$target_file"
        echo " - Match line not found. Block appended to end of file."
    fi
}







print_edit_files() {
    {
        printf '\n%.0s' {1..30}
        echo -e "📚 All Tracked Edit Files (${#EDIT_FILES[@]} files)"
        echo -e "===================================================="
    } >> "$LOG_FILE" 2>&1

    for file in "${EDIT_FILES[@]}"; do
        {
            printf '\n%.0s' {1..3}
            echo "🔰 File: $file"
            echo "🔰"
            echo "🔰 (づ￣ 3￣)づ"
            echo "🔰 ___________"

            if [ -f "$file" ]; then
                cat "$file"
            else
                echo "⚠️ File not found: $file"
            fi

            printf '\n%.0s' {1..3}
        } >> "$LOG_FILE" 2>&1
    done
}

print_summary() {
    local duration=$(( $(date +%s) - START_TIME ))

    log_block "All Tracked Edit Files (${#EDIT_FILES[@]} files)"
    for ((i=0; i<${#EDIT_FILES[@]}; i++)); do
        echo "[$((i+1))]  ${EDIT_FILES[$i]}"
    done
    printf '\n%.0s' {1..3}

    log_block "Build Completed in ${duration} seconds"
    echo " - Duration           : ${duration} seconds"
    echo " - Executed in        : cd $IOCB_IOCBOOT"
    echo " - Log file location  : $LOG_FILE"
}












#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

            ##                ##       ##
                                       ##
           ###     #####     ###      #####
            ##     ##  ##     ##       ##
            ##     ##  ##     ##       ##
            ##     ##  ##     ##       ## ##
           ####    ##  ##    ####       ###

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# ========== Check Environment ==========
step01_check_env() {
    log_block "${FUNCNAME[0]} : Checking environment variables"
    for var in EPICS_SYNAPPS EPICS_PATH EPICS_BASE; do
        [ -z "${!var}" ] && abort_on_error "$var is not defined"
        echo "$var = ${!var}"
    done
}


step02_clean_existing_app_folder() {
    log_block "${FUNCNAME[0]} : Remove existing application folder if exists"

    cd "$EPICS_PATH/siteApp"
    if [ -d "$TOPDIR" ]; then
        echo "Existing folder found: $TOPDIR"
        dir_file
        rm -rf "$TOPDIR" || abort_on_error "Failed to remove $TOPDIR"
        echo ""
        echo "Removed existing folder: $TOPDIR"
    else
        echo "No existing folder found for: $TOPDIR"
    fi
}



step03_create_app_folder() {
    log_block "${FUNCNAME[0]} : Creating application folder (from script name)"

    # 디렉토리 생성 및 이동
    mkdir -p "$TOPDIR" || abort_on_error "Failed to create $TOPDIR"
    cd "$TOPDIR" || abort_on_error "Failed to cd into $TOPDIR"

    echo "APPNAME      = $APPNAME"
    echo "TOPDIR       = $TOPDIR"
    dir_file
}



step04_define_paths() {
    log_block "${FUNCNAME[0]} : Define and export IOC directory paths"

    # IOC 설치 경로 전역 사용 가능하도록 설정
    export IOCB_CONFIGURE="${TOPDIR}/configure"
    export IOCB_APP="${TOPDIR}/${APPNAME}App"
    export IOCB_APP_SRC="${IOCB_APP}/src"
    export IOCB_APP_DB="${IOCB_APP}/Db"
    export IOCB_APP_OP="${IOCB_APP}/op"
    export IOCB_IOCBOOT="${TOPDIR}/iocBoot/ioc${APPNAME}"

    # 로그 출력
    echo "TOPDIR            = $TOPDIR"
    echo "IOCB_CONFIGURE    = $IOCB_CONFIGURE"
    echo "IOCB_APP          = $IOCB_APP"
    echo "IOCB_APP_SRC      = $IOCB_APP_SRC"
    echo "IOCB_APP_DB       = $IOCB_APP_DB"
    echo "IOCB_APP_OP       = $IOCB_APP_OP"
    echo "IOCB_IOCBOOT      = $IOCB_IOCBOOT"
}

















#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

          ########    #####   ######
          ## ## ##   ##   ##   ##  ##
             ##     ##   ##   ##  ##
             ##     ##   ##   #####
             ##     ##   ##   ##
             ##     ##   ##   ##
            ####     #####   ####

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# ========== Generate IOC Application ==========
step10_generate_ioc_app() {
    log_block "${FUNCNAME[0]} : Generating IOC App with makeBaseApp"
    #   makeBaseApp.pl 명령어로 IOC 애플리케이션 생성
    #   -i 옵션은 IOC 애플리케이션을 생성할 때, 필요한 디렉토리 구조를 자동으로 생성.
    #   -t ioc 옵션은 IOC 애플리케이션을 생성할 때, IOC 템플릿을 사용.

    cd "$TOPDIR" || abort_on_error "Failed to cd to $TOPDIR"
    #echo "" | makeBaseApp.pl -t example ${APPNAME}
    echo "" | makeBaseApp.pl -t ioc ${APPNAME}
    #echo "" | makeBaseApp.pl -i -t example ${APPNAME}
    echo "" | makeBaseApp.pl -i -t ioc ${APPNAME}
}




step11_validate_ioc_structure() {
    log_block "${FUNCNAME[0]} : Validating IOC structure..."

    local required_paths=(
        "${IOCB_APP}/op"
        "${IOCB_IOCBOOT}/autosave"
    )

    for path in "${required_paths[@]}"; do
        if [[ ! -d "$path" ]]; then
            echo "⚠️  Creating it now : $path"
            mkdir -p "$path"
        fi
    done
}



step12_validate_ioc_structure_and_files() {
  log_block "${FUNCNAME[0]} : Validating IOC structure and essential files..."

  local required_items=(
    "${TOPDIR}/Makefile"
    "${TOPDIR}/configure/Makefile"
    "${TOPDIR}/configure/CONFIG"
    "${TOPDIR}/configure/RELEASE"
    "${TOPDIR}/configure/RULES"
    "${TOPDIR}/configure/RULES_DIRS"
    "${TOPDIR}/configure/RULES.ioc"
    "${TOPDIR}/configure/RULES_TOP"
    "${TOPDIR}/configure/CONFIG_SITE"

    "${IOCB_APP}/Makefile"
    "${IOCB_APP}/src/Makefile"
    "${IOCB_APP}/src/${APPNAME}Main.cpp"
    "${IOCB_APP}/Db/Makefile"

    "${TOPDIR}/iocBoot/Makefile"
    "${TOPDIR}/iocBoot/ioc${APPNAME}/Makefile"
    "${TOPDIR}/iocBoot/ioc${APPNAME}/st.cmd"
    )

    local all_ok=true

    for item in "${required_items[@]}"; do
    if [[ ! -e "$item" ]]; then
        echo "❌ Missing: $item"
        all_ok=false
    fi
    done

    if [[ "$all_ok" = false ]]; then
        echo "⚠️ Error: Some required files or directories are missing."
        echo "⚠️ IOC structure check failed. Exiting script."
        exit 1
    fi
    echo "- IOC structure and basic files have been successfully verified."
}






step15_download_files_from_measComp() {
    log_block "${FUNCNAME[0]} : measComp-R4-2 모듈에서 필요한 파일 복사 중..."

    local COPYDIR
    local MEASCOMP=${EPICS_SYNAPPS}/measComp-R4-2

    # DB 템플릿 및 substitutions 복사
    COPYDIR="${MEASCOMP}/measCompApp/Db"
    cp ${COPYDIR}/*.template "${IOCB_APP_DB}"
    cp ${COPYDIR}/*.req "${IOCB_APP_DB}"
    cp ${COPYDIR}/USB1608G_2AO_settings.req "${IOCB_APP_DB}"

    # CPP
    COPYDIR="${MEASCOMP}/measCompApp/src"
    copy2paste_file "${IOCB_APP_SRC}" ${COPYDIR}/drvMultiFunction.cpp
    copy2paste_file "${IOCB_APP_SRC}" ${COPYDIR}/drvUSBCTR.cpp
    copy2paste_file "${IOCB_APP_SRC}" ${COPYDIR}/measCompSupport.dbd
    copy2paste_file "${IOCB_APP_SRC}" ${COPYDIR}/measCompAppMain.cpp
    copy2paste_file "${IOCB_APP_SRC}" ${COPYDIR}/measCompDiscover.cpp
    copy2paste_file "${IOCB_APP_SRC}" ${COPYDIR}/measCompDiscover.h
    copy2paste_file "${IOCB_APP_SRC}" ${COPYDIR}/USBCTR_SNL.st

    # MEDM
    COPYDIR="${MEASCOMP}/measCompApp/op/adl"
    copy2paste_file "${IOCB_APP_OP}" ${COPYDIR}/measCompDigitalIO8.adl
    copy2paste_file "${IOCB_APP_OP}" ${COPYDIR}/measCompAnalogIn8.adl
    copy2paste_file "${IOCB_APP_OP}" ${COPYDIR}/measCompADCStripChart.adl
    copy2paste_file "${IOCB_APP_OP}" ${COPYDIR}/measCompAiSetup.adl
    copy2paste_file "${IOCB_APP_OP}" ${COPYDIR}/measCompAnalogOut2.adl
    copy2paste_file "${IOCB_APP_OP}" ${COPYDIR}/measCompAoSetup2.adl

    echo " - measComp 관련 파일 복사 완료"
}


step16_download_files_from_gitrepo() {
    log_block "${FUNCNAME[0]} : git-repo 모듈에서 필요한 파일 복사 중..."

    local COPYDIR

    # CPP
    COPYDIR="/root/git_repo/DEV-202504/B02_siteApp/siteApp_USB1608G-2AO"
    copy2paste_file "${IOCB_APP_DB}" ${COPYDIR}/threshold_logic.template

    cp ${COPYDIR}/USB1608G_2AO_my.substitutions "${IOCB_APP_DB}/${APPNAME}.substitutions"

    # MEDM
    cp ${COPYDIR}/USB1608G_2AO_my.adl "${IOCB_APP_OP}/${APPNAME}.adl"

    # TEST scripts
    COPYDIR="/root/git_repo/DEV-202504/B02_siteApp/siteApp_USB1608G-2AO"
    copy2paste_file "${IOCB_IOCBOOT}" ${COPYDIR}/catest_USB1608G_2AO.sh
    copy2paste_file "${IOCB_IOCBOOT}" ${COPYDIR}/medm_USB1608G_2AO.sh

    echo " - git_repo 관련 파일 복사 완료"
}





#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

                                       ###      ##
                                      ## ##
           ####     ####    #####     ##       ###      ### ##
          ##  ##   ##  ##   ##  ##   ####       ##     ##  ##
          ##       ##  ##   ##  ##    ##        ##     ##  ##
          ##  ##   ##  ##   ##  ##    ##        ##      #####
           ####     ####    ##  ##   ####      ####        ##
                                                       #####

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# ========== Modify configure/RELEASE ==========
step20_update_release_file() {
    log_block "${FUNCNAME[0]} : Modifying configure/RELEASE"
    #   configure/RELEASE 수정
    #   - ASYN, STREAMDEVICE 등 라이브러리 모듈을 연결

    local EFILE="${IOCB_CONFIGURE}/RELEASE"
    local MLINE=""
    local INSBL=$(cat << EOF  # 내부변수 확장 X
# RELEASE - Location of external support modules

# EPICS_BASE should appear last so earlier modules can override stuff:
EPICS_BASE = /usr/local/epics/EPICS_R7.0/base

SUPPORT=${EPICS_SYNAPPS}

ASYN=\$(SUPPORT)/asyn-R4-44-2
CALC=\$(SUPPORT)/calc-R3-7-5
SCALER=\$(SUPPORT)/scaler-4-1
MCA=\$(SUPPORT)/mca-R7-10
BUSY=\$(SUPPORT)/busy-R1-7-4
SSCAN=\$(SUPPORT)/sscan-R2-11-6
AUTOSAVE=\$(SUPPORT)/autosave-R5-11
SNCSEQ=\$(SUPPORT)/sequencer-mirror-R2-2-9
MEASCOMP=\$(SUPPORT)/measComp-R4-2


# Set RULES here if you want to use build rules from somewhere
# other than EPICS_BASE:
#RULES = \$(MODULES)/build-rules

# These lines allow developers to override these RELEASE settings
# without having to modify this file directly.
-include \$(TOP)/../RELEASE.local
-include \$(TOP)/../RELEASE.\$(EPICS_HOST_ARCH).local
-include \$(TOP)/configure/RELEASE.local
EOF
    )
    insert_once_after_line "$EFILE" "$MLINE" "$INSBL" "override"
}















#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

               ##
              ##    #####   ######    ####
             ##    ##        ##  ##  ##  ##
            ##      #####    ##      ##
           ##           ##   ##      ##  ##
          ##       ######   ####      ####

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


# ========== Update Makefile ==========
step30_update_src_makefile() {
    log_block "${FUNCNAME[0]} : Updating src/Makefile"

    local EFILE="${IOCB_APP_SRC}/Makefile"
    local MLINE=""
    local INSBL=$(cat << EOF  # 내부변수 확장 O
TOP=../..

include \$(TOP)/configure/CONFIG
#----------------------------------------
# Build the IOC application


PROD_IOC = ${APPNAME}
# ${APPNAME}.dbd will be created and installed
DBD += ${APPNAME}.dbd


# ${APPNAME}.dbd will be made up from these files:
${APPNAME}_DBD += base.dbd
${APPNAME}_DBD += measCompApp.dbd
${APPNAME}_DBD += measCompSupport.dbd


# Include dbd files from all support applications:
#${APPNAME}_DBD += xxx.dbd

# Add all the support libraries needed by this IOC
#${APPNAME}_LIBS += xxx

# #${APPNAME}_registerRecordDeviceDriver.cpp derives from #${APPNAME}.dbd
${APPNAME}_SRCS += ${APPNAME}_registerRecordDeviceDriver.cpp
${APPNAME}_SRCS += drvMultiFunction.cpp
${APPNAME}_SRCS += drvUSBCTR.cpp
${APPNAME}_SRCS += measCompDiscover.cpp
${APPNAME}_SRCS += USBCTR_SNL.st


# Build the main IOC entry point on workstation OSs.
${APPNAME}_SRCS_DEFAULT += ${APPNAME}Main.cpp
${APPNAME}_SRCS_vxWorks += -nil-

# Add support from base/src/vxWorks if needed
#${APPNAME}_OBJS_vxWorks += \$(EPICS_BASE_BIN)/vxComLibrary

# Finally link to the EPICS Base libraries
${APPNAME}_LIBS += \$(EPICS_BASE_IOC_LIBS)
${APPNAME}_LIBS += measComp
${APPNAME}_LIBS += scaler
${APPNAME}_LIBS += busy
${APPNAME}_LIBS += calc
${APPNAME}_LIBS += mca
${APPNAME}_LIBS += sscan
${APPNAME}_LIBS += autosave
${APPNAME}_LIBS += asyn
${APPNAME}_LIBS += seq pv

${APPNAME}_SYS_LIBS_Linux += uldaq
${APPNAME}_SYS_LIBS_Linux += usb-1.0
#===========================

include \$(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE
EOF
)
    insert_once_after_line "$EFILE" "$MLINE" "$INSBL" "override"
}













# ========== Update CPP ==========
step31_update_src_MainCpp() {
    log_block "${FUNCNAME[0]} : Updating src/Main.cpp"

    local EFILE="${IOCB_APP_SRC}/${APPNAME}Main.cpp"
    local MLINE=""
    local INSBL=$(cat << EOF  # 내부변수 확장 O
/* --------------------------------------------------- add line */

/* ------------------------------------------------------------ */
EOF
)
    insert_once_after_line "$EFILE" "$MLINE" "$INSBL" "bypass"
}




















#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 #####      ##     ######     ##     ######     ##      #####   #######
  ## ##    ####    # ## #    ####     ##  ##   ####    ##   ##   ##   #
  ##  ##  ##  ##     ##     ##  ##    ##  ##  ##  ##   ##        ## #
  ##  ##  ##  ##     ##     ##  ##    #####   ##  ##    #####    ####
  ##  ##  ######     ##     ######    ##  ##  ######        ##   ## #
  ## ##   ##  ##     ##     ##  ##    ##  ##  ##  ##   ##   ##   ##   #
 #####    ##  ##    ####    ##  ##   ######   ##  ##    #####   #######

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

step40_update_db_makefile() {
    log_block "${FUNCNAME[0]} : Updating app/Db/Makefile"

    local EFILE="${IOCB_APP_DB}/Makefile"
    local MLINE=""
    local INSBL=$(cat << 'EOF'  # 내부변수 확장X
TOP=../..
include $(TOP)/configure/CONFIG

#  Optimization of db files using dbst (DEFAULT: NO)
#DB_OPT = YES

#----------------------------------------------------
# Create and install (or just install)
# databases, templates, substitutions like this

DB += $(patsubst ../%, %, $(wildcard ../*.template))
DB += $(patsubst ../%, %, $(wildcard ../*.db))
DB += $(patsubst ../%, %, $(wildcard ../*.vdb))
DB += $(patsubst ../%, %, $(wildcard ../*.substitutions))

REQ += $(patsubst ../%, %, $(wildcard ../*.req))

#----------------------------------------------------
# If <anyname>.db template is not named <anyname>*.template add
# <anyname>_TEMPLATE = <templatename>

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

EOF
)
    insert_once_after_line "$EFILE" "$MLINE" "$INSBL" "override"
}




# ==========  Create DB ==========
step50_create_db() {
    log_block "${FUNCNAME[0]} : Creating user.db"

    local EFILE="${IOCB_APP_DB}/user.db"
    local MLINE="No matching line found, so appended at the end."
    local INSBL=$(cat << 'EOF'  # 내부변수 확장X
# --------------------------------------------------- add line

# -------------------------------------------------------------
EOF
)
    insert_once_after_line "$EFILE" "$MLINE" "$INSBL" "bypass"
}






# ==========  Create protocol ==========
step51_create_proto() {
    log_block "${FUNCNAME[0]} : Creating user.proto"

    local EFILE="${IOCB_APP_DB}/user.proto"
    local MLINE="No matching line found, so appended at the end."
    local INSBL=$(cat << 'EOF'  # 내부변수 확장X
# --------------------------------------------------- add line

# -------------------------------------------------------------
EOF
)
    insert_once_after_line "$EFILE" "$MLINE" "$INSBL" "bypass"
}







# ==========  Create substitutions ==========
step52_create_substitutions() {
    log_block "${FUNCNAME[0]} : Creating user.substitutions"

    local EFILE="${IOCB_APP_DB}/user.substitutions"
    local MLINE="No matching line found, so appended at the end."
    local INSBL=$(cat << 'EOF'  # 내부변수 확장X
# --------------------------------------------------- add line

# -------------------------------------------------------------
EOF
)
    insert_once_after_line "$EFILE" "$MLINE" "$INSBL" "bypass"
}























#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

            ##                       ###                          ##
                                      ##                          ##
           ###      ####     ####     ##       ####     ####     #####
            ##     ##  ##   ##  ##    #####   ##  ##   ##  ##     ##
            ##     ##  ##   ##        ##  ##  ##  ##   ##  ##     ##
            ##     ##  ##   ##  ##    ##  ##  ##  ##   ##  ##     ## ##
           ####     ####     ####    ######    ####     ####       ###

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


# ==========  Create autosave ==========
step60_save_restore_cmd() {
    log_block "${FUNCNAME[0]} : Creating save_restore.cmd"

    local EFILE="${IOCB_IOCBOOT}/save_restore.cmd"
    local MLINE=""
    local INSBL=$(cat << 'EOF'  # 내부변수 확장X
# Debug-output level
save_restoreSet_Debug(0)

# Ok to save/restore save sets with missing values (no CA connection to PV)?
save_restoreSet_IncompleteSetsOk(1)
# Save dated backup files?
save_restoreSet_DatedBackupFiles(1)

# Number of sequenced backup files to write
save_restoreSet_NumSeqFiles(3)
# Time interval between sequenced backups
save_restoreSet_SeqPeriodInSeconds(300)

# specify where save files should be
set_savefile_path(".", "autosave")

# specify what save files should be restored.  Note these files must be
# in the directory specified in set_savefile_path(), or, if that function
# has not been called, from the directory current when iocInit is invoked0
set_pass0_restoreFile("auto_settings.sav")
set_pass1_restoreFile("auto_settings.sav")

# specify directories in which to to search for included request files
# Note cdCommands defines 'startup', but envPaths does not
set_requestfile_path(".",         "")
set_requestfile_path(".",         "autosave")
set_requestfile_path($(AUTOSAVE), "db")
set_requestfile_path($(CALC),     "db")
set_requestfile_path($(SCALER),   "db")
set_requestfile_path($(SSCAN),    "db")
set_requestfile_path($(MEASCOMP), "db")
EOF
)
    insert_once_after_line "$EFILE" "$MLINE" "$INSBL" "override"
}




step61_auto_settings() {
    log_block "${FUNCNAME[0]} : Creating auto_settings.reqd"

    local EFILE="${IOCB_IOCBOOT}/auto_settings.req"
    local MLINE=""
    local INSBL=$(cat << EOF  # 내부변수 확장X
    file "${IOCB_APP_DB}/USB1608G_2AO_settings.req", P=\$(P)
EOF
)
    insert_once_after_line "$EFILE" "$MLINE" "$INSBL" "override"
}













#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

                   ##   ##    ##     ###  ##  #######
                   ### ###   ####     ##  ##   ##   #
                   #######  ##  ##    ## ##    ## #
                   #######  ##  ##    ####     ####
                   ## # ##  ######    ## ##    ## #
                   ##   ##  ##  ##    ##  ##   ##   #
                   ##   ##  ##  ##   ###  ##  #######

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

step70_build_ioc() {
    log_block "${FUNCNAME[0]} : Building IOC for $APPNAME"

    local BUILD_LOG
    BUILD_LOG=$(mktemp)
    local ERROR_PATTERNS='(fatal|unknown|undefined|no such|No rule|multiple definition|error:|Error [0-9])'

    cd "$TOPDIR" || abort_on_error "Failed to cd into $TOPDIR"
    make -j >> "$BUILD_LOG" 2>&1 || abort_on_error "make failed"

    # 오류 확인
    if grep -E -i "$ERROR_PATTERNS" "$BUILD_LOG" >/dev/null; then
        echo "❌ Build errors detected. See details below:"
        grep -Ein "$ERROR_PATTERNS" "$BUILD_LOG"
    else
        echo "⭕ No significant build errors found."
    fi
}









#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

                     ##                                   ###
                     ##                                    ##
           #####    #####             ####    ##  ##       ##
          ##         ##              ##  ##   #######   #####
           #####     ##              ##       ## # ##  ##  ##
               ##    ## ##    ##     ##  ##   ##   ##  ##  ##
          ######      ###     ##      ####    ##   ##   ######

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# ==========  Update st.cmd ==========
step80_Update_st_cmd() {
    log_block "${FUNCNAME[0]} : Update st.cmd"

    local EFILE="${IOCB_IOCBOOT}/st.cmd"
    local ADD_LINE=""
    local INSBL=$(cat << EOF  # 내부변수 확장 O
#!../../bin/linux-x86_64/${APPNAME}
< envPaths

## Register all support components
dbLoadDatabase("\$(TOP)/dbd/${APPNAME}.dbd")
${APPNAME}_registerRecordDeviceDriver(pdbbase)

epicsEnvSet("PREFIX", "${APPNAME}:")
epicsEnvSet("PORT", "${APPNAME}_PORT")
epicsEnvSet("WDIG_POINTS", "1048576")
epicsEnvSet("WGEN_POINTS", "1048576")
epicsEnvSet("UNIQUE_ID", "01D97CFA")

## Configure port driver
MultiFunctionConfig("\$(PORT)", "\$(UNIQUE_ID)", \$(WDIG_POINTS), \$(WGEN_POINTS))

dbLoadTemplate("\$(TOP)/${APPNAME}App/Db/${APPNAME}.substitutions", "P=\$(PREFIX),PORT=\$(PORT),WDIG_POINTS=\$(WDIG_POINTS),WGEN_POINTS=\$(WGEN_POINTS)")

< save_restore.cmd

iocInit

create_monitor_set("auto_settings.req",30,"P=\$(PREFIX)")

dbpf \$(PREFIX)WaveDigDwell.PROC 1
dbpf \$(PREFIX)WaveGenUserDwell.PROC 1

dbl
EOF
    )
    insert_once_after_line "$EFILE" "$MLINE" "$INSBL" "override"
}










step90_run_ioc() {
    log_block "${FUNCNAME[0]} : EPICS iocRun"
    printf '\n%.0s' {1..2}

    # source util_changeDirectory.sh ${IOCB_IOCBOOT}
    cd "$IOCB_IOCBOOT" || { echo "Directory not found!"; exit 1; }
    chmod +x st.cmd
    ls -alF ${IOCB_IOCBOOT}
    ./st.cmd
}









# ========== Main ==========
main() {
    {
        init_log
        printf '\n%.0s' {1..3}
        #--------------------------------------
        step01_check_env
        printf '\n%.0s' {1..3}
        step02_clean_existing_app_folder
        printf '\n%.0s' {1..3}
        step03_create_app_folder
        printf '\n%.0s' {1..3}
        step04_define_paths
        printf '\n%.0s' {1..6}
        # --------------------------------------
        # IOCB_APP
        step10_generate_ioc_app
        printf '\n%.0s' {1..3}
        step11_validate_ioc_structure
        printf '\n%.0s' {1..3}
        step12_validate_ioc_structure_and_files
        printf '\n%.0s' {1..3}
        step15_download_files_from_measComp
        printf '\n%.0s' {1..3}
        step16_download_files_from_gitrepo
        printf '\n%.0s' {1..3}
        dir_tree $TOPDIR
        printf '\n%.0s' {1..3}
         #--------------------------------------
        # IOCB_CONFIGURE
        step20_update_release_file
        printf '\n%.0s' {1..3}
        #--------------------------------------
        # IOCB_APP_SRC
        step30_update_src_makefile
        printf '\n%.0s' {1..3}
        step31_update_src_MainCpp
        printf '\n%.0s' {1..3}
        #--------------------------------------
        # IOCB_APP_DB
        step40_update_db_makefile
        printf '\n%.0s' {1..3}
        step50_create_db
        printf '\n%.0s' {1..3}
        step51_create_proto
        printf '\n%.0s' {1..3}
        step52_create_substitutions
        printf '\n%.0s' {1..3}
        #--------------------------------------
        # IOCB_IOCBOOT
        step60_save_restore_cmd
        printf '\n%.0s' {1..3}
        step61_auto_settings
        printf '\n%.0s' {1..3}
        #--------------------------------------
        # MAKE
        step70_build_ioc
        printf '\n%.0s' {1..3}
        dir_tree $TOPDIR
        #--------------------------------------
        # ST.CMD
        printf '\n%.0s' {1..3}
        step80_Update_st_cmd
        printf '\n%.0s' {1..3}
        #--------------------------------------
        # RUN
        step04_define_paths
        printf '\n%.0s' {1..3}
        step90_run_ioc
        printf '\n%.0s' {1..3}
        #--------------------------------------
        print_summary
        printf '\n%.0s' {1..3}
        print_edit_files

    } | tee -a "$LOG_FILE"
}

main "$@"
