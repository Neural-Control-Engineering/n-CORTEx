/*
 * JOLT.h
 *
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * Code generation for model "JOLT".
 *
 * Model version              : 1.353
 * Simulink Coder version : 9.9 (R2023a) 19-Nov-2022
 * C++ source code generated on : Tue Nov 28 13:13:38 2023
 *
 * Target selection: slrealtime.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Intel->x86-64 (Linux 64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef RTW_HEADER_JOLT_h_
#define RTW_HEADER_JOLT_h_
#include <logsrv.h>
#include "rtwtypes.h"
#include "simstruc.h"
#include "fixedpoint.h"
#include "verify/verifyIntrf.h"
#include "slrealtime/libsrc/IP/tcp.hpp"
#include "slrealtime/libsrc/IP/ip.hpp"
#include "slrealtime/libsrc/IP/socketFactory.hpp"
#include "JOLT_types.h"
#include <stddef.h>

extern "C"
{

#include "rt_nonfinite.h"

}

extern "C"
{

#include "rtGetNaN.h"

}

#include <cstring>
#include "JOLT_cal.h"

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

/* Block signals for system '<S8>/MATLAB Function4' */
struct B_MATLABFunction4_JOLT_T {
  real_T sigPulse;                     /* '<S8>/MATLAB Function4' */
};

/* Block states (default storage) for system '<S8>/MATLAB Function4' */
struct DW_MATLABFunction4_JOLT_T {
  real_T t0;                           /* '<S8>/MATLAB Function4' */
  int32_T sfEvent;                     /* '<S8>/MATLAB Function4' */
  uint8_T is_active_c7_JOLT;           /* '<S8>/MATLAB Function4' */
  boolean_T doneDoubleBufferReInit;    /* '<S8>/MATLAB Function4' */
  boolean_T t0_not_empty;              /* '<S8>/MATLAB Function4' */
};

/* Block signals (default storage) */
struct B_JOLT_T {
  real_T Memory2[8000];                /* '<Root>/Memory2' */
  real_T monofilBaseBuffer_out[8000];  /* '<Root>/MATLAB Function1' */
  real_T x_data[8000];
  real_T absdiff_data[8000];
  real_T TCPServer;                    /* '<Root>/TCP Server' */
  real_T TCPReceive_o2;                /* '<Root>/TCP Receive' */
  real_T Memory1;                      /* '<Root>/Memory1' */
  real_T npxls_trig;                   /* '<Root>/Npxls Trig' */
  real_T Clock;                        /* '<S6>/Clock' */
  real_T Clock_p;                      /* '<S8>/Clock' */
  real_T Clock_j;                      /* '<S7>/Clock' */
  real_T stim_raw;                     /* '<Root>/Analog input ' */
  real_T rawMonofilData;               /* '<Root>/Analog input ' */
  real_T stim_filt;                    /* '<Root>/Discrete Filter' */
  real_T Add1;                         /* '<S10>/Add1' */
  real_T Product;                      /* '<S10>/Product' */
  real_T Add;                          /* '<S10>/Add' */
  real_T npxlsAcqCutoff;               /* '<Root>/Delay' */
  real_T Clock_a;                      /* '<S9>/Clock' */
  real_T TCPSend;                      /* '<Root>/TCP Send' */
  real_T PulseGen1Hz;                  /* '<Root>/Digital input ' */
  real_T HiddenRateTransitionForToWks_In;
  /* '<Root>/HiddenRateTransitionForToWks_InsertedFor_TAQSigLogging_InsertedFor_Digital input _at_outport_0_at_inport_0' */
  real_T sigPulse;                     /* '<S7>/MATLAB Function4' */
  real_T sigPulse_p;                   /* '<S6>/MATLAB Function4' */
  real_T out;                          /* '<S5>/MATLAB Function' */
  real_T out_c;                        /* '<S3>/MATLAB Function' */
  real_T npxlsAcq_trig;                /* '<Root>/MATLAB Function1' */
  real_T acqStatus;                    /* '<Root>/MATLAB Function1' */
  real_T S_out;                        /* '<Root>/MATLAB Function1' */
  real_T acqTone_trig;                 /* '<Root>/MATLAB Function1' */
  real_T npxlsAcq_out;                 /* '<Root>/MATLAB Function1' */
  real_T restingAcq;                   /* '<Root>/MATLAB Function1' */
  real_T stimSig_sel;                  /* '<Root>/MATLAB Function1' */
  real_T baseAvg;                      /* '<Root>/MATLAB Function1' */
  real_T changeAvg;                    /* '<Root>/MATLAB Function1' */
  real_T baseBuffLen;                  /* '<Root>/MATLAB Function1' */
  real_T buffOut[8000];                /* '<S1>/MATLAB Function' */
  uint8_T buttonStat;                  /* '<Root>/TCP Receive' */
  uint8_T convertedMonofil;            /* '<S10>/Data Type Conversion' */
  uint8_T out_j;                       /* '<S4>/MATLAB Function' */
  B_MATLABFunction4_JOLT_T sf_MATLABFunction4_h;/* '<S9>/MATLAB Function4' */
  B_MATLABFunction4_JOLT_T sf_MATLABFunction4_d;/* '<S8>/MATLAB Function4' */
};

