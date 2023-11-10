/*
 * nCORTEx.cpp
 *
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * Code generation for model "nCORTEx".
 *
 * Model version              : 1.119
 * Simulink Coder version : 9.9 (R2023a) 19-Nov-2022
 * C++ source code generated on : Sun Oct 22 13:35:46 2023
 *
 * Target selection: slrealtime.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Intel->x86-64 (Linux 64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "nCORTEx.h"
#include "rtwtypes.h"
#include "nCORTEx_cal.h"
#include "nCORTEx_private.h"
#include <cstring>

extern "C"
{

#include "rt_nonfinite.h"

}

/* Named constants for MATLAB Function: '<Root>/MATLAB Function' */
const int32_T nCORTEx_CALL_EVENT = -1;
const real_T nCORTEx_RGND = 0.0;       /* real_T ground */

/* Block signals (default storage) */
B_nCORTEx_T nCORTEx_B;

/* Block states (default storage) */
DW_nCORTEx_T nCORTEx_DW;

/* Real-time model */
RT_MODEL_nCORTEx_T nCORTEx_M_ = RT_MODEL_nCORTEx_T();
RT_MODEL_nCORTEx_T *const nCORTEx_M = &nCORTEx_M_;

/* Model step function */
void nCORTEx_step(void)
{
  real_T tmp;

  /* DiscretePulseGenerator: '<Root>/Whisker Trig' */
  tmp = nCORTEx_cal->T_whisk / 2.0;

  /* DiscretePulseGenerator: '<Root>/Whisker Trig' */
  nCORTEx_B.whiskCam_trig = (nCORTEx_DW.clockTickCounter < tmp) &&
    (nCORTEx_DW.clockTickCounter >= 0) ? nCORTEx_cal->WhiskerTrig_Amp : 0.0;

  /* DiscretePulseGenerator: '<Root>/Whisker Trig' */
  if (nCORTEx_DW.clockTickCounter >= nCORTEx_cal->T_whisk - 1.0) {
    nCORTEx_DW.clockTickCounter = 0;
  } else {
    nCORTEx_DW.clockTickCounter++;
  }

  /* DiscretePulseGenerator: '<Root>/Npxls Trig' */
  tmp = nCORTEx_cal->T_npxls / 2.0;

  /* DiscretePulseGenerator: '<Root>/Npxls Trig' */
  nCORTEx_B.npxls_trig = (nCORTEx_DW.clockTickCounter_n < tmp) &&
    (nCORTEx_DW.clockTickCounter_n >= 0) ? nCORTEx_cal->NpxlsTrig_Amp : 0.0;

  /* DiscretePulseGenerator: '<Root>/Npxls Trig' */
  if (nCORTEx_DW.clockTickCounter_n >= nCORTEx_cal->T_npxls - 1.0) {
    nCORTEx_DW.clockTickCounter_n = 0;
  } else {
    nCORTEx_DW.clockTickCounter_n++;
  }

  /* DiscretePulseGenerator: '<Root>/Pupil Trig' */
  tmp = nCORTEx_cal->T_pupil / 2.0;

  /* DiscretePulseGenerator: '<Root>/Pupil Trig' */
  nCORTEx_B.pupilCam_trig = (nCORTEx_DW.clockTickCounter_c < tmp) &&
    (nCORTEx_DW.clockTickCounter_c >= 0) ? nCORTEx_cal->PupilTrig_Amp : 0.0;

  /* DiscretePulseGenerator: '<Root>/Pupil Trig' */
  if (nCORTEx_DW.clockTickCounter_c >= nCORTEx_cal->T_pupil - 1.0) {
    nCORTEx_DW.clockTickCounter_c = 0;
  } else {
    nCORTEx_DW.clockTickCounter_c++;
  }

  /* Memory: '<Root>/Memory2' */
  nCORTEx_B.Memory2 = nCORTEx_DW.Memory2_PreviousInput;

  /* Memory: '<Root>/Memory1' */
  nCORTEx_B.Memory1 = nCORTEx_DW.Memory1_PreviousInput;

  /* Memory: '<Root>/Memory' */
  nCORTEx_B.Memory = nCORTEx_DW.Memory_PreviousInput;

  /* Memory: '<Root>/Memory3' */
  nCORTEx_B.Memory3 = nCORTEx_DW.Memory3_PreviousInput;

  /* Memory: '<Root>/Memory4' */
  nCORTEx_B.Memory4 = nCORTEx_DW.Memory4_PreviousInput;

  /* MATLAB Function: '<Root>/MATLAB Function' incorporates:
   *  Constant: '<Root>/Constant1'
   *  Constant: '<Root>/Constant2'
   */
  nCORTEx_DW.sfEvent_e = nCORTEx_CALL_EVENT;
  switch (static_cast<int32_T>(nCORTEx_B.Memory2)) {
   case 1:
    nCORTEx_B.npxlsAcq_out = 2.5;
    nCORTEx_B.onsetTone_trig = 1.0;
    nCORTEx_B.state_out = 2.0;
    nCORTEx_B.localTime_out = 1.0;
    nCORTEx_B.trialNum_out = 1.0;
    break;

   case 2:
    nCORTEx_B.onsetTone_trig = 0.0;
    nCORTEx_B.state_out = nCORTEx_B.Memory2;
    nCORTEx_B.localTime_out = nCORTEx_B.Memory1 + 1.0;
    nCORTEx_B.trialNum_out = nCORTEx_B.Memory + 1.0;
    nCORTEx_B.npxlsAcq_out = nCORTEx_B.Memory3;
    break;

   default:
    nCORTEx_B.onsetTone_trig = 0.0;
    nCORTEx_B.state_out = nCORTEx_B.Memory2;
    nCORTEx_B.localTime_out = nCORTEx_B.Memory1;
    nCORTEx_B.trialNum_out = nCORTEx_B.Memory;
    nCORTEx_B.npxlsAcq_out = nCORTEx_B.Memory3;
    break;
  }

  if (nCORTEx_B.Memory4 + 1.0 == nCORTEx_cal->tStop * nCORTEx_cal->SampleTime) {
    nCORTEx_B.npxlsAcq_out = 0.0;
  }

  nCORTEx_B.counter_out = nCORTEx_B.Memory4 + 1.0;

  /* End of MATLAB Function: '<Root>/MATLAB Function' */

  /* Clock: '<S2>/Clock' */
  nCORTEx_B.Clock = nCORTEx_M->Timing.t[0];

  /* MATLAB Function: '<S2>/MATLAB Function1' */
  nCORTEx_DW.sfEvent = nCORTEx_CALL_EVENT;
  if (nCORTEx_B.onsetTone_trig != 0.0) {
    nCORTEx_B.tonePulse = 1.0;
    nCORTEx_DW.t0 = nCORTEx_B.Clock;
    nCORTEx_DW.t0_not_empty = true;
  } else if (nCORTEx_DW.t0_not_empty) {
    nCORTEx_B.tonePulse = (nCORTEx_B.Clock - nCORTEx_DW.t0 < 1.5);
  } else {
    nCORTEx_B.tonePulse = 0.0;
  }

  /* End of MATLAB Function: '<S2>/MATLAB Function1' */

  /* S-Function (sg_IO191_setup_s): '<Root>/Setup ' */

  /* Level2 S-Function Block: '<Root>/Setup ' (sg_IO191_setup_s) */
  {
    SimStruct *rts = nCORTEx_M->childSfunctions[0];
    sfcnOutputs(rts,0);
  }

  /* S-Function (sg_IO191_do_s): '<Root>/Digital output ' */

  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = nCORTEx_M->childSfunctions[1];
    sfcnOutputs(rts,0);
  }

  /* S-Function (sg_IO191_di_s): '<Root>/Digital input ' */

  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = nCORTEx_M->childSfunctions[2];
    sfcnOutputs(rts,0);
  }

  /* RateTransition generated from: '<Root>/Digital input ' */
  nCORTEx_B.HiddenRateTransitionForToWks_In = nCORTEx_B.PulseGen1Hz;

  /* RelationalOperator: '<Root>/Relational Operator' incorporates:
   *  Constant: '<Root>/Constant'
   */
  nCORTEx_B.RelationalOperator = (nCORTEx_B.counter_out >=
    nCORTEx_cal->maxFrames);

  /* Stop: '<Root>/Stop Simulation' */
  if (nCORTEx_B.RelationalOperator) {
    rtmSetStopRequested(nCORTEx_M, 1);
  }

  /* End of Stop: '<Root>/Stop Simulation' */

  /* Update for Memory: '<Root>/Memory2' */
  nCORTEx_DW.Memory2_PreviousInput = nCORTEx_B.state_out;

  /* Update for Memory: '<Root>/Memory1' */
  nCORTEx_DW.Memory1_PreviousInput = nCORTEx_B.localTime_out;

  /* Update for Memory: '<Root>/Memory' */
  nCORTEx_DW.Memory_PreviousInput = nCORTEx_B.trialNum_out;

  /* Update for Memory: '<Root>/Memory3' */
  nCORTEx_DW.Memory3_PreviousInput = nCORTEx_B.npxlsAcq_out;

  /* Update for Memory: '<Root>/Memory4' */
  nCORTEx_DW.Memory4_PreviousInput = nCORTEx_B.counter_out;

  /* Update absolute time for base rate */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   * Timer of this task consists of two 32 bit unsigned integers.
   * The two integers represent the low bits Timing.clockTick0 and the high bits
   * Timing.clockTickH0. When the low bit overflows to 0, the high bits increment.
   */
  if (!(++nCORTEx_M->Timing.clockTick0)) {
    ++nCORTEx_M->Timing.clockTickH0;
  }

  nCORTEx_M->Timing.t[0] = nCORTEx_M->Timing.clockTick0 *
    nCORTEx_M->Timing.stepSize0 + nCORTEx_M->Timing.clockTickH0 *
    nCORTEx_M->Timing.stepSize0 * 4294967296.0;

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
    if (!(++nCORTEx_M->Timing.clockTick1)) {
      ++nCORTEx_M->Timing.clockTickH1;
    }

    nCORTEx_M->Timing.t[1] = nCORTEx_M->Timing.clockTick1 *
      nCORTEx_M->Timing.stepSize1 + nCORTEx_M->Timing.clockTickH1 *
      nCORTEx_M->Timing.stepSize1 * 4294967296.0;
  }
}

