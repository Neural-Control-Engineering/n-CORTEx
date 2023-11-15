/*
 * JOLT.cpp
 *
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * Code generation for model "JOLT".
 *
 * Model version              : 1.322
 * Simulink Coder version : 9.9 (R2023a) 19-Nov-2022
 * C++ source code generated on : Wed Nov 15 00:39:33 2023
 *
 * Target selection: slrealtime.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Intel->x86-64 (Linux 64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "JOLT.h"
#include "rtwtypes.h"
#include "JOLT_private.h"
#include "JOLT_cal.h"
#include <cstring>

extern "C"
{

#include "rt_nonfinite.h"

}

#include <cmath>

/* Named constants for MATLAB Function: '<S8>/MATLAB Function4' */
const int32_T JOLT_CALL_EVENT = -1;

/* Named constants for MATLAB Function: '<S1>/MATLAB Function' */
const int32_T JOLT_CALL_EVENT_l = -1;
const real_T JOLT_RGND = 0.0;          /* real_T ground */

/* Block signals (default storage) */
B_JOLT_T JOLT_B;

/* Block states (default storage) */
DW_JOLT_T JOLT_DW;

/* Real-time model */
RT_MODEL_JOLT_T JOLT_M_ = RT_MODEL_JOLT_T();
RT_MODEL_JOLT_T *const JOLT_M = &JOLT_M_;

/* Forward declaration for local functions */
static void JOLT_nonzeros(const real_T s[8000], real_T v_data[], int32_T *v_size);
static real_T JOLT_blockedSummation(const real_T x_data[], const int32_T *x_size,
  int32_T vlen);

/*
 * System initialize for atomic system:
 *    '<S8>/MATLAB Function4'
 *    '<S9>/MATLAB Function4'
 */
void JOLT_MATLABFunction4_Init(DW_MATLABFunction4_JOLT_T *localDW)
{
  localDW->sfEvent = JOLT_CALL_EVENT;
  localDW->t0_not_empty = false;
  localDW->is_active_c7_JOLT = 0U;
}

/*
 * Output and update for atomic system:
 *    '<S8>/MATLAB Function4'
 *    '<S9>/MATLAB Function4'
 */
void JOLT_MATLABFunction4(real_T rtu_onset_trig, real_T rtu_sigAmp, real_T
  rtu_sigPulseLen, real_T rtu_t, B_MATLABFunction4_JOLT_T *localB,
  DW_MATLABFunction4_JOLT_T *localDW)
{
  localDW->sfEvent = JOLT_CALL_EVENT;
  if (rtu_onset_trig != 0.0) {
    localB->sigPulse = rtu_sigAmp;
    localDW->t0 = rtu_t;
    localDW->t0_not_empty = true;
  } else if (localDW->t0_not_empty) {
    if (rtu_t - localDW->t0 < rtu_sigPulseLen) {
      localB->sigPulse = rtu_sigAmp;
    } else {
      localB->sigPulse = 0.0;
    }
  } else {
    localB->sigPulse = 0.0;
  }
}

/* Function for MATLAB Function: '<Root>/MATLAB Function1' */
static void JOLT_nonzeros(const real_T s[8000], real_T v_data[], int32_T *v_size)
{
  int32_T i;
  i = 0;
  for (int32_T b_k = 0; b_k < 8000; b_k++) {
    if (s[b_k] != 0.0) {
      i++;
    }
  }

  *v_size = i;
  i = -1;
  for (int32_T b_k = 0; b_k < 8000; b_k++) {
    real_T s_0;
    s_0 = s[b_k];
    if (s_0 != 0.0) {
      i++;
      v_data[i] = s_0;
    }
  }
}

/* Function for MATLAB Function: '<Root>/MATLAB Function1' */
static real_T JOLT_blockedSummation(const real_T x_data[], const int32_T *x_size,
  int32_T vlen)
{
  real_T y;
  if ((*x_size == 0) || (vlen == 0)) {
    y = 0.0;
  } else {
    int32_T firstBlockLength;
    int32_T lastBlockLength;
    int32_T nblocks;
    int32_T xblockoffset;
    if (vlen <= 1024) {
      firstBlockLength = vlen;
      lastBlockLength = 0;
      nblocks = 1;
    } else {
      firstBlockLength = 1024;
      nblocks = static_cast<uint16_T>(vlen) >> 10;
      lastBlockLength = vlen - (nblocks << 10);
      if (lastBlockLength > 0) {
        nblocks++;
      } else {
        lastBlockLength = 1024;
      }
    }

    y = x_data[0];
    for (xblockoffset = 2; xblockoffset <= firstBlockLength; xblockoffset++) {
      y += x_data[xblockoffset - 1];
    }

    for (firstBlockLength = 2; firstBlockLength <= nblocks; firstBlockLength++)
    {
      real_T bsum;
      int32_T hi;
      xblockoffset = (firstBlockLength - 1) << 10;
      bsum = x_data[xblockoffset];
      if (firstBlockLength == nblocks) {
        hi = lastBlockLength;
      } else {
        hi = 1024;
      }

      for (int32_T b_k = 2; b_k <= hi; b_k++) {
        bsum += x_data[(xblockoffset + b_k) - 1];
      }

      y += bsum;
    }
  }

  return y;
}