/* Block states (default storage) for system '<Root>' */
struct DW_JOLT_T {
  real_T DiscreteFilter_states[500];   /* '<Root>/Discrete Filter' */
  real_T Delay_DSTATE[700];            /* '<Root>/Delay' */
  real_T Memory2_PreviousInput[8000];  /* '<Root>/Memory2' */
  real_T Memory1_PreviousInput;        /* '<Root>/Memory1' */
  real_T DiscreteFilter_tmp;           /* '<Root>/Discrete Filter' */
  real_T Add_DWORK1;                   /* '<S10>/Add' */
  real_T t0;                           /* '<S7>/MATLAB Function4' */
  real_T t0_b;                         /* '<S6>/MATLAB Function4' */
  real_T Setup_RWORK[2];               /* '<Root>/Setup ' */
  void *Setup_PWORK;                   /* '<Root>/Setup ' */
  void *TCPServer_PWORK;               /* '<Root>/TCP Server' */
  void *TCPReceive_PWORK[2];           /* '<Root>/TCP Receive' */
  void *Digitaloutput_PWORK;           /* '<Root>/Digital output ' */
  void *Analoginput_PWORK;             /* '<Root>/Analog input ' */
  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Discr;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MUX1_;   /* synthesized block */

  void *TCPSend_PWORK;                 /* '<Root>/TCP Send' */
  void *Digitalinput_PWORK;            /* '<Root>/Digital input ' */
  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Digit;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MUX2_;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Subsy;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Delay;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_DataT;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Analo;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Ana_p;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Sub_a;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MUX_a;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Sub_l;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_Npxls;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MATLA;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_a;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_j;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_c;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_f;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_g;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_MAT_o;   /* synthesized block */

  struct {
    void *AQHandles;
  } TAQSigLogging_InsertedFor_TCPRe;   /* synthesized block */

  int32_T clockTickCounter;            /* '<Root>/Npxls Trig' */
  int32_T sfEvent;                     /* '<S7>/MATLAB Function4' */
  int32_T sfEvent_k;                   /* '<S6>/MATLAB Function4' */
  int32_T sfEvent_m;                   /* '<S5>/MATLAB Function' */
  int32_T sfEvent_p;                   /* '<S4>/MATLAB Function' */
  int32_T sfEvent_e;                   /* '<S3>/MATLAB Function' */
  int32_T sfEvent_d;                   /* '<Root>/MATLAB Function1' */
  int32_T sfEvent_c;                   /* '<S1>/MATLAB Function' */
  int_T TCPReceive_IWORK;              /* '<Root>/TCP Receive' */
  int_T Analoginput_IWORK[2];          /* '<Root>/Analog input ' */
  uint8_T is_active_c5_JOLT;           /* '<S7>/MATLAB Function4' */
  uint8_T is_active_c4_JOLT;           /* '<S6>/MATLAB Function4' */
  uint8_T is_active_c8_JOLT;           /* '<S5>/MATLAB Function' */
  uint8_T is_active_c6_JOLT;           /* '<S4>/MATLAB Function' */
  uint8_T is_active_c1_JOLT;           /* '<S3>/MATLAB Function' */
  uint8_T is_active_c2_JOLT;           /* '<Root>/MATLAB Function1' */
  uint8_T is_active_c3_JOLT;           /* '<S1>/MATLAB Function' */
  boolean_T doneDoubleBufferReInit;    /* '<S7>/MATLAB Function4' */
  boolean_T t0_not_empty;              /* '<S7>/MATLAB Function4' */
  boolean_T doneDoubleBufferReInit_f;  /* '<S6>/MATLAB Function4' */
  boolean_T t0_not_empty_p;            /* '<S6>/MATLAB Function4' */
  boolean_T doneDoubleBufferReInit_m;  /* '<S5>/MATLAB Function' */
  boolean_T doneDoubleBufferReInit_c;  /* '<S4>/MATLAB Function' */
  boolean_T doneDoubleBufferReInit_fa; /* '<S3>/MATLAB Function' */
  boolean_T doneDoubleBufferReInit_d;  /* '<Root>/MATLAB Function1' */
  boolean_T doneDoubleBufferReInit_h;  /* '<S1>/MATLAB Function' */
  DW_MATLABFunction4_JOLT_T sf_MATLABFunction4_h;/* '<S9>/MATLAB Function4' */
  DW_MATLABFunction4_JOLT_T sf_MATLABFunction4_d;/* '<S8>/MATLAB Function4' */
};

/* Real-time Model Data Structure */
struct tag_RTM_JOLT_T {
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
    SimStruct childSFunctions[4];
    SimStruct *childSFunctionPtrs[4];
    struct _ssBlkInfo2 blkInfo2[4];
    struct _ssSFcnModelMethods2 methods2[4];
    struct _ssSFcnModelMethods3 methods3[4];
    struct _ssSFcnModelMethods4 methods4[4];
    struct _ssStatesInfo2 statesInfo2[4];
    ssPeriodicStatesInfo periodicStatesInfo[4];
    struct _ssPortInfo2 inputOutputPortInfo2[4];
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
      struct _ssPortInputs inputPortInfo[15];
      struct _ssInPortUnit inputPortUnits[15];
      struct _ssInPortCoSimAttribute inputPortCoSimAttribute[15];
      uint_T attribs[6];
      mxArray *params[6];
      struct _ssDWorkRecord dWork[1];
      struct _ssDWorkAuxRecord dWorkAux[1];
    } Sfcn1;

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
    } Sfcn2;

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
    } Sfcn3;
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

  extern struct B_JOLT_T JOLT_B;

#ifdef __cplusplus

}

#endif

/* Block states (default storage) */
extern struct DW_JOLT_T JOLT_DW;

/* External data declarations for dependent source files */
extern const real_T JOLT_RGND;         /* real_T ground */

#ifdef __cplusplus

extern "C"
{

#endif

  /* Model entry point functions */
  extern void JOLT_initialize(void);
  extern void JOLT_step(void);
  extern void JOLT_terminate(void);

#ifdef __cplusplus

}

#endif

/* Real-time Model object */
#ifdef __cplusplus

extern "C"
{

#endif

  extern RT_MODEL_JOLT_T *const JOLT_M;

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
 * '<Root>' : 'JOLT'
 * '<S1>'   : 'JOLT/Buffer'
 * '<S2>'   : 'JOLT/MATLAB Function1'
 * '<S3>'   : 'JOLT/MUX'
 * '<S4>'   : 'JOLT/MUX1'
 * '<S5>'   : 'JOLT/MUX2'
 * '<S6>'   : 'JOLT/Subsystem'
 * '<S7>'   : 'JOLT/Subsystem1'
 * '<S8>'   : 'JOLT/Subsystem2'
 * '<S9>'   : 'JOLT/Subsystem3'
 * '<S10>'  : 'JOLT/tcpConversion'
 * '<S11>'  : 'JOLT/Buffer/MATLAB Function'
 * '<S12>'  : 'JOLT/MUX/MATLAB Function'
 * '<S13>'  : 'JOLT/MUX1/MATLAB Function'
 * '<S14>'  : 'JOLT/MUX2/MATLAB Function'
 * '<S15>'  : 'JOLT/Subsystem/MATLAB Function4'
 * '<S16>'  : 'JOLT/Subsystem1/MATLAB Function4'
 * '<S17>'  : 'JOLT/Subsystem2/MATLAB Function4'
 * '<S18>'  : 'JOLT/Subsystem3/MATLAB Function4'
 */
#endif                                 /* RTW_HEADER_JOLT_h_ */
