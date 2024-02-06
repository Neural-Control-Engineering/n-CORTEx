/*
 * DEV2P.cpp
 *
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * Code generation for model "DEV2P".
 *
 * Model version              : 1.123
 * Simulink Coder version : 9.9 (R2023a) 19-Nov-2022
 * C++ source code generated on : Tue Jan 30 17:16:16 2024
 *
 * Target selection: slrealtime.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Intel->x86-64 (Linux 64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "DEV2P.h"
#include "rtwtypes.h"
#include "DEV2P_cal.h"
#include "DEV2P_private.h"
#include <cstring>

extern "C"
{

#include "rt_nonfinite.h"

}

/* Named constants for MATLAB Function: '<Root>/MATLAB Function' */
const int32_T DEV2P_CALL_EVENT = -1;
const real_T DEV2P_RGND = 0.0;         /* real_T ground */

/* Block signals (default storage) */
B_DEV2P_T DEV2P_B;

/* Block states (default storage) */
DW_DEV2P_T DEV2P_DW;

/* Real-time model */
RT_MODEL_DEV2P_T DEV2P_M_ = RT_MODEL_DEV2P_T();
RT_MODEL_DEV2P_T *const DEV2P_M = &DEV2P_M_;

/* Model step function */
void DEV2P_step(void)
{
  real_T tmp;

  /* RelationalOperator: '<Root>/Relational Operator' incorporates:
   *  Constant: '<Root>/Constant'
   */
  DEV2P_B.RelationalOperator = (DEV2P_cal->maxFrames <= 0.0);

  /* Stop: '<Root>/Stop Simulation' */
  if (DEV2P_B.RelationalOperator) {
    rtmSetStopRequested(DEV2P_M, 1);
  }

  /* End of Stop: '<Root>/Stop Simulation' */

  /* DiscretePulseGenerator: '<Root>/Pupil Trig' */
  tmp = DEV2P_cal->T_pupil / 2.0;

  /* DiscretePulseGenerator: '<Root>/Pupil Trig' */
  DEV2P_B.pupilCam_trig = (DEV2P_DW.clockTickCounter < tmp) &&
    (DEV2P_DW.clockTickCounter >= 0) ? DEV2P_cal->PupilTrig_Amp : 0.0;

  /* DiscretePulseGenerator: '<Root>/Pupil Trig' */
  if (DEV2P_DW.clockTickCounter >= DEV2P_cal->T_pupil - 1.0) {
    DEV2P_DW.clockTickCounter = 0;
  } else {
    DEV2P_DW.clockTickCounter++;
  }

  /* DiscretePulseGenerator: '<Root>/imAcq_outTst' */
  DEV2P_B.imAcq_outTst = (DEV2P_DW.clockTickCounter_a <
    DEV2P_cal->imAcq_outTst_Duty) && (DEV2P_DW.clockTickCounter_a >= 0) ?
    DEV2P_cal->imAcq_outTst_Amp : 0.0;

  /* DiscretePulseGenerator: '<Root>/imAcq_outTst' */
  if (DEV2P_DW.clockTickCounter_a >= DEV2P_cal->imAcq_outTst_Period - 1.0) {
    DEV2P_DW.clockTickCounter_a = 0;
  } else {
    DEV2P_DW.clockTickCounter_a++;
  }

  /* Memory: '<Root>/Memory2' */
  DEV2P_B.Memory2 = DEV2P_DW.Memory2_PreviousInput;

  /* Memory: '<Root>/Memory1' */
  DEV2P_B.Memory1 = DEV2P_DW.Memory1_PreviousInput;

  /* Memory: '<Root>/Memory' */
  DEV2P_B.Memory = DEV2P_DW.Memory_PreviousInput;

  /* MATLAB Function: '<Root>/MATLAB Function' */
  DEV2P_DW.sfEvent_e = DEV2P_CALL_EVENT;
  switch (static_cast<int32_T>(DEV2P_B.Memory2)) {
   case 0:
    DEV2P_B.imAcq_out = 5.0;
    DEV2P_B.state_out = 2.0;
    DEV2P_B.localTime_out = DEV2P_B.Memory1 + 1.0;
    DEV2P_B.pupilAcq_out = 1.0;
    DEV2P_B.treadAcq_out = 1.0;
    break;

   case 2:
    DEV2P_B.imAcq_out = 0.0;
    DEV2P_B.pupilAcq_out = DEV2P_B.Memory;
    DEV2P_B.treadAcq_out = 0.0;
    DEV2P_B.localTime_out = DEV2P_B.Memory1 + 1.0;
    DEV2P_B.state_out = DEV2P_B.Memory2;
    break;

   default:
    DEV2P_B.state_out = DEV2P_B.Memory2;
    DEV2P_B.localTime_out = DEV2P_B.Memory1;
    DEV2P_B.pupilAcq_out = DEV2P_B.Memory;
    DEV2P_B.treadAcq_out = 0.0;
    DEV2P_B.imAcq_out = 0.0;
    break;
  }

  /* End of MATLAB Function: '<Root>/MATLAB Function' */

  /* Clock: '<S2>/Clock' */
  DEV2P_B.Clock = DEV2P_M->Timing.t[0];

  /* MATLAB Function: '<S2>/MATLAB Function1' */
  DEV2P_DW.sfEvent = DEV2P_CALL_EVENT;
  if (DEV2P_B.pupilAcq_out != 0.0) {
    DEV2P_B.tonePulse = 1.0;
    DEV2P_DW.t0 = DEV2P_B.Clock;
    DEV2P_DW.t0_not_empty = true;
  } else if (DEV2P_DW.t0_not_empty) {
    DEV2P_B.tonePulse = (DEV2P_B.Clock - DEV2P_DW.t0 < 1.5);
  } else {
    DEV2P_B.tonePulse = 0.0;
  }

  /* End of MATLAB Function: '<S2>/MATLAB Function1' */

  /* S-Function (sg_IO191_setup_s): '<Root>/Setup ' */

  /* Level2 S-Function Block: '<Root>/Setup ' (sg_IO191_setup_s) */
  {
    SimStruct *rts = DEV2P_M->childSfunctions[0];
    sfcnOutputs(rts,0);
  }

  /* S-Function (sg_IO191_do_s): '<Root>/Digital output ' */

  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = DEV2P_M->childSfunctions[1];
    sfcnOutputs(rts,0);
  }

  /* S-Function (sg_IO191_di_s): '<Root>/Digital input ' */

  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = DEV2P_M->childSfunctions[2];
    sfcnOutputs(rts,0);
  }

  /* RateTransition generated from: '<Root>/Digital input ' */
  DEV2P_B.HiddenRateTransitionForToWks_In = DEV2P_B.PulseGen1Hz;

  /* Update for Memory: '<Root>/Memory2' */
  DEV2P_DW.Memory2_PreviousInput = DEV2P_B.state_out;

  /* Update for Memory: '<Root>/Memory1' */
  DEV2P_DW.Memory1_PreviousInput = DEV2P_B.localTime_out;

  /* Update for Memory: '<Root>/Memory' */
  DEV2P_DW.Memory_PreviousInput = DEV2P_B.treadAcq_out;

  /* Update absolute time for base rate */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   * Timer of this task consists of two 32 bit unsigned integers.
   * The two integers represent the low bits Timing.clockTick0 and the high bits
   * Timing.clockTickH0. When the low bit overflows to 0, the high bits increment.
   */
  if (!(++DEV2P_M->Timing.clockTick0)) {
    ++DEV2P_M->Timing.clockTickH0;
  }

  DEV2P_M->Timing.t[0] = DEV2P_M->Timing.clockTick0 * DEV2P_M->Timing.stepSize0
    + DEV2P_M->Timing.clockTickH0 * DEV2P_M->Timing.stepSize0 * 4294967296.0;

  {
    /* Update absolute timer for sample time: [0.001s, 0.0s] */
    /* The "clockTick1" counts the number of times the code of this task has
     * been executed. The absolute time is the multiplication of "clockTick1"
     * and "Timing.stepSize1". Size of "clockTick1" ensures timer will not
     * overflow during the application lifespan selected.
     * Timer of this task consists of two 32 bit unsigned integers.
     * The two integers represent the low bits Timing.clockTick1 and the high bits
     * Timing.clockTickH1. When the low bit overflows to 0, the high bits increment.
     */
    if (!(++DEV2P_M->Timing.clockTick1)) {
      ++DEV2P_M->Timing.clockTickH1;
    }

    DEV2P_M->Timing.t[1] = DEV2P_M->Timing.clockTick1 *
      DEV2P_M->Timing.stepSize1 + DEV2P_M->Timing.clockTickH1 *
      DEV2P_M->Timing.stepSize1 * 4294967296.0;
  }
}

