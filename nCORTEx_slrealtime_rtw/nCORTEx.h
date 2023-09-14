/*
 * nCORTEx.h
 *
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * Code generation for model "nCORTEx".
 *
 * Model version              : 1.63
 * Simulink Coder version : 9.9 (R2023a) 19-Nov-2022
 * C++ source code generated on : Wed Sep 13 23:26:09 2023
 *
 * Target selection: slrealtime.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Intel->x86-64 (Linux 64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef RTW_HEADER_nCORTEx_h_
#define RTW_HEADER_nCORTEx_h_
#include <stdio.h>
#include <string.h>
#include <logsrv.h>
#include "rtwtypes.h"
#include "simstruc.h"
#include "fixedpoint.h"
#include "verify/verifyIntrf.h"
#include "nCORTEx_types.h"
#include <stddef.h>
#include <cstring>
#include "nCORTEx_cal.h"

extern "C"
{

#include "rt_nonfinite.h"

}

/* Macros for accessing real-time model data structure */
#ifndef rtmGetContTimeOutputInconsistentWithStateAtMajorStepFlag
#define rtmGetContTimeOutputInconsistentWithStateAtMajorStepFlag(rtm) ((rtm)->CTOutputIncnstWithState)
#endif

#ifndef rtmSetContTimeOutputInconsistentWithStateAtMajorStepFlag
#define rtmSetContTimeOutputInconsistentWithStateAtMajorStepFlag(rtm, val) ((rtm)->CTOutputIncnstWithState = (val))
#endif

#ifndef rtmGetDerivCacheNeedsReset
#define rtmGetDerivCacheNeedsReset(rtm) ((rtm)->derivCacheNeedsReset)
#endif

#ifndef rtmSetDerivCacheNeedsReset
#define rtmSetDerivCacheNeedsReset(rtm, val) ((rtm)->derivCacheNeedsReset = (val))
#endif

#ifndef rtmGetFinalTime
#define rtmGetFinalTime(rtm)           ((rtm)->Timing.tFinal)
#endif

#ifndef rtmGetSampleHitArray
#define rtmGetSampleHitArray(rtm)      ((rtm)->Timing.sampleHitArray)
#endif

#ifndef rtmGetStepSize
#define rtmGetStepSize(rtm)            ((rtm)->Timing.stepSize)
#endif

#ifndef rtmGetZCCacheNeedsReset
#define rtmGetZCCacheNeedsReset(rtm)   ((rtm)->zCCacheNeedsReset)
#endif

#ifndef rtmSetZCCacheNeedsReset
#define rtmSetZCCacheNeedsReset(rtm, val) ((rtm)->zCCacheNeedsReset = (val))
#endif

#ifndef rtmGet_TimeOfLastOutput
#define rtmGet_TimeOfLastOutput(rtm)   ((rtm)->Timing.timeOfLastOutput)
#endif

#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

#ifndef rtmGetStopRequested
#define rtmGetStopRequested(rtm)       ((rtm)->Timing.stopRequestedFlag)
#endif

#ifndef rtmSetStopRequested
#define rtmSetStopRequested(rtm, val)  ((rtm)->Timing.stopRequestedFlag = (val))
#endif

#ifndef rtmGetStopRequestedPtr
#define rtmGetStopRequestedPtr(rtm)    (&((rtm)->Timing.stopRequestedFlag))
#endif

#ifndef rtmGetT
#define rtmGetT(rtm)                   (rtmGetTPtr((rtm))[0])
#endif

#ifndef rtmGetTFinal
#define rtmGetTFinal(rtm)              ((rtm)->Timing.tFinal)
#endif

#ifndef rtmGetTPtr
#define rtmGetTPtr(rtm)                ((rtm)->Timing.t)
#endif

#ifndef rtmGetTStart
#define rtmGetTStart(rtm)              ((rtm)->Timing.tStart)
#endif

#ifndef rtmGetTimeOfLastOutput
#define rtmGetTimeOfLastOutput(rtm)    ((rtm)->Timing.timeOfLastOutput)
#endif

