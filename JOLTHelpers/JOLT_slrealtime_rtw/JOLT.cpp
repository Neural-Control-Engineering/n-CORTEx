/*
 * JOLT.cpp
 *
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * Code generation for model "JOLT".
 *
 * Model version              : 1.146
 * Simulink Coder version : 9.9 (R2023a) 19-Nov-2022
 * C++ source code generated on : Fri Oct 13 15:34:05 2023
 *
 * Target selection: slrealtime.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Intel->x86-64 (Linux 64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "JOLT.h"
#include "rtwtypes.h"
#include "JOLT_cal.h"
#include "JOLT_private.h"
#include <cstring>

extern "C"
{

#include "rt_nonfinite.h"

}

/* Named constants for MATLAB Function: '<Root>/MATLAB Function1' */
const int32_T JOLT_CALL_EVENT = -1;
const real_T JOLT_RGND = 0.0;          /* real_T ground */

/* Block signals (default storage) */
B_JOLT_T JOLT_B;

/* Block states (default storage) */
DW_JOLT_T JOLT_DW;

/* Real-time model */
RT_MODEL_JOLT_T JOLT_M_ = RT_MODEL_JOLT_T();
RT_MODEL_JOLT_T *const JOLT_M = &JOLT_M_;

/* Model step function */
void JOLT_step(void)
{
  real_T tmp;

  /* DiscretePulseGenerator: '<Root>/Npxls Trig' */
  tmp = JOLT_cal->T_npxls / 2.0;

  /* DiscretePulseGenerator: '<Root>/Npxls Trig' */
  JOLT_B.npxls_trig = (JOLT_DW.clockTickCounter < tmp) &&
    (JOLT_DW.clockTickCounter >= 0) ? JOLT_cal->NpxlsTrig_Amp : 0.0;

  /* DiscretePulseGenerator: '<Root>/Npxls Trig' */
  if (JOLT_DW.clockTickCounter >= JOLT_cal->T_npxls - 1.0) {
    JOLT_DW.clockTickCounter = 0;
  } else {
    JOLT_DW.clockTickCounter++;
  }

  /* S-Function (sg_IO191_setup_s): '<Root>/Setup ' */

  /* Level2 S-Function Block: '<Root>/Setup ' (sg_IO191_setup_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[0];
    sfcnOutputs(rts,0);
  }

  /* S-Function (slrealtimeTCPServer): '<Root>/TCP Server' incorporates:
   *  Constant: '<Root>/Constant'
   */
  {
    try {
      int enable = (int)JOLT_cal->Constant_Value;
      slrealtime::ip::tcp::Server* server = reinterpret_cast<slrealtime::ip::tcp::
        Server*>(JOLT_DW.TCPServer_PWORK);
      bool connected = server->connected();
      if (enable <= 0) {
        if (connected)
          server->reset();
        connected = false;
      } else {
        if (!connected)
          server->connect();
      }

      connected = server->connected();
      JOLT_B.TCPServer = (double)connected;
    } catch (std::exception& e) {
      std::string tmp = std::string(e.what());
      static std::string eMsg = tmp;
      rtmSetErrorStatus(JOLT_M, eMsg.c_str());
      rtmSetStopRequested(JOLT_M, 1);
      ;
    }
  }

  /* S-Function (slrealtimeTCPReceive): '<Root>/TCP Receive' */
  {
    try {
      int status = 0;
      size_t bytesReceived = 0;
      int outportWidth = (int)JOLT_DW.TCPReceive_IWORK;
      char *rcvBuf = (char *)JOLT_DW.TCPReceive_PWORK[1];
      int enable = (int)JOLT_B.TCPServer;
      slrealtime::ip::tcp::Socket* sock = reinterpret_cast<slrealtime::ip::tcp::
        Socket*>(JOLT_DW.TCPReceive_PWORK[0]);
      if (!sock)
        return;
      memset(rcvBuf, 0, outportWidth);
      if (enable > 0) {
        bytesReceived = sock->receive(rcvBuf, outportWidth);
      }

      JOLT_B.TCPReceive_o2 = (double)bytesReceived;
      void *dataPort = &JOLT_B.buttonStat;
      if (bytesReceived>0) {
        memcpy(dataPort,(void*)rcvBuf,outportWidth);
      }
    } catch (std::exception& e) {
      std::string tmp = std::string(e.what());
      static std::string eMsg = tmp;
      rtmSetErrorStatus(JOLT_M, eMsg.c_str());
      rtmSetStopRequested(JOLT_M, 1);
      ;
    }
  }

  /* S-Function (sg_IO191_ad_s): '<Root>/Analog input ' */

  /* Level2 S-Function Block: '<Root>/Analog input ' (sg_IO191_ad_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[1];
    sfcnOutputs(rts,0);
  }

  /* Memory: '<Root>/Memory' */
  JOLT_B.Memory = JOLT_DW.Memory_PreviousInput;

  /* MATLAB Function: '<Root>/MATLAB Function1' */
  JOLT_DW.sfEvent = JOLT_CALL_EVENT;
  JOLT_B.npxlsAcq_out = JOLT_B.Memory;
  JOLT_B.S_out = 0.0;
  JOLT_B.acqStatus = 0.0;
  JOLT_B.acqTone = 0.0;

  /* S-Function (sg_IO191_do_s): '<Root>/Digital output ' */

  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[2];
    sfcnOutputs(rts,0);
  }

  /* S-Function (sg_IO191_di_s): '<Root>/Digital input ' */

  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[3];
    sfcnOutputs(rts,0);
  }

  /* RateTransition generated from: '<Root>/Digital input ' */
  JOLT_B.HiddenRateTransitionForToWks_In = JOLT_B.PulseGen1Hz;

  /* Update for Memory: '<Root>/Memory' */
  JOLT_DW.Memory_PreviousInput = JOLT_B.npxlsAcq_out;

  /* Update absolute time for base rate */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   * Timer of this task consists of two 32 bit unsigned integers.
   * The two integers represent the low bits Timing.clockTick0 and the high bits
   * Timing.clockTickH0. When the low bit overflows to 0, the high bits increment.
   */
  if (!(++JOLT_M->Timing.clockTick0)) {
    ++JOLT_M->Timing.clockTickH0;
  }

  JOLT_M->Timing.t[0] = JOLT_M->Timing.clockTick0 * JOLT_M->Timing.stepSize0 +
    JOLT_M->Timing.clockTickH0 * JOLT_M->Timing.stepSize0 * 4294967296.0;
}