/* Model initialize function */
void nCORTEx_initialize(void)
{
  /* Registration code */

  /* initialize non-finites */
  rt_InitInfAndNaN(sizeof(real_T));

  {
    /* Setup solver object */
    rtsiSetSimTimeStepPtr(&nCORTEx_M->solverInfo, &nCORTEx_M->Timing.simTimeStep);
    rtsiSetTPtr(&nCORTEx_M->solverInfo, &rtmGetTPtr(nCORTEx_M));
    rtsiSetStepSizePtr(&nCORTEx_M->solverInfo, &nCORTEx_M->Timing.stepSize0);
    rtsiSetErrorStatusPtr(&nCORTEx_M->solverInfo, (&rtmGetErrorStatus(nCORTEx_M)));
    rtsiSetRTModelPtr(&nCORTEx_M->solverInfo, nCORTEx_M);
  }

  rtsiSetSimTimeStep(&nCORTEx_M->solverInfo, MAJOR_TIME_STEP);
  rtsiSetSolverName(&nCORTEx_M->solverInfo,"FixedStepDiscrete");
  nCORTEx_M->solverInfoPtr = (&nCORTEx_M->solverInfo);

  /* Initialize timing info */
  {
    int_T *mdlTsMap = nCORTEx_M->Timing.sampleTimeTaskIDArray;
    mdlTsMap[0] = 0;
    mdlTsMap[1] = 1;

    /* polyspace +2 MISRA2012:D4.1 [Justified:Low] "nCORTEx_M points to
       static memory which is guaranteed to be non-NULL" */
    nCORTEx_M->Timing.sampleTimeTaskIDPtr = (&mdlTsMap[0]);
    nCORTEx_M->Timing.sampleTimes = (&nCORTEx_M->Timing.sampleTimesArray[0]);
    nCORTEx_M->Timing.offsetTimes = (&nCORTEx_M->Timing.offsetTimesArray[0]);

    /* task periods */
    nCORTEx_M->Timing.sampleTimes[0] = (0.0);
    nCORTEx_M->Timing.sampleTimes[1] = (0.001);

    /* task offsets */
    nCORTEx_M->Timing.offsetTimes[0] = (0.0);
    nCORTEx_M->Timing.offsetTimes[1] = (0.0);
  }

  rtmSetTPtr(nCORTEx_M, &nCORTEx_M->Timing.tArray[0]);

  {
    int_T *mdlSampleHits = nCORTEx_M->Timing.sampleHitArray;
    mdlSampleHits[0] = 1;
    mdlSampleHits[1] = 1;
    nCORTEx_M->Timing.sampleHits = (&mdlSampleHits[0]);
  }

  rtmSetTFinal(nCORTEx_M, -1);
  nCORTEx_M->Timing.stepSize0 = 0.001;
  nCORTEx_M->Timing.stepSize1 = 0.001;
  nCORTEx_M->solverInfoPtr = (&nCORTEx_M->solverInfo);
  nCORTEx_M->Timing.stepSize = (0.001);
  rtsiSetFixedStepSize(&nCORTEx_M->solverInfo, 0.001);
  rtsiSetSolverMode(&nCORTEx_M->solverInfo, SOLVER_MODE_SINGLETASKING);

  /* block I/O */
  (void) std::memset((static_cast<void *>(&nCORTEx_B)), 0,
                     sizeof(B_nCORTEx_T));

  /* states (dwork) */
  (void) std::memset(static_cast<void *>(&nCORTEx_DW), 0,
                     sizeof(DW_nCORTEx_T));

  /* child S-Function registration */
  {
    RTWSfcnInfo *sfcnInfo = &nCORTEx_M->NonInlinedSFcns.sfcnInfo;
    nCORTEx_M->sfcnInfo = (sfcnInfo);
    rtssSetErrorStatusPtr(sfcnInfo, (&rtmGetErrorStatus(nCORTEx_M)));
    nCORTEx_M->Sizes.numSampTimes = (2);
    rtssSetNumRootSampTimesPtr(sfcnInfo, &nCORTEx_M->Sizes.numSampTimes);
    nCORTEx_M->NonInlinedSFcns.taskTimePtrs[0] = (&rtmGetTPtr(nCORTEx_M)[0]);
    nCORTEx_M->NonInlinedSFcns.taskTimePtrs[1] = (&rtmGetTPtr(nCORTEx_M)[1]);
    rtssSetTPtrPtr(sfcnInfo,nCORTEx_M->NonInlinedSFcns.taskTimePtrs);
    rtssSetTStartPtr(sfcnInfo, &rtmGetTStart(nCORTEx_M));
    rtssSetTFinalPtr(sfcnInfo, &rtmGetTFinal(nCORTEx_M));
    rtssSetTimeOfLastOutputPtr(sfcnInfo, &rtmGetTimeOfLastOutput(nCORTEx_M));
    rtssSetStepSizePtr(sfcnInfo, &nCORTEx_M->Timing.stepSize);
    rtssSetStopRequestedPtr(sfcnInfo, &rtmGetStopRequested(nCORTEx_M));
    rtssSetDerivCacheNeedsResetPtr(sfcnInfo, &nCORTEx_M->derivCacheNeedsReset);
    rtssSetZCCacheNeedsResetPtr(sfcnInfo, &nCORTEx_M->zCCacheNeedsReset);
    rtssSetContTimeOutputInconsistentWithStateAtMajorStepPtr(sfcnInfo,
      &nCORTEx_M->CTOutputIncnstWithState);
    rtssSetSampleHitsPtr(sfcnInfo, &nCORTEx_M->Timing.sampleHits);
    rtssSetPerTaskSampleHitsPtr(sfcnInfo, &nCORTEx_M->Timing.perTaskSampleHits);
    rtssSetSimModePtr(sfcnInfo, &nCORTEx_M->simMode);
    rtssSetSolverInfoPtr(sfcnInfo, &nCORTEx_M->solverInfoPtr);
  }

  nCORTEx_M->Sizes.numSFcns = (3);

  /* register each child */
  {
    (void) std::memset(static_cast<void *>
                       (&nCORTEx_M->NonInlinedSFcns.childSFunctions[0]), 0,
                       3*sizeof(SimStruct));
    nCORTEx_M->childSfunctions = (&nCORTEx_M->
      NonInlinedSFcns.childSFunctionPtrs[0]);
    nCORTEx_M->childSfunctions[0] = (&nCORTEx_M->
      NonInlinedSFcns.childSFunctions[0]);
    nCORTEx_M->childSfunctions[1] = (&nCORTEx_M->
      NonInlinedSFcns.childSFunctions[1]);
    nCORTEx_M->childSfunctions[2] = (&nCORTEx_M->
      NonInlinedSFcns.childSFunctions[2]);

    /* Level2 S-Function Block: nCORTEx/<Root>/Setup  (sg_IO191_setup_s) */
    {
      SimStruct *rts = nCORTEx_M->childSfunctions[0];

      /* timing info */
      time_T *sfcnPeriod = nCORTEx_M->NonInlinedSFcns.Sfcn0.sfcnPeriod;
      time_T *sfcnOffset = nCORTEx_M->NonInlinedSFcns.Sfcn0.sfcnOffset;
      int_T *sfcnTsMap = nCORTEx_M->NonInlinedSFcns.Sfcn0.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &nCORTEx_M->NonInlinedSFcns.blkInfo2[0]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &nCORTEx_M->NonInlinedSFcns.inputOutputPortInfo2[0]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, nCORTEx_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &nCORTEx_M->NonInlinedSFcns.methods2[0]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &nCORTEx_M->NonInlinedSFcns.methods3[0]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &nCORTEx_M->NonInlinedSFcns.methods4[0]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &nCORTEx_M->NonInlinedSFcns.statesInfo2[0]);
        ssSetPeriodicStatesInfo(rts,
          &nCORTEx_M->NonInlinedSFcns.periodicStatesInfo[0]);
      }

      /* path info */
      ssSetModelName(rts, "Setup ");
      ssSetPath(rts, "nCORTEx/Setup ");
      ssSetRTModel(rts,nCORTEx_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &nCORTEx_M->NonInlinedSFcns.Sfcn0.params;
        ssSetSFcnParamsCount(rts, 9);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)nCORTEx_cal->Setup_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)nCORTEx_cal->Setup_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)nCORTEx_cal->Setup_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)nCORTEx_cal->Setup_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)nCORTEx_cal->Setup_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)nCORTEx_cal->Setup_P6_Size);
        ssSetSFcnParam(rts, 6, (mxArray*)nCORTEx_cal->Setup_P7_Size);
        ssSetSFcnParam(rts, 7, (mxArray*)nCORTEx_cal->Setup_P8_Size);
        ssSetSFcnParam(rts, 8, (mxArray*)nCORTEx_cal->Setup_P9_Size);
      }

      /* work vectors */
      ssSetRWork(rts, (real_T *) &nCORTEx_DW.Setup_RWORK[0]);
      ssSetPWork(rts, (void **) &nCORTEx_DW.Setup_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &nCORTEx_M->NonInlinedSFcns.Sfcn0.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &nCORTEx_M->NonInlinedSFcns.Sfcn0.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 2);

        /* RWORK */
        ssSetDWorkWidthAsInt(rts, 0, 2);
        ssSetDWorkDataType(rts, 0,SS_DOUBLE);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &nCORTEx_DW.Setup_RWORK[0]);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 1, 1);
        ssSetDWorkDataType(rts, 1,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 1, 0);
        ssSetDWork(rts, 1, &nCORTEx_DW.Setup_PWORK);
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

    /* Level2 S-Function Block: nCORTEx/<Root>/Digital output  (sg_IO191_do_s) */
    {
      SimStruct *rts = nCORTEx_M->childSfunctions[1];

      /* timing info */
      time_T *sfcnPeriod = nCORTEx_M->NonInlinedSFcns.Sfcn1.sfcnPeriod;
      time_T *sfcnOffset = nCORTEx_M->NonInlinedSFcns.Sfcn1.sfcnOffset;
      int_T *sfcnTsMap = nCORTEx_M->NonInlinedSFcns.Sfcn1.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &nCORTEx_M->NonInlinedSFcns.blkInfo2[1]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &nCORTEx_M->NonInlinedSFcns.inputOutputPortInfo2[1]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, nCORTEx_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &nCORTEx_M->NonInlinedSFcns.methods2[1]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &nCORTEx_M->NonInlinedSFcns.methods3[1]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &nCORTEx_M->NonInlinedSFcns.methods4[1]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &nCORTEx_M->NonInlinedSFcns.statesInfo2[1]);
        ssSetPeriodicStatesInfo(rts,
          &nCORTEx_M->NonInlinedSFcns.periodicStatesInfo[1]);
      }

      /* inputs */
      {
        _ssSetNumInputPorts(rts, 15);
        ssSetPortInfoForInputs(rts,
          &nCORTEx_M->NonInlinedSFcns.Sfcn1.inputPortInfo[0]);
        ssSetPortInfoForInputs(rts,
          &nCORTEx_M->NonInlinedSFcns.Sfcn1.inputPortInfo[0]);
        _ssSetPortInfo2ForInputUnits(rts,
          &nCORTEx_M->NonInlinedSFcns.Sfcn1.inputPortUnits[0]);
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
          &nCORTEx_M->NonInlinedSFcns.Sfcn1.inputPortCoSimAttribute[0]);
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
          ssSetInputPortSignal(rts, 0, &nCORTEx_B.whiskCam_trig);
          _ssSetInputPortNumDimensions(rts, 0, 1);
          ssSetInputPortWidthAsInt(rts, 0, 1);
        }

        /* port 1 */
        {
          ssSetInputPortRequiredContiguous(rts, 1, 1);
          ssSetInputPortSignal(rts, 1, &nCORTEx_B.npxls_trig);
          _ssSetInputPortNumDimensions(rts, 1, 1);
          ssSetInputPortWidthAsInt(rts, 1, 1);
        }

        /* port 2 */
        {
          ssSetInputPortRequiredContiguous(rts, 2, 1);
          ssSetInputPortSignal(rts, 2, &nCORTEx_B.pupilCam_trig);
          _ssSetInputPortNumDimensions(rts, 2, 1);
          ssSetInputPortWidthAsInt(rts, 2, 1);
        }

        /* port 3 */
        {
          ssSetInputPortRequiredContiguous(rts, 3, 1);
          ssSetInputPortSignal(rts, 3, &nCORTEx_B.npxlsAcq_out);
          _ssSetInputPortNumDimensions(rts, 3, 1);
          ssSetInputPortWidthAsInt(rts, 3, 1);
        }

        /* port 4 */
        {
          ssSetInputPortRequiredContiguous(rts, 4, 1);
          ssSetInputPortSignal(rts, 4, (const_cast<real_T*>(&nCORTEx_RGND)));
          _ssSetInputPortNumDimensions(rts, 4, 1);
          ssSetInputPortWidthAsInt(rts, 4, 1);
        }

        /* port 5 */
        {
          ssSetInputPortRequiredContiguous(rts, 5, 1);
          ssSetInputPortSignal(rts, 5, (const_cast<real_T*>(&nCORTEx_RGND)));
          _ssSetInputPortNumDimensions(rts, 5, 1);
          ssSetInputPortWidthAsInt(rts, 5, 1);
        }

        /* port 6 */
        {
          ssSetInputPortRequiredContiguous(rts, 6, 1);
          ssSetInputPortSignal(rts, 6, (const_cast<real_T*>(&nCORTEx_RGND)));
          _ssSetInputPortNumDimensions(rts, 6, 1);
          ssSetInputPortWidthAsInt(rts, 6, 1);
        }

        /* port 7 */
        {
          ssSetInputPortRequiredContiguous(rts, 7, 1);
          ssSetInputPortSignal(rts, 7, (const_cast<real_T*>(&nCORTEx_RGND)));
          _ssSetInputPortNumDimensions(rts, 7, 1);
          ssSetInputPortWidthAsInt(rts, 7, 1);
        }

        /* port 8 */
        {
          ssSetInputPortRequiredContiguous(rts, 8, 1);
          ssSetInputPortSignal(rts, 8, (const_cast<real_T*>(&nCORTEx_RGND)));
          _ssSetInputPortNumDimensions(rts, 8, 1);
          ssSetInputPortWidthAsInt(rts, 8, 1);
        }

        /* port 9 */
        {
          ssSetInputPortRequiredContiguous(rts, 9, 1);
          ssSetInputPortSignal(rts, 9, (const_cast<real_T*>(&nCORTEx_RGND)));
          _ssSetInputPortNumDimensions(rts, 9, 1);
          ssSetInputPortWidthAsInt(rts, 9, 1);
        }

        /* port 10 */
        {
          ssSetInputPortRequiredContiguous(rts, 10, 1);
          ssSetInputPortSignal(rts, 10, (const_cast<real_T*>(&nCORTEx_RGND)));
          _ssSetInputPortNumDimensions(rts, 10, 1);
          ssSetInputPortWidthAsInt(rts, 10, 1);
        }

        /* port 11 */
        {
          ssSetInputPortRequiredContiguous(rts, 11, 1);
          ssSetInputPortSignal(rts, 11, (const_cast<real_T*>(&nCORTEx_RGND)));
          _ssSetInputPortNumDimensions(rts, 11, 1);
          ssSetInputPortWidthAsInt(rts, 11, 1);
        }

        /* port 12 */
        {
          ssSetInputPortRequiredContiguous(rts, 12, 1);
          ssSetInputPortSignal(rts, 12, (const_cast<real_T*>(&nCORTEx_RGND)));
          _ssSetInputPortNumDimensions(rts, 12, 1);
          ssSetInputPortWidthAsInt(rts, 12, 1);
        }

        /* port 13 */
        {
          ssSetInputPortRequiredContiguous(rts, 13, 1);
          ssSetInputPortSignal(rts, 13, (const_cast<real_T*>(&nCORTEx_RGND)));
          _ssSetInputPortNumDimensions(rts, 13, 1);
          ssSetInputPortWidthAsInt(rts, 13, 1);
        }

        /* port 14 */
        {
          ssSetInputPortRequiredContiguous(rts, 14, 1);
          ssSetInputPortSignal(rts, 14, &nCORTEx_B.tonePulse);
          _ssSetInputPortNumDimensions(rts, 14, 1);
          ssSetInputPortWidthAsInt(rts, 14, 1);
        }
      }

      /* path info */
      ssSetModelName(rts, "Digital output ");
      ssSetPath(rts, "nCORTEx/Digital output ");
      ssSetRTModel(rts,nCORTEx_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &nCORTEx_M->NonInlinedSFcns.Sfcn1.params;
        ssSetSFcnParamsCount(rts, 6);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)nCORTEx_cal->Digitaloutput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)nCORTEx_cal->Digitaloutput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)nCORTEx_cal->Digitaloutput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)nCORTEx_cal->Digitaloutput_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)nCORTEx_cal->Digitaloutput_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)nCORTEx_cal->Digitaloutput_P6_Size);
      }

      /* work vectors */
      ssSetPWork(rts, (void **) &nCORTEx_DW.Digitaloutput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &nCORTEx_M->NonInlinedSFcns.Sfcn1.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &nCORTEx_M->NonInlinedSFcns.Sfcn1.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 1);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 0, 1);
        ssSetDWorkDataType(rts, 0,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &nCORTEx_DW.Digitaloutput_PWORK);
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
      _ssSetInputPortConnected(rts, 0, 1);
      _ssSetInputPortConnected(rts, 1, 1);
      _ssSetInputPortConnected(rts, 2, 1);
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

    /* Level2 S-Function Block: nCORTEx/<Root>/Digital input  (sg_IO191_di_s) */
    {
      SimStruct *rts = nCORTEx_M->childSfunctions[2];

      /* timing info */
      time_T *sfcnPeriod = nCORTEx_M->NonInlinedSFcns.Sfcn2.sfcnPeriod;
      time_T *sfcnOffset = nCORTEx_M->NonInlinedSFcns.Sfcn2.sfcnOffset;
      int_T *sfcnTsMap = nCORTEx_M->NonInlinedSFcns.Sfcn2.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &nCORTEx_M->NonInlinedSFcns.blkInfo2[2]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &nCORTEx_M->NonInlinedSFcns.inputOutputPortInfo2[2]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, nCORTEx_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &nCORTEx_M->NonInlinedSFcns.methods2[2]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &nCORTEx_M->NonInlinedSFcns.methods3[2]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &nCORTEx_M->NonInlinedSFcns.methods4[2]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &nCORTEx_M->NonInlinedSFcns.statesInfo2[2]);
        ssSetPeriodicStatesInfo(rts,
          &nCORTEx_M->NonInlinedSFcns.periodicStatesInfo[2]);
      }

      /* outputs */
      {
        ssSetPortInfoForOutputs(rts,
          &nCORTEx_M->NonInlinedSFcns.Sfcn2.outputPortInfo[0]);
        ssSetPortInfoForOutputs(rts,
          &nCORTEx_M->NonInlinedSFcns.Sfcn2.outputPortInfo[0]);
        _ssSetNumOutputPorts(rts, 1);
        _ssSetPortInfo2ForOutputUnits(rts,
          &nCORTEx_M->NonInlinedSFcns.Sfcn2.outputPortUnits[0]);
        ssSetOutputPortUnit(rts, 0, 0);
        _ssSetPortInfo2ForOutputCoSimAttribute(rts,
          &nCORTEx_M->NonInlinedSFcns.Sfcn2.outputPortCoSimAttribute[0]);
        ssSetOutputPortIsContinuousQuantity(rts, 0, 0);

        /* port 0 */
        {
          _ssSetOutputPortNumDimensions(rts, 0, 1);
          ssSetOutputPortWidthAsInt(rts, 0, 1);
          ssSetOutputPortSignal(rts, 0, ((real_T *) &nCORTEx_B.PulseGen1Hz));
        }
      }

      /* path info */
      ssSetModelName(rts, "Digital input ");
      ssSetPath(rts, "nCORTEx/Digital input ");
      ssSetRTModel(rts,nCORTEx_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &nCORTEx_M->NonInlinedSFcns.Sfcn2.params;
        ssSetSFcnParamsCount(rts, 4);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)nCORTEx_cal->Digitalinput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)nCORTEx_cal->Digitalinput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)nCORTEx_cal->Digitalinput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)nCORTEx_cal->Digitalinput_P4_Size);
      }

      /* work vectors */
      ssSetPWork(rts, (void **) &nCORTEx_DW.Digitalinput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &nCORTEx_M->NonInlinedSFcns.Sfcn2.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &nCORTEx_M->NonInlinedSFcns.Sfcn2.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 1);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 0, 1);
        ssSetDWorkDataType(rts, 0,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &nCORTEx_DW.Digitalinput_PWORK);
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
    SimStruct *rts = nCORTEx_M->childSfunctions[0];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_do_s): '<Root>/Digital output ' */
  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = nCORTEx_M->childSfunctions[1];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_di_s): '<Root>/Digital input ' */
  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = nCORTEx_M->childSfunctions[2];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* InitializeConditions for DiscretePulseGenerator: '<Root>/Whisker Trig' */
  nCORTEx_DW.clockTickCounter = 0;

  /* InitializeConditions for DiscretePulseGenerator: '<Root>/Npxls Trig' */
  nCORTEx_DW.clockTickCounter_n = 0;

  /* InitializeConditions for DiscretePulseGenerator: '<Root>/Pupil Trig' */
  nCORTEx_DW.clockTickCounter_c = 0;

  /* InitializeConditions for Memory: '<Root>/Memory2' */
  nCORTEx_DW.Memory2_PreviousInput = nCORTEx_cal->Memory2_InitialCondition;

  /* InitializeConditions for Memory: '<Root>/Memory1' */
  nCORTEx_DW.Memory1_PreviousInput = nCORTEx_cal->Memory1_InitialCondition;

  /* InitializeConditions for Memory: '<Root>/Memory' */
  nCORTEx_DW.Memory_PreviousInput = nCORTEx_cal->Memory_InitialCondition;

  /* InitializeConditions for Memory: '<Root>/Memory3' */
  nCORTEx_DW.Memory3_PreviousInput = nCORTEx_cal->Memory3_InitialCondition;

  /* InitializeConditions for Memory: '<Root>/Memory4' */
  nCORTEx_DW.Memory4_PreviousInput = nCORTEx_cal->Memory4_InitialCondition;

  /* SystemInitialize for MATLAB Function: '<Root>/MATLAB Function' */
  nCORTEx_DW.sfEvent_e = nCORTEx_CALL_EVENT;
  nCORTEx_DW.is_active_c1_nCORTEx = 0U;

  /* SystemInitialize for MATLAB Function: '<S2>/MATLAB Function1' */
  nCORTEx_DW.sfEvent = nCORTEx_CALL_EVENT;
  nCORTEx_DW.t0_not_empty = false;
  nCORTEx_DW.is_active_c2_nCORTEx = 0U;
}

/* Model terminate function */
void nCORTEx_terminate(void)
{
  /* Terminate for S-Function (sg_IO191_setup_s): '<Root>/Setup ' */
  /* Level2 S-Function Block: '<Root>/Setup ' (sg_IO191_setup_s) */
  {
    SimStruct *rts = nCORTEx_M->childSfunctions[0];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_do_s): '<Root>/Digital output ' */
  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = nCORTEx_M->childSfunctions[1];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_di_s): '<Root>/Digital input ' */
  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = nCORTEx_M->childSfunctions[2];
    sfcnTerminate(rts);
  }
}