/* Block signals (default storage) */
struct B_nCORTEx_T {
  real_T whiskCam_trig;                /* '<Root>/Whisker Trig' */
  real_T npxls_trig;                   /* '<Root>/Npxls Trig' */
  real_T pupilCam_trig;                /* '<Root>/Pupil Trig' */
  real_T Memory2;                      /* '<Root>/Memory2' */
  real_T Memory1;                      /* '<Root>/Memory1' */
  real_T Memory;                       /* '<Root>/Memory' */
  real_T Clock;                        /* '<S3>/Clock' */
  real_T TmpSignalConversionAtToFileInpo[5];
  real_T Clock_k;                      /* '<S2>/Clock' */
  real_T tonePulse;                    /* '<S3>/MATLAB Function1' */
  real_T state_out;                    /* '<Root>/MATLAB Function' */
  real_T localTime_out;                /* '<Root>/MATLAB Function' */
  real_T trialNum_out;                 /* '<Root>/MATLAB Function' */
  real_T onsetTone_trig;               /* '<Root>/MATLAB Function' */
  boolean_T RelationalOperator;        /* '<S2>/Relational Operator' */
};

/* Block states (default storage) for system '<Root>' */
struct DW_nCORTEx_T {
  real_T Memory2_PreviousInput;        /* '<Root>/Memory2' */
  real_T Memory1_PreviousInput;        /* '<Root>/Memory1' */
  real_T Memory_PreviousInput;         /* '<Root>/Memory' */
  real_T t0;                           /* '<S3>/MATLAB Function1' */
  real_T Setup_RWORK[2];               /* '<Root>/Setup ' */
  struct {
    void *FilePtr;
  } ToFile_PWORK;                      /* '<Root>/To File' */

  void *Setup_PWORK;                   /* '<Root>/Setup ' */
  void *Digitaloutput_PWORK;           /* '<Root>/Digital output ' */
  struct {
    void *LoggedData[4];
  } Scope_PWORK;                       /* '<Root>/Scope' */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_toneP;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Pupil;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Npxls;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Whisk;   /* synthesized block */

  int32_T clockTickCounter;            /* '<Root>/Whisker Trig' */
  int32_T clockTickCounter_n;          /* '<Root>/Npxls Trig' */
  int32_T clockTickCounter_c;          /* '<Root>/Pupil Trig' */
  int32_T sfEvent;                     /* '<S3>/MATLAB Function1' */
  int32_T sfEvent_e;                   /* '<Root>/MATLAB Function' */
  struct {
    int_T Count;
    int_T Decimation;
  } ToFile_IWORK;                      /* '<Root>/To File' */

  uint8_T is_active_c2_nCORTEx;        /* '<S3>/MATLAB Function1' */
  uint8_T is_active_c1_nCORTEx;        /* '<Root>/MATLAB Function' */
  boolean_T doneDoubleBufferReInit;    /* '<S3>/MATLAB Function1' */
  boolean_T t0_not_empty;              /* '<S3>/MATLAB Function1' */
  boolean_T doneDoubleBufferReInit_e;  /* '<Root>/MATLAB Function' */
};

/* Real-time Model Data Structure */
struct tag_RTM_nCORTEx_T {
  struct SimStruct_tag * *childSfunctions;
  const char_T *errorStatus;
  SS_SimMode simMode;
  RTWSolverInfo solverInfo;
  RTWSolverInfo *solverInfoPtr;
  void *sfcnInfo;

  /*
   * NonInlinedSFcns:
   * The following substructure contains information regarding
   * non-inlined s-functions used in the model.
   */
  struct {
    RTWSfcnInfo sfcnInfo;
    time_T *taskTimePtrs[2];
    SimStruct childSFunctions[2];
    SimStruct *childSFunctionPtrs[2];
    struct _ssBlkInfo2 blkInfo2[2];
    struct _ssSFcnModelMethods2 methods2[2];
    struct _ssSFcnModelMethods3 methods3[2];
    struct _ssSFcnModelMethods4 methods4[2];
    struct _ssStatesInfo2 statesInfo2[2];
    ssPeriodicStatesInfo periodicStatesInfo[2];
    struct _ssPortInfo2 inputOutputPortInfo2[2];
    struct {
      time_T sfcnPeriod[1];
      time_T sfcnOffset[1];
      int_T sfcnTsMap[1];
      uint_T attribs[9];
      mxArray *params[9];
      struct _ssDWorkRecord dWork[2];
      struct _ssDWorkAuxRecord dWorkAux[2];
    } Sfcn0;

