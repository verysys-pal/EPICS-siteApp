# Technology Stack

## Build System
- **EPICS Base**: R7.0 - Experimental Physics and Industrial Control System
- **GNU Make**: Standard EPICS makefile-based build system
- **Target Architecture**: linux-x86_64

## Core Dependencies
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

## System Libraries
- **uldaq**: Measurement Computing Universal Library for Linux
- **libusb-1.0**: USB device access library

## Programming Languages
- **C++**: Primary application code (drivers, main program)
- **C**: EPICS record support and device drivers
- **SNL**: State Notation Language for sequencer programs
- **EPICS Database**: Template-based record definitions

## Common Build Commands

### Full Build
```bash
make clean uninstall
make
```

### IOC Startup
```bash
cd iocBoot/iocUSB1608G_2AO_cpp
../../bin/linux-x86_64/USB1608G_2AO_cpp st.cmd
```

### Testing
```bash
# Channel Access testing
./catest_USB1608G_2AO.sh

# MEDM GUI launch  
./medm_USB1608G_2AO.sh
```

### Development Workflow
1. Modify source in `USB1608G_2AO_cppApp/src/`
2. Update database templates in `USB1608G_2AO_cppApp/Db/`
3. Run `make` from project root
4. Test IOC with `st.cmd` startup script