real_T rt_roundd_snf(real_T u)
{
  real_T y;
  if (std::abs(u) < 4.503599627370496E+15) {
    if (u >= 0.5) {
      y = std::floor(u + 0.5);
    } else if (u > -0.5) {
      y = u * 0.0;
    } else {
      y = std::ceil(u - 0.5);
    }
  } else {
    y = u;
  }

  return y;
}

/* Model step function */
void JOLT_step(void)
{
  real_T v_data[10];
  real_T absdiff;
  real_T baseAvg;
  real_T scale;
  real_T t;
  real_T xbar;
  int32_T b;
  int32_T i;
  int32_T x_size;
  uint8_T tmp;
  boolean_T result;

  /* Memory: '<Root>/Memory2' */
  std::memcpy(&JOLT_B.Memory2[0], &JOLT_DW.Memory2_PreviousInput[0], 8000U *
              sizeof(real_T));

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

  /* Memory: '<Root>/Memory1' */
  JOLT_B.Memory1 = JOLT_DW.Memory1_PreviousInput;

  /* MATLAB Function: '<Root>/MATLAB Function1' incorporates:
   *  Memory: '<Root>/Memory2'
   */
  JOLT_DW.sfEvent_d = JOLT_CALL_EVENT_l;
  switch (static_cast<int32_T>(JOLT_B.Memory1)) {
   case 0:
    switch (JOLT_B.buttonStat) {
     case 1U:
      JOLT_B.npxlsAcq_out = 0.0;
      JOLT_B.acqStatus = 1.0;
      JOLT_B.S_out = 1.0;
      JOLT_B.restingAcq = 0.0;
      break;

     case 2U:
      JOLT_B.npxlsAcq_out = 0.0;
      JOLT_B.acqStatus = 2.0;
      JOLT_B.S_out = JOLT_B.Memory1;
      JOLT_B.restingAcq = 0.0;
      break;

     case 3U:
      JOLT_B.npxlsAcq_out = 0.0;
      JOLT_B.acqStatus = 3.0;
      JOLT_B.S_out = JOLT_B.Memory1;
      JOLT_B.restingAcq = 0.0;
      break;

     case 4U:
      JOLT_B.acqStatus = 4.0;
      JOLT_B.restingAcq = 0.0;
      JOLT_B.npxlsAcq_out = 2.5;
      JOLT_B.S_out = 0.0;
      break;

     default:
      JOLT_B.acqStatus = 0.0;
      JOLT_B.S_out = JOLT_B.Memory1;
      JOLT_B.npxlsAcq_out = 0.0;
      JOLT_B.restingAcq = 0.0;
      break;
    }

    JOLT_B.acqTone_trig = 0.0;
    JOLT_B.npxlsAcq_trig = 0.0;
    baseAvg = 0.0;
    scale = 0.0;
    JOLT_B.baseBuffLen = 0.0;
    JOLT_B.stimSig_sel = 0.0;
    std::memset(&JOLT_B.monofilBaseBuffer_out[0], 0, 8000U * sizeof(real_T));
    break;

   case 1:
    JOLT_B.acqStatus = 0.0;
    JOLT_B.acqTone_trig = 0.0;
    JOLT_B.npxlsAcq_out = 0.0;
    JOLT_B.npxlsAcq_trig = 0.0;
    JOLT_B.restingAcq = 0.0;
    JOLT_B.stimSig_sel = 0.0;
    JOLT_B.S_out = 1.0;
    std::memcpy(&JOLT_B.monofilBaseBuffer_out[0], &JOLT_B.Memory2[0], 8000U *
                sizeof(real_T));
    JOLT_B.baseBuffLen = 8000.0;
    JOLT_nonzeros(&JOLT_B.Memory2[0], JOLT_B.x_data, &x_size);
    baseAvg = JOLT_blockedSummation(JOLT_B.x_data, &x_size, x_size) /
      static_cast<real_T>(x_size);
    JOLT_nonzeros(&JOLT_B.Memory2[0], JOLT_B.x_data, &x_size);
    if (x_size == 0) {
      xbar = (rtNaN);
    } else if (x_size == 1) {
      if ((!rtIsInf(JOLT_B.x_data[0])) && (!rtIsNaN(JOLT_B.x_data[0]))) {
        xbar = 0.0;
      } else {
        xbar = (rtNaN);
      }
    } else {
      xbar = JOLT_blockedSummation(JOLT_B.x_data, &x_size, x_size) /
        static_cast<real_T>(x_size);
      b = x_size;
      for (i = 0; i < b; i++) {
        JOLT_B.absdiff_data[i] = std::abs(JOLT_B.x_data[i] - xbar);
      }

      xbar = 0.0;
      scale = 3.3121686421112381E-170;
      i = x_size;
      for (b = 0; b < i; b++) {
        absdiff = JOLT_B.absdiff_data[b];
        if (absdiff > scale) {
          t = scale / absdiff;
          xbar = xbar * t * t + 1.0;
          scale = absdiff;
        } else {
          t = absdiff / scale;
          xbar += t * t;
        }
      }

      xbar = scale * std::sqrt(xbar);
      xbar /= std::sqrt(static_cast<real_T>(x_size) - 1.0);
    }

    i = 0;
    for (b = 0; b < 10; b++) {
      if (JOLT_B.Memory2[b + 7990] != 0.0) {
        i++;
      }
    }

    x_size = i;
    i = -1;
    for (b = 0; b < 10; b++) {
      scale = JOLT_B.Memory2[b + 7990];
      if (scale != 0.0) {
        i++;
        v_data[i] = scale;
      }
    }

    scale = JOLT_blockedSummation(v_data, &x_size, x_size) / static_cast<real_T>
      (x_size);
    if (scale > 3.0 * xbar + baseAvg) {
      JOLT_B.stimSig_sel = 1.0;
      JOLT_B.S_out = 2.0;
    }
    break;

   case 2:
    std::memcpy(&JOLT_B.monofilBaseBuffer_out[0], &JOLT_B.Memory2[0], 8000U *
                sizeof(real_T));
    JOLT_B.baseBuffLen = 0.0;
    baseAvg = 0.0;
    scale = 0.0;
    JOLT_B.acqStatus = 0.0;
    JOLT_B.restingAcq = 1.0;
    JOLT_B.stimSig_sel = 0.0;
    JOLT_B.npxlsAcq_out = 0.0;
    JOLT_B.npxlsAcq_trig = 1.0;
    JOLT_B.acqTone_trig = 1.0;
    JOLT_B.S_out = 0.0;
    break;

   default:
    std::memcpy(&JOLT_B.monofilBaseBuffer_out[0], &JOLT_B.Memory2[0], 8000U *
                sizeof(real_T));
    JOLT_B.baseBuffLen = 0.0;
    baseAvg = 0.0;
    scale = 0.0;
    JOLT_B.S_out = 0.0;
    JOLT_B.acqStatus = 0.0;
    JOLT_B.stimSig_sel = 0.0;
    JOLT_B.acqTone_trig = 0.0;
    JOLT_B.npxlsAcq_out = 0.0;
    JOLT_B.npxlsAcq_trig = 0.0;
    JOLT_B.restingAcq = 1.0;
    break;
  }

  JOLT_B.baseAvg = baseAvg;
  JOLT_B.changeAvg = scale;

  /* End of MATLAB Function: '<Root>/MATLAB Function1' */

  /* DiscretePulseGenerator: '<Root>/Npxls Trig' */
  baseAvg = JOLT_cal->T_npxls / 2.0;

  /* DiscretePulseGenerator: '<Root>/Npxls Trig' */
  JOLT_B.npxls_trig = (JOLT_DW.clockTickCounter < baseAvg) &&
    (JOLT_DW.clockTickCounter >= 0) ? JOLT_cal->NpxlsTrig_Amp : 0.0;

  /* DiscretePulseGenerator: '<Root>/Npxls Trig' */
  if (JOLT_DW.clockTickCounter >= JOLT_cal->T_npxls - 1.0) {
    JOLT_DW.clockTickCounter = 0;
  } else {
    JOLT_DW.clockTickCounter++;
  }

  /* Clock: '<S6>/Clock' */
  JOLT_B.Clock = JOLT_M->Timing.t[0];

  /* MATLAB Function: '<S6>/MATLAB Function4' incorporates:
   *  Constant: '<S6>/Constant'
   *  Constant: '<S6>/Constant1'
   */
  JOLT_DW.sfEvent_k = JOLT_CALL_EVENT_l;
  if (JOLT_B.npxlsAcq_trig != 0.0) {
    JOLT_B.sigPulse_p = JOLT_cal->Constant_Value_c;
    JOLT_DW.t0_b = JOLT_B.Clock;
    JOLT_DW.t0_not_empty_p = true;
  } else if (JOLT_DW.t0_not_empty_p) {
    if (JOLT_B.Clock - JOLT_DW.t0_b < JOLT_cal->Constant1_Value) {
      JOLT_B.sigPulse_p = JOLT_cal->Constant_Value_c;
    } else {
      JOLT_B.sigPulse_p = 0.0;
    }
  } else {
    JOLT_B.sigPulse_p = 0.0;
  }

  /* End of MATLAB Function: '<S6>/MATLAB Function4' */

  /* Clock: '<S8>/Clock' */
  JOLT_B.Clock_p = JOLT_M->Timing.t[0];

  /* MATLAB Function: '<S8>/MATLAB Function4' incorporates:
   *  Constant: '<S8>/Constant'
   *  Constant: '<S8>/Constant1'
   */
  JOLT_MATLABFunction4(JOLT_B.restingAcq, JOLT_cal->Constant_Value_a,
                       JOLT_cal->Constant1_Value_p, JOLT_B.Clock_p,
                       &JOLT_B.sf_MATLABFunction4_d,
                       &JOLT_DW.sf_MATLABFunction4_d);

  /* MATLAB Function: '<S3>/MATLAB Function' */
  JOLT_DW.sfEvent_e = JOLT_CALL_EVENT_l;
  switch (static_cast<int32_T>(JOLT_B.sf_MATLABFunction4_d.sigPulse)) {
   case 1:
    JOLT_B.out_c = JOLT_B.sigPulse_p;
    break;

   case 0:
    JOLT_B.out_c = JOLT_B.npxlsAcq_out;
    break;

   default:
    JOLT_B.out_c = 0.0;
    break;
  }

  /* End of MATLAB Function: '<S3>/MATLAB Function' */

  /* Clock: '<S7>/Clock' */
  JOLT_B.Clock_j = JOLT_M->Timing.t[0];

  /* MATLAB Function: '<S7>/MATLAB Function4' incorporates:
   *  Constant: '<S7>/Constant'
   *  Constant: '<S7>/Constant1'
   */
  JOLT_DW.sfEvent = JOLT_CALL_EVENT_l;
  if (JOLT_B.acqTone_trig != 0.0) {
    JOLT_B.sigPulse = JOLT_cal->Constant_Value_j;
    JOLT_DW.t0 = JOLT_B.Clock_j;
    JOLT_DW.t0_not_empty = true;
  } else if (JOLT_DW.t0_not_empty) {
    if (JOLT_B.Clock_j - JOLT_DW.t0 < JOLT_cal->Constant1_Value_k) {
      JOLT_B.sigPulse = JOLT_cal->Constant_Value_j;
    } else {
      JOLT_B.sigPulse = 0.0;
    }
  } else {
    JOLT_B.sigPulse = 0.0;
  }

  /* End of MATLAB Function: '<S7>/MATLAB Function4' */

  /* S-Function (sg_IO191_do_s): '<Root>/Digital output ' */

  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[1];
    sfcnOutputs(rts,0);
  }

  /* S-Function (sg_IO191_ad_s): '<Root>/Analog input ' */

  /* Level2 S-Function Block: '<Root>/Analog input ' (sg_IO191_ad_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[2];
    sfcnOutputs(rts,0);
  }

  /* DiscreteFilter: '<Root>/Discrete Filter' */
  baseAvg = JOLT_B.monofilData_raw;
  baseAvg -= JOLT_DW.DiscreteFilter_states[0] * JOLT_cal->
    DiscreteFilter_DenCoef[1];
  baseAvg -= JOLT_DW.DiscreteFilter_states[1] * JOLT_cal->
    DiscreteFilter_DenCoef[2];
  baseAvg -= JOLT_DW.DiscreteFilter_states[2] * JOLT_cal->
    DiscreteFilter_DenCoef[3];
  baseAvg -= JOLT_DW.DiscreteFilter_states[3] * JOLT_cal->
    DiscreteFilter_DenCoef[4];
  baseAvg /= JOLT_cal->DiscreteFilter_DenCoef[0];
  JOLT_DW.DiscreteFilter_tmp = baseAvg;
  baseAvg = JOLT_cal->DiscreteFilter_NumCoef[0] * JOLT_DW.DiscreteFilter_tmp;
  baseAvg += JOLT_DW.DiscreteFilter_states[0] * JOLT_cal->
    DiscreteFilter_NumCoef[1];
  baseAvg += JOLT_DW.DiscreteFilter_states[1] * JOLT_cal->
    DiscreteFilter_NumCoef[2];
  baseAvg += JOLT_DW.DiscreteFilter_states[2] * JOLT_cal->
    DiscreteFilter_NumCoef[3];
  baseAvg += JOLT_DW.DiscreteFilter_states[3] * JOLT_cal->
    DiscreteFilter_NumCoef[4];

  /* DiscreteFilter: '<Root>/Discrete Filter' */
  JOLT_B.monofilData_filt = baseAvg;

  /* MATLAB Function: '<S1>/MATLAB Function' */
  JOLT_DW.sfEvent_c = JOLT_CALL_EVENT_l;
  std::memcpy(&JOLT_B.buffOut[0], &JOLT_B.monofilBaseBuffer_out[1], 7999U *
              sizeof(real_T));
  JOLT_B.buffOut[7999] = JOLT_B.monofilData_filt;

  /* Sum: '<S10>/Add1' incorporates:
   *  Constant: '<S10>/Constant1'
   */
  JOLT_B.Add1 = JOLT_cal->Constant1_Value_d + JOLT_B.monofilData_filt;

  /* Product: '<S10>/Product' incorporates:
   *  Constant: '<S10>/Constant2'
   */
  JOLT_B.Product = JOLT_cal->Constant2_Value * JOLT_B.Add1;

  /* DataTypeConversion: '<S10>/Data Type Conversion' */
  baseAvg = std::ceil(JOLT_B.Product);
  if (rtIsNaN(baseAvg) || rtIsInf(baseAvg)) {
    baseAvg = 0.0;
  } else {
    baseAvg = std::fmod(baseAvg, 256.0);
  }

  /* DataTypeConversion: '<S10>/Data Type Conversion' */
  JOLT_B.convertedMonofil = static_cast<uint8_T>(baseAvg < 0.0 ?
    static_cast<int32_T>(static_cast<uint8_T>(-static_cast<int8_T>
    (static_cast<uint8_T>(-baseAvg)))) : static_cast<int32_T>
    (static_cast<uint8_T>(baseAvg)));

  /* Sum: '<S10>/Add' incorporates:
   *  Constant: '<S10>/Constant5'
   */
  JOLT_B.Add = JOLT_cal->Constant5_Value + static_cast<real_T>
    (JOLT_B.convertedMonofil);

  /* Delay: '<Root>/Delay' */
  JOLT_B.Delay = JOLT_DW.Delay_DSTATE[0];

  /* Clock: '<S9>/Clock' */
  JOLT_B.Clock_a = JOLT_M->Timing.t[0];

  /* MATLAB Function: '<S9>/MATLAB Function4' incorporates:
   *  Constant: '<S9>/Constant'
   *  Constant: '<S9>/Constant1'
   */
  JOLT_MATLABFunction4(JOLT_B.stimSig_sel, JOLT_cal->Constant_Value_n,
                       JOLT_cal->Constant1_Value_bz, JOLT_B.Clock_a,
                       &JOLT_B.sf_MATLABFunction4_h,
                       &JOLT_DW.sf_MATLABFunction4_h);

  /* MATLAB Function: '<S5>/MATLAB Function' incorporates:
   *  Constant: '<Root>/Constant1'
   */
  JOLT_DW.sfEvent_m = JOLT_CALL_EVENT_l;
  switch (static_cast<int32_T>(JOLT_B.sf_MATLABFunction4_h.sigPulse)) {
   case 1:
    JOLT_B.out = JOLT_cal->Constant1_Value_b;
    break;

   case 0:
    JOLT_B.out = JOLT_B.Delay;
    break;

   default:
    JOLT_B.out = 0.0;
    break;
  }

  /* End of MATLAB Function: '<S5>/MATLAB Function' */

  /* MATLAB Function: '<S4>/MATLAB Function' incorporates:
   *  Constant: '<Root>/Constant2'
   *  Constant: '<Root>/Constant4'
   */
  JOLT_DW.sfEvent_p = JOLT_CALL_EVENT_l;
  result = (JOLT_B.out == 0.0);
  if (result) {
    i = 0;
  } else {
    result = (JOLT_B.out == 2.5);
    if (result) {
      i = 1;
    } else {
      result = (JOLT_B.out == 2.0);
      if (result) {
        i = 2;
      } else {
        i = -1;
      }
    }
  }

  switch (i) {
   case 0:
    baseAvg = rt_roundd_snf(JOLT_B.Add);
    if (baseAvg < 256.0) {
      if (baseAvg >= 0.0) {
        tmp = static_cast<uint8_T>(baseAvg);
      } else {
        tmp = 0U;
      }
    } else {
      tmp = MAX_uint8_T;
    }

    JOLT_B.out_j = tmp;
    break;

   case 1:
    baseAvg = rt_roundd_snf(JOLT_cal->Constant4_Value);
    if (baseAvg < 256.0) {
      if (baseAvg >= 0.0) {
        tmp = static_cast<uint8_T>(baseAvg);
      } else {
        tmp = 0U;
      }
    } else {
      tmp = MAX_uint8_T;
    }

    JOLT_B.out_j = tmp;
    break;

   case 2:
    baseAvg = rt_roundd_snf(JOLT_cal->Constant2_Value_c);
    if (baseAvg < 256.0) {
      if (baseAvg >= 0.0) {
        tmp = static_cast<uint8_T>(baseAvg);
      } else {
        tmp = 0U;
      }
    } else {
      tmp = MAX_uint8_T;
    }

    JOLT_B.out_j = tmp;
    break;

   default:
    baseAvg = rt_roundd_snf(JOLT_cal->Constant4_Value);
    if (baseAvg < 256.0) {
      if (baseAvg >= 0.0) {
        tmp = static_cast<uint8_T>(baseAvg);
      } else {
        tmp = 0U;
      }
    } else {
      tmp = MAX_uint8_T;
    }

    JOLT_B.out_j = tmp;
    break;
  }

  /* End of MATLAB Function: '<S4>/MATLAB Function' */
  /* S-Function (slrealtimeTCPSend): '<Root>/TCP Send' incorporates:
   *  Constant: '<Root>/Constant3'
   */
  {
    try {
      size_t bytesSent = 0;
      int enable = (int)JOLT_B.TCPServer;
      char *sendBuf = (char *)&JOLT_B.out_j;
      size_t bytesToSend = (size_t)JOLT_cal->Constant3_Value;
      slrealtime::ip::tcp::Socket* sock = reinterpret_cast<slrealtime::ip::tcp::
        Socket*>(JOLT_DW.TCPSend_PWORK);
      if (!sock)
        return;
      if (enable > 0) {
        bytesSent = sock->send(sendBuf, bytesToSend);
        JOLT_B.TCPSend = (double)bytesSent;
      }
    } catch (std::exception& e) {
      std::string tmp = std::string(e.what());
      static std::string eMsg = tmp;
      rtmSetErrorStatus(JOLT_M, eMsg.c_str());
      rtmSetStopRequested(JOLT_M, 1);
      ;
    }
  }

  /* S-Function (sg_IO191_di_s): '<Root>/Digital input ' */

  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[3];
    sfcnOutputs(rts,0);
  }

  /* RateTransition generated from: '<Root>/Digital input ' */
  JOLT_B.HiddenRateTransitionForToWks_In = JOLT_B.PulseGen1Hz;

  /* Update for Memory: '<Root>/Memory2' */
  std::memcpy(&JOLT_DW.Memory2_PreviousInput[0], &JOLT_B.buffOut[0], 8000U *
              sizeof(real_T));

  /* Update for Memory: '<Root>/Memory1' */
  JOLT_DW.Memory1_PreviousInput = JOLT_B.S_out;

  /* Update for DiscreteFilter: '<Root>/Discrete Filter' */
  JOLT_DW.DiscreteFilter_states[3] = JOLT_DW.DiscreteFilter_states[2];
  JOLT_DW.DiscreteFilter_states[2] = JOLT_DW.DiscreteFilter_states[1];
  JOLT_DW.DiscreteFilter_states[1] = JOLT_DW.DiscreteFilter_states[0];
  JOLT_DW.DiscreteFilter_states[0] = JOLT_DW.DiscreteFilter_tmp;

  /* Update for Delay: '<Root>/Delay' */
  for (int32_T i = 0; i < 549; i++) {
    JOLT_DW.Delay_DSTATE[i] = JOLT_DW.Delay_DSTATE[i + 1];
  }

  JOLT_DW.Delay_DSTATE[549] = JOLT_B.sigPulse_p;

  /* End of Update for Delay: '<Root>/Delay' */

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
    if (!(++JOLT_M->Timing.clockTick1)) {
      ++JOLT_M->Timing.clockTickH1;
    }

    JOLT_M->Timing.t[1] = JOLT_M->Timing.clockTick1 * JOLT_M->Timing.stepSize1 +
      JOLT_M->Timing.clockTickH1 * JOLT_M->Timing.stepSize1 * 4294967296.0;
  }
}

/* Model initialize function */
void JOLT_initialize(void)
{
  /* Registration code */

  /* initialize non-finites */
  rt_InitInfAndNaN(sizeof(real_T));

  {
    /* Setup solver object */
    rtsiSetSimTimeStepPtr(&JOLT_M->solverInfo, &JOLT_M->Timing.simTimeStep);
    rtsiSetTPtr(&JOLT_M->solverInfo, &rtmGetTPtr(JOLT_M));
    rtsiSetStepSizePtr(&JOLT_M->solverInfo, &JOLT_M->Timing.stepSize0);
    rtsiSetErrorStatusPtr(&JOLT_M->solverInfo, (&rtmGetErrorStatus(JOLT_M)));
    rtsiSetRTModelPtr(&JOLT_M->solverInfo, JOLT_M);
  }

  rtsiSetSimTimeStep(&JOLT_M->solverInfo, MAJOR_TIME_STEP);
  rtsiSetSolverName(&JOLT_M->solverInfo,"FixedStepDiscrete");
  JOLT_M->solverInfoPtr = (&JOLT_M->solverInfo);

  /* Initialize timing info */
  {
    int_T *mdlTsMap = JOLT_M->Timing.sampleTimeTaskIDArray;
    mdlTsMap[0] = 0;
    mdlTsMap[1] = 1;

    /* polyspace +2 MISRA2012:D4.1 [Justified:Low] "JOLT_M points to
       static memory which is guaranteed to be non-NULL" */
    JOLT_M->Timing.sampleTimeTaskIDPtr = (&mdlTsMap[0]);
    JOLT_M->Timing.sampleTimes = (&JOLT_M->Timing.sampleTimesArray[0]);
    JOLT_M->Timing.offsetTimes = (&JOLT_M->Timing.offsetTimesArray[0]);

    /* task periods */
    JOLT_M->Timing.sampleTimes[0] = (0.0);
    JOLT_M->Timing.sampleTimes[1] = (0.001);

    /* task offsets */
    JOLT_M->Timing.offsetTimes[0] = (0.0);
    JOLT_M->Timing.offsetTimes[1] = (0.0);
  }

  rtmSetTPtr(JOLT_M, &JOLT_M->Timing.tArray[0]);

  {
    int_T *mdlSampleHits = JOLT_M->Timing.sampleHitArray;
    mdlSampleHits[0] = 1;
    mdlSampleHits[1] = 1;
    JOLT_M->Timing.sampleHits = (&mdlSampleHits[0]);
  }

  rtmSetTFinal(JOLT_M, -1);
  JOLT_M->Timing.stepSize0 = 0.001;
  JOLT_M->Timing.stepSize1 = 0.001;
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
    JOLT_M->Sizes.numSampTimes = (2);
    rtssSetNumRootSampTimesPtr(sfcnInfo, &JOLT_M->Sizes.numSampTimes);
    JOLT_M->NonInlinedSFcns.taskTimePtrs[0] = (&rtmGetTPtr(JOLT_M)[0]);
    JOLT_M->NonInlinedSFcns.taskTimePtrs[1] = (&rtmGetTPtr(JOLT_M)[1]);
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
      sfcnTsMap[0] = 1;

      /* set compiled values of dynamic vector attributes */
      ssSetNumNonsampledZCsAsInt(rts, 0);

      /* Update connectivity flags for each port */
      /* Update the BufferDstPort flags for each input port */
    }

    /* Level2 S-Function Block: JOLT/<Root>/Digital output  (sg_IO191_do_s) */
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

      /* inputs */
      {
        _ssSetNumInputPorts(rts, 15);
        ssSetPortInfoForInputs(rts, &JOLT_M->
          NonInlinedSFcns.Sfcn1.inputPortInfo[0]);
        ssSetPortInfoForInputs(rts, &JOLT_M->
          NonInlinedSFcns.Sfcn1.inputPortInfo[0]);
        _ssSetPortInfo2ForInputUnits(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn1.inputPortUnits[0]);
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
          &JOLT_M->NonInlinedSFcns.Sfcn1.inputPortCoSimAttribute[0]);
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
          ssSetInputPortSignal(rts, 3, &JOLT_B.out_c);
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
          ssSetInputPortSignal(rts, 14, &JOLT_B.sigPulse);
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
          &JOLT_M->NonInlinedSFcns.Sfcn1.params;
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
          &JOLT_M->NonInlinedSFcns.Sfcn1.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &JOLT_M->NonInlinedSFcns.Sfcn1.dWorkAux;
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
      sfcnTsMap[0] = 1;

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

    /* Level2 S-Function Block: JOLT/<Root>/Analog input  (sg_IO191_ad_s) */
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

      /* outputs */
      {
        ssSetPortInfoForOutputs(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn2.outputPortInfo[0]);
        ssSetPortInfoForOutputs(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn2.outputPortInfo[0]);
        _ssSetNumOutputPorts(rts, 2);
        _ssSetPortInfo2ForOutputUnits(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn2.outputPortUnits[0]);
        ssSetOutputPortUnit(rts, 0, 0);
        ssSetOutputPortUnit(rts, 1, 0);
        _ssSetPortInfo2ForOutputCoSimAttribute(rts,
          &JOLT_M->NonInlinedSFcns.Sfcn2.outputPortCoSimAttribute[0]);
        ssSetOutputPortIsContinuousQuantity(rts, 0, 0);
        ssSetOutputPortIsContinuousQuantity(rts, 1, 0);

        /* port 0 */
        {
          _ssSetOutputPortNumDimensions(rts, 0, 1);
          ssSetOutputPortWidthAsInt(rts, 0, 1);
          ssSetOutputPortSignal(rts, 0, ((real_T *) &JOLT_B.monofilData_raw));
        }

        /* port 1 */
        {
          _ssSetOutputPortNumDimensions(rts, 1, 1);
          ssSetOutputPortWidthAsInt(rts, 1, 1);
          ssSetOutputPortSignal(rts, 1, ((real_T *) &JOLT_B.rawMonofilData));
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
          &JOLT_M->NonInlinedSFcns.Sfcn2.params;
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
          &JOLT_M->NonInlinedSFcns.Sfcn2.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &JOLT_M->NonInlinedSFcns.Sfcn2.dWorkAux;
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
      sfcnTsMap[0] = 1;

      /* set compiled values of dynamic vector attributes */
      ssSetNumNonsampledZCsAsInt(rts, 0);

      /* Update connectivity flags for each port */
      _ssSetOutputPortConnected(rts, 0, 1);
      _ssSetOutputPortConnected(rts, 1, 1);
      _ssSetOutputPortBeingMerged(rts, 0, 0);
      _ssSetOutputPortBeingMerged(rts, 1, 0);

      /* Update the BufferDstPort flags for each input port */
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

  /* Start for S-Function (sg_IO191_do_s): '<Root>/Digital output ' */
  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[1];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_ad_s): '<Root>/Analog input ' */
  /* Level2 S-Function Block: '<Root>/Analog input ' (sg_IO191_ad_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[2];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (slrealtimeTCPSend): '<Root>/TCP Send' incorporates:
   *  Constant: '<Root>/Constant3'
   */
  {
    try {
      slrealtime::ip::tcp::Socket* sock = (slrealtime::ip::tcp::Socket*)
        slrealtime::ip::SocketFactory::getSocket("0.0.0.0", 8001U);
      JOLT_DW.TCPSend_PWORK = reinterpret_cast<void*>(sock);
    } catch (std::exception& e) {
      std::string tmp = std::string(e.what());
      static std::string eMsg = tmp;
      rtmSetErrorStatus(JOLT_M, eMsg.c_str());
      rtmSetStopRequested(JOLT_M, 1);
      ;
    }
  }

  /* Start for S-Function (sg_IO191_di_s): '<Root>/Digital input ' */
  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[3];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  {
    int32_T i;

    /* InitializeConditions for Memory: '<Root>/Memory2' */
    for (i = 0; i < 8000; i++) {
      JOLT_DW.Memory2_PreviousInput[i] = JOLT_cal->Memory2_InitialCondition;
    }

    /* End of InitializeConditions for Memory: '<Root>/Memory2' */

    /* InitializeConditions for Memory: '<Root>/Memory1' */
    JOLT_DW.Memory1_PreviousInput = JOLT_cal->Memory1_InitialCondition;

    /* InitializeConditions for DiscretePulseGenerator: '<Root>/Npxls Trig' */
    JOLT_DW.clockTickCounter = 0;

    /* InitializeConditions for DiscreteFilter: '<Root>/Discrete Filter' */
    JOLT_DW.DiscreteFilter_states[0] = JOLT_cal->DiscreteFilter_InitialStates;
    JOLT_DW.DiscreteFilter_states[1] = JOLT_cal->DiscreteFilter_InitialStates;
    JOLT_DW.DiscreteFilter_states[2] = JOLT_cal->DiscreteFilter_InitialStates;
    JOLT_DW.DiscreteFilter_states[3] = JOLT_cal->DiscreteFilter_InitialStates;

    /* InitializeConditions for Delay: '<Root>/Delay' */
    for (i = 0; i < 550; i++) {
      JOLT_DW.Delay_DSTATE[i] = JOLT_cal->Delay_InitialCondition;
    }

    /* End of InitializeConditions for Delay: '<Root>/Delay' */

    /* SystemInitialize for MATLAB Function: '<Root>/MATLAB Function1' */
    JOLT_DW.sfEvent_d = JOLT_CALL_EVENT_l;
    JOLT_DW.is_active_c2_JOLT = 0U;

    /* SystemInitialize for MATLAB Function: '<S6>/MATLAB Function4' */
    JOLT_DW.sfEvent_k = JOLT_CALL_EVENT_l;
    JOLT_DW.t0_not_empty_p = false;
    JOLT_DW.is_active_c4_JOLT = 0U;

    /* SystemInitialize for MATLAB Function: '<S8>/MATLAB Function4' */
    JOLT_MATLABFunction4_Init(&JOLT_DW.sf_MATLABFunction4_d);

    /* SystemInitialize for MATLAB Function: '<S3>/MATLAB Function' */
    JOLT_DW.sfEvent_e = JOLT_CALL_EVENT_l;
    JOLT_DW.is_active_c1_JOLT = 0U;

    /* SystemInitialize for MATLAB Function: '<S7>/MATLAB Function4' */
    JOLT_DW.sfEvent = JOLT_CALL_EVENT_l;
    JOLT_DW.t0_not_empty = false;
    JOLT_DW.is_active_c5_JOLT = 0U;

    /* SystemInitialize for MATLAB Function: '<S1>/MATLAB Function' */
    JOLT_DW.sfEvent_c = JOLT_CALL_EVENT_l;
    JOLT_DW.is_active_c3_JOLT = 0U;

    /* SystemInitialize for MATLAB Function: '<S9>/MATLAB Function4' */
    JOLT_MATLABFunction4_Init(&JOLT_DW.sf_MATLABFunction4_h);

    /* SystemInitialize for MATLAB Function: '<S5>/MATLAB Function' */
    JOLT_DW.sfEvent_m = JOLT_CALL_EVENT_l;
    JOLT_DW.is_active_c8_JOLT = 0U;

    /* SystemInitialize for MATLAB Function: '<S4>/MATLAB Function' */
    JOLT_DW.sfEvent_p = JOLT_CALL_EVENT_l;
    JOLT_DW.is_active_c6_JOLT = 0U;
  }
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

  /* Terminate for S-Function (sg_IO191_do_s): '<Root>/Digital output ' */
  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[1];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_ad_s): '<Root>/Analog input ' */
  /* Level2 S-Function Block: '<Root>/Analog input ' (sg_IO191_ad_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[2];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (slrealtimeTCPSend): '<Root>/TCP Send' incorporates:
   *  Constant: '<Root>/Constant3'
   */
  {
  }

  /* Terminate for S-Function (sg_IO191_di_s): '<Root>/Digital input ' */
  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = JOLT_M->childSfunctions[3];
    sfcnTerminate(rts);
  }
}
