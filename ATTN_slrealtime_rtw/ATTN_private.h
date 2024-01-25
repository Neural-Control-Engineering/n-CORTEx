/*
 * ATTN_private.h
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

#ifndef RTW_HEADER_ATTN_private_h_
#define RTW_HEADER_ATTN_private_h_
#include "rtwtypes.h"
#include "multiword_types.h"
#include "ATTN.h"
#include "ATTN_types.h"

/* Private macros used by the generated code to access rtModel */
#ifndef rtmIsMajorTimeStep
#define rtmIsMajorTimeStep(rtm)        (((rtm)->Timing.simTimeStep) == MAJOR_TIME_STEP)
#endif

#ifndef rtmIsMinorTimeStep
#define rtmIsMinorTimeStep(rtm)        (((rtm)->Timing.simTimeStep) == MINOR_TIME_STEP)
#endif

#ifndef rtmSetTFinal
#define rtmSetTFinal(rtm, val)         ((rtm)->Timing.tFinal = (val))
#endif

#ifndef rtmSetTPtr
#define rtmSetTPtr(rtm, val)           ((rtm)->Timing.t = (val))
#endif

extern real_T rt_roundd_snf(real_T u);
extern void* slrtRegisterSignalToLoggingService(uintptr_t sigAddr);
extern "C" void sg_IO191_setup_s(SimStruct *rts);
extern "C" void sg_IO191_ad_s(SimStruct *rts);
extern "C" void sg_IO191_da_s(SimStruct *rts);
extern "C" void sg_IO191_do_s(SimStruct *rts);
extern "C" void sg_IO191_di_s(SimStruct *rts);
extern void ATTN_MATLABFunction2_Init(DW_MATLABFunction2_ATTN_T *localDW);
extern void ATTN_MATLABFunction2(real_T rtu_trigger, real_T rtu_duration, real_T
  rtu_amp, real_T rtu_t, B_MATLABFunction2_ATTN_T *localB,
  DW_MATLABFunction2_ATTN_T *localDW);

#endif                                 /* RTW_HEADER_ATTN_private_h_ */
