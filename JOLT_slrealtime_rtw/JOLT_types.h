/*
 * JOLT_types.h
 *
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * Code generation for model "JOLT".
 *
 * Model version              : 1.215
 * Simulink Coder version : 9.9 (R2023a) 19-Nov-2022
 * C++ source code generated on : Tue Oct 17 19:06:01 2023
 *
 * Target selection: slrealtime.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Intel->x86-64 (Linux 64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef RTW_HEADER_JOLT_types_h_
#define RTW_HEADER_JOLT_types_h_
#include "rtwtypes.h"
#ifndef struct_emxArray_real_T_JOLT_T
#define struct_emxArray_real_T_JOLT_T

struct emxArray_real_T_JOLT_T
{
  real_T *data;
  int32_T *size;
  int32_T allocatedSize;
  int32_T numDimensions;
  boolean_T canFreeData;
}

;

#endif                                 /* struct_emxArray_real_T_JOLT_T */

/* Forward declaration for rtModel */
typedef struct tag_RTM_JOLT_T RT_MODEL_JOLT_T;

#endif                                 /* RTW_HEADER_JOLT_types_h_ */
