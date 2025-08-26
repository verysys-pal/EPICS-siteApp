TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
# Build the IOC application


PROD_IOC = USB1608G_2AO_cpp
# USB1608G_2AO_cpp.dbd will be created and installed
DBD += USB1608G_2AO_cpp.dbd


# USB1608G_2AO_cpp.dbd will be made up from these files:
USB1608G_2AO_cpp_DBD += base.dbd
USB1608G_2AO_cpp_DBD += measCompApp.dbd
USB1608G_2AO_cpp_DBD += measCompSupport.dbd
USB1608G_2AO_cpp_DBD += thresholdLogicSupport.dbd
USB1608G_2AO_cpp_DBD += simpleTestSupport.dbd


# Include dbd files from all support applications:
#USB1608G_2AO_cpp_DBD += xxx.dbd

# Add all the support libraries needed by this IOC
#USB1608G_2AO_cpp_LIBS += xxx

# #USB1608G_2AO_cpp_registerRecordDeviceDriver.cpp derives from #USB1608G_2AO_cpp.dbd
USB1608G_2AO_cpp_SRCS += USB1608G_2AO_cpp_registerRecordDeviceDriver.cpp
USB1608G_2AO_cpp_SRCS += drvMultiFunction.cpp
USB1608G_2AO_cpp_SRCS += drvUSBCTR.cpp
USB1608G_2AO_cpp_SRCS += measCompDiscover.cpp
USB1608G_2AO_cpp_SRCS += ThresholdLogicController.cpp
USB1608G_2AO_cpp_SRCS += ErrorHandler.cpp
USB1608G_2AO_cpp_SRCS += SimpleTest.cpp
USB1608G_2AO_cpp_SRCS += USBCTR_SNL.st


# Build the main IOC entry point on workstation OSs.
USB1608G_2AO_cpp_SRCS_DEFAULT += USB1608G_2AO_cppMain.cpp
USB1608G_2AO_cpp_SRCS_vxWorks += -nil-

# Add support from base/src/vxWorks if needed
#USB1608G_2AO_cpp_OBJS_vxWorks += $(EPICS_BASE_BIN)/vxComLibrary

# Finally link to the EPICS Base libraries
USB1608G_2AO_cpp_LIBS += $(EPICS_BASE_IOC_LIBS)
USB1608G_2AO_cpp_LIBS += measComp
USB1608G_2AO_cpp_LIBS += scaler
USB1608G_2AO_cpp_LIBS += busy
USB1608G_2AO_cpp_LIBS += calc
USB1608G_2AO_cpp_LIBS += mca
USB1608G_2AO_cpp_LIBS += sscan
USB1608G_2AO_cpp_LIBS += autosave
USB1608G_2AO_cpp_LIBS += asyn
USB1608G_2AO_cpp_LIBS += seq pv

USB1608G_2AO_cpp_SYS_LIBS_Linux += uldaq
USB1608G_2AO_cpp_SYS_LIBS_Linux += usb-1.0
#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE
