/*
 * ATTN.h
 *
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * Code generation for model "ATTN".
 *
 * Model version              : 1.583
 * Simulink Coder version : 9.9 (R2023a) 19-Nov-2022
 * C++ source code generated on : Thu Jan 25 15:00:41 2024
 *
 * Target selection: slrealtime.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Intel->x86-64 (Linux 64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef RTW_HEADER_ATTN_h_
#define RTW_HEADER_ATTN_h_
#include <ctime>
#include <logsrv.h>
#include "rtwtypes.h"
#include "simstruc.h"
#include "fixedpoint.h"
#include "verify/verifyIntrf.h"
#include "ATTN_types.h"

extern "C"
{

#include "rt_nonfinite.h"

}

#include <stddef.h>

extern "C"
{

#include "rtGetNaN.h"

}

#include <cstring>
#include "ATTN_cal.h"

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

/* Block signals for system '<S3>/MATLAB Function2' */
struct B_MATLABFunction2_ATTN_T {
  real_T y;                            /* '<S3>/MATLAB Function2' */
};

/* Block states (default storage) for system '<S3>/MATLAB Function2' */
struct DW_MATLABFunction2_ATTN_T {
  real_T t0;                           /* '<S3>/MATLAB Function2' */
  real_T y0;                           /* '<S3>/MATLAB Function2' */
  int32_T sfEvent;                     /* '<S3>/MATLAB Function2' */
  uint8_T is_active_c3_ATTN;           /* '<S3>/MATLAB Function2' */
  boolean_T doneDoubleBufferReInit;    /* '<S3>/MATLAB Function2' */
  boolean_T t0_not_empty;              /* '<S3>/MATLAB Function2' */
  boolean_T y0_not_empty;              /* '<S3>/MATLAB Function2' */
};

/* Block signals (default storage) */
struct B_ATTN_T {
  real_T Memory8;                      /* '<Root>/Memory8' */
  real_T Memory2;                      /* '<Root>/Memory2' */
  real_T Memory1;                      /* '<Root>/Memory1' */
  real_T Memory;                       /* '<Root>/Memory' */
  real_T Analoginput_o1;               /* '<Root>/Analog input ' */
  real_T lickometer_piezo;             /* '<Root>/Analog input ' */
  real_T Memory11;                     /* '<Root>/Memory11' */
  real_T Memory7;                      /* '<Root>/Memory7' */
  real_T clock_time;                   /* '<Root>/Clock' */
  real_T Memory3;                      /* '<Root>/Memory3' */
  real_T Memory4;                      /* '<Root>/Memory4' */
  real_T Memory9;                      /* '<Root>/Memory9' */
  real_T Memory5;                      /* '<Root>/Memory5' */
  real_T Memory6;                      /* '<Root>/Memory6' */
  real_T Memory10;                     /* '<Root>/Memory10' */
  real_T Clock1;                       /* '<S4>/Clock1' */
  real_T Clock2;                       /* '<S3>/Clock2' */
  real_T whiskCam_trig;                /* '<Root>/Whisker Trig' */
  real_T npxls_trig;                   /* '<Root>/Npxls Trig' */
  real_T pupilCam_trig;                /* '<Root>/Pupil Trig' */
  real_T Clock1_b;                     /* '<S5>/Clock1' */
  real_T Clock1_l;                     /* '<S6>/Clock1' */
  real_T PulseGen1Hz;                  /* '<Root>/Digital input ' */
  real_T HiddenRateTransitionForToWks_In;
  /* '<Root>/HiddenRateTransitionForToWks_InsertedFor_TAQSigLogging_InsertedFor_Digital input _at_outport_0_at_inport_0' */
  real_T tonePulse;                    /* '<S6>/MATLAB Function1' */
  real_T y;                            /* '<S5>/MATLAB Function1' */
  real_T Lick;                         /* '<Root>/MATLAB Function1' */
  real_T y1;                           /* '<Root>/MATLAB Function1' */
  real_T y2;                           /* '<Root>/MATLAB Function1' */
  real_T ADOut;                        /* '<Root>/MATLAB Function1' */
  real_T state_out;                    /* '<Root>/MATLAB Function' */
  real_T localTime_out;                /* '<Root>/MATLAB Function' */
  real_T trialNum_out;                 /* '<Root>/MATLAB Function' */
  real_T npxlsAcq_out;                 /* '<Root>/MATLAB Function' */
  real_T counter_out;                  /* '<Root>/MATLAB Function' */
  real_T numLicks_out;                 /* '<Root>/MATLAB Function' */
  real_T reward_trigger_out;           /* '<Root>/MATLAB Function' */
  real_T right_trigger_out;            /* '<Root>/MATLAB Function' */
  real_T left_trigger_out;             /* '<Root>/MATLAB Function' */
  real_T delay_out;                    /* '<Root>/MATLAB Function' */
  real_T was_target_out;               /* '<Root>/MATLAB Function' */
  real_T reward_duration_out;          /* '<Root>/MATLAB Function' */
  real_T stim_duration_out;            /* '<Root>/MATLAB Function' */
  real_T onsetTone_trig;               /* '<Root>/MATLAB Function' */
  boolean_T RelationalOperator;        /* '<Root>/Relational Operator' */
  B_MATLABFunction2_ATTN_T sf_MATLABFunction1_d;/* '<S4>/MATLAB Function1' */
  B_MATLABFunction2_ATTN_T sf_MATLABFunction2;/* '<S3>/MATLAB Function2' */
};