/* Model initialize function */
void JOLT_initialize(void)
{
  /* Registration code */

  /* initialize non-finites */
  rt_InitInfAndNaN(sizeof(real_T));
  rtsiSetSolverName(&JOLT_M->solverInfo,"FixedStepDiscrete");
  JOLT_M->solverInfoPtr = (&JOLT_M->solverInfo);

  /* Initialize timing info */
  {
    int_T *mdlTsMap = JOLT_M->Timing.sampleTimeTaskIDArray;
    mdlTsMap[0] = 0;

    /* polyspace +2 MISRA2012:D4.1 [Justified:Low] "JOLT_M points to
       static memory which is guaranteed to be non-NULL" */
    JOLT_M->Timing.sampleTimeTaskIDPtr = (&mdlTsMap[0]);
    JOLT_M->Timing.sampleTimes = (&JOLT_M->Timing.sampleTimesArray[0]);
    JOLT_M->Timing.offsetTimes = (&JOLT_M->Timing.offsetTimesArray[0]);

    /* task periods */
    JOLT_M->Timing.sampleTimes[0] = (0.001);

    /* task offsets */
    JOLT_M->Timing.offsetTimes[0] = (0.0);
  }

  rtmSetTPtr(JOLT_M, &JOLT_M->Timing.tArray[0]);

  {
    int_T *mdlSampleHits = JOLT_M->Timing.sampleHitArray;
    mdlSampleHits[0] = 1;
    JOLT_M->Timing.sampleHits = (&mdlSampleHits[0]);
  }

  rtmSetTFinal(JOLT_M, -1);
  JOLT_M->Timing.stepSize0 = 0.001;
  JOLT_M->solverInfoPtr = (&JOLT_M->solverInfo);
  JOLT_M->Timing.stepSize = (0.001);
  rtsiSetFixedStepSize(&JOLT_M->solverInfo, 0.001);
  rtsiSetSolverMode(&JOLT_M->solverInfo, SOLVER_MODE_SINGLETASKING);

  /* block I/O */
  (void) std::memset((static_cast<void *>(&JOLT_B)), 0,
                     sizeof(B_JOLT_T));

  /* states (dwork) */
  (void) std::memset(static_cast<void *>(&JOLT_DW), 0,
                     sizeof(DW_JOLT_T));

  /* child S-Function registration */
  {
    RTWSfcnInfo *sfcnInfo = &JOLT_M->NonInlinedSFcns.sfcnInfo;
    JOLT_M->sfcnInfo = (sfcnInfo);
    rtssSetErrorStatusPtr(sfcnInfo, (&rtmGetErrorStatus(JOLT_M)));
    JOLT_M->Sizes.numSampTimes = (1);
    rtssSetNumRootSampTimesPtr(sfcnInfo, &JOLT_M->Sizes.numSampTimes);
    JOLT_M->NonInlinedSFcns.taskTimePtrs[0] = (&rtmGetTPtr(JOLT_M)[0]);
    rtssSetTPtrPtr(sfcnInfo,JOLT_M->NonInlinedSFcns.taskTimePtrs);
    rtssSetTStartPtr(sfcnInfo, &rtmGetTStart(JOLT_M));
    rtssSetTFinalPtr(sfcnInfo, &rtmGetTFinal(JOLT_M));
    rtssSetTimeOfLastOutputPtr(sfcnInfo, &rtmGetTimeOfLastOutput(JOLT_M));
    rtssSetStepSizePtr(sfcnInfo, &JOLT_M->Timing.stepSize);
    rtssSetStopRequestedPtr(sfcnInfo, &rtmGetStopRequested(JOLT_M));
    rtssSetDerivCacheNeedsResetPtr(sfcnInfo, &JOLT_M->derivCacheNeedsReset);
    rtssSetZCCacheNeedsResetPtr(sfcnInfo, &JOLT_M->zCCacheNeedsReset);
    rtssSetContTimeOutputInconsistentWithStateAtMajorStepPtr(sfcnInfo,
      &JOLT_M->CTOutputIncnstWithState);
    rtssSetSampleHitsPtr(sfcnInfo, &JOLT_M->Timing.sampleHits);
    rtssSetPerTaskSampleHitsPtr(sfcnInfo, &JOLT_M->Timing.perTaskSampleHits);
    rtssSetSimModePtr(sfcnInfo, &JOLT_M->simMode);
    rtssSetSolverInfoPtr(sfcnInfo, &JOLT_M->solverInfoPtr);
  }

  JOLT_M->Sizes.numSFcns = (4);

  /* register each child */
  {
    (void) std::memset(static_cast<void *>
                       (&JOLT_M->NonInlinedSFcns.childSFunctions[0]), 0,
                       4*sizeof(SimStruct));
    JOLT_M->childSfunctions = (&JOLT_M->NonInlinedSFcns.childSFunctionPtrs[0]);
    JOLT_M->childSfunctions[0] = (&JOLT_M->NonInlinedSFcns.childSFunctions[0]);
    JOLT_M->childSfunctions[1] = (&JOLT_M->NonInlinedSFcns.childSFunctions[1]);
    JOLT_M->childSfunctions[2] = (&JOLT_M->NonInlinedSFcns.childSFunctions[2]);
    JOLT_M->childSfunctions[3] = (&JOLT_M->NonInlinedSFcns.childSFunctions[3]);

    /* Level2 S-Function Block: JOLT/<Root>/Setup  (sg_IO191_setup_s) */
    {
      SimStruct *rts = JOLT_M->childSfunctions[0];

      /* timing info */
      time_T *sfcnPeriod = JOLT_M->NonInlinedSFcns.Sfcn0.sfcnPeriod;
      time_T *sfcnOffset = JOLT_M->NonInlinedSFcns.Sfcn0.sfcnOffset;
      int_T *sfcnTsMap = JOLT_M->NonInlinedSFcns.Sfcn0.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &JOLT_M->NonInlinedSFcns.blkInfo2[0]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &JOLT_M->NonInlinedSFcns.inputOutputPortInfo2[0]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, JOLT_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &JOLT_M->NonInlinedSFcns.methods2[0]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &JOLT_M->NonInlinedSFcns.methods3[0]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &JOLT_M->NonInlinedSFcns.methods4[0]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &JOLT_M->NonInlinedSFcns.statesInfo2[0]);
        ssSetPeriodicStatesInfo(rts, &JOLT_M->
          NonInlinedSFcns.periodicStatesInfo[0]);
      }

      /* path info */
      ssSetModelName(rts, "Setup ");
      ssSetPath(rts, "JOLT/Setup ");
      ssSetRTModel(rts,JOLT_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &JOLT_M->NonInlinedSFcns.Sfcn0.params;
        ssSetSFcnParamsCount(rts, 9);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)JOLT_cal->Setup_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)JOLT_cal->Setup_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)JOLT_cal->Setup_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)JOLT_cal->Setup_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)JOLT_cal->Setup_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)JOLT_cal->Setup_P6_Size);
        ssSetSFcnParam(rts, 6, (mxArray*)JOLT_cal->Setup_P7_Size);
        ssSetSFcnParam(rts, 7, (mxArray*)JOLT_cal->Setup_P8_Size);
        ssSetSFcnParam(rts, 8, (mxArray*)JOLT_cal->Setup_P9_Size);
      }

      /* work vectors */
      ssSetRWork(rts, (real_T *) &JOLT_DW.Setup_RWORK[0]);
      ssSetPWork(rts, (void **) &JOLT_DW.Setup_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &JOLT_M->NonInlinedSFcns.Sfcn0.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &JOLT_M->NonInlinedSFcns.Sfcn0.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 2);

        /* RWORK */
        ssSetDWorkWidthAsInt(rts, 0, 2);
        ssSetDWorkDataType(rts, 0,SS_DOUBLE);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &JOLT_DW.Setup_RWORK[0]);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 1, 1);
        ssSetDWorkDataType(rts, 1,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 1, 0);
        ssSetDWork(rts, 1, &JOLT_DW.Setup_PWORK);
      }

      /* registration */
      sg_IO191_setup_s(rts);
      sfcnInitializeSizes(rts);
      sfcnInitializeSampleTimes(rts);

      /* adjust sample time */
      ssSetSampleTime(rts, 0, 0.001);
      ssSetOffsetTime(rts, 0, 0.0);
      sfcnTsMap[0] = 0;

      /* set compiled values of dynamic vector attributes */
      ssSetNumNonsampledZCsAsInt(rts, 0);

      /* Update connectivity flags for each port */
      /* Update the BufferDstPort flags for each input port */
    }

    /* Level2 S-Function Block: JOLT/<Root>/Analog input  (sg_IO191_ad_s) */
    {
      SimStruct *rts = JOLT_M->childSfunctions[1];

      /* timing info */
      time_T *sfcnPeriod = JOLT_M->NonInlinedSFcns.Sfcn1.sfcnPeriod;
      time_T *sfcnOffset = JOLT_M->NonInlinedSFcns.Sfcn1.sfcnOffset;
      int_T *sfcnTsMap = JOLT_M->NonInlinedSFcns.Sfcn1.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &JOLT_M->NonInlinedSFcns.blkInfo2[1]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &JOLT_M->NonInlinedSFcns.inputOutputPortInfo2[1]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, JOLT_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &JOLT_M->NonInlinedSFcns.methods2[1]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &JOLT_M->NonInlinedSFcns.methods3[1]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &JOLT_M->NonInlinedSFcns.methods4[1]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &JOLT_M->NonInlinedSFcns.statesInfo2[1]);
        ssSetPeriodicStatesInfo(rts, &JOLT_M->
          NonInlinedSFcns.periodicStatesInfo[1]);
      }

      /* outputs */
      {
        ssSetPortInfoForOutputs(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn1.outputPortInfo[0]);
        ssSetPortInfoForOutputs(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn1.outputPortInfo[0]);
        _ssSetNumOutputPorts(rts, 1);
        _ssSetPortInfo2ForOutputUnits(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn1.outputPortUnits[0]);
        ssSetOutputPortUnit(rts, 0, 0);
        _ssSetPortInfo2ForOutputCoSimAttribute(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn1.outputPortCoSimAttribute[0]);
        ssSetOutputPortIsContinuousQuantity(rts, 0, 0);

        /* port 0 */
        {
          _ssSetOutputPortNumDimensions(rts, 0, 1);
          ssSetOutputPortWidthAsInt(rts, 0, 1);
          ssSetOutputPortSignal(rts, 0, ((real_T *) &JOLT_B.monofilData));
        }
      }

      /* path info */
      ssSetModelName(rts, "Analog input ");
      ssSetPath(rts, "JOLT/Analog input ");
      ssSetRTModel(rts,JOLT_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &JOLT_M->NonInlinedSFcns.Sfcn1.params;
        ssSetSFcnParamsCount(rts, 9);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)JOLT_cal->Analoginput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)JOLT_cal->Analoginput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)JOLT_cal->Analoginput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)JOLT_cal->Analoginput_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)JOLT_cal->Analoginput_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)JOLT_cal->Analoginput_P6_Size);
        ssSetSFcnParam(rts, 6, (mxArray*)JOLT_cal->Analoginput_P7_Size);
        ssSetSFcnParam(rts, 7, (mxArray*)JOLT_cal->Analoginput_P8_Size);
        ssSetSFcnParam(rts, 8, (mxArray*)JOLT_cal->Analoginput_P9_Size);
      }

      /* work vectors */
      ssSetIWork(rts, (int_T *) &JOLT_DW.Analoginput_IWORK[0]);
      ssSetPWork(rts, (void **) &JOLT_DW.Analoginput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &JOLT_M->NonInlinedSFcns.Sfcn1.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &JOLT_M->NonInlinedSFcns.Sfcn1.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 2);

        /* IWORK */
        ssSetDWorkWidthAsInt(rts, 0, 2);
        ssSetDWorkDataType(rts, 0,SS_INTEGER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &JOLT_DW.Analoginput_IWORK[0]);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 1, 1);
        ssSetDWorkDataType(rts, 1,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 1, 0);
        ssSetDWork(rts, 1, &JOLT_DW.Analoginput_PWORK);
      }

      /* registration */
      sg_IO191_ad_s(rts);
      sfcnInitializeSizes(rts);
      sfcnInitializeSampleTimes(rts);

      /* adjust sample time */
      ssSetSampleTime(rts, 0, 0.001);
      ssSetOffsetTime(rts, 0, 0.0);
      sfcnTsMap[0] = 0;

      /* set compiled values of dynamic vector attributes */
      ssSetNumNonsampledZCsAsInt(rts, 0);

      /* Update connectivity flags for each port */
      _ssSetOutputPortConnected(rts, 0, 1);
      _ssSetOutputPortBeingMerged(rts, 0, 0);

      /* Update the BufferDstPort flags for each input port */
    }

    /* Level2 S-Function Block: JOLT/<Root>/Digital output  (sg_IO191_do_s) */
    {
      SimStruct *rts = JOLT_M->childSfunctions[2];

      /* timing info */
      time_T *sfcnPeriod = JOLT_M->NonInlinedSFcns.Sfcn2.sfcnPeriod;
      time_T *sfcnOffset = JOLT_M->NonInlinedSFcns.Sfcn2.sfcnOffset;
      int_T *sfcnTsMap = JOLT_M->NonInlinedSFcns.Sfcn2.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &JOLT_M->NonInlinedSFcns.blkInfo2[2]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &JOLT_M->NonInlinedSFcns.inputOutputPortInfo2[2]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, JOLT_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &JOLT_M->NonInlinedSFcns.methods2[2]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &JOLT_M->NonInlinedSFcns.methods3[2]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &JOLT_M->NonInlinedSFcns.methods4[2]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &JOLT_M->NonInlinedSFcns.statesInfo2[2]);
        ssSetPeriodicStatesInfo(rts, &JOLT_M->
          NonInlinedSFcns.periodicStatesInfo[2]);
      }

      /* inputs */
      {
        _ssSetNumInputPorts(rts, 15);
        ssSetPortInfoForInputs(rts, &JOLT_M->
          NonInlinedSFcns.Sfcn2.inputPortInfo[0]);
        ssSetPortInfoForInputs(rts, &JOLT_M->
          NonInlinedSFcns.Sfcn2.inputPortInfo[0]);
        _ssSetPortInfo2ForInputUnits(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn2.inputPortUnits[0]);
        ssSetInputPortUnit(rts, 0, 0);
        ssSetInputPortUnit(rts, 1, 0);
        ssSetInputPortUnit(rts, 2, 0);
        ssSetInputPortUnit(rts, 3, 0);
        ssSetInputPortUnit(rts, 4, 0);
        ssSetInputPortUnit(rts, 5, 0);
        ssSetInputPortUnit(rts, 6, 0);
        ssSetInputPortUnit(rts, 7, 0);
        ssSetInputPortUnit(rts, 8, 0);
        ssSetInputPortUnit(rts, 9, 0);
        ssSetInputPortUnit(rts, 10, 0);
        ssSetInputPortUnit(rts, 11, 0);
        ssSetInputPortUnit(rts, 12, 0);
        ssSetInputPortUnit(rts, 13, 0);
        ssSetInputPortUnit(rts, 14, 0);
        _ssSetPortInfo2ForInputCoSimAttribute(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn2.inputPortCoSimAttribute[0]);
        ssSetInputPortIsContinuousQuantity(rts, 0, 0);
        ssSetInputPortIsContinuousQuantity(rts, 1, 0);
        ssSetInputPortIsContinuousQuantity(rts, 2, 0);
        ssSetInputPortIsContinuousQuantity(rts, 3, 0);
        ssSetInputPortIsContinuousQuantity(rts, 4, 0);
        ssSetInputPortIsContinuousQuantity(rts, 5, 0);
        ssSetInputPortIsContinuousQuantity(rts, 6, 0);
        ssSetInputPortIsContinuousQuantity(rts, 7, 0);
        ssSetInputPortIsContinuousQuantity(rts, 8, 0);
        ssSetInputPortIsContinuousQuantity(rts, 9, 0);
        ssSetInputPortIsContinuousQuantity(rts, 10, 0);
        ssSetInputPortIsContinuousQuantity(rts, 11, 0);
        ssSetInputPortIsContinuousQuantity(rts, 12, 0);
        ssSetInputPortIsContinuousQuantity(rts, 13, 0);
        ssSetInputPortIsContinuousQuantity(rts, 14, 0);

        /* port 0 */
        {
          ssSetInputPortRequiredContiguous(rts, 0, 1);
          ssSetInputPortSignal(rts, 0, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 0, 1);
          ssSetInputPortWidthAsInt(rts, 0, 1);
        }

        /* port 1 */
        {
          ssSetInputPortRequiredContiguous(rts, 1, 1);
          ssSetInputPortSignal(rts, 1, &JOLT_B.npxls_trig);
          _ssSetInputPortNumDimensions(rts, 1, 1);
          ssSetInputPortWidthAsInt(rts, 1, 1);
        }

        /* port 2 */
        {
          ssSetInputPortRequiredContiguous(rts, 2, 1);
          ssSetInputPortSignal(rts, 2, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 2, 1);
          ssSetInputPortWidthAsInt(rts, 2, 1);
        }

        /* port 3 */
        {
          ssSetInputPortRequiredContiguous(rts, 3, 1);
          ssSetInputPortSignal(rts, 3, &JOLT_B.npxlsAcq_out);
          _ssSetInputPortNumDimensions(rts, 3, 1);
          ssSetInputPortWidthAsInt(rts, 3, 1);
        }

        /* port 4 */
        {
          ssSetInputPortRequiredContiguous(rts, 4, 1);
          ssSetInputPortSignal(rts, 4, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 4, 1);
          ssSetInputPortWidthAsInt(rts, 4, 1);
        }

        /* port 5 */
        {
          ssSetInputPortRequiredContiguous(rts, 5, 1);
          ssSetInputPortSignal(rts, 5, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 5, 1);
          ssSetInputPortWidthAsInt(rts, 5, 1);
        }

        /* port 6 */
        {
          ssSetInputPortRequiredContiguous(rts, 6, 1);
          ssSetInputPortSignal(rts, 6, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 6, 1);
          ssSetInputPortWidthAsInt(rts, 6, 1);
        }

        /* port 7 */
        {
          ssSetInputPortRequiredContiguous(rts, 7, 1);
          ssSetInputPortSignal(rts, 7, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 7, 1);
          ssSetInputPortWidthAsInt(rts, 7, 1);
        }

        /* port 8 */
        {
          ssSetInputPortRequiredContiguous(rts, 8, 1);
          ssSetInputPortSignal(rts, 8, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 8, 1);
          ssSetInputPortWidthAsInt(rts, 8, 1);
        }

        /* port 9 */
        {
          ssSetInputPortRequiredContiguous(rts, 9, 1);
          ssSetInputPortSignal(rts, 9, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 9, 1);
          ssSetInputPortWidthAsInt(rts, 9, 1);
        }

        /* port 10 */
        {
          ssSetInputPortRequiredContiguous(rts, 10, 1);
          ssSetInputPortSignal(rts, 10, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 10, 1);
          ssSetInputPortWidthAsInt(rts, 10, 1);
        }

        /* port 11 */
        {
          ssSetInputPortRequiredContiguous(rts, 11, 1);
          ssSetInputPortSignal(rts, 11, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 11, 1);
          ssSetInputPortWidthAsInt(rts, 11, 1);
        }

        /* port 12 */
        {
          ssSetInputPortRequiredContiguous(rts, 12, 1);
          ssSetInputPortSignal(rts, 12, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 12, 1);
          ssSetInputPortWidthAsInt(rts, 12, 1);
        }

        /* port 13 */
        {
          ssSetInputPortRequiredContiguous(rts, 13, 1);
          ssSetInputPortSignal(rts, 13, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 13, 1);
          ssSetInputPortWidthAsInt(rts, 13, 1);
        }

        /* port 14 */
        {
          ssSetInputPortRequiredContiguous(rts, 14, 1);
          ssSetInputPortSignal(rts, 14, (const_cast<real_T*>(&JOLT_RGND)));
          _ssSetInputPortNumDimensions(rts, 14, 1);
          ssSetInputPortWidthAsInt(rts, 14, 1);
        }
      }

      /* path info */
      ssSetModelName(rts, "Digital output ");
      ssSetPath(rts, "JOLT/Digital output ");
      ssSetRTModel(rts,JOLT_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &JOLT_M->NonInlinedSFcns.Sfcn2.params;
        ssSetSFcnParamsCount(rts, 6);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)JOLT_cal->Digitaloutput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)JOLT_cal->Digitaloutput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)JOLT_cal->Digitaloutput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)JOLT_cal->Digitaloutput_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)JOLT_cal->Digitaloutput_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)JOLT_cal->Digitaloutput_P6_Size);
      }

      /* work vectors */
      ssSetPWork(rts, (void **) &JOLT_DW.Digitaloutput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &JOLT_M->NonInlinedSFcns.Sfcn2.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &JOLT_M->NonInlinedSFcns.Sfcn2.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 1);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 0, 1);
        ssSetDWorkDataType(rts, 0,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &JOLT_DW.Digitaloutput_PWORK);
      }

      /* registration */
      sg_IO191_do_s(rts);
      sfcnInitializeSizes(rts);
      sfcnInitializeSampleTimes(rts);

      /* adjust sample time */
      ssSetSampleTime(rts, 0, 0.001);
      ssSetOffsetTime(rts, 0, 0.0);
      sfcnTsMap[0] = 0;

      /* set compiled values of dynamic vector attributes */
      ssSetNumNonsampledZCsAsInt(rts, 0);

      /* Update connectivity flags for each port */
      _ssSetInputPortConnected(rts, 0, 0);
      _ssSetInputPortConnected(rts, 1, 1);
      _ssSetInputPortConnected(rts, 2, 0);
      _ssSetInputPortConnected(rts, 3, 1);
      _ssSetInputPortConnected(rts, 4, 0);
      _ssSetInputPortConnected(rts, 5, 0);
      _ssSetInputPortConnected(rts, 6, 0);
      _ssSetInputPortConnected(rts, 7, 0);
      _ssSetInputPortConnected(rts, 8, 0);
      _ssSetInputPortConnected(rts, 9, 0);
      _ssSetInputPortConnected(rts, 10, 0);
      _ssSetInputPortConnected(rts, 11, 0);
      _ssSetInputPortConnected(rts, 12, 0);
      _ssSetInputPortConnected(rts, 13, 0);
      _ssSetInputPortConnected(rts, 14, 0);

      /* Update the BufferDstPort flags for each input port */
      ssSetInputPortBufferDstPort(rts, 0, -1);
      ssSetInputPortBufferDstPort(rts, 1, -1);
      ssSetInputPortBufferDstPort(rts, 2, -1);
      ssSetInputPortBufferDstPort(rts, 3, -1);
      ssSetInputPortBufferDstPort(rts, 4, -1);
      ssSetInputPortBufferDstPort(rts, 5, -1);
      ssSetInputPortBufferDstPort(rts, 6, -1);
      ssSetInputPortBufferDstPort(rts, 7, -1);
      ssSetInputPortBufferDstPort(rts, 8, -1);
      ssSetInputPortBufferDstPort(rts, 9, -1);
      ssSetInputPortBufferDstPort(rts, 10, -1);
      ssSetInputPortBufferDstPort(rts, 11, -1);
      ssSetInputPortBufferDstPort(rts, 12, -1);
      ssSetInputPortBufferDstPort(rts, 13, -1);
      ssSetInputPortBufferDstPort(rts, 14, -1);
    }

    /* Level2 S-Function Block: JOLT/<Root>/Digital input  (sg_IO191_di_s) */
    {
      SimStruct *rts = JOLT_M->childSfunctions[3];

      /* timing info */
      time_T *sfcnPeriod = JOLT_M->NonInlinedSFcns.Sfcn3.sfcnPeriod;
      time_T *sfcnOffset = JOLT_M->NonInlinedSFcns.Sfcn3.sfcnOffset;
      int_T *sfcnTsMap = JOLT_M->NonInlinedSFcns.Sfcn3.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &JOLT_M->NonInlinedSFcns.blkInfo2[3]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &JOLT_M->NonInlinedSFcns.inputOutputPortInfo2[3]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, JOLT_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &JOLT_M->NonInlinedSFcns.methods2[3]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &JOLT_M->NonInlinedSFcns.methods3[3]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &JOLT_M->NonInlinedSFcns.methods4[3]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &JOLT_M->NonInlinedSFcns.statesInfo2[3]);
        ssSetPeriodicStatesInfo(rts, &JOLT_M->
          NonInlinedSFcns.periodicStatesInfo[3]);
      }

      /* outputs */
      {
        ssSetPortInfoForOutputs(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn3.outputPortInfo[0]);
        ssSetPortInfoForOutputs(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn3.outputPortInfo[0]);
        _ssSetNumOutputPorts(rts, 1);
        _ssSetPortInfo2ForOutputUnits(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn3.outputPortUnits[0]);
        ssSetOutputPortUnit(rts, 0, 0);
        _ssSetPortInfo2ForOutputCoSimAttribute(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn3.outputPortCoSimAttribute[0]);
        ssSetOutputPortIsContinuousQuantity(rts, 0, 0);

        /* port 0 */
        {
          _ssSetOutputPortNumDimensions(rts, 0, 1);
          ssSetOutputPortWidthAsInt(rts, 0, 1);
          ssSetOutputPortSignal(rts, 0, ((real_T *) &JOLT_B.PulseGen1Hz));
        }
      }

      /* path info */
      ssSetModelName(rts, "Digital input ");
      ssSetPath(rts, "JOLT/Digital input ");
      ssSetRTModel(rts,JOLT_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &JOLT_M->NonInlinedSFcns.Sfcn3.params;
        ssSetSFcnParamsCount(rts, 4);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)JOLT_cal->Digitalinput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)JOLT_cal->Digitalinput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)JOLT_cal->Digitalinput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)JOLT_cal->Digitalinput_P4_Size);
      }

      /* work vectors */
      ssSetPWork(rts, (void **) &JOLT_DW.Digitalinput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &JOLT_M->NonInlinedSFcns.Sfcn3.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &JOLT_M->NonInlinedSFcns.Sfcn3.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 1);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 0, 1);
        ssSetDWorkDataType(rts, 0,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &JOLT_DW.Digitalinput_PWORK);
      }

      /* registration */
      sg_IO191_di_s(rts);
      sfcnInitializeSizes(rts);
      sfcnInitializeSampleTimes(rts);

      /* adjust sample time */
      ssSetSampleTime(rts, 0, 0.001);
      ssSetOffsetTime(rts, 0, 0.0);
      sfcnTsMap[0] = 0;

      /* set compiled values of dynamic vector attributes */
      ssSetNumNonsampledZCsAsInt(rts, 0);

      /* Update connectivity flags for each port */
      _ssSetOutputPortConnected(rts, 0, 1);
      _ssSetOutputPortBeingMerged(rts, 0, 0);

      /* Update the BufferDstPort flags for each input port */
    }
  }

  /* Start for S-Function (sg_IO191_setup_s): '<Root>/Setup ' */
  /* Level2 S-Function Block: '<Root>/Setup ' (sg_IO191_setup_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[0];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (slrealtimeTCPServer): '<Root>/TCP Server' incorporates:
   *  Constant: '<Root>/Constant'
   */
  {
    try {
      slrealtime::ip::tcp::Server* server = (slrealtime::ip::tcp::Server*)
        slrealtime::ip::SocketFactory::createSocket(slrealtime::ip::SocketType::
        TCPServer, "0.0.0.0", 8001U);
      JOLT_DW.TCPServer_PWORK = reinterpret_cast<void*>(server);
      server->reset();
    } catch (std::exception& e) {
      std::string tmp = std::string(e.what());
      static std::string eMsg = tmp;
      rtmSetErrorStatus(JOLT_M, eMsg.c_str());
      rtmSetStopRequested(JOLT_M, 1);
      ;
    }
  }

  /* Start for S-Function (slrealtimeTCPReceive): '<Root>/TCP Receive' */
  {
    try {
      slrealtime::ip::tcp::Socket* sock = (slrealtime::ip::tcp::Socket*)
        slrealtime::ip::SocketFactory::getSocket("0.0.0.0", 8001U);
      char *buffer = (char *) calloc(1, 1);
      JOLT_DW.TCPReceive_PWORK[0] = reinterpret_cast<void*>(sock);
      JOLT_DW.TCPReceive_PWORK[1] = (void *)buffer;
      JOLT_DW.TCPReceive_IWORK = 1;
    } catch (std::exception& e) {
      std::string tmp = std::string(e.what());
      static std::string eMsg = tmp;
      rtmSetErrorStatus(JOLT_M, eMsg.c_str());
      rtmSetStopRequested(JOLT_M, 1);
      ;
    }
  }

  /* Start for S-Function (sg_IO191_ad_s): '<Root>/Analog input ' */
  /* Level2 S-Function Block: '<Root>/Analog input ' (sg_IO191_ad_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[1];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_do_s): '<Root>/Digital output ' */
  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[2];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_di_s): '<Root>/Digital input ' */
  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[3];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* InitializeConditions for DiscretePulseGenerator: '<Root>/Npxls Trig' */
  JOLT_DW.clockTickCounter = 0;

  /* InitializeConditions for Memory: '<Root>/Memory' */
  JOLT_DW.Memory_PreviousInput = JOLT_cal->Memory_InitialCondition;

  /* SystemInitialize for MATLAB Function: '<Root>/MATLAB Function1' */
  JOLT_DW.sfEvent = JOLT_CALL_EVENT;
  JOLT_DW.is_active_c2_JOLT = 0U;
}

