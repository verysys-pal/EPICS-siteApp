#!../../bin/linux-x86_64/USB1608G_2AO_cpp
< envPaths

## Register all support components
dbLoadDatabase("$(TOP)/dbd/USB1608G_2AO_cpp.dbd")
USB1608G_2AO_cpp_registerRecordDeviceDriver(pdbbase)

# 간단한 테스트 실행
SimpleTest

# IOC 종료
exit