/* Model initialize function */
void DEV2P_initialize(void)
{
  /* Registration code */

  /* initialize non-finites */
  rt_InitInfAndNaN(sizeof(real_T));

  {
    /* Setup solver object */
    rtsiSetSimTimeStepPtr(&DEV2P_M->solverInfo, &DEV2P_M->Timing.simTimeStep);
    rtsiSetTPtr(&DEV2P_M->solverInfo, &rtmGetTPtr(DEV2P_M));
    rtsiSetStepSizePtr(&DEV2P_M->solverInfo, &DEV2P_M->Timing.stepSize0);
    rtsiSetErrorStatusPtr(&DEV2P_M->solverInfo, (&rtmGetErrorStatus(DEV2P_M)));
    rtsiSetRTModelPtr(&DEV2P_M->solverInfo, DEV2P_M);
  }

  rtsiSetSimTimeStep(&DEV2P_M->solverInfo, MAJOR_TIME_STEP);
  rtsiSetSolverName(&DEV2P_M->solverInfo,"FixedStepDiscrete");
  DEV2P_M->solverInfoPtr = (&DEV2P_M->solverInfo);

  /* Initialize timing info */
  {
    int_T *mdlTsMap = DEV2P_M->Timing.sampleTimeTaskIDArray;
    mdlTsMap[0] = 0;
    mdlTsMap[1] = 1;

    /* polyspace +2 MISRA2012:D4.1 [Justified:Low] "DEV2P_M points to
       static memory which is guaranteed to be non-NULL" */
    DEV2P_M->Timing.sampleTimeTaskIDPtr = (&mdlTsMap[0]);
    DEV2P_M->Timing.sampleTimes = (&DEV2P_M->Timing.sampleTimesArray[0]);
    DEV2P_M->Timing.offsetTimes = (&DEV2P_M->Timing.offsetTimesArray[0]);

    /* task periods */
    DEV2P_M->Timing.sampleTimes[0] = (0.0);
    DEV2P_M->Timing.sampleTimes[1] = (0.001);

    /* task offsets */
    DEV2P_M->Timing.offsetTimes[0] = (0.0);
    DEV2P_M->Timing.offsetTimes[1] = (0.0);
  }

  rtmSetTPtr(DEV2P_M, &DEV2P_M->Timing.tArray[0]);

  {
    int_T *mdlSampleHits = DEV2P_M->Timing.sampleHitArray;
    mdlSampleHits[0] = 1;
    mdlSampleHits[1] = 1;
    DEV2P_M->Timing.sampleHits = (&mdlSampleHits[0]);
  }

  rtmSetTFinal(DEV2P_M, -1);
  DEV2P_M->Timing.stepSize0 = 0.001;
  DEV2P_M->Timing.stepSize1 = 0.001;
  DEV2P_M->solverInfoPtr = (&DEV2P_M->solverInfo);
  DEV2P_M->Timing.stepSize = (0.001);
  rtsiSetFixedStepSize(&DEV2P_M->solverInfo, 0.001);
  rtsiSetSolverMode(&DEV2P_M->solverInfo, SOLVER_MODE_SINGLETASKING);

  /* block I/O */
  (void) std::memset((static_cast<void *>(&DEV2P_B)), 0,
                     sizeof(B_DEV2P_T));

  /* states (dwork) */
  (void) std::memset(static_cast<void *>(&DEV2P_DW), 0,
                     sizeof(DW_DEV2P_T));

  /* child S-Function registration */
  {
    RTWSfcnInfo *sfcnInfo = &DEV2P_M->NonInlinedSFcns.sfcnInfo;
    DEV2P_M->sfcnInfo = (sfcnInfo);
    rtssSetErrorStatusPtr(sfcnInfo, (&rtmGetErrorStatus(DEV2P_M)));
    DEV2P_M->Sizes.numSampTimes = (2);
    rtssSetNumRootSampTimesPtr(sfcnInfo, &DEV2P_M->Sizes.numSampTimes);
    DEV2P_M->NonInlinedSFcns.taskTimePtrs[0] = (&rtmGetTPtr(DEV2P_M)[0]);
    DEV2P_M->NonInlinedSFcns.taskTimePtrs[1] = (&rtmGetTPtr(DEV2P_M)[1]);
    rtssSetTPtrPtr(sfcnInfo,DEV2P_M->NonInlinedSFcns.taskTimePtrs);
    rtssSetTStartPtr(sfcnInfo, &rtmGetTStart(DEV2P_M));
    rtssSetTFinalPtr(sfcnInfo, &rtmGetTFinal(DEV2P_M));
    rtssSetTimeOfLastOutputPtr(sfcnInfo, &rtmGetTimeOfLastOutput(DEV2P_M));
    rtssSetStepSizePtr(sfcnInfo, &DEV2P_M->Timing.stepSize);
    rtssSetStopRequestedPtr(sfcnInfo, &rtmGetStopRequested(DEV2P_M));
    rtssSetDerivCacheNeedsResetPtr(sfcnInfo, &DEV2P_M->derivCacheNeedsReset);
    rtssSetZCCacheNeedsResetPtr(sfcnInfo, &DEV2P_M->zCCacheNeedsReset);
    rtssSetContTimeOutputInconsistentWithStateAtMajorStepPtr(sfcnInfo,
      &DEV2P_M->CTOutputIncnstWithState);
    rtssSetSampleHitsPtr(sfcnInfo, &DEV2P_M->Timing.sampleHits);
    rtssSetPerTaskSampleHitsPtr(sfcnInfo, &DEV2P_M->Timing.perTaskSampleHits);
    rtssSetSimModePtr(sfcnInfo, &DEV2P_M->simMode);
    rtssSetSolverInfoPtr(sfcnInfo, &DEV2P_M->solverInfoPtr);
  }

  DEV2P_M->Sizes.numSFcns = (3);

  /* register each child */
  {
    (void) std::memset(static_cast<void *>
                       (&DEV2P_M->NonInlinedSFcns.childSFunctions[0]), 0,
                       3*sizeof(SimStruct));
    DEV2P_M->childSfunctions = (&DEV2P_M->NonInlinedSFcns.childSFunctionPtrs[0]);
    DEV2P_M->childSfunctions[0] = (&DEV2P_M->NonInlinedSFcns.childSFunctions[0]);
    DEV2P_M->childSfunctions[1] = (&DEV2P_M->NonInlinedSFcns.childSFunctions[1]);
    DEV2P_M->childSfunctions[2] = (&DEV2P_M->NonInlinedSFcns.childSFunctions[2]);

    /* Level2 S-Function Block: DEV2P/<Root>/Setup  (sg_IO191_setup_s) */
    {
      SimStruct *rts = DEV2P_M->childSfunctions[0];

      /* timing info */
      time_T *sfcnPeriod = DEV2P_M->NonInlinedSFcns.Sfcn0.sfcnPeriod;
      time_T *sfcnOffset = DEV2P_M->NonInlinedSFcns.Sfcn0.sfcnOffset;
      int_T *sfcnTsMap = DEV2P_M->NonInlinedSFcns.Sfcn0.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &DEV2P_M->NonInlinedSFcns.blkInfo2[0]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &DEV2P_M->NonInlinedSFcns.inputOutputPortInfo2[0]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, DEV2P_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &DEV2P_M->NonInlinedSFcns.methods2[0]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &DEV2P_M->NonInlinedSFcns.methods3[0]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &DEV2P_M->NonInlinedSFcns.methods4[0]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &DEV2P_M->NonInlinedSFcns.statesInfo2[0]);
        ssSetPeriodicStatesInfo(rts,
          &DEV2P_M->NonInlinedSFcns.periodicStatesInfo[0]);
      }

      /* path info */
      ssSetModelName(rts, "Setup ");
      ssSetPath(rts, "DEV2P/Setup ");
      ssSetRTModel(rts,DEV2P_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &DEV2P_M->NonInlinedSFcns.Sfcn0.params;
        ssSetSFcnParamsCount(rts, 9);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)DEV2P_cal->Setup_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)DEV2P_cal->Setup_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)DEV2P_cal->Setup_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)DEV2P_cal->Setup_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)DEV2P_cal->Setup_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)DEV2P_cal->Setup_P6_Size);
        ssSetSFcnParam(rts, 6, (mxArray*)DEV2P_cal->Setup_P7_Size);
        ssSetSFcnParam(rts, 7, (mxArray*)DEV2P_cal->Setup_P8_Size);
        ssSetSFcnParam(rts, 8, (mxArray*)DEV2P_cal->Setup_P9_Size);
      }

      /* work vectors */
      ssSetRWork(rts, (real_T *) &DEV2P_DW.Setup_RWORK[0]);
      ssSetPWork(rts, (void **) &DEV2P_DW.Setup_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &DEV2P_M->NonInlinedSFcns.Sfcn0.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &DEV2P_M->NonInlinedSFcns.Sfcn0.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 2);

        /* RWORK */
        ssSetDWorkWidthAsInt(rts, 0, 2);
        ssSetDWorkDataType(rts, 0,SS_DOUBLE);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &DEV2P_DW.Setup_RWORK[0]);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 1, 1);
        ssSetDWorkDataType(rts, 1,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 1, 0);
        ssSetDWork(rts, 1, &DEV2P_DW.Setup_PWORK);
      }

      /* registration */
      sg_IO191_setup_s(rts);
      sfcnInitializeSizes(rts);
      sfcnInitializeSampleTimes(rts);

      /* adjust sample time */
      ssSetSampleTime(rts, 0, 0.001);
      ssSetOffsetTime(rts, 0, 0.0);
      sfcnTsMap[0] = 1;

      /* set compiled values of dynamic vector attributes */
      ssSetNumNonsampledZCsAsInt(rts, 0);

      /* Update connectivity flags for each port */
      /* Update the BufferDstPort flags for each input port */
    }

    /* Level2 S-Function Block: DEV2P/<Root>/Digital output  (sg_IO191_do_s) */
    {
      SimStruct *rts = DEV2P_M->childSfunctions[1];

      /* timing info */
      time_T *sfcnPeriod = DEV2P_M->NonInlinedSFcns.Sfcn1.sfcnPeriod;
      time_T *sfcnOffset = DEV2P_M->NonInlinedSFcns.Sfcn1.sfcnOffset;
      int_T *sfcnTsMap = DEV2P_M->NonInlinedSFcns.Sfcn1.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &DEV2P_M->NonInlinedSFcns.blkInfo2[1]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &DEV2P_M->NonInlinedSFcns.inputOutputPortInfo2[1]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, DEV2P_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &DEV2P_M->NonInlinedSFcns.methods2[1]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &DEV2P_M->NonInlinedSFcns.methods3[1]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &DEV2P_M->NonInlinedSFcns.methods4[1]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &DEV2P_M->NonInlinedSFcns.statesInfo2[1]);
        ssSetPeriodicStatesInfo(rts,
          &DEV2P_M->NonInlinedSFcns.periodicStatesInfo[1]);
      }

      /* inputs */
      {
        _ssSetNumInputPorts(rts, 15);
        ssSetPortInfoForInputs(rts,
          &DEV2P_M->NonInlinedSFcns.Sfcn1.inputPortInfo[0]);
        ssSetPortInfoForInputs(rts,
          &DEV2P_M->NonInlinedSFcns.Sfcn1.inputPortInfo[0]);
        _ssSetPortInfo2ForInputUnits(rts,
          &DEV2P_M->NonInlinedSFcns.Sfcn1.inputPortUnits[0]);
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
          &DEV2P_M->NonInlinedSFcns.Sfcn1.inputPortCoSimAttribute[0]);
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
          ssSetInputPortSignal(rts, 0, (const_cast<real_T*>(&DEV2P_RGND)));
          _ssSetInputPortNumDimensions(rts, 0, 1);
          ssSetInputPortWidthAsInt(rts, 0, 1);
        }

        /* port 1 */
        {
          ssSetInputPortRequiredContiguous(rts, 1, 1);
          ssSetInputPortSignal(rts, 1, (const_cast<real_T*>(&DEV2P_RGND)));
          _ssSetInputPortNumDimensions(rts, 1, 1);
          ssSetInputPortWidthAsInt(rts, 1, 1);
        }

        /* port 2 */
        {
          ssSetInputPortRequiredContiguous(rts, 2, 1);
          ssSetInputPortSignal(rts, 2, &DEV2P_B.pupilCam_trig);
          _ssSetInputPortNumDimensions(rts, 2, 1);
          ssSetInputPortWidthAsInt(rts, 2, 1);
        }

        /* port 3 */
        {
          ssSetInputPortRequiredContiguous(rts, 3, 1);
          ssSetInputPortSignal(rts, 3, (const_cast<real_T*>(&DEV2P_RGND)));
          _ssSetInputPortNumDimensions(rts, 3, 1);
          ssSetInputPortWidthAsInt(rts, 3, 1);
        }

        /* port 4 */
        {
          ssSetInputPortRequiredContiguous(rts, 4, 1);
          ssSetInputPortSignal(rts, 4, (const_cast<real_T*>(&DEV2P_RGND)));
          _ssSetInputPortNumDimensions(rts, 4, 1);
          ssSetInputPortWidthAsInt(rts, 4, 1);
        }

        /* port 5 */
        {
          ssSetInputPortRequiredContiguous(rts, 5, 1);
          ssSetInputPortSignal(rts, 5, (const_cast<real_T*>(&DEV2P_RGND)));
          _ssSetInputPortNumDimensions(rts, 5, 1);
          ssSetInputPortWidthAsInt(rts, 5, 1);
        }

        /* port 6 */
        {
          ssSetInputPortRequiredContiguous(rts, 6, 1);
          ssSetInputPortSignal(rts, 6, (const_cast<real_T*>(&DEV2P_RGND)));
          _ssSetInputPortNumDimensions(rts, 6, 1);
          ssSetInputPortWidthAsInt(rts, 6, 1);
        }

        /* port 7 */
        {
          ssSetInputPortRequiredContiguous(rts, 7, 1);
          ssSetInputPortSignal(rts, 7, (const_cast<real_T*>(&DEV2P_RGND)));
          _ssSetInputPortNumDimensions(rts, 7, 1);
          ssSetInputPortWidthAsInt(rts, 7, 1);
        }

        /* port 8 */
        {
          ssSetInputPortRequiredContiguous(rts, 8, 1);
          ssSetInputPortSignal(rts, 8, &DEV2P_B.imAcq_outTst);
          _ssSetInputPortNumDimensions(rts, 8, 1);
          ssSetInputPortWidthAsInt(rts, 8, 1);
        }

        /* port 9 */
        {
          ssSetInputPortRequiredContiguous(rts, 9, 1);
          ssSetInputPortSignal(rts, 9, (const_cast<real_T*>(&DEV2P_RGND)));
          _ssSetInputPortNumDimensions(rts, 9, 1);
          ssSetInputPortWidthAsInt(rts, 9, 1);
        }

        /* port 10 */
        {
          ssSetInputPortRequiredContiguous(rts, 10, 1);
          ssSetInputPortSignal(rts, 10, (const_cast<real_T*>(&DEV2P_RGND)));
          _ssSetInputPortNumDimensions(rts, 10, 1);
          ssSetInputPortWidthAsInt(rts, 10, 1);
        }

        /* port 11 */
        {
          ssSetInputPortRequiredContiguous(rts, 11, 1);
          ssSetInputPortSignal(rts, 11, (const_cast<real_T*>(&DEV2P_RGND)));
          _ssSetInputPortNumDimensions(rts, 11, 1);
          ssSetInputPortWidthAsInt(rts, 11, 1);
        }

        /* port 12 */
        {
          ssSetInputPortRequiredContiguous(rts, 12, 1);
          ssSetInputPortSignal(rts, 12, (const_cast<real_T*>(&DEV2P_RGND)));
          _ssSetInputPortNumDimensions(rts, 12, 1);
          ssSetInputPortWidthAsInt(rts, 12, 1);
        }

        /* port 13 */
        {
          ssSetInputPortRequiredContiguous(rts, 13, 1);
          ssSetInputPortSignal(rts, 13, (const_cast<real_T*>(&DEV2P_RGND)));
          _ssSetInputPortNumDimensions(rts, 13, 1);
          ssSetInputPortWidthAsInt(rts, 13, 1);
        }

        /* port 14 */
        {
          ssSetInputPortRequiredContiguous(rts, 14, 1);
          ssSetInputPortSignal(rts, 14, &DEV2P_B.tonePulse);
          _ssSetInputPortNumDimensions(rts, 14, 1);
          ssSetInputPortWidthAsInt(rts, 14, 1);
        }
      }

      /* path info */
      ssSetModelName(rts, "Digital output ");
      ssSetPath(rts, "DEV2P/Digital output ");
      ssSetRTModel(rts,DEV2P_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &DEV2P_M->NonInlinedSFcns.Sfcn1.params;
        ssSetSFcnParamsCount(rts, 6);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)DEV2P_cal->Digitaloutput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)DEV2P_cal->Digitaloutput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)DEV2P_cal->Digitaloutput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)DEV2P_cal->Digitaloutput_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)DEV2P_cal->Digitaloutput_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)DEV2P_cal->Digitaloutput_P6_Size);
      }

      /* work vectors */
      ssSetPWork(rts, (void **) &DEV2P_DW.Digitaloutput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &DEV2P_M->NonInlinedSFcns.Sfcn1.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &DEV2P_M->NonInlinedSFcns.Sfcn1.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 1);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 0, 1);
        ssSetDWorkDataType(rts, 0,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &DEV2P_DW.Digitaloutput_PWORK);
      }

      /* registration */
      sg_IO191_do_s(rts);
      sfcnInitializeSizes(rts);
      sfcnInitializeSampleTimes(rts);

      /* adjust sample time */
      ssSetSampleTime(rts, 0, 0.001);
      ssSetOffsetTime(rts, 0, 0.0);
      sfcnTsMap[0] = 1;

      /* set compiled values of dynamic vector attributes */
      ssSetNumNonsampledZCsAsInt(rts, 0);

      /* Update connectivity flags for each port */
      _ssSetInputPortConnected(rts, 0, 0);
      _ssSetInputPortConnected(rts, 1, 0);
      _ssSetInputPortConnected(rts, 2, 1);
      _ssSetInputPortConnected(rts, 3, 0);
      _ssSetInputPortConnected(rts, 4, 0);
      _ssSetInputPortConnected(rts, 5, 0);
      _ssSetInputPortConnected(rts, 6, 0);
      _ssSetInputPortConnected(rts, 7, 0);
      _ssSetInputPortConnected(rts, 8, 1);
      _ssSetInputPortConnected(rts, 9, 0);
      _ssSetInputPortConnected(rts, 10, 0);
      _ssSetInputPortConnected(rts, 11, 0);
      _ssSetInputPortConnected(rts, 12, 0);
      _ssSetInputPortConnected(rts, 13, 0);
      _ssSetInputPortConnected(rts, 14, 1);

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

    /* Level2 S-Function Block: DEV2P/<Root>/Digital input  (sg_IO191_di_s) */
    {
      SimStruct *rts = DEV2P_M->childSfunctions[2];

      /* timing info */
      time_T *sfcnPeriod = DEV2P_M->NonInlinedSFcns.Sfcn2.sfcnPeriod;
      time_T *sfcnOffset = DEV2P_M->NonInlinedSFcns.Sfcn2.sfcnOffset;
      int_T *sfcnTsMap = DEV2P_M->NonInlinedSFcns.Sfcn2.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &DEV2P_M->NonInlinedSFcns.blkInfo2[2]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &DEV2P_M->NonInlinedSFcns.inputOutputPortInfo2[2]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, DEV2P_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &DEV2P_M->NonInlinedSFcns.methods2[2]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &DEV2P_M->NonInlinedSFcns.methods3[2]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &DEV2P_M->NonInlinedSFcns.methods4[2]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &DEV2P_M->NonInlinedSFcns.statesInfo2[2]);
        ssSetPeriodicStatesInfo(rts,
          &DEV2P_M->NonInlinedSFcns.periodicStatesInfo[2]);
      }

      /* outputs */
      {
        ssSetPortInfoForOutputs(rts,
          &DEV2P_M->NonInlinedSFcns.Sfcn2.outputPortInfo[0]);
        ssSetPortInfoForOutputs(rts,
          &DEV2P_M->NonInlinedSFcns.Sfcn2.outputPortInfo[0]);
        _ssSetNumOutputPorts(rts, 1);
        _ssSetPortInfo2ForOutputUnits(rts,
          &DEV2P_M->NonInlinedSFcns.Sfcn2.outputPortUnits[0]);
        ssSetOutputPortUnit(rts, 0, 0);
        _ssSetPortInfo2ForOutputCoSimAttribute(rts,
          &DEV2P_M->NonInlinedSFcns.Sfcn2.outputPortCoSimAttribute[0]);
        ssSetOutputPortIsContinuousQuantity(rts, 0, 0);

        /* port 0 */
        {
          _ssSetOutputPortNumDimensions(rts, 0, 1);
          ssSetOutputPortWidthAsInt(rts, 0, 1);
          ssSetOutputPortSignal(rts, 0, ((real_T *) &DEV2P_B.PulseGen1Hz));
        }
      }

      /* path info */
      ssSetModelName(rts, "Digital input ");
      ssSetPath(rts, "DEV2P/Digital input ");
      ssSetRTModel(rts,DEV2P_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &DEV2P_M->NonInlinedSFcns.Sfcn2.params;
        ssSetSFcnParamsCount(rts, 4);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)DEV2P_cal->Digitalinput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)DEV2P_cal->Digitalinput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)DEV2P_cal->Digitalinput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)DEV2P_cal->Digitalinput_P4_Size);
      }

      /* work vectors */
      ssSetPWork(rts, (void **) &DEV2P_DW.Digitalinput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &DEV2P_M->NonInlinedSFcns.Sfcn2.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &DEV2P_M->NonInlinedSFcns.Sfcn2.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 1);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 0, 1);
        ssSetDWorkDataType(rts, 0,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &DEV2P_DW.Digitalinput_PWORK);
      }

      /* registration */
      sg_IO191_di_s(rts);
      sfcnInitializeSizes(rts);
      sfcnInitializeSampleTimes(rts);

      /* adjust sample time */
      ssSetSampleTime(rts, 0, 0.001);
      ssSetOffsetTime(rts, 0, 0.0);
      sfcnTsMap[0] = 1;

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
    SimStruct *rts = DEV2P_M->childSfunctions[0];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_do_s): '<Root>/Digital output ' */
  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = DEV2P_M->childSfunctions[1];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_di_s): '<Root>/Digital input ' */
  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = DEV2P_M->childSfunctions[2];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* InitializeConditions for DiscretePulseGenerator: '<Root>/Pupil Trig' */
  DEV2P_DW.clockTickCounter = 0;

  /* InitializeConditions for DiscretePulseGenerator: '<Root>/imAcq_outTst' */
  DEV2P_DW.clockTickCounter_a = 0;

  /* InitializeConditions for Memory: '<Root>/Memory2' */
  DEV2P_DW.Memory2_PreviousInput = DEV2P_cal->Memory2_InitialCondition;

  /* InitializeConditions for Memory: '<Root>/Memory1' */
  DEV2P_DW.Memory1_PreviousInput = DEV2P_cal->Memory1_InitialCondition;

  /* InitializeConditions for Memory: '<Root>/Memory' */
  DEV2P_DW.Memory_PreviousInput = DEV2P_cal->Memory_InitialCondition;

  /* SystemInitialize for MATLAB Function: '<Root>/MATLAB Function' */
  DEV2P_DW.sfEvent_e = DEV2P_CALL_EVENT;
  DEV2P_DW.is_active_c1_DEV2P = 0U;

  /* SystemInitialize for MATLAB Function: '<S2>/MATLAB Function1' */
  DEV2P_DW.sfEvent = DEV2P_CALL_EVENT;
  DEV2P_DW.t0_not_empty = false;
  DEV2P_DW.is_active_c2_DEV2P = 0U;
}

/* Model terminate function */
void DEV2P_terminate(void)
{
  /* Terminate for S-Function (sg_IO191_setup_s): '<Root>/Setup ' */
  /* Level2 S-Function Block: '<Root>/Setup ' (sg_IO191_setup_s) */
  {
    SimStruct *rts = DEV2P_M->childSfunctions[0];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_do_s): '<Root>/Digital output ' */
  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = DEV2P_M->childSfunctions[1];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_di_s): '<Root>/Digital input ' */
  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = DEV2P_M->childSfunctions[2];
    sfcnTerminate(rts);
  }
}
