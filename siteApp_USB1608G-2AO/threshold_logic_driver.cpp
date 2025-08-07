/* threshold_logic_driver.cpp */

#include <iocsh.h>
#include <epicsThread.h>
#include <epicsExport.h>

#include "threshold_logic_driver.h"

/**
 * @brief ThresholdLogicDriver 클래스의 생성자.
 * @param portName 이 드라이버에 대한 asyn 포트 이름.
 * @param numLinks 지원할 링크(주소)의 수.
 */
ThresholdLogicDriver::ThresholdLogicDriver(const char *portName, int numLinks)
    : asynPortDriver(portName,
                     numLinks, /* maxAddr */
                     asynInt32Mask | asynFloat64Mask | asynDrvUserMask, /* Interface mask */
                     asynInt32Mask | asynFloat64Mask,  /* Interrupt mask */
                     ASYN_CANBLOCK, /* asynFlags. This driver can block but is not multi-device */
                     1, /* Autoconnect */
                     0, /* Default priority */
                     0) /* Default stack size*/
{
    // 파라미터 생성
    createParam(P_AI_Val_String,    asynParamFloat64, &P_AI_Val);
    createParam(P_BO_Val_String,    asynParamInt32,   &P_BO_Val);
    createParam(P_Threshold_String, asynParamFloat64, &P_Threshold);
    createParam(P_AutoMode_String,  asynParamInt32,   &P_AutoMode);

    // 파라미터 초기값 설정
    for (int i = 0; i < numLinks; i++) {
        setDoubleParam(i, P_AI_Val, 0.0);
        setIntegerParam(i, P_BO_Val, 0);
        setDoubleParam(i, P_Threshold, 0.0);
        setIntegerParam(i, P_AutoMode, 1); // 기본값: 자동 모드
        callParamCallbacks(i);
    }
}

/**
 * @brief 정수형(int32) 파라미터에 값이 쓰여질 때 호출되는 메서드.
 */
asynStatus ThresholdLogicDriver::writeInt32(asynUser *pasynUser, epicsInt32 value)
{
    int addr = 0;
    int function = pasynUser->reason;
    asynStatus status = asynSuccess;
    const char *paramName;

    getAddress(pasynUser, &addr);
    getParamName(function, &paramName);

    /* 파라미터 라이브러리에 값 설정 */
    status = (asynStatus)setIntegerParam(addr, function, value);

    if (function == P_AutoMode) {
        /* AutoMode가 변경되면, 출력을 업데이트 */
        updateOutput(addr);
    } else if (function == P_BO_Val) {
        /* BO_VAL이 직접 쓰여지면, 수동 모드인지 확인 */
        int autoMode;
        getIntegerParam(addr, P_AutoMode, &autoMode);
        if (autoMode) {
            // 자동 모드에서는 로직이 출력을 결정하므로, 로직을 다시 평가하여 덮어씀
            updateOutput(addr);
        }
        // 수동 모드에서는 사용자가 쓴 값을 그대로 사용
    }

    /* 상위 계층이 변경사항을 알 수 있도록 콜백 호출 */
    status = (asynStatus)callParamCallbacks(addr);

    if (status)
        epicsSnprintf(pasynUser->errorMessage, pasynUser->errorMessageSize,
                      "%s:%s: status=%d, function=%d, name=%s, value=%d",
                      driverName, __func__, status, function, paramName, value);
    else
        asynPrint(pasynUser, ASYN_TRACEIO_DRIVER,
                  "%s:%s: function=%d, name=%s, value=%d\n",
                  driverName, __func__, function, paramName, value);

    return status;
}

/**
 * @brief 실수형(float64) 파라미터에 값이 쓰여질 때 호출되는 메서드.
 */
asynStatus ThresholdLogicDriver::writeFloat64(asynUser *pasynUser, epicsFloat64 value)
{
    int addr = 0;
    int function = pasynUser->reason;
    asynStatus status = asynSuccess;
    const char *paramName;

    getAddress(pasynUser, &addr);
    getParamName(function, &paramName);

    /* 파라미터 라이브러리에 값 설정 */
    status = (asynStatus)setDoubleParam(addr, function, value);

    if (function == P_AI_Val || function == P_Threshold) {
        /* AI_VAL 또는 Threshold가 변경되면, 출력을 업데이트 */
        updateOutput(addr);
    }

    /* 상위 계층이 변경사항을 알 수 있도록 콜백 호출 */
    status = (asynStatus)callParamCallbacks(addr);

    if (status)
        epicsSnprintf(pasynUser->errorMessage, pasynUser->errorMessageSize,
                      "%s:%s: status=%d, function=%d, name=%s, value=%f",
                      driverName, __func__, status, function, paramName, value);
    else
        asynPrint(pasynUser, ASYN_TRACEIO_DRIVER,
                  "%s:%s: function=%d, name=%s, value=%f\n",
                  driverName, __func__, function, paramName, value);

    return status;
}

/**
 * @brief 바이너리 출력을 업데이트하는 private 헬퍼 함수.
 */
void ThresholdLogicDriver::updateOutput(int addr)
{
    int autoMode;
    double aiVal, thresholdVal;

    getIntegerParam(addr, P_AutoMode, &autoMode);

    if (autoMode) {
        getDoubleParam(addr, P_AI_Val, &aiVal);
        getDoubleParam(addr, P_Threshold, &thresholdVal);

        int newBoVal = (aiVal > thresholdVal) ? 1 : 0;
        setIntegerParam(addr, P_BO_Val, newBoVal);
    }
    // 수동 모드에서는 아무것도 하지 않음. BO_VAL은 사용자가 제어.
}

/* iocsh를 위한 설정 함수 */
extern "C" int thresholdLogicDriverConfigure(const char *portName, int numLinks)
{
    new ThresholdLogicDriver(portName, numLinks);
    return(asynSuccess);
}

/* EPICS iocsh 셸 명령어 정의 */
static const iocshArg initArg0 = { "portName", iocshArgString };
static const iocshArg initArg1 = { "numLinks", iocshArgInt };
static const iocshArg * const initArgs[] = { &initArg0, &initArg1 };
static const iocshFuncDef initFuncDef = {"thresholdLogicDriverConfigure", 2, initArgs};
static void initCallFunc(const iocshArgBuf *args)
{
    thresholdLogicDriverConfigure(args[0].sval, args[1].ival);
}

void thresholdLogicDriverRegister(void)
{
    iocshRegister(&initFuncDef, initCallFunc);
}

extern "C" {
epicsExportRegistrar(thresholdLogicDriverRegister);
}