/* Block states (default storage) for system '<Root>' */
struct DW_ATTN_T {
  real_T Memory8_PreviousInput;        /* '<Root>/Memory8' */
  real_T Memory2_PreviousInput;        /* '<Root>/Memory2' */
  real_T Memory1_PreviousInput;        /* '<Root>/Memory1' */
  real_T Memory_PreviousInput;         /* '<Root>/Memory' */
  real_T Memory11_PreviousInput;       /* '<Root>/Memory11' */
  real_T Memory7_PreviousInput;        /* '<Root>/Memory7' */
  real_T Memory3_PreviousInput;        /* '<Root>/Memory3' */
  real_T Memory4_PreviousInput;        /* '<Root>/Memory4' */
  real_T Memory9_PreviousInput;        /* '<Root>/Memory9' */
  real_T Memory5_PreviousInput;        /* '<Root>/Memory5' */
  real_T Memory6_PreviousInput;        /* '<Root>/Memory6' */
  real_T Memory10_PreviousInput;       /* '<Root>/Memory10' */
  real_T t0;                           /* '<S6>/MATLAB Function1' */
  real_T t0_p;                         /* '<S5>/MATLAB Function1' */
  real_T Setup_RWORK[2];               /* '<Root>/Setup ' */
  void *Setup_PWORK;                   /* '<Root>/Setup ' */
  void *Analoginput_PWORK;             /* '<Root>/Analog input ' */
  void *Analogoutput_PWORK;            /* '<Root>/Analog output ' */
  void *Digitaloutput_PWORK;           /* '<Root>/Digital output ' */
  void *Digitalinput_PWORK;            /* '<Root>/Digital input ' */
  struct {
    void *LoggedData[5];
  } Scope_PWORK;                       /* '<Root>/Scope' */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Digit;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Rewar;   /* synthesized block */

  struct {
    void *LoggedData;
  } reward_scope_PWORK;                /* '<Root>/reward_scope' */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Pupil;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Npxls;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Whisk;   /* synthesized block */

  struct {
    void *LoggedData;
  } left_scope_PWORK;                  /* '<Root>/left_scope' */

  struct {
    void *LoggedData;
  } right_scope_PWORK;                 /* '<Root>/right_scope' */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MATLA;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_n;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_k;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_h;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_f;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_p;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_o;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_c;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_m;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MA_cm;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_g;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_b;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Clock;   /* synthesized block */

  struct {
    void *LoggedData;
  } Scope2_PWORK;                      /* '<Root>/Scope2' */

  struct {
    void *LoggedData;
  } Scope4_PWORK;                      /* '<Root>/Scope4' */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_a;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MA_bd;   /* synthesized block */

  struct {
    void *LoggedData;
  } Scope3_PWORK;                      /* '<Root>/Scope3' */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Analo;   /* synthesized block */

  int32_T clockTickCounter;            /* '<Root>/Whisker Trig' */
  int32_T clockTickCounter_n;          /* '<Root>/Npxls Trig' */
  int32_T clockTickCounter_c;          /* '<Root>/Pupil Trig' */
  int32_T sfEvent;                     /* '<S6>/MATLAB Function1' */
  int32_T sfEvent_a;                   /* '<S5>/MATLAB Function1' */
  int32_T sfEvent_b;                   /* '<Root>/MATLAB Function1' */
  int32_T sfEvent_e;                   /* '<Root>/MATLAB Function' */
  uint32_T seed;                       /* '<Root>/MATLAB Function' */
  uint32_T method;                     /* '<Root>/MATLAB Function' */
  uint32_T state[625];                 /* '<Root>/MATLAB Function' */
  uint32_T state_k[2];                 /* '<Root>/MATLAB Function' */
  uint32_T state_j;                    /* '<Root>/MATLAB Function' */
  int_T Analoginput_IWORK[2];          /* '<Root>/Analog input ' */
  uint8_T is_active_c2_ATTN;           /* '<S6>/MATLAB Function1' */
  uint8_T is_active_c5_ATTN;           /* '<S5>/MATLAB Function1' */
  uint8_T is_active_c6_ATTN;           /* '<Root>/MATLAB Function1' */
  uint8_T is_active_c1_ATTN;           /* '<Root>/MATLAB Function' */
  boolean_T doneDoubleBufferReInit;    /* '<S6>/MATLAB Function1' */
  boolean_T t0_not_empty;              /* '<S6>/MATLAB Function1' */
  boolean_T doneDoubleBufferReInit_i;  /* '<S5>/MATLAB Function1' */
  boolean_T t0_not_empty_p;            /* '<S5>/MATLAB Function1' */
  boolean_T doneDoubleBufferReInit_j;  /* '<Root>/MATLAB Function1' */
  boolean_T doneDoubleBufferReInit_e;  /* '<Root>/MATLAB Function' */
  boolean_T seed_not_empty;            /* '<Root>/MATLAB Function' */
  boolean_T method_not_empty;          /* '<Root>/MATLAB Function' */
  boolean_T state_not_empty;           /* '<Root>/MATLAB Function' */
  boolean_T state_not_empty_d;         /* '<Root>/MATLAB Function' */
  boolean_T state_not_empty_n;         /* '<Root>/MATLAB Function' */
  DW_MATLABFunction2_ATTN_T sf_MATLABFunction1_d;/* '<S4>/MATLAB Function1' */
  DW_MATLABFunction2_ATTN_T sf_MATLABFunction2;/* '<S3>/MATLAB Function2' */
};

