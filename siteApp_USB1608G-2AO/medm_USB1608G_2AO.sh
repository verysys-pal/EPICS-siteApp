#!/bin/bash

# Ensure EPICS_PATH is set
if [ -z "$EPICS_PATH" ]; then
    echo "EPICS_PATH must be set."
    exit 1
fi

# ========== Logging ==========
LOG_DIR="/root/log"
script_name="${0##*/}";
script_name="${script_name%.*}"
LOG_FILE="$LOG_DIR/$script_name.log"

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

log() {
    echo "$1" >> "$LOG_FILE"
}

export EPICS_SITE=${EPICS_PATH}/siteApp
OPDIR="${EPICS_SITE}/USB1608G_2AO/USB1608G_2AOApp/op"
# ========== Functions ==========
# /usr/local/epics/EPICS_R7.0/siteApp/USB1608G/USB1608GApp/op/USB1608G.adl

USB1608G_2AO_exec() {
    log "USB1608G_2AO_exec"
    cd "$OPDIR"
    # args="P=USB1608G_2AO:,Bi=Bi,Li=Li,Bo=Bo,Lo=Lo,Bd=Bd,Ai=Ai,Ao=Ao,Ct=Counter,Wd=WaveDig,Wg=WaveGen,Pg=PulseGen,Tg=Trig"
    export MEDM_MACRO='-macro P=USB1608G_2AO:,Bi=Bi,Li=Li,Bo=Bo,Lo=Lo,Bd=Bd,Ai=Ai,Ao=Ao,Ct=Counter,Wd=WaveDig,Wg=WaveGen,Pg=PulseGen,Tg=Trig'
    export MEDM_FONT='-displayFont fixed'
    medm -x $MEDM_MACRO $MEDM_FONT USB1608G_2AO.adl &
    echo " - cd ${OPDIR}"
}

USB1608G_2AO_edit() {
    log "USB1608G_2AO_edit"
    cd "$OPDIR"
    # args="P=USB1608G_2AO:,Bi=Bi,Li=Li,Bo=Bo,Lo=Lo,Bd=Bd,Ai=Ai,Ao=Ao,Ct=Counter,Wd=WaveDig,Wg=WaveGen,Pg=PulseGen,Tg=Trig"
    export MEDM_MACRO='-macro P=USB1608G_2AO:,Bi=Bi,Li=Li,Bo=Bo,Lo=Lo,Bd=Bd,Ai=Ai,Ao=Ao,Ct=Counter,Wd=WaveDig,Wg=WaveGen,Pg=PulseGen,Tg=Trig'
    export MEDM_FONT='-displayFont fixed'
    medm $MEDM_MACRO $MEDM_FONT USB1608G_2AO.adl &
    echo " - cd ${OPDIR}"
}


measCompDigitalIO8_exec() {
    log "measCompDigitalIO8_exec"
    cd "$OPDIR"
    export MEDM_MACRO='-macro P=USB1608G_2AO:,Bi=Bi,Li=Li,Bo=Bo,Lo=Lo,Bd=Bd'
    export MEDM_FONT='-displayFont fixed'
    medm -x $MEDM_MACRO $MEDM_FONT measCompDigitalIO8.adl &
    echo " - cd ${OPDIR}"
}

measCompDigitalIO8_edit() {
    log "measCompDigitalIO8_edit"
    cd "$OPDIR"
    export MEDM_MACRO='-macro P=USB1608G_2AO:,Bi=Bi,Li=Li,Bo=Bo,Lo=Lo,Bd=Bd'
    export MEDM_FONT='-displayFont fixed'
    medm $MEDM_MACRO $MEDM_FONT measCompDigitalIO8.adl &
    echo " - cd ${OPDIR}"
}






# ========== Common function ==========
kill_medm() {
    log "kill_medm"
    echo "[INFO] Checking for existing medm processes..."

    local medm_pids
    medm_pids=$(pgrep -x medm)

    if [[ -z "$medm_pids" ]]; then
        printf "%7s%s\n" "" "- No medm process found. Nothing to kill."
        log "No medm process found."
    else
        printf "%7s%s\n" "" "- Found medm process(es): $medm_pids"
        log "Killing medm process(es): $medm_pids"
        printf "%7s%s\n" "" "- Killing medm process(es)..."
        kill $medm_pids
        sleep 0.5

        if pgrep -x medm >/dev/null; then
            printf "%7s%s\n" "" "- [WARN] Some medm process(es) may still be running."
            log "[WARN] Some medm process(es) may still be running."
        else
            printf "%7s%s\n" "" "- All medm process(es) terminated successfully."
            log "All medm process(es) terminated."
        fi
    fi
}













# ========== Main ==========
handle_selection() {
        case "$1" in
                        1) USB1608G_2AO_exec ;;
                        2) USB1608G_2AO_edit ;;
            3) measCompDigitalIO8_exec ;;
            4) measCompDigitalIO8_edit ;;
                        0)
                                        echo "Exit the script"
                                        log "Exit selected"
                                        return 0
                                        ;;
                        *)
                                        echo ""
                                        echo "You have entered '${1}'"
                                        echo "Please select the number in the list..."
                                        echo ""
                                        log "Invalid input: ${1}"
                                        return 1
                                        ;;
        esac

        echo -e "\n========================================"
        echo "[DONE] All tasks completed"
        return 0
}


main() {
    init_log
    kill_medm

    while true; do
        echo ""
        echo "Enter the number of you want to script"
        echo "1 : USB1608G_2AO_exec"
        echo "2 : USB1608G_2AO_edit"
        echo ""
        echo "3 : measCompDigitalIO8_exec"
        echo "4 : measCompDigitalIO8_edit"
        echo ""
        echo "0 : Exit script"
        echo -n "Enter the number : "
        read answer

        if handle_selection "$answer"; then
            break
        fi
    done
}
main