    struct {
      time_T sfcnPeriod[1];
      time_T sfcnOffset[1];
      int_T sfcnTsMap[1];
      struct _ssPortInputs inputPortInfo[16];
      struct _ssInPortUnit inputPortUnits[16];
      struct _ssInPortCoSimAttribute inputPortCoSimAttribute[16];
      uint_T attribs[6];
      mxArray *params[6];
      struct _ssDWorkRecord dWork[1];
      struct _ssDWorkAuxRecord dWorkAux[1];
    } Sfcn1;
  } NonInlinedSFcns;

  boolean_T zCCacheNeedsReset;
  boolean_T derivCacheNeedsReset;
  boolean_T CTOutputIncnstWithState;

  /*
   * Sizes:
   * The following substructure contains sizes information
   * for many of the model attributes such as inputs, outputs,
   * dwork, sample times, etc.
   */
  struct {
    uint32_T options;
    int_T numContStates;
    int_T numU;
    int_T numY;
    int_T numSampTimes;
    int_T numBlocks;
    int_T numBlockIO;
    int_T numBlockPrms;
    int_T numDwork;
    int_T numSFcnPrms;
    int_T numSFcns;
    int_T numIports;
    int_T numOports;
    int_T numNonSampZCs;
    int_T sysDirFeedThru;
    int_T rtwGenSfcn;
  } Sizes;

  /*
   * Timing:
   * The following substructure contains information regarding
   * the timing information for the model.
   */
  struct {
    time_T stepSize;
    uint32_T clockTick0;
    uint32_T clockTickH0;
    time_T stepSize0;
    uint32_T clockTick1;
    uint32_T clockTickH1;
    time_T stepSize1;
    time_T tStart;
    time_T tFinal;
    time_T timeOfLastOutput;
    SimTimeStep simTimeStep;
    boolean_T stopRequestedFlag;
    time_T *sampleTimes;
    time_T *offsetTimes;
    int_T *sampleTimeTaskIDPtr;
    int_T *sampleHits;
    int_T *perTaskSampleHits;
    time_T *t;
    time_T sampleTimesArray[2];
    time_T offsetTimesArray[2];
    int_T sampleTimeTaskIDArray[2];
    int_T sampleHitArray[2];
    int_T perTaskSampleHitsArray[4];
    time_T tArray[2];
  } Timing;
};

/* Block signals (default storage) */
#ifdef __cplusplus

extern "C"
{

#endif

  extern struct B_nCORTEx_T nCORTEx_B;

#ifdef __cplusplus

}

#endif

/* Block states (default storage) */
extern struct DW_nCORTEx_T nCORTEx_DW;

/* External data declarations for dependent source files */
extern const real_T nCORTEx_RGND;      /* real_T ground */

#ifdef __cplusplus

extern "C"
{

#endif

  /* Model entry point functions */
  extern void nCORTEx_initialize(void);
  extern void nCORTEx_step(void);
  extern void nCORTEx_terminate(void);

#ifdef __cplusplus

}

#endif

/* Real-time Model object */
#ifdef __cplusplus

extern "C"
{

#endif

  extern RT_MODEL_nCORTEx_T *const nCORTEx_M;

#ifdef __cplusplus

}

#endif

/*-
 * The generated code includes comments that allow you to trace directly
 * back to the appropriate location in the model.  The basic format
 * is <system>/block_name, where system is the system number (uniquely
 * assigned by Simulink) and block_name is the name of the block.
 *
 * Use the MATLAB hilite_system command to trace the generated code back
 * to the model.  For example,
 *
 * hilite_system('<S3>')    - opens system 3
 * hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
 *
 * Here is the system hierarchy for this model
 *
 * '<Root>' : 'nCORTEx'
 * '<S1>'   : 'nCORTEx/MATLAB Function'
 * '<S2>'   : 'nCORTEx/Session Timer'
 * '<S3>'   : 'nCORTEx/tonePulse'
 * '<S4>'   : 'nCORTEx/tonePulse/MATLAB Function1'
 */
#endif                                 /* RTW_HEADER_nCORTEx_h_ */