/* Model terminate function */
void JOLT_terminate(void)
{
  /* Terminate for S-Function (sg_IO191_setup_s): '<Root>/Setup ' */
  /* Level2 S-Function Block: '<Root>/Setup ' (sg_IO191_setup_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[0];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (slrealtimeTCPServer): '<Root>/TCP Server' incorporates:
   *  Constant: '<Root>/Constant'
   */
  {
    if (JOLT_DW.TCPServer_PWORK != NULL) {
      slrealtime::ip::tcp::Server* server = reinterpret_cast<slrealtime::ip::tcp::
        Server*>(JOLT_DW.TCPServer_PWORK);
      slrealtime::ip::SocketFactory::releaseSocket(server->localAddress(),
        server->port());
    }
  }

  /* Terminate for S-Function (slrealtimeTCPReceive): '<Root>/TCP Receive' */
  {
    if (JOLT_DW.TCPReceive_PWORK[1] != NULL) {
      char_T *rcvBuf = (char_T *)JOLT_DW.TCPReceive_PWORK[1];
      if (rcvBuf)
        free(rcvBuf);
    }
  }

  /* Terminate for S-Function (sg_IO191_ad_s): '<Root>/Analog input ' */
  /* Level2 S-Function Block: '<Root>/Analog input ' (sg_IO191_ad_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[1];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_do_s): '<Root>/Digital output ' */
  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[2];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_di_s): '<Root>/Digital input ' */
  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[3];
    sfcnTerminate(rts);
  }
}