/* Real-time Model Data Structure */
struct tag_RTM_ATTN_T {
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
    SimStruct childSFunctions[5];
    SimStruct *childSFunctionPtrs[5];
    struct _ssBlkInfo2 blkInfo2[5];
    struct _ssSFcnModelMethods2 methods2[5];
    struct _ssSFcnModelMethods3 methods3[5];
    struct _ssSFcnModelMethods4 methods4[5];
    struct _ssStatesInfo2 statesInfo2[5];
    ssPeriodicStatesInfo periodicStatesInfo[5];
    struct _ssPortInfo2 inputOutputPortInfo2[5];
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
      struct _ssPortOutputs outputPortInfo[2];
      struct _ssOutPortUnit outputPortUnits[2];
      struct _ssOutPortCoSimAttribute outputPortCoSimAttribute[2];
      uint_T attribs[9];
      mxArray *params[9];
      struct _ssDWorkRecord dWork[2];
      struct _ssDWorkAuxRecord dWorkAux[2];
    } Sfcn1;

    struct {
      time_T sfcnPeriod[1];
      time_T sfcnOffset[1];
      int_T sfcnTsMap[1];
      struct _ssPortInputs inputPortInfo[2];
      struct _ssInPortUnit inputPortUnits[2];
      struct _ssInPortCoSimAttribute inputPortCoSimAttribute[2];
      uint_T attribs[7];
      mxArray *params[7];
      struct _ssDWorkRecord dWork[1];
      struct _ssDWorkAuxRecord dWorkAux[1];
    } Sfcn2;

    struct {
      time_T sfcnPeriod[1];
      time_T sfcnOffset[1];
      int_T sfcnTsMap[1];
      struct _ssPortInputs inputPortInfo[15];
      struct _ssInPortUnit inputPortUnits[15];
      struct _ssInPortCoSimAttribute inputPortCoSimAttribute[15];
      uint_T attribs[6];
      mxArray *params[6];
      struct _ssDWorkRecord dWork[1];
      struct _ssDWorkAuxRecord dWorkAux[1];
    } Sfcn3;

    struct {
      time_T sfcnPeriod[1];
      time_T sfcnOffset[1];
      int_T sfcnTsMap[1];
      struct _ssPortOutputs outputPortInfo[1];
      struct _ssOutPortUnit outputPortUnits[1];
      struct _ssOutPortCoSimAttribute outputPortCoSimAttribute[1];
      uint_T attribs[4];
      mxArray *params[4];
      struct _ssDWorkRecord dWork[1];
      struct _ssDWorkAuxRecord dWorkAux[1];
    } Sfcn4;
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

  extern struct B_ATTN_T ATTN_B;

#ifdef __cplusplus

}

#endif

/* Block states (default storage) */
extern struct DW_ATTN_T ATTN_DW;

/* External data declarations for dependent source files */
extern const real_T ATTN_RGND;         /* real_T ground */

#ifdef __cplusplus

extern "C"
{

#endif

  /* Model entry point functions */
  extern void ATTN_initialize(void);
  extern void ATTN_step(void);
  extern void ATTN_terminate(void);

#ifdef __cplusplus

}

#endif

/* Real-time Model object */
#ifdef __cplusplus

extern "C"
{

#endif

  extern RT_MODEL_ATTN_T *const ATTN_M;

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
 * '<Root>' : 'ATTN'
 * '<S1>'   : 'ATTN/MATLAB Function'
 * '<S2>'   : 'ATTN/MATLAB Function1'
 * '<S3>'   : 'ATTN/PiezoDriver_1'
 * '<S4>'   : 'ATTN/PiezoDriver_2'
 * '<S5>'   : 'ATTN/RewardDriver'
 * '<S6>'   : 'ATTN/onsetToneDriver'
 * '<S7>'   : 'ATTN/PiezoDriver_1/MATLAB Function2'
 * '<S8>'   : 'ATTN/PiezoDriver_2/MATLAB Function1'
 * '<S9>'   : 'ATTN/RewardDriver/MATLAB Function1'
 * '<S10>'  : 'ATTN/onsetToneDriver/MATLAB Function1'
 */
#endif                                 /* RTW_HEADER_ATTN_h_ */
