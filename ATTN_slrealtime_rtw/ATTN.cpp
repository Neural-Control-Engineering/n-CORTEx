/*
 * ATTN.cpp
 *
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * Code generation for model "ATTN".
 *
 * Model version              : 1.668
 * Simulink Coder version : 9.9 (R2023a) 19-Nov-2022
 * C++ source code generated on : Sun Feb  4 10:17:36 2024
 *
 * Target selection: slrealtime.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Intel->x86-64 (Linux 64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "ATTN.h"
#include "rtwtypes.h"
#include "ATTN_private.h"
#include "ATTN_cal.h"
#include <cstring>
#include <cmath>
#include <ctime>
#include <stddef.h>

extern "C"
{

#include "rt_nonfinite.h"

}

/* Named constants for MATLAB Function: '<S3>/MATLAB Function2' */
const int32_T ATTN_CALL_EVENT = -1;

/* Named constants for MATLAB Function: '<Root>/MATLAB Function' */
const int32_T ATTN_CALL_EVENT_n = -1;
const real_T ATTN_RGND = 0.0;          /* real_T ground */

/* Block signals (default storage) */
B_ATTN_T ATTN_B;

/* Block states (default storage) */
DW_ATTN_T ATTN_DW;

/* Real-time model */
RT_MODEL_ATTN_T ATTN_M_ = RT_MODEL_ATTN_T();
RT_MODEL_ATTN_T *const ATTN_M = &ATTN_M_;

/* Forward declaration for local functions */
static real_T ATTN_now(void);
static real_T ATTN_mod(real_T x);
static void ATTN_rng(void);
static real_T ATTN_rand(void);

/*
 * System initialize for atomic system:
 *    '<S3>/MATLAB Function2'
 *    '<S4>/MATLAB Function1'
 */
void ATTN_MATLABFunction2_Init(DW_MATLABFunction2_ATTN_T *localDW)
{
  localDW->sfEvent = ATTN_CALL_EVENT;
  localDW->t0_not_empty = false;
  localDW->y0_not_empty = false;
  localDW->is_active_c3_ATTN = 0U;
}

/*
 * Output and update for atomic system:
 *    '<S3>/MATLAB Function2'
 *    '<S4>/MATLAB Function1'
 */
void ATTN_MATLABFunction2(real_T rtu_trigger, real_T rtu_duration, real_T
  rtu_amp, real_T rtu_t, B_MATLABFunction2_ATTN_T *localB,
  DW_MATLABFunction2_ATTN_T *localDW)
{
  real_T increment;
  localDW->sfEvent = ATTN_CALL_EVENT;
  increment = rtu_amp / (rtu_duration * 1000.0 / 2.0);
  if (rtu_trigger != 0.0) {
    localDW->t0 = rtu_t;
    localDW->t0_not_empty = true;
    localB->y = 0.0;
    localDW->y0 = 0.0;
    localDW->y0_not_empty = true;
  } else if (localDW->t0_not_empty) {
    real_T tmp;
    tmp = rtu_t - localDW->t0;
    if (tmp <= rtu_duration / 2.0) {
      localB->y = localDW->y0 + increment;
      localDW->y0 = localB->y;
    } else if (tmp <= rtu_duration) {
      localB->y = localDW->y0 - increment;
      increment = localB->y;
      if (increment > 0.0) {
        localB->y = increment;
      } else {
        localB->y = 0.0;
      }

      localDW->y0 = localB->y;
    } else {
      localB->y = 0.0;
    }
  } else {
    localB->y = 0.0;
  }
}

/* Function for MATLAB Function: '<Root>/MATLAB Function' */
static real_T ATTN_now(void)
{
  std::time_t rawtime;
  std::tm expl_temp;
  real_T dDateNum;
  int32_T timeinfo_tm_hour;
  int32_T timeinfo_tm_mday;
  int32_T timeinfo_tm_min;
  int32_T timeinfo_tm_mon;
  int32_T timeinfo_tm_sec;
  int32_T timeinfo_tm_year;
  int16_T cDaysMonthWise[12];
  cDaysMonthWise[0] = 0;
  cDaysMonthWise[1] = 31;
  cDaysMonthWise[2] = 59;
  cDaysMonthWise[3] = 90;
  cDaysMonthWise[4] = 120;
  cDaysMonthWise[5] = 151;
  cDaysMonthWise[6] = 181;
  cDaysMonthWise[7] = 212;
  cDaysMonthWise[8] = 243;
  cDaysMonthWise[9] = 273;
  cDaysMonthWise[10] = 304;
  cDaysMonthWise[11] = 334;
  std::time(&rawtime);
  expl_temp = *std::localtime(&rawtime);
  timeinfo_tm_min = expl_temp.tm_min;
  timeinfo_tm_sec = expl_temp.tm_sec;
  timeinfo_tm_hour = expl_temp.tm_hour;
  timeinfo_tm_mday = expl_temp.tm_mday;
  timeinfo_tm_mon = expl_temp.tm_mon + 1;
  timeinfo_tm_year = expl_temp.tm_year + 1900;
  dDateNum = ((((365.0 * static_cast<real_T>(timeinfo_tm_year) + std::ceil(
    static_cast<real_T>(timeinfo_tm_year) / 4.0)) - std::ceil(static_cast<real_T>
    (timeinfo_tm_year) / 100.0)) + std::ceil(static_cast<real_T>
    (timeinfo_tm_year) / 400.0)) + static_cast<real_T>
              (cDaysMonthWise[timeinfo_tm_mon - 1])) + static_cast<real_T>
    (timeinfo_tm_mday);
  if (timeinfo_tm_mon > 2) {
    boolean_T guard1;
    if (timeinfo_tm_year == 0) {
      timeinfo_tm_mday = 0;
    } else {
      timeinfo_tm_mday = static_cast<int32_T>(std::fmod(static_cast<real_T>
        (timeinfo_tm_year), 4.0));
      if ((timeinfo_tm_mday != 0) && (timeinfo_tm_year < 0)) {
        timeinfo_tm_mday += 4;
      }
    }

    guard1 = false;
    if (timeinfo_tm_mday == 0) {
      if (timeinfo_tm_year != 0) {
        timeinfo_tm_mday = static_cast<int32_T>(std::fmod(static_cast<real_T>
          (timeinfo_tm_year), 100.0));
        if ((timeinfo_tm_mday != 0) && (timeinfo_tm_year < 0)) {
          timeinfo_tm_mday += 100;
        }
      }

      if (timeinfo_tm_mday != 0) {
        dDateNum++;
      } else {
        guard1 = true;
      }
    } else {
      guard1 = true;
    }

    if (guard1) {
      if (timeinfo_tm_year == 0) {
        timeinfo_tm_mday = 0;
      } else {
        timeinfo_tm_mday = static_cast<int32_T>(std::fmod(static_cast<real_T>
          (timeinfo_tm_year), 400.0));
        if ((timeinfo_tm_mday != 0) && (timeinfo_tm_year < 0)) {
          timeinfo_tm_mday += 400;
        }
      }

      if (timeinfo_tm_mday == 0) {
        dDateNum++;
      }
    }
  }

  return ((static_cast<real_T>(timeinfo_tm_hour) * 3600.0 + static_cast<real_T>
           (timeinfo_tm_min) * 60.0) + static_cast<real_T>(timeinfo_tm_sec)) /
    86400.0 + dDateNum;
}

/* Function for MATLAB Function: '<Root>/MATLAB Function' */
static real_T ATTN_mod(real_T x)
{
  real_T r;
  if (rtIsNaN(x) || rtIsInf(x)) {
    r = (rtNaN);
  } else if (x == 0.0) {
    r = 0.0;
  } else {
    r = std::fmod(x, 2.147483647E+9);
    if (r == 0.0) {
      r = 0.0;
    } else if (x < 0.0) {
      r += 2.147483647E+9;
    }
  }

  return r;
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

/* Function for MATLAB Function: '<Root>/MATLAB Function' */
static void ATTN_rng(void)
{
  std::time_t b_eTime;
  std::time_t eTime;
  real_T b_y;
  real_T y;
  int32_T b_r;
  int32_T exitg1;
  int32_T t;
  uint32_T r;
  y = ATTN_now() * 8.64E+6;
  y = std::floor(y);
  y = ATTN_mod(y);
  eTime = std::time(NULL);
  do {
    exitg1 = 0;
    b_eTime = std::time(NULL);
    if ((int32_T)b_eTime <= (int32_T)eTime + 1) {
      b_y = ATTN_now() * 8.64E+6;
      b_y = std::floor(b_y);
      if (y != ATTN_mod(b_y)) {
        exitg1 = 1;
      }
    } else {
      exitg1 = 1;
    }
  } while (exitg1 == 0);

  y = rt_roundd_snf(y);
  if (y < 4.294967296E+9) {
    if (y >= 0.0) {
      r = static_cast<uint32_T>(y);
    } else {
      r = 0U;
    }
  } else {
    r = MAX_uint32_T;
  }

  ATTN_DW.seed = r;
  if (ATTN_DW.method == 7U) {
    r = ATTN_DW.seed;
    ATTN_DW.state[0] = ATTN_DW.seed;
    for (b_r = 0; b_r < 623; b_r++) {
      r = ((r >> 30U ^ r) * 1812433253U + static_cast<uint32_T>(b_r)) + 1U;
      ATTN_DW.state[b_r + 1] = r;
    }

    ATTN_DW.state[624] = 624U;
  } else if (ATTN_DW.method == 5U) {
    ATTN_DW.state_k[0] = 362436069U;
    ATTN_DW.state_k[1] = ATTN_DW.seed;
    if (ATTN_DW.state_k[1] == 0U) {
      ATTN_DW.state_k[1] = 521288629U;
    }
  } else if (ATTN_DW.method == 4U) {
    b_r = static_cast<int32_T>(ATTN_DW.seed >> 16U);
    t = static_cast<int32_T>(ATTN_DW.seed & 32768U);
    r = ((((ATTN_DW.seed - (static_cast<uint32_T>(b_r) << 16U)) -
           static_cast<uint32_T>(t)) << 16U) + static_cast<uint32_T>(t)) +
      static_cast<uint32_T>(b_r);
    if (r < 1U) {
      r = 1144108930U;
    } else if (r > 2147483646U) {
      r = 2147483646U;
    }

    ATTN_DW.state_j = r;
  }
}

/* Function for MATLAB Function: '<Root>/MATLAB Function' */
static real_T ATTN_rand(void)
{
  real_T r;
  uint32_T u[2];
  if (ATTN_DW.method == 4U) {
    int32_T k;
    uint32_T mti;
    uint32_T y;
    k = static_cast<int32_T>(ATTN_DW.state_j / 127773U);
    mti = (ATTN_DW.state_j - static_cast<uint32_T>(k) * 127773U) * 16807U;
    y = 2836U * static_cast<uint32_T>(k);
    if (mti < y) {
      mti = ~(y - mti) & 2147483647U;
    } else {
      mti -= y;
    }

    r = static_cast<real_T>(mti) * 4.6566128752457969E-10;
    ATTN_DW.state_j = mti;
  } else if (ATTN_DW.method == 5U) {
    uint32_T mti;
    uint32_T y;
    mti = 69069U * ATTN_DW.state_k[0] + 1234567U;
    y = ATTN_DW.state_k[1] << 13 ^ ATTN_DW.state_k[1];
    y ^= y >> 17;
    y ^= y << 5;
    ATTN_DW.state_k[0] = mti;
    ATTN_DW.state_k[1] = y;
    r = static_cast<real_T>(mti + y) * 2.328306436538696E-10;
  } else {
    /* ========================= COPYRIGHT NOTICE ============================ */
    /*  This is a uniform (0,1) pseudorandom number generator based on:        */
    /*                                                                         */
    /*  A C-program for MT19937, with initialization improved 2002/1/26.       */
    /*  Coded by Takuji Nishimura and Makoto Matsumoto.                        */
    /*                                                                         */
    /*  Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura,      */
    /*  All rights reserved.                                                   */
    /*                                                                         */
    /*  Redistribution and use in source and binary forms, with or without     */
    /*  modification, are permitted provided that the following conditions     */
    /*  are met:                                                               */
    /*                                                                         */
    /*    1. Redistributions of source code must retain the above copyright    */
    /*       notice, this list of conditions and the following disclaimer.     */
    /*                                                                         */
    /*    2. Redistributions in binary form must reproduce the above copyright */
    /*       notice, this list of conditions and the following disclaimer      */
    /*       in the documentation and/or other materials provided with the     */
    /*       distribution.                                                     */
    /*                                                                         */
    /*    3. The names of its contributors may not be used to endorse or       */
    /*       promote products derived from this software without specific      */
    /*       prior written permission.                                         */
    /*                                                                         */
    /*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    */
    /*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      */
    /*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  */
    /*  A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT  */
    /*  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,  */
    /*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       */
    /*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  */
    /*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  */
    /*  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    */
    /*  (INCLUDING  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE */
    /*  OF THIS  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  */
    /*                                                                         */
    /* =============================   END   ================================= */
    int32_T exitg1;
    do {
      int32_T k;
      uint32_T mti;
      exitg1 = 0;
      for (k = 0; k < 2; k++) {
        uint32_T y;
        mti = ATTN_DW.state[624] + 1U;
        if (mti >= 625U) {
          for (int32_T kk = 0; kk < 227; kk++) {
            mti = (ATTN_DW.state[kk + 1] & 2147483647U) | (ATTN_DW.state[kk] &
              2147483648U);
            if ((mti & 1U) == 0U) {
              mti >>= 1U;
            } else {
              mti = mti >> 1U ^ 2567483615U;
            }

            ATTN_DW.state[kk] = ATTN_DW.state[kk + 397] ^ mti;
          }

          for (int32_T kk = 0; kk < 396; kk++) {
            mti = (ATTN_DW.state[kk + 227] & 2147483648U) | (ATTN_DW.state[kk +
              228] & 2147483647U);
            if ((mti & 1U) == 0U) {
              mti >>= 1U;
            } else {
              mti = mti >> 1U ^ 2567483615U;
            }

            ATTN_DW.state[kk + 227] = ATTN_DW.state[kk] ^ mti;
          }

          mti = (ATTN_DW.state[623] & 2147483648U) | (ATTN_DW.state[0] &
            2147483647U);
          if ((mti & 1U) == 0U) {
            mti >>= 1U;
          } else {
            mti = mti >> 1U ^ 2567483615U;
          }

          ATTN_DW.state[623] = ATTN_DW.state[396] ^ mti;
          mti = 1U;
        }

        y = ATTN_DW.state[static_cast<int32_T>(mti) - 1];
        ATTN_DW.state[624] = mti;
        y ^= y >> 11U;
        y ^= y << 7U & 2636928640U;
        y ^= y << 15U & 4022730752U;
        u[k] = y >> 18U ^ y;
      }

      r = (static_cast<real_T>(u[0] >> 5U) * 6.7108864E+7 + static_cast<real_T>
           (u[1] >> 6U)) * 1.1102230246251565E-16;
      if (r == 0.0) {
        boolean_T b_isvalid;
        if ((ATTN_DW.state[624] >= 1U) && (ATTN_DW.state[624] < 625U)) {
          boolean_T exitg2;
          b_isvalid = false;
          k = 1;
          exitg2 = false;
          while ((!exitg2) && (k < 625)) {
            if (ATTN_DW.state[k - 1] == 0U) {
              k++;
            } else {
              b_isvalid = true;
              exitg2 = true;
            }
          }
        } else {
          b_isvalid = false;
        }

        if (!b_isvalid) {
          mti = 5489U;
          ATTN_DW.state[0] = 5489U;
          for (k = 0; k < 623; k++) {
            mti = ((mti >> 30U ^ mti) * 1812433253U + static_cast<uint32_T>(k))
              + 1U;
            ATTN_DW.state[k + 1] = mti;
          }

          ATTN_DW.state[624] = 624U;
        }
      } else {
        exitg1 = 1;
      }
    } while (exitg1 == 0);
  }

  return r;
}

/* Model step function */
void ATTN_step(void)
{
  real_T ADIn;
  real_T b_y1;

  /* Memory: '<Root>/Memory8' */
  ATTN_B.Memory8 = ATTN_DW.Memory8_PreviousInput;

  /* Memory: '<Root>/Memory2' */
  ATTN_B.Memory2 = ATTN_DW.Memory2_PreviousInput;

  /* Memory: '<Root>/Memory1' */
  ATTN_B.Memory1 = ATTN_DW.Memory1_PreviousInput;

  /* Memory: '<Root>/Memory' */
  ATTN_B.Memory = ATTN_DW.Memory_PreviousInput;

  /* S-Function (sg_IO191_setup_s): '<Root>/Setup ' */

  /* Level2 S-Function Block: '<Root>/Setup ' (sg_IO191_setup_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[0];
    sfcnOutputs(rts,0);
  }

  /* S-Function (sg_IO191_ad_s): '<Root>/Analog input ' */

  /* Level2 S-Function Block: '<Root>/Analog input ' (sg_IO191_ad_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[1];
    sfcnOutputs(rts,0);
  }

  /* Memory: '<Root>/Memory11' */
  ATTN_B.Memory11 = ATTN_DW.Memory11_PreviousInput;

  /* Memory: '<Root>/Memory7' */
  ATTN_B.Memory7 = ATTN_DW.Memory7_PreviousInput;

  /* MATLAB Function: '<Root>/MATLAB Function1' incorporates:
   *  Constant: '<Root>/Constant1'
   *  Constant: '<Root>/Thrd'
   */
  ATTN_DW.sfEvent_b = ATTN_CALL_EVENT_n;
  ADIn = std::abs(ATTN_B.lickometer_piezo - ATTN_cal->Constant1_Value);
  if (ADIn > ATTN_cal->Thrd_Value) {
    b_y1 = ATTN_B.Memory11 + 1.0;
    ATTN_B.y2 = ATTN_B.Memory7;
  } else {
    b_y1 = 0.0;
    ATTN_B.y2 = 0.0;
  }

  if (((b_y1 > 5.0) && (ATTN_B.Memory7 == 0.0)) || (ADIn > 0.0205)) {
    ATTN_B.Lick = 1.0;
    ATTN_B.y2 = 1.0;
  } else {
    ATTN_B.Lick = 0.0;
  }

  ATTN_B.ADOut = ADIn;
  ATTN_B.y1 = b_y1;

  /* End of MATLAB Function: '<Root>/MATLAB Function1' */

  /* Clock: '<Root>/Clock' */
  ATTN_B.clock_time = ATTN_M->Timing.t[0];

  /* Memory: '<Root>/Memory3' */
  ATTN_B.Memory3 = ATTN_DW.Memory3_PreviousInput;

  /* Memory: '<Root>/Memory4' */
  ATTN_B.Memory4 = ATTN_DW.Memory4_PreviousInput;

  /* Memory: '<Root>/Memory9' */
  ATTN_B.Memory9 = ATTN_DW.Memory9_PreviousInput;

  /* Memory: '<Root>/Memory5' */
  ATTN_B.Memory5 = ATTN_DW.Memory5_PreviousInput;

  /* Memory: '<Root>/Memory6' */
  ATTN_B.Memory6 = ATTN_DW.Memory6_PreviousInput;

  /* Memory: '<Root>/Memory10' */
  ATTN_B.Memory10 = ATTN_DW.Memory10_PreviousInput;

  /* Constant: '<Root>/swtichTime' */
  ATTN_B.swtichTime = ATTN_cal->switchTime;

  /* Constant: '<Root>/trainingStage' */
  ATTN_B.trainingStage = ATTN_cal->trainingStage;

  /* MATLAB Function: '<Root>/MATLAB Function' incorporates:
   *  Constant: '<Root>/rewardDuration'
   *  Constant: '<Root>/targetSide'
   *  Constant: '<Root>/triangleDuration'
   */
  ATTN_DW.sfEvent_e = ATTN_CALL_EVENT_n;
  ATTN_B.counter_out = ATTN_B.Memory4 + 1.0;
  switch (static_cast<int32_T>(ATTN_B.trainingStage)) {
   case 1:
    switch (static_cast<int32_T>(ATTN_B.Memory2)) {
     case 0:
      ATTN_rng();
      ATTN_B.state_out = 1.0;
      ATTN_B.npxlsAcq_out = 2.5;
      ATTN_B.localTime_out = 1.0;
      ATTN_B.trialNum_out = 0.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ADIn = 0.0;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 1:
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.state_out = 2.0;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = 1.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ADIn = 0.0;
      b_y1 = 4.0;
      while ((b_y1 >= 9.0) || (b_y1 <= 5.0)) {
        b_y1 = ATTN_rand();
        b_y1 = std::log(b_y1);
        b_y1 *= -7.0;
      }

      ATTN_B.delay_out = ATTN_B.clock_time + b_y1;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 2:
      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
      } else {
        ATTN_B.state_out = 3.0;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ADIn = ATTN_B.Memory9;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 3:
      if (ATTN_rand() <= 0.6) {
        if (ATTN_cal->targetSide != 0.0) {
          ATTN_B.right_trigger_out = 1.0;
          ATTN_B.left_trigger_out = 0.0;
        } else {
          ATTN_B.left_trigger_out = 1.0;
          ATTN_B.right_trigger_out = 0.0;
        }

        ATTN_B.was_target_out = 0.0;
      } else {
        if (ATTN_cal->targetSide != 0.0) {
          ATTN_B.left_trigger_out = 1.0;
          ATTN_B.right_trigger_out = 0.0;
        } else {
          ATTN_B.right_trigger_out = 1.0;
          ATTN_B.left_trigger_out = 0.0;
        }

        ATTN_B.was_target_out = 1.0;
      }

      ATTN_B.state_out = 4.0;
      ATTN_B.delay_out = ATTN_B.clock_time + 0.2;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 4:
      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
        ATTN_B.delay_out = ATTN_B.Memory5;
      } else if (ATTN_B.Memory10 != 0.0) {
        ATTN_B.state_out = 5.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 1.0;
      } else {
        ATTN_B.state_out = 6.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 1.0;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.left_trigger_out = 0.0;
      ATTN_B.right_trigger_out = 0.0;
      ADIn = ATTN_B.Memory9;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 5:
      ATTN_B.reward_trigger_out = 1.0;
      ATTN_B.state_out = 6.0;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 6:
      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
      } else {
        ATTN_B.state_out = 1.0;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     default:
      ATTN_B.state_out = ATTN_B.Memory2;
      ATTN_B.localTime_out = ATTN_B.Memory1;
      ATTN_B.trialNum_out = ATTN_B.Memory;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ADIn = ATTN_B.Memory9;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;
    }
    break;

   case 2:
    switch (static_cast<int32_T>(ATTN_B.Memory2)) {
     case 0:
      ATTN_rng();
      ATTN_B.state_out = 1.0;
      ATTN_B.npxlsAcq_out = 2.5;
      ATTN_B.localTime_out = 1.0;
      ATTN_B.trialNum_out = 0.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ADIn = 0.0;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 1:
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.state_out = 2.0;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = 1.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ADIn = 0.0;
      b_y1 = 7.0;
      while ((b_y1 >= 12.0) || (b_y1 <= 8.0)) {
        b_y1 = ATTN_rand();
        b_y1 = std::log(b_y1);
        b_y1 *= -10.0;
      }

      ATTN_B.delay_out = ATTN_B.clock_time + b_y1;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 2:
      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
      } else {
        ATTN_B.state_out = 3.0;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ADIn = ATTN_B.Memory9;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 3:
      if (ATTN_rand() <= 0.6) {
        if (ATTN_cal->targetSide != 0.0) {
          ATTN_B.right_trigger_out = 1.0;
          ATTN_B.left_trigger_out = 0.0;
        } else {
          ATTN_B.left_trigger_out = 1.0;
          ATTN_B.right_trigger_out = 0.0;
        }

        ATTN_B.was_target_out = 0.0;
      } else {
        if (ATTN_cal->targetSide != 0.0) {
          ATTN_B.left_trigger_out = 1.0;
          ATTN_B.right_trigger_out = 0.0;
        } else {
          ATTN_B.right_trigger_out = 1.0;
          ATTN_B.left_trigger_out = 0.0;
        }

        ATTN_B.was_target_out = 1.0;
      }

      ATTN_B.state_out = 4.0;
      ATTN_B.delay_out = ATTN_B.clock_time + 0.2;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 4:
      if (ATTN_B.Lick != 0.0) {
        ADIn = ATTN_B.Memory9 + 1.0;
      } else {
        ADIn = ATTN_B.Memory9;
      }

      if (ADIn != 0.0) {
        ATTN_B.state_out = 7.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 2.0;
      } else if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
        ATTN_B.delay_out = ATTN_B.Memory5;
      } else {
        ATTN_B.state_out = 5.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 1.5;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 5:
      if (ATTN_B.Lick != 0.0) {
        ADIn = ATTN_B.Memory9 + 1.0;
      } else {
        ADIn = ATTN_B.Memory9;
      }

      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
        ATTN_B.delay_out = ATTN_B.Memory5;
      } else if ((ADIn != 0.0) && (ATTN_B.Memory10 != 0.0)) {
        ATTN_B.state_out = 6.0;
        ATTN_B.delay_out = ATTN_B.Memory5;
      } else {
        ATTN_B.state_out = 7.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 0.5;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 6:
      ATTN_B.reward_trigger_out = 1.0;
      ATTN_B.state_out = 7.0;
      ATTN_B.delay_out = ATTN_B.clock_time + 0.5;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 7:
      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
      } else {
        ATTN_B.state_out = 1.0;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ADIn = ATTN_B.Memory9;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     default:
      ATTN_B.state_out = ATTN_B.Memory2;
      ATTN_B.localTime_out = ATTN_B.Memory1;
      ATTN_B.trialNum_out = ATTN_B.Memory;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ADIn = ATTN_B.Memory9;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;
    }
    break;

   case 3:
    switch (static_cast<int32_T>(ATTN_B.Memory2)) {
     case 0:
      ATTN_rng();
      ATTN_B.state_out = 1.0;
      ATTN_B.npxlsAcq_out = 2.5;
      ATTN_B.localTime_out = 1.0;
      ATTN_B.trialNum_out = 0.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ADIn = 0.0;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 1:
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.state_out = 2.0;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = 1.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      if ((!(ATTN_B.Memory10 != 0.0)) && (!(ATTN_B.Memory9 != 0.0))) {
        ADIn = 3.0;
        while ((ADIn >= 6.0) || (ADIn <= 4.0)) {
          ADIn = ATTN_rand();
          ADIn = std::log(ADIn);
          ADIn *= -5.0;
        }

        ATTN_B.delay_out = ATTN_B.clock_time + ADIn;
      } else {
        ADIn = 7.0;
        while ((ADIn >= 12.0) || (ADIn <= 8.0)) {
          ADIn = ATTN_rand();
          ADIn = std::log(ADIn);
          ADIn *= -10.0;
        }

        ATTN_B.delay_out = ATTN_B.clock_time + ADIn;
      }

      ADIn = 0.0;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 2:
      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
      } else {
        ATTN_B.state_out = 3.0;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ADIn = ATTN_B.Memory9;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 3:
      if (ATTN_rand() <= 0.7) {
        if (ATTN_cal->targetSide != 0.0) {
          ATTN_B.right_trigger_out = 1.0;
          ATTN_B.left_trigger_out = 0.0;
        } else {
          ATTN_B.left_trigger_out = 1.0;
          ATTN_B.right_trigger_out = 0.0;
        }

        ATTN_B.was_target_out = 0.0;
      } else {
        if (ATTN_cal->targetSide != 0.0) {
          ATTN_B.left_trigger_out = 1.0;
          ATTN_B.right_trigger_out = 0.0;
        } else {
          ATTN_B.right_trigger_out = 1.0;
          ATTN_B.left_trigger_out = 0.0;
        }

        ATTN_B.was_target_out = 1.0;
      }

      ATTN_B.state_out = 4.0;
      ATTN_B.delay_out = ATTN_B.clock_time + 0.2;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 4:
      if (ATTN_B.Lick != 0.0) {
        ADIn = ATTN_B.Memory9 + 1.0;
      } else {
        ADIn = ATTN_B.Memory9;
      }

      if (ADIn != 0.0) {
        ATTN_B.state_out = 7.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 1.5;
      } else if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
        ATTN_B.delay_out = ATTN_B.Memory5;
      } else {
        ATTN_B.state_out = 5.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 1.0;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 5:
      if (ATTN_B.Lick != 0.0) {
        ADIn = ATTN_B.Memory9 + 1.0;
      } else {
        ADIn = ATTN_B.Memory9;
      }

      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
        ATTN_B.delay_out = ATTN_B.Memory5;
      } else if ((ADIn != 0.0) && (ATTN_B.Memory10 != 0.0)) {
        ATTN_B.state_out = 6.0;
        ATTN_B.delay_out = ATTN_B.Memory5;
      } else {
        ATTN_B.state_out = 7.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 0.5;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 6:
      ATTN_B.reward_trigger_out = 1.0;
      ATTN_B.state_out = 7.0;
      ATTN_B.delay_out = ATTN_B.clock_time + 0.5;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 7:
      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
      } else {
        ATTN_B.state_out = 1.0;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ADIn = ATTN_B.Memory9;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     default:
      ATTN_B.state_out = ATTN_B.Memory2;
      ATTN_B.localTime_out = ATTN_B.Memory1;
      ATTN_B.trialNum_out = ATTN_B.Memory;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ADIn = ATTN_B.Memory9;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;
    }
    break;

   case 4:
    switch (static_cast<int32_T>(ATTN_B.Memory2)) {
     case 0:
      ATTN_rng();
      ATTN_B.state_out = 1.0;
      ATTN_B.npxlsAcq_out = 2.5;
      ATTN_B.localTime_out = 1.0;
      ATTN_B.trialNum_out = 0.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ADIn = 0.0;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 1:
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.state_out = 2.0;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = 1.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      if ((!(ATTN_B.Memory10 != 0.0)) && (!(ATTN_B.Memory9 != 0.0))) {
        ADIn = 3.0;
        while ((ADIn >= 6.0) || (ADIn <= 4.0)) {
          ADIn = ATTN_rand();
          ADIn = std::log(ADIn);
          ADIn *= -5.0;
        }

        ATTN_B.delay_out = ATTN_B.clock_time + ADIn;
      } else {
        ADIn = 7.0;
        while ((ADIn >= 12.0) || (ADIn <= 8.0)) {
          ADIn = ATTN_rand();
          ADIn = std::log(ADIn);
          ADIn *= -10.0;
        }

        ATTN_B.delay_out = ATTN_B.clock_time + ADIn;
      }

      ADIn = 0.0;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 2:
      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
      } else {
        ATTN_B.state_out = 3.0;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ADIn = ATTN_B.Memory9;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 3:
      if (ATTN_B.clock_time < ATTN_B.swtichTime * 60.0) {
        if (ATTN_rand() <= 0.6) {
          if (ATTN_cal->targetSide != 0.0) {
            ATTN_B.right_trigger_out = 1.0;
            ATTN_B.left_trigger_out = 0.0;
          } else {
            ATTN_B.left_trigger_out = 1.0;
            ATTN_B.right_trigger_out = 0.0;
          }

          ATTN_B.was_target_out = 0.0;
        } else {
          if (ATTN_cal->targetSide != 0.0) {
            ATTN_B.left_trigger_out = 1.0;
            ATTN_B.right_trigger_out = 0.0;
          } else {
            ATTN_B.right_trigger_out = 1.0;
            ATTN_B.left_trigger_out = 0.0;
          }

          ATTN_B.was_target_out = 1.0;
        }
      } else if (ATTN_rand() <= 0.6) {
        if (ATTN_cal->targetSide != 0.0) {
          ATTN_B.left_trigger_out = 1.0;
          ATTN_B.right_trigger_out = 0.0;
        } else {
          ATTN_B.right_trigger_out = 1.0;
          ATTN_B.left_trigger_out = 0.0;
        }

        ATTN_B.was_target_out = 0.0;
      } else {
        if (ATTN_cal->targetSide != 0.0) {
          ATTN_B.right_trigger_out = 1.0;
          ATTN_B.left_trigger_out = 0.0;
        } else {
          ATTN_B.left_trigger_out = 1.0;
          ATTN_B.right_trigger_out = 0.0;
        }

        ATTN_B.was_target_out = 1.0;
      }

      ATTN_B.state_out = 4.0;
      ATTN_B.delay_out = ATTN_B.clock_time + 0.2;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 4:
      if (ATTN_B.Lick != 0.0) {
        ADIn = ATTN_B.Memory9 + 1.0;
      } else {
        ADIn = ATTN_B.Memory9;
      }

      if (ADIn != 0.0) {
        ATTN_B.state_out = 7.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 1.5;
      } else if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
        ATTN_B.delay_out = ATTN_B.Memory5;
      } else {
        ATTN_B.state_out = 5.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 1.0;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 5:
      if (ATTN_B.Lick != 0.0) {
        ADIn = ATTN_B.Memory9 + 1.0;
      } else {
        ADIn = ATTN_B.Memory9;
      }

      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
        ATTN_B.delay_out = ATTN_B.Memory5;
      } else if ((ADIn != 0.0) && (ATTN_B.Memory10 != 0.0)) {
        ATTN_B.state_out = 6.0;
        ATTN_B.delay_out = ATTN_B.Memory5;
      } else {
        ATTN_B.state_out = 7.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 0.5;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 6:
      ATTN_B.reward_trigger_out = 1.0;
      ATTN_B.state_out = 7.0;
      ATTN_B.delay_out = ATTN_B.clock_time + 0.5;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 7:
      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
      } else {
        ATTN_B.state_out = 1.0;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ADIn = ATTN_B.Memory9;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     default:
      ATTN_B.state_out = ATTN_B.Memory2;
      ATTN_B.localTime_out = ATTN_B.Memory1;
      ATTN_B.trialNum_out = ATTN_B.Memory;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ADIn = ATTN_B.Memory9;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;
    }
    break;

   case 111:
    switch (static_cast<int32_T>(ATTN_B.Memory2)) {
     case 0:
      ATTN_rng();
      ATTN_B.state_out = 1.0;
      ATTN_B.npxlsAcq_out = 0.0;
      ATTN_B.localTime_out = 1.0;
      ATTN_B.trialNum_out = 1.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ADIn = 0.0;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 1:
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = 1.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ATTN_B.delay_out = ATTN_B.clock_time + 1.0;
      ADIn = 0.0;
      ATTN_B.reward_trigger_out = 1.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = 0.03;
      ATTN_B.state_out = 2.0;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     default:
      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
        ATTN_B.reward_trigger_out = 0.0;
        ATTN_B.delay_out = ATTN_B.Memory5;
        ATTN_B.reward_duration_out = 0.03;
      } else {
        ATTN_B.state_out = ATTN_B.Memory2 + 1.0;
        ATTN_B.reward_trigger_out = 1.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 1.0;
        ATTN_B.reward_duration_out = 0.03;
      }

      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.left_trigger_out = ATTN_B.Memory6;
      ATTN_B.right_trigger_out = ATTN_B.Memory8;
      ADIn = ATTN_B.Memory9;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;
    }
    break;

   case 222:
    switch (static_cast<int32_T>(ATTN_B.Memory2)) {
     case 0:
      ATTN_rng();
      ATTN_B.state_out = 1.0;
      ATTN_B.npxlsAcq_out = 0.0;
      ATTN_B.localTime_out = 1.0;
      ATTN_B.trialNum_out = 1.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ADIn = 0.0;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 1:
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = 1.0;
      if (ATTN_cal->targetSide != 0.0) {
        ATTN_B.left_trigger_out = 1.0;
        ATTN_B.right_trigger_out = 0.0;
      } else {
        ATTN_B.right_trigger_out = 1.0;
        ATTN_B.left_trigger_out = 0.0;
      }

      ATTN_B.delay_out = ATTN_B.clock_time + 1.0;
      ADIn = 0.0;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.state_out = 2.0;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     default:
      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
        ATTN_B.delay_out = ATTN_B.Memory5;
        ATTN_B.left_trigger_out = 0.0;
        ATTN_B.right_trigger_out = 0.0;
      } else {
        ATTN_B.state_out = ATTN_B.Memory2 + 1.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 1.0;
        if (ATTN_cal->targetSide != 0.0) {
          ATTN_B.left_trigger_out = 1.0;
          ATTN_B.right_trigger_out = 0.0;
        } else {
          ATTN_B.right_trigger_out = 1.0;
          ATTN_B.left_trigger_out = 0.0;
        }
      }

      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;
    }
    break;

   default:
    switch (static_cast<int32_T>(ATTN_B.Memory2)) {
     case 0:
      ATTN_rng();
      ATTN_B.state_out = 1.0;
      ATTN_B.npxlsAcq_out = 0.0;
      ATTN_B.localTime_out = 1.0;
      ATTN_B.trialNum_out = 1.0;
      ATTN_B.right_trigger_out = 0.0;
      ATTN_B.left_trigger_out = 0.0;
      ADIn = 0.0;
      ATTN_B.delay_out = ATTN_B.Memory5;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.stim_duration_out = ATTN_cal->triangleDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     case 1:
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = 1.0;
      if (ATTN_cal->targetSide != 0.0) {
        ATTN_B.right_trigger_out = 1.0;
        ATTN_B.left_trigger_out = 0.0;
      } else {
        ATTN_B.left_trigger_out = 1.0;
        ATTN_B.right_trigger_out = 0.0;
      }

      ATTN_B.delay_out = ATTN_B.clock_time + 10.0;
      ADIn = 0.0;
      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.was_target_out = 0.0;
      ATTN_B.stim_duration_out = 0.05;
      ATTN_B.state_out = 2.0;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;

     default:
      if (ATTN_B.clock_time < ATTN_B.Memory5) {
        ATTN_B.state_out = ATTN_B.Memory2;
        ATTN_B.delay_out = ATTN_B.Memory5;
        ATTN_B.left_trigger_out = 0.0;
        ATTN_B.right_trigger_out = 0.0;
        ATTN_B.stim_duration_out = (ATTN_B.Memory2 - 1.0) * 0.05;
      } else {
        ATTN_B.state_out = ATTN_B.Memory2 + 1.0;
        ATTN_B.delay_out = ATTN_B.clock_time + 10.0;
        if (ATTN_cal->targetSide != 0.0) {
          ATTN_B.right_trigger_out = 1.0;
          ATTN_B.left_trigger_out = 0.0;
        } else {
          ATTN_B.left_trigger_out = 1.0;
          ATTN_B.right_trigger_out = 0.0;
        }

        ATTN_B.stim_duration_out = 0.05 * ATTN_B.Memory2;
      }

      ATTN_B.reward_trigger_out = 0.0;
      ATTN_B.localTime_out = ATTN_B.Memory1 + 1.0;
      ATTN_B.trialNum_out = ATTN_B.Memory + 1.0;
      ATTN_B.npxlsAcq_out = ATTN_B.Memory3;
      ADIn = ATTN_B.Memory9;
      ATTN_B.was_target_out = ATTN_B.Memory10;
      ATTN_B.reward_duration_out = ATTN_cal->rewardDuration;
      ATTN_B.onsetTone_trig = 0.0;
      break;
    }
    break;
  }

  ATTN_B.numLicks_out = ADIn;

  /* End of MATLAB Function: '<Root>/MATLAB Function' */

  /* Clock: '<S4>/Clock1' */
  ATTN_B.Clock1 = ATTN_M->Timing.t[0];

  /* MATLAB Function: '<S4>/MATLAB Function1' incorporates:
   *  Constant: '<Root>/triangleAmplitude'
   */
  ATTN_MATLABFunction2(ATTN_B.Memory8, ATTN_B.stim_duration_out,
                       ATTN_cal->triangleAmplitude, ATTN_B.Clock1,
                       &ATTN_B.sf_MATLABFunction1_d,
                       &ATTN_DW.sf_MATLABFunction1_d);

  /* Clock: '<S3>/Clock2' */
  ATTN_B.Clock2 = ATTN_M->Timing.t[0];

  /* MATLAB Function: '<S3>/MATLAB Function2' incorporates:
   *  Constant: '<Root>/triangleAmplitude'
   */
  ATTN_MATLABFunction2(ATTN_B.Memory6, ATTN_B.stim_duration_out,
                       ATTN_cal->triangleAmplitude, ATTN_B.Clock2,
                       &ATTN_B.sf_MATLABFunction2, &ATTN_DW.sf_MATLABFunction2);

  /* S-Function (sg_IO191_da_s): '<Root>/Analog output ' */

  /* Level2 S-Function Block: '<Root>/Analog output ' (sg_IO191_da_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[2];
    sfcnOutputs(rts,0);
  }

  /* DiscretePulseGenerator: '<Root>/Whisker Trig' */
  ADIn = ATTN_cal->T_whisk / 2.0;

  /* DiscretePulseGenerator: '<Root>/Whisker Trig' */
  ATTN_B.whiskCam_trig = (ATTN_DW.clockTickCounter < ADIn) &&
    (ATTN_DW.clockTickCounter >= 0) ? ATTN_cal->WhiskerTrig_Amp : 0.0;

  /* DiscretePulseGenerator: '<Root>/Whisker Trig' */
  if (ATTN_DW.clockTickCounter >= ATTN_cal->T_whisk - 1.0) {
    ATTN_DW.clockTickCounter = 0;
  } else {
    ATTN_DW.clockTickCounter++;
  }

  /* DiscretePulseGenerator: '<Root>/Npxls Trig' */
  ADIn = ATTN_cal->T_npxls / 2.0;

  /* DiscretePulseGenerator: '<Root>/Npxls Trig' */
  ATTN_B.npxls_trig = (ATTN_DW.clockTickCounter_n < ADIn) &&
    (ATTN_DW.clockTickCounter_n >= 0) ? ATTN_cal->NpxlsTrig_Amp : 0.0;

  /* DiscretePulseGenerator: '<Root>/Npxls Trig' */
  if (ATTN_DW.clockTickCounter_n >= ATTN_cal->T_npxls - 1.0) {
    ATTN_DW.clockTickCounter_n = 0;
  } else {
    ATTN_DW.clockTickCounter_n++;
  }

  /* DiscretePulseGenerator: '<Root>/Pupil Trig' */
  ADIn = ATTN_cal->T_pupil / 2.0;

  /* DiscretePulseGenerator: '<Root>/Pupil Trig' */
  ATTN_B.pupilCam_trig = (ATTN_DW.clockTickCounter_c < ADIn) &&
    (ATTN_DW.clockTickCounter_c >= 0) ? ATTN_cal->PupilTrig_Amp : 0.0;

  /* DiscretePulseGenerator: '<Root>/Pupil Trig' */
  if (ATTN_DW.clockTickCounter_c >= ATTN_cal->T_pupil - 1.0) {
    ATTN_DW.clockTickCounter_c = 0;
  } else {
    ATTN_DW.clockTickCounter_c++;
  }

  /* Clock: '<S5>/Clock1' */
  ATTN_B.Clock1_b = ATTN_M->Timing.t[0];

  /* MATLAB Function: '<S5>/MATLAB Function1' incorporates:
   *  Constant: '<S5>/Constant4'
   */
  ATTN_DW.sfEvent_a = ATTN_CALL_EVENT_n;
  if (ATTN_B.reward_trigger_out != 0.0) {
    ATTN_DW.t0_p = ATTN_B.Clock1_b;
    ATTN_DW.t0_not_empty_p = true;
    ATTN_B.y = ATTN_cal->Constant4_Value;
  } else if (ATTN_DW.t0_not_empty_p) {
    if (ATTN_B.Clock1_b - ATTN_DW.t0_p <= ATTN_B.reward_duration_out) {
      ATTN_B.y = ATTN_cal->Constant4_Value;
    } else {
      ATTN_B.y = 0.0;
    }
  } else {
    ATTN_B.y = 0.0;
  }

  /* End of MATLAB Function: '<S5>/MATLAB Function1' */

  /* DiscretePulseGenerator: '<Root>/Photometry_Trigger' */
  ADIn = ATTN_cal->T_npxls / 2.0;

  /* DiscretePulseGenerator: '<Root>/Photometry_Trigger' */
  ATTN_B.npxls_trig_j = (ATTN_DW.clockTickCounter_o < ADIn) &&
    (ATTN_DW.clockTickCounter_o >= 0) ? ATTN_cal->Photometry_Trigger_Amp : 0.0;

  /* DiscretePulseGenerator: '<Root>/Photometry_Trigger' */
  if (ATTN_DW.clockTickCounter_o >= ATTN_cal->T_npxls - 1.0) {
    ATTN_DW.clockTickCounter_o = 0;
  } else {
    ATTN_DW.clockTickCounter_o++;
  }

  /* Clock: '<S6>/Clock1' */
  ATTN_B.Clock1_l = ATTN_M->Timing.t[0];

  /* MATLAB Function: '<S6>/MATLAB Function1' */
  ATTN_DW.sfEvent = ATTN_CALL_EVENT_n;
  if (ATTN_B.onsetTone_trig != 0.0) {
    ATTN_B.tonePulse = 1.0;
    ATTN_DW.t0 = ATTN_B.Clock1_l;
    ATTN_DW.t0_not_empty = true;
  } else if (ATTN_DW.t0_not_empty) {
    ATTN_B.tonePulse = (ATTN_B.Clock1_l - ATTN_DW.t0 < 1.5);
  } else {
    ATTN_B.tonePulse = 0.0;
  }

  /* End of MATLAB Function: '<S6>/MATLAB Function1' */

  /* S-Function (sg_IO191_do_s): '<Root>/Digital output ' */

  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[3];
    sfcnOutputs(rts,0);
  }

  /* S-Function (sg_IO191_di_s): '<Root>/Digital input ' */

  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[4];
    sfcnOutputs(rts,0);
  }

  /* RateTransition generated from: '<Root>/Digital input ' */
  ATTN_B.HiddenRateTransitionForToWks_In = ATTN_B.PulseGen1Hz;

  /* RelationalOperator: '<Root>/Relational Operator' incorporates:
   *  Constant: '<Root>/Constant'
   */
  ATTN_B.RelationalOperator = (ATTN_B.counter_out >= ATTN_cal->maxFrame);

  /* Stop: '<Root>/Stop Simulation' */
  if (ATTN_B.RelationalOperator) {
    rtmSetStopRequested(ATTN_M, 1);
  }

  /* End of Stop: '<Root>/Stop Simulation' */

  /* Update for Memory: '<Root>/Memory8' */
  ATTN_DW.Memory8_PreviousInput = ATTN_B.right_trigger_out;

  /* Update for Memory: '<Root>/Memory2' */
  ATTN_DW.Memory2_PreviousInput = ATTN_B.state_out;

  /* Update for Memory: '<Root>/Memory1' */
  ATTN_DW.Memory1_PreviousInput = ATTN_B.localTime_out;

  /* Update for Memory: '<Root>/Memory' */
  ATTN_DW.Memory_PreviousInput = ATTN_B.trialNum_out;

  /* Update for Memory: '<Root>/Memory11' */
  ATTN_DW.Memory11_PreviousInput = ATTN_B.y1;

  /* Update for Memory: '<Root>/Memory7' */
  ATTN_DW.Memory7_PreviousInput = ATTN_B.y2;

  /* Update for Memory: '<Root>/Memory3' */
  ATTN_DW.Memory3_PreviousInput = ATTN_B.npxlsAcq_out;

  /* Update for Memory: '<Root>/Memory4' */
  ATTN_DW.Memory4_PreviousInput = ATTN_B.counter_out;

  /* Update for Memory: '<Root>/Memory9' */
  ATTN_DW.Memory9_PreviousInput = ATTN_B.numLicks_out;

  /* Update for Memory: '<Root>/Memory5' */
  ATTN_DW.Memory5_PreviousInput = ATTN_B.delay_out;

  /* Update for Memory: '<Root>/Memory6' */
  ATTN_DW.Memory6_PreviousInput = ATTN_B.left_trigger_out;

  /* Update for Memory: '<Root>/Memory10' */
  ATTN_DW.Memory10_PreviousInput = ATTN_B.was_target_out;

  /* Update absolute time for base rate */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   * Timer of this task consists of two 32 bit unsigned integers.
   * The two integers represent the low bits Timing.clockTick0 and the high bits
   * Timing.clockTickH0. When the low bit overflows to 0, the high bits increment.
   */
  if (!(++ATTN_M->Timing.clockTick0)) {
    ++ATTN_M->Timing.clockTickH0;
  }

  ATTN_M->Timing.t[0] = ATTN_M->Timing.clockTick0 * ATTN_M->Timing.stepSize0 +
    ATTN_M->Timing.clockTickH0 * ATTN_M->Timing.stepSize0 * 4294967296.0;

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
    if (!(++ATTN_M->Timing.clockTick1)) {
      ++ATTN_M->Timing.clockTickH1;
    }

    ATTN_M->Timing.t[1] = ATTN_M->Timing.clockTick1 * ATTN_M->Timing.stepSize1 +
      ATTN_M->Timing.clockTickH1 * ATTN_M->Timing.stepSize1 * 4294967296.0;
  }
}

/* Model initialize function */
void ATTN_initialize(void)
{
  /* Registration code */

  /* initialize non-finites */
  rt_InitInfAndNaN(sizeof(real_T));

  {
    /* Setup solver object */
    rtsiSetSimTimeStepPtr(&ATTN_M->solverInfo, &ATTN_M->Timing.simTimeStep);
    rtsiSetTPtr(&ATTN_M->solverInfo, &rtmGetTPtr(ATTN_M));
    rtsiSetStepSizePtr(&ATTN_M->solverInfo, &ATTN_M->Timing.stepSize0);
    rtsiSetErrorStatusPtr(&ATTN_M->solverInfo, (&rtmGetErrorStatus(ATTN_M)));
    rtsiSetRTModelPtr(&ATTN_M->solverInfo, ATTN_M);
  }

  rtsiSetSimTimeStep(&ATTN_M->solverInfo, MAJOR_TIME_STEP);
  rtsiSetSolverName(&ATTN_M->solverInfo,"FixedStepDiscrete");
  ATTN_M->solverInfoPtr = (&ATTN_M->solverInfo);

  /* Initialize timing info */
  {
    int_T *mdlTsMap = ATTN_M->Timing.sampleTimeTaskIDArray;
    mdlTsMap[0] = 0;
    mdlTsMap[1] = 1;

    /* polyspace +2 MISRA2012:D4.1 [Justified:Low] "ATTN_M points to
       static memory which is guaranteed to be non-NULL" */
    ATTN_M->Timing.sampleTimeTaskIDPtr = (&mdlTsMap[0]);
    ATTN_M->Timing.sampleTimes = (&ATTN_M->Timing.sampleTimesArray[0]);
    ATTN_M->Timing.offsetTimes = (&ATTN_M->Timing.offsetTimesArray[0]);

    /* task periods */
    ATTN_M->Timing.sampleTimes[0] = (0.0);
    ATTN_M->Timing.sampleTimes[1] = (0.001);

    /* task offsets */
    ATTN_M->Timing.offsetTimes[0] = (0.0);
    ATTN_M->Timing.offsetTimes[1] = (0.0);
  }

  rtmSetTPtr(ATTN_M, &ATTN_M->Timing.tArray[0]);

  {
    int_T *mdlSampleHits = ATTN_M->Timing.sampleHitArray;
    mdlSampleHits[0] = 1;
    mdlSampleHits[1] = 1;
    ATTN_M->Timing.sampleHits = (&mdlSampleHits[0]);
  }

  rtmSetTFinal(ATTN_M, -1);
  ATTN_M->Timing.stepSize0 = 0.001;
  ATTN_M->Timing.stepSize1 = 0.001;
  ATTN_M->solverInfoPtr = (&ATTN_M->solverInfo);
  ATTN_M->Timing.stepSize = (0.001);
  rtsiSetFixedStepSize(&ATTN_M->solverInfo, 0.001);
  rtsiSetSolverMode(&ATTN_M->solverInfo, SOLVER_MODE_SINGLETASKING);

  /* block I/O */
  (void) std::memset((static_cast<void *>(&ATTN_B)), 0,
                     sizeof(B_ATTN_T));

  /* states (dwork) */
  (void) std::memset(static_cast<void *>(&ATTN_DW), 0,
                     sizeof(DW_ATTN_T));

  /* child S-Function registration */
  {
    RTWSfcnInfo *sfcnInfo = &ATTN_M->NonInlinedSFcns.sfcnInfo;
    ATTN_M->sfcnInfo = (sfcnInfo);
    rtssSetErrorStatusPtr(sfcnInfo, (&rtmGetErrorStatus(ATTN_M)));
    ATTN_M->Sizes.numSampTimes = (2);
    rtssSetNumRootSampTimesPtr(sfcnInfo, &ATTN_M->Sizes.numSampTimes);
    ATTN_M->NonInlinedSFcns.taskTimePtrs[0] = (&rtmGetTPtr(ATTN_M)[0]);
    ATTN_M->NonInlinedSFcns.taskTimePtrs[1] = (&rtmGetTPtr(ATTN_M)[1]);
    rtssSetTPtrPtr(sfcnInfo,ATTN_M->NonInlinedSFcns.taskTimePtrs);
    rtssSetTStartPtr(sfcnInfo, &rtmGetTStart(ATTN_M));
    rtssSetTFinalPtr(sfcnInfo, &rtmGetTFinal(ATTN_M));
    rtssSetTimeOfLastOutputPtr(sfcnInfo, &rtmGetTimeOfLastOutput(ATTN_M));
    rtssSetStepSizePtr(sfcnInfo, &ATTN_M->Timing.stepSize);
    rtssSetStopRequestedPtr(sfcnInfo, &rtmGetStopRequested(ATTN_M));
    rtssSetDerivCacheNeedsResetPtr(sfcnInfo, &ATTN_M->derivCacheNeedsReset);
    rtssSetZCCacheNeedsResetPtr(sfcnInfo, &ATTN_M->zCCacheNeedsReset);
    rtssSetContTimeOutputInconsistentWithStateAtMajorStepPtr(sfcnInfo,
      &ATTN_M->CTOutputIncnstWithState);
    rtssSetSampleHitsPtr(sfcnInfo, &ATTN_M->Timing.sampleHits);
    rtssSetPerTaskSampleHitsPtr(sfcnInfo, &ATTN_M->Timing.perTaskSampleHits);
    rtssSetSimModePtr(sfcnInfo, &ATTN_M->simMode);
    rtssSetSolverInfoPtr(sfcnInfo, &ATTN_M->solverInfoPtr);
  }

  ATTN_M->Sizes.numSFcns = (5);

  /* register each child */
  {
    (void) std::memset(static_cast<void *>
                       (&ATTN_M->NonInlinedSFcns.childSFunctions[0]), 0,
                       5*sizeof(SimStruct));
    ATTN_M->childSfunctions = (&ATTN_M->NonInlinedSFcns.childSFunctionPtrs[0]);

    {
      int_T i;
      for (i = 0; i < 5; i++) {
        ATTN_M->childSfunctions[i] = (&ATTN_M->NonInlinedSFcns.childSFunctions[i]);
      }
    }

    /* Level2 S-Function Block: ATTN/<Root>/Setup  (sg_IO191_setup_s) */
    {
      SimStruct *rts = ATTN_M->childSfunctions[0];

      /* timing info */
      time_T *sfcnPeriod = ATTN_M->NonInlinedSFcns.Sfcn0.sfcnPeriod;
      time_T *sfcnOffset = ATTN_M->NonInlinedSFcns.Sfcn0.sfcnOffset;
      int_T *sfcnTsMap = ATTN_M->NonInlinedSFcns.Sfcn0.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &ATTN_M->NonInlinedSFcns.blkInfo2[0]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &ATTN_M->NonInlinedSFcns.inputOutputPortInfo2[0]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, ATTN_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &ATTN_M->NonInlinedSFcns.methods2[0]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &ATTN_M->NonInlinedSFcns.methods3[0]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &ATTN_M->NonInlinedSFcns.methods4[0]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &ATTN_M->NonInlinedSFcns.statesInfo2[0]);
        ssSetPeriodicStatesInfo(rts, &ATTN_M->
          NonInlinedSFcns.periodicStatesInfo[0]);
      }

      /* path info */
      ssSetModelName(rts, "Setup ");
      ssSetPath(rts, "ATTN/Setup ");
      ssSetRTModel(rts,ATTN_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &ATTN_M->NonInlinedSFcns.Sfcn0.params;
        ssSetSFcnParamsCount(rts, 9);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)ATTN_cal->Setup_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)ATTN_cal->Setup_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)ATTN_cal->Setup_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)ATTN_cal->Setup_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)ATTN_cal->Setup_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)ATTN_cal->Setup_P6_Size);
        ssSetSFcnParam(rts, 6, (mxArray*)ATTN_cal->Setup_P7_Size);
        ssSetSFcnParam(rts, 7, (mxArray*)ATTN_cal->Setup_P8_Size);
        ssSetSFcnParam(rts, 8, (mxArray*)ATTN_cal->Setup_P9_Size);
      }

      /* work vectors */
      ssSetRWork(rts, (real_T *) &ATTN_DW.Setup_RWORK[0]);
      ssSetPWork(rts, (void **) &ATTN_DW.Setup_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &ATTN_M->NonInlinedSFcns.Sfcn0.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &ATTN_M->NonInlinedSFcns.Sfcn0.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 2);

        /* RWORK */
        ssSetDWorkWidthAsInt(rts, 0, 2);
        ssSetDWorkDataType(rts, 0,SS_DOUBLE);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &ATTN_DW.Setup_RWORK[0]);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 1, 1);
        ssSetDWorkDataType(rts, 1,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 1, 0);
        ssSetDWork(rts, 1, &ATTN_DW.Setup_PWORK);
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

    /* Level2 S-Function Block: ATTN/<Root>/Analog input  (sg_IO191_ad_s) */
    {
      SimStruct *rts = ATTN_M->childSfunctions[1];

      /* timing info */
      time_T *sfcnPeriod = ATTN_M->NonInlinedSFcns.Sfcn1.sfcnPeriod;
      time_T *sfcnOffset = ATTN_M->NonInlinedSFcns.Sfcn1.sfcnOffset;
      int_T *sfcnTsMap = ATTN_M->NonInlinedSFcns.Sfcn1.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &ATTN_M->NonInlinedSFcns.blkInfo2[1]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &ATTN_M->NonInlinedSFcns.inputOutputPortInfo2[1]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, ATTN_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &ATTN_M->NonInlinedSFcns.methods2[1]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &ATTN_M->NonInlinedSFcns.methods3[1]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &ATTN_M->NonInlinedSFcns.methods4[1]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &ATTN_M->NonInlinedSFcns.statesInfo2[1]);
        ssSetPeriodicStatesInfo(rts, &ATTN_M->
          NonInlinedSFcns.periodicStatesInfo[1]);
      }

      /* outputs */
      {
        ssSetPortInfoForOutputs(rts,
          &ATTN_M->NonInlinedSFcns.Sfcn1.outputPortInfo[0]);
        ssSetPortInfoForOutputs(rts,
          &ATTN_M->NonInlinedSFcns.Sfcn1.outputPortInfo[0]);
        _ssSetNumOutputPorts(rts, 2);
        _ssSetPortInfo2ForOutputUnits(rts,
          &ATTN_M->NonInlinedSFcns.Sfcn1.outputPortUnits[0]);
        ssSetOutputPortUnit(rts, 0, 0);
        ssSetOutputPortUnit(rts, 1, 0);
        _ssSetPortInfo2ForOutputCoSimAttribute(rts,
          &ATTN_M->NonInlinedSFcns.Sfcn1.outputPortCoSimAttribute[0]);
        ssSetOutputPortIsContinuousQuantity(rts, 0, 0);
        ssSetOutputPortIsContinuousQuantity(rts, 1, 0);

        /* port 0 */
        {
          _ssSetOutputPortNumDimensions(rts, 0, 1);
          ssSetOutputPortWidthAsInt(rts, 0, 1);
          ssSetOutputPortSignal(rts, 0, ((real_T *) &ATTN_B.Analoginput_o1));
        }

        /* port 1 */
        {
          _ssSetOutputPortNumDimensions(rts, 1, 1);
          ssSetOutputPortWidthAsInt(rts, 1, 1);
          ssSetOutputPortSignal(rts, 1, ((real_T *) &ATTN_B.lickometer_piezo));
        }
      }

      /* path info */
      ssSetModelName(rts, "Analog input ");
      ssSetPath(rts, "ATTN/Analog input ");
      ssSetRTModel(rts,ATTN_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &ATTN_M->NonInlinedSFcns.Sfcn1.params;
        ssSetSFcnParamsCount(rts, 9);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)ATTN_cal->Analoginput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)ATTN_cal->Analoginput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)ATTN_cal->Analoginput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)ATTN_cal->Analoginput_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)ATTN_cal->Analoginput_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)ATTN_cal->Analoginput_P6_Size);
        ssSetSFcnParam(rts, 6, (mxArray*)ATTN_cal->Analoginput_P7_Size);
        ssSetSFcnParam(rts, 7, (mxArray*)ATTN_cal->Analoginput_P8_Size);
        ssSetSFcnParam(rts, 8, (mxArray*)ATTN_cal->Analoginput_P9_Size);
      }

      /* work vectors */
      ssSetIWork(rts, (int_T *) &ATTN_DW.Analoginput_IWORK[0]);
      ssSetPWork(rts, (void **) &ATTN_DW.Analoginput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &ATTN_M->NonInlinedSFcns.Sfcn1.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &ATTN_M->NonInlinedSFcns.Sfcn1.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 2);

        /* IWORK */
        ssSetDWorkWidthAsInt(rts, 0, 2);
        ssSetDWorkDataType(rts, 0,SS_INTEGER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &ATTN_DW.Analoginput_IWORK[0]);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 1, 1);
        ssSetDWorkDataType(rts, 1,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 1, 0);
        ssSetDWork(rts, 1, &ATTN_DW.Analoginput_PWORK);
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
      _ssSetOutputPortConnected(rts, 0, 0);
      _ssSetOutputPortConnected(rts, 1, 1);
      _ssSetOutputPortBeingMerged(rts, 0, 0);
      _ssSetOutputPortBeingMerged(rts, 1, 0);

      /* Update the BufferDstPort flags for each input port */
    }

    /* Level2 S-Function Block: ATTN/<Root>/Analog output  (sg_IO191_da_s) */
    {
      SimStruct *rts = ATTN_M->childSfunctions[2];

      /* timing info */
      time_T *sfcnPeriod = ATTN_M->NonInlinedSFcns.Sfcn2.sfcnPeriod;
      time_T *sfcnOffset = ATTN_M->NonInlinedSFcns.Sfcn2.sfcnOffset;
      int_T *sfcnTsMap = ATTN_M->NonInlinedSFcns.Sfcn2.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &ATTN_M->NonInlinedSFcns.blkInfo2[2]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &ATTN_M->NonInlinedSFcns.inputOutputPortInfo2[2]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, ATTN_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &ATTN_M->NonInlinedSFcns.methods2[2]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &ATTN_M->NonInlinedSFcns.methods3[2]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &ATTN_M->NonInlinedSFcns.methods4[2]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &ATTN_M->NonInlinedSFcns.statesInfo2[2]);
        ssSetPeriodicStatesInfo(rts, &ATTN_M->
          NonInlinedSFcns.periodicStatesInfo[2]);
      }

      /* inputs */
      {
        _ssSetNumInputPorts(rts, 2);
        ssSetPortInfoForInputs(rts, &ATTN_M->
          NonInlinedSFcns.Sfcn2.inputPortInfo[0]);
        ssSetPortInfoForInputs(rts, &ATTN_M->
          NonInlinedSFcns.Sfcn2.inputPortInfo[0]);
        _ssSetPortInfo2ForInputUnits(rts,
          &ATTN_M->NonInlinedSFcns.Sfcn2.inputPortUnits[0]);
        ssSetInputPortUnit(rts, 0, 0);
        ssSetInputPortUnit(rts, 1, 0);
        _ssSetPortInfo2ForInputCoSimAttribute(rts,
          &ATTN_M->NonInlinedSFcns.Sfcn2.inputPortCoSimAttribute[0]);
        ssSetInputPortIsContinuousQuantity(rts, 0, 0);
        ssSetInputPortIsContinuousQuantity(rts, 1, 0);

        /* port 0 */
        {
          ssSetInputPortRequiredContiguous(rts, 0, 1);
          ssSetInputPortSignal(rts, 0, &ATTN_B.sf_MATLABFunction1_d.y);
          _ssSetInputPortNumDimensions(rts, 0, 1);
          ssSetInputPortWidthAsInt(rts, 0, 1);
        }

        /* port 1 */
        {
          ssSetInputPortRequiredContiguous(rts, 1, 1);
          ssSetInputPortSignal(rts, 1, &ATTN_B.sf_MATLABFunction2.y);
          _ssSetInputPortNumDimensions(rts, 1, 1);
          ssSetInputPortWidthAsInt(rts, 1, 1);
        }
      }

      /* path info */
      ssSetModelName(rts, "Analog output ");
      ssSetPath(rts, "ATTN/Analog output ");
      ssSetRTModel(rts,ATTN_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &ATTN_M->NonInlinedSFcns.Sfcn2.params;
        ssSetSFcnParamsCount(rts, 7);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)ATTN_cal->Analogoutput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)ATTN_cal->Analogoutput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)ATTN_cal->Analogoutput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)ATTN_cal->Analogoutput_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)ATTN_cal->Analogoutput_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)ATTN_cal->Analogoutput_P6_Size);
        ssSetSFcnParam(rts, 6, (mxArray*)ATTN_cal->Analogoutput_P7_Size);
      }

      /* work vectors */
      ssSetPWork(rts, (void **) &ATTN_DW.Analogoutput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &ATTN_M->NonInlinedSFcns.Sfcn2.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &ATTN_M->NonInlinedSFcns.Sfcn2.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 1);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 0, 1);
        ssSetDWorkDataType(rts, 0,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &ATTN_DW.Analogoutput_PWORK);
      }

      /* registration */
      sg_IO191_da_s(rts);
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

      /* Update the BufferDstPort flags for each input port */
      ssSetInputPortBufferDstPort(rts, 0, -1);
      ssSetInputPortBufferDstPort(rts, 1, -1);
    }

    /* Level2 S-Function Block: ATTN/<Root>/Digital output  (sg_IO191_do_s) */
    {
      SimStruct *rts = ATTN_M->childSfunctions[3];

      /* timing info */
      time_T *sfcnPeriod = ATTN_M->NonInlinedSFcns.Sfcn3.sfcnPeriod;
      time_T *sfcnOffset = ATTN_M->NonInlinedSFcns.Sfcn3.sfcnOffset;
      int_T *sfcnTsMap = ATTN_M->NonInlinedSFcns.Sfcn3.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &ATTN_M->NonInlinedSFcns.blkInfo2[3]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &ATTN_M->NonInlinedSFcns.inputOutputPortInfo2[3]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, ATTN_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &ATTN_M->NonInlinedSFcns.methods2[3]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &ATTN_M->NonInlinedSFcns.methods3[3]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &ATTN_M->NonInlinedSFcns.methods4[3]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &ATTN_M->NonInlinedSFcns.statesInfo2[3]);
        ssSetPeriodicStatesInfo(rts, &ATTN_M->
          NonInlinedSFcns.periodicStatesInfo[3]);
      }

      /* inputs */
      {
        _ssSetNumInputPorts(rts, 15);
        ssSetPortInfoForInputs(rts, &ATTN_M->
          NonInlinedSFcns.Sfcn3.inputPortInfo[0]);
        ssSetPortInfoForInputs(rts, &ATTN_M->
          NonInlinedSFcns.Sfcn3.inputPortInfo[0]);
        _ssSetPortInfo2ForInputUnits(rts,
          &ATTN_M->NonInlinedSFcns.Sfcn3.inputPortUnits[0]);
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
          &ATTN_M->NonInlinedSFcns.Sfcn3.inputPortCoSimAttribute[0]);
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
          ssSetInputPortSignal(rts, 0, &ATTN_B.whiskCam_trig);
          _ssSetInputPortNumDimensions(rts, 0, 1);
          ssSetInputPortWidthAsInt(rts, 0, 1);
        }

        /* port 1 */
        {
          ssSetInputPortRequiredContiguous(rts, 1, 1);
          ssSetInputPortSignal(rts, 1, &ATTN_B.npxls_trig);
          _ssSetInputPortNumDimensions(rts, 1, 1);
          ssSetInputPortWidthAsInt(rts, 1, 1);
        }

        /* port 2 */
        {
          ssSetInputPortRequiredContiguous(rts, 2, 1);
          ssSetInputPortSignal(rts, 2, &ATTN_B.pupilCam_trig);
          _ssSetInputPortNumDimensions(rts, 2, 1);
          ssSetInputPortWidthAsInt(rts, 2, 1);
        }

        /* port 3 */
        {
          ssSetInputPortRequiredContiguous(rts, 3, 1);
          ssSetInputPortSignal(rts, 3, &ATTN_B.npxlsAcq_out);
          _ssSetInputPortNumDimensions(rts, 3, 1);
          ssSetInputPortWidthAsInt(rts, 3, 1);
        }

        /* port 4 */
        {
          ssSetInputPortRequiredContiguous(rts, 4, 1);
          ssSetInputPortSignal(rts, 4, &ATTN_B.y);
          _ssSetInputPortNumDimensions(rts, 4, 1);
          ssSetInputPortWidthAsInt(rts, 4, 1);
        }

        /* port 5 */
        {
          ssSetInputPortRequiredContiguous(rts, 5, 1);
          ssSetInputPortSignal(rts, 5, (const_cast<real_T*>(&ATTN_RGND)));
          _ssSetInputPortNumDimensions(rts, 5, 1);
          ssSetInputPortWidthAsInt(rts, 5, 1);
        }

        /* port 6 */
        {
          ssSetInputPortRequiredContiguous(rts, 6, 1);
          ssSetInputPortSignal(rts, 6, &ATTN_B.npxlsAcq_out);
          _ssSetInputPortNumDimensions(rts, 6, 1);
          ssSetInputPortWidthAsInt(rts, 6, 1);
        }

        /* port 7 */
        {
          ssSetInputPortRequiredContiguous(rts, 7, 1);
          ssSetInputPortSignal(rts, 7, &ATTN_B.npxls_trig_j);
          _ssSetInputPortNumDimensions(rts, 7, 1);
          ssSetInputPortWidthAsInt(rts, 7, 1);
        }

        /* port 8 */
        {
          ssSetInputPortRequiredContiguous(rts, 8, 1);
          ssSetInputPortSignal(rts, 8, (const_cast<real_T*>(&ATTN_RGND)));
          _ssSetInputPortNumDimensions(rts, 8, 1);
          ssSetInputPortWidthAsInt(rts, 8, 1);
        }

        /* port 9 */
        {
          ssSetInputPortRequiredContiguous(rts, 9, 1);
          ssSetInputPortSignal(rts, 9, (const_cast<real_T*>(&ATTN_RGND)));
          _ssSetInputPortNumDimensions(rts, 9, 1);
          ssSetInputPortWidthAsInt(rts, 9, 1);
        }

        /* port 10 */
        {
          ssSetInputPortRequiredContiguous(rts, 10, 1);
          ssSetInputPortSignal(rts, 10, (const_cast<real_T*>(&ATTN_RGND)));
          _ssSetInputPortNumDimensions(rts, 10, 1);
          ssSetInputPortWidthAsInt(rts, 10, 1);
        }

        /* port 11 */
        {
          ssSetInputPortRequiredContiguous(rts, 11, 1);
          ssSetInputPortSignal(rts, 11, (const_cast<real_T*>(&ATTN_RGND)));
          _ssSetInputPortNumDimensions(rts, 11, 1);
          ssSetInputPortWidthAsInt(rts, 11, 1);
        }

        /* port 12 */
        {
          ssSetInputPortRequiredContiguous(rts, 12, 1);
          ssSetInputPortSignal(rts, 12, (const_cast<real_T*>(&ATTN_RGND)));
          _ssSetInputPortNumDimensions(rts, 12, 1);
          ssSetInputPortWidthAsInt(rts, 12, 1);
        }

        /* port 13 */
        {
          ssSetInputPortRequiredContiguous(rts, 13, 1);
          ssSetInputPortSignal(rts, 13, (const_cast<real_T*>(&ATTN_RGND)));
          _ssSetInputPortNumDimensions(rts, 13, 1);
          ssSetInputPortWidthAsInt(rts, 13, 1);
        }

        /* port 14 */
        {
          ssSetInputPortRequiredContiguous(rts, 14, 1);
          ssSetInputPortSignal(rts, 14, &ATTN_B.tonePulse);
          _ssSetInputPortNumDimensions(rts, 14, 1);
          ssSetInputPortWidthAsInt(rts, 14, 1);
        }
      }

      /* path info */
      ssSetModelName(rts, "Digital output ");
      ssSetPath(rts, "ATTN/Digital output ");
      ssSetRTModel(rts,ATTN_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &ATTN_M->NonInlinedSFcns.Sfcn3.params;
        ssSetSFcnParamsCount(rts, 6);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)ATTN_cal->Digitaloutput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)ATTN_cal->Digitaloutput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)ATTN_cal->Digitaloutput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)ATTN_cal->Digitaloutput_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)ATTN_cal->Digitaloutput_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)ATTN_cal->Digitaloutput_P6_Size);
      }

      /* work vectors */
      ssSetPWork(rts, (void **) &ATTN_DW.Digitaloutput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &ATTN_M->NonInlinedSFcns.Sfcn3.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &ATTN_M->NonInlinedSFcns.Sfcn3.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 1);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 0, 1);
        ssSetDWorkDataType(rts, 0,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &ATTN_DW.Digitaloutput_PWORK);
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
      _ssSetInputPortConnected(rts, 4, 1);
      _ssSetInputPortConnected(rts, 5, 0);
      _ssSetInputPortConnected(rts, 6, 1);
      _ssSetInputPortConnected(rts, 7, 1);
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

    /* Level2 S-Function Block: ATTN/<Root>/Digital input  (sg_IO191_di_s) */
    {
      SimStruct *rts = ATTN_M->childSfunctions[4];

      /* timing info */
      time_T *sfcnPeriod = ATTN_M->NonInlinedSFcns.Sfcn4.sfcnPeriod;
      time_T *sfcnOffset = ATTN_M->NonInlinedSFcns.Sfcn4.sfcnOffset;
      int_T *sfcnTsMap = ATTN_M->NonInlinedSFcns.Sfcn4.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &ATTN_M->NonInlinedSFcns.blkInfo2[4]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &ATTN_M->NonInlinedSFcns.inputOutputPortInfo2[4]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, ATTN_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &ATTN_M->NonInlinedSFcns.methods2[4]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &ATTN_M->NonInlinedSFcns.methods3[4]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &ATTN_M->NonInlinedSFcns.methods4[4]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &ATTN_M->NonInlinedSFcns.statesInfo2[4]);
        ssSetPeriodicStatesInfo(rts, &ATTN_M->
          NonInlinedSFcns.periodicStatesInfo[4]);
      }

      /* outputs */
      {
        ssSetPortInfoForOutputs(rts,
          &ATTN_M->NonInlinedSFcns.Sfcn4.outputPortInfo[0]);
        ssSetPortInfoForOutputs(rts,
          &ATTN_M->NonInlinedSFcns.Sfcn4.outputPortInfo[0]);
        _ssSetNumOutputPorts(rts, 1);
        _ssSetPortInfo2ForOutputUnits(rts,
          &ATTN_M->NonInlinedSFcns.Sfcn4.outputPortUnits[0]);
        ssSetOutputPortUnit(rts, 0, 0);
        _ssSetPortInfo2ForOutputCoSimAttribute(rts,
          &ATTN_M->NonInlinedSFcns.Sfcn4.outputPortCoSimAttribute[0]);
        ssSetOutputPortIsContinuousQuantity(rts, 0, 0);

        /* port 0 */
        {
          _ssSetOutputPortNumDimensions(rts, 0, 1);
          ssSetOutputPortWidthAsInt(rts, 0, 1);
          ssSetOutputPortSignal(rts, 0, ((real_T *) &ATTN_B.PulseGen1Hz));
        }
      }

      /* path info */
      ssSetModelName(rts, "Digital input ");
      ssSetPath(rts, "ATTN/Digital input ");
      ssSetRTModel(rts,ATTN_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &ATTN_M->NonInlinedSFcns.Sfcn4.params;
        ssSetSFcnParamsCount(rts, 4);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)ATTN_cal->Digitalinput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)ATTN_cal->Digitalinput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)ATTN_cal->Digitalinput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)ATTN_cal->Digitalinput_P4_Size);
      }

      /* work vectors */
      ssSetPWork(rts, (void **) &ATTN_DW.Digitalinput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &ATTN_M->NonInlinedSFcns.Sfcn4.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &ATTN_M->NonInlinedSFcns.Sfcn4.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 1);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 0, 1);
        ssSetDWorkDataType(rts, 0,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &ATTN_DW.Digitalinput_PWORK);
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
    SimStruct *rts = ATTN_M->childSfunctions[0];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_ad_s): '<Root>/Analog input ' */
  /* Level2 S-Function Block: '<Root>/Analog input ' (sg_IO191_ad_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[1];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for Constant: '<Root>/swtichTime' */
  ATTN_B.swtichTime = ATTN_cal->switchTime;

  /* Start for Constant: '<Root>/trainingStage' */
  ATTN_B.trainingStage = ATTN_cal->trainingStage;

  /* Start for S-Function (sg_IO191_da_s): '<Root>/Analog output ' */
  /* Level2 S-Function Block: '<Root>/Analog output ' (sg_IO191_da_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[2];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_do_s): '<Root>/Digital output ' */
  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[3];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_di_s): '<Root>/Digital input ' */
  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[4];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  {
    static const uint32_T tmp[625] = { 5489U, 1301868182U, 2938499221U,
      2950281878U, 1875628136U, 751856242U, 944701696U, 2243192071U, 694061057U,
      219885934U, 2066767472U, 3182869408U, 485472502U, 2336857883U, 1071588843U,
      3418470598U, 951210697U, 3693558366U, 2923482051U, 1793174584U,
      2982310801U, 1586906132U, 1951078751U, 1808158765U, 1733897588U,
      431328322U, 4202539044U, 530658942U, 1714810322U, 3025256284U, 3342585396U,
      1937033938U, 2640572511U, 1654299090U, 3692403553U, 4233871309U,
      3497650794U, 862629010U, 2943236032U, 2426458545U, 1603307207U,
      1133453895U, 3099196360U, 2208657629U, 2747653927U, 931059398U, 761573964U,
      3157853227U, 785880413U, 730313442U, 124945756U, 2937117055U, 3295982469U,
      1724353043U, 3021675344U, 3884886417U, 4010150098U, 4056961966U,
      699635835U, 2681338818U, 1339167484U, 720757518U, 2800161476U, 2376097373U,
      1532957371U, 3902664099U, 1238982754U, 3725394514U, 3449176889U,
      3570962471U, 4287636090U, 4087307012U, 3603343627U, 202242161U,
      2995682783U, 1620962684U, 3704723357U, 371613603U, 2814834333U,
      2111005706U, 624778151U, 2094172212U, 4284947003U, 1211977835U, 991917094U,
      1570449747U, 2962370480U, 1259410321U, 170182696U, 146300961U, 2836829791U,
      619452428U, 2723670296U, 1881399711U, 1161269684U, 1675188680U,
      4132175277U, 780088327U, 3409462821U, 1036518241U, 1834958505U,
      3048448173U, 161811569U, 618488316U, 44795092U, 3918322701U, 1924681712U,
      3239478144U, 383254043U, 4042306580U, 2146983041U, 3992780527U,
      3518029708U, 3545545436U, 3901231469U, 1896136409U, 2028528556U,
      2339662006U, 501326714U, 2060962201U, 2502746480U, 561575027U, 581893337U,
      3393774360U, 1778912547U, 3626131687U, 2175155826U, 319853231U, 986875531U,
      819755096U, 2915734330U, 2688355739U, 3482074849U, 2736559U, 2296975761U,
      1029741190U, 2876812646U, 690154749U, 579200347U, 4027461746U, 1285330465U,
      2701024045U, 4117700889U, 759495121U, 3332270341U, 2313004527U,
      2277067795U, 4131855432U, 2722057515U, 1264804546U, 3848622725U,
      2211267957U, 4100593547U, 959123777U, 2130745407U, 3194437393U, 486673947U,
      1377371204U, 17472727U, 352317554U, 3955548058U, 159652094U, 1232063192U,
      3835177280U, 49423123U, 3083993636U, 733092U, 2120519771U, 2573409834U,
      1112952433U, 3239502554U, 761045320U, 1087580692U, 2540165110U, 641058802U,
      1792435497U, 2261799288U, 1579184083U, 627146892U, 2165744623U,
      2200142389U, 2167590760U, 2381418376U, 1793358889U, 3081659520U,
      1663384067U, 2009658756U, 2689600308U, 739136266U, 2304581039U,
      3529067263U, 591360555U, 525209271U, 3131882996U, 294230224U, 2076220115U,
      3113580446U, 1245621585U, 1386885462U, 3203270426U, 123512128U, 12350217U,
      354956375U, 4282398238U, 3356876605U, 3888857667U, 157639694U, 2616064085U,
      1563068963U, 2762125883U, 4045394511U, 4180452559U, 3294769488U,
      1684529556U, 1002945951U, 3181438866U, 22506664U, 691783457U, 2685221343U,
      171579916U, 3878728600U, 2475806724U, 2030324028U, 3331164912U,
      1708711359U, 1970023127U, 2859691344U, 2588476477U, 2748146879U,
      136111222U, 2967685492U, 909517429U, 2835297809U, 3206906216U, 3186870716U,
      341264097U, 2542035121U, 3353277068U, 548223577U, 3170936588U, 1678403446U,
      297435620U, 2337555430U, 466603495U, 1132321815U, 1208589219U, 696392160U,
      894244439U, 2562678859U, 470224582U, 3306867480U, 201364898U, 2075966438U,
      1767227936U, 2929737987U, 3674877796U, 2654196643U, 3692734598U,
      3528895099U, 2796780123U, 3048728353U, 842329300U, 191554730U, 2922459673U,
      3489020079U, 3979110629U, 1022523848U, 2202932467U, 3583655201U,
      3565113719U, 587085778U, 4176046313U, 3013713762U, 950944241U, 396426791U,
      3784844662U, 3477431613U, 3594592395U, 2782043838U, 3392093507U,
      3106564952U, 2829419931U, 1358665591U, 2206918825U, 3170783123U, 31522386U,
      2988194168U, 1782249537U, 1105080928U, 843500134U, 1225290080U,
      1521001832U, 3605886097U, 2802786495U, 2728923319U, 3996284304U,
      903417639U, 1171249804U, 1020374987U, 2824535874U, 423621996U, 1988534473U,
      2493544470U, 1008604435U, 1756003503U, 1488867287U, 1386808992U,
      732088248U, 1780630732U, 2482101014U, 976561178U, 1543448953U, 2602866064U,
      2021139923U, 1952599828U, 2360242564U, 2117959962U, 2753061860U,
      2388623612U, 4138193781U, 2962920654U, 2284970429U, 766920861U,
      3457264692U, 2879611383U, 815055854U, 2332929068U, 1254853997U,
      3740375268U, 3799380844U, 4091048725U, 2006331129U, 1982546212U,
      686850534U, 1907447564U, 2682801776U, 2780821066U, 998290361U, 1342433871U,
      4195430425U, 607905174U, 3902331779U, 2454067926U, 1708133115U,
      1170874362U, 2008609376U, 3260320415U, 2211196135U, 433538229U,
      2728786374U, 2189520818U, 262554063U, 1182318347U, 3710237267U,
      1221022450U, 715966018U, 2417068910U, 2591870721U, 2870691989U,
      3418190842U, 4238214053U, 1540704231U, 1575580968U, 2095917976U,
      4078310857U, 2313532447U, 2110690783U, 4056346629U, 4061784526U,
      1123218514U, 551538993U, 597148360U, 4120175196U, 3581618160U, 3181170517U,
      422862282U, 3227524138U, 1713114790U, 662317149U, 1230418732U, 928171837U,
      1324564878U, 1928816105U, 1786535431U, 2878099422U, 3290185549U,
      539474248U, 1657512683U, 552370646U, 1671741683U, 3655312128U, 1552739510U,
      2605208763U, 1441755014U, 181878989U, 3124053868U, 1447103986U,
      3183906156U, 1728556020U, 3502241336U, 3055466967U, 1013272474U,
      818402132U, 1715099063U, 2900113506U, 397254517U, 4194863039U, 1009068739U,
      232864647U, 2540223708U, 2608288560U, 2415367765U, 478404847U, 3455100648U,
      3182600021U, 2115988978U, 434269567U, 4117179324U, 3461774077U, 887256537U,
      3545801025U, 286388911U, 3451742129U, 1981164769U, 786667016U, 3310123729U,
      3097811076U, 2224235657U, 2959658883U, 3370969234U, 2514770915U,
      3345656436U, 2677010851U, 2206236470U, 271648054U, 2342188545U,
      4292848611U, 3646533909U, 3754009956U, 3803931226U, 4160647125U,
      1477814055U, 4043852216U, 1876372354U, 3133294443U, 3871104810U,
      3177020907U, 2074304428U, 3479393793U, 759562891U, 164128153U, 1839069216U,
      2114162633U, 3989947309U, 3611054956U, 1333547922U, 835429831U, 494987340U,
      171987910U, 1252001001U, 370809172U, 3508925425U, 2535703112U, 1276855041U,
      1922855120U, 835673414U, 3030664304U, 613287117U, 171219893U, 3423096126U,
      3376881639U, 2287770315U, 1658692645U, 1262815245U, 3957234326U,
      1168096164U, 2968737525U, 2655813712U, 2132313144U, 3976047964U,
      326516571U, 353088456U, 3679188938U, 3205649712U, 2654036126U, 1249024881U,
      880166166U, 691800469U, 2229503665U, 1673458056U, 4032208375U, 1851778863U,
      2563757330U, 376742205U, 1794655231U, 340247333U, 1505873033U, 396524441U,
      879666767U, 3335579166U, 3260764261U, 3335999539U, 506221798U, 4214658741U,
      975887814U, 2080536343U, 3360539560U, 571586418U, 138896374U, 4234352651U,
      2737620262U, 3928362291U, 1516365296U, 38056726U, 3599462320U, 3585007266U,
      3850961033U, 471667319U, 1536883193U, 2310166751U, 1861637689U,
      2530999841U, 4139843801U, 2710569485U, 827578615U, 2012334720U,
      2907369459U, 3029312804U, 2820112398U, 1965028045U, 35518606U, 2478379033U,
      643747771U, 1924139484U, 4123405127U, 3811735531U, 3429660832U,
      3285177704U, 1948416081U, 1311525291U, 1183517742U, 1739192232U,
      3979815115U, 2567840007U, 4116821529U, 213304419U, 4125718577U,
      1473064925U, 2442436592U, 1893310111U, 4195361916U, 3747569474U,
      828465101U, 2991227658U, 750582866U, 1205170309U, 1409813056U, 678418130U,
      1171531016U, 3821236156U, 354504587U, 4202874632U, 3882511497U,
      1893248677U, 1903078632U, 26340130U, 2069166240U, 3657122492U, 3725758099U,
      831344905U, 811453383U, 3447711422U, 2434543565U, 4166886888U, 3358210805U,
      4142984013U, 2988152326U, 3527824853U, 982082992U, 2809155763U, 190157081U,
      3340214818U, 2365432395U, 2548636180U, 2894533366U, 3474657421U,
      2372634704U, 2845748389U, 43024175U, 2774226648U, 1987702864U, 3186502468U,
      453610222U, 4204736567U, 1392892630U, 2471323686U, 2470534280U,
      3541393095U, 4269885866U, 3909911300U, 759132955U, 1482612480U, 667715263U,
      1795580598U, 2337923983U, 3390586366U, 581426223U, 1515718634U, 476374295U,
      705213300U, 363062054U, 2084697697U, 2407503428U, 2292957699U, 2426213835U,
      2199989172U, 1987356470U, 4026755612U, 2147252133U, 270400031U,
      1367820199U, 2369854699U, 2844269403U, 79981964U, 624U };

    /* InitializeConditions for Memory: '<Root>/Memory8' */
    ATTN_DW.Memory8_PreviousInput = ATTN_cal->Memory8_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory2' */
    ATTN_DW.Memory2_PreviousInput = ATTN_cal->Memory2_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory1' */
    ATTN_DW.Memory1_PreviousInput = ATTN_cal->Memory1_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory' */
    ATTN_DW.Memory_PreviousInput = ATTN_cal->Memory_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory11' */
    ATTN_DW.Memory11_PreviousInput = ATTN_cal->Memory11_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory7' */
    ATTN_DW.Memory7_PreviousInput = ATTN_cal->Memory7_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory3' */
    ATTN_DW.Memory3_PreviousInput = ATTN_cal->Memory3_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory4' */
    ATTN_DW.Memory4_PreviousInput = ATTN_cal->Memory4_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory9' */
    ATTN_DW.Memory9_PreviousInput = ATTN_cal->Memory9_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory5' */
    ATTN_DW.Memory5_PreviousInput = ATTN_cal->Memory5_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory6' */
    ATTN_DW.Memory6_PreviousInput = ATTN_cal->Memory6_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory10' */
    ATTN_DW.Memory10_PreviousInput = ATTN_cal->Memory10_InitialCondition;

    /* InitializeConditions for DiscretePulseGenerator: '<Root>/Whisker Trig' */
    ATTN_DW.clockTickCounter = 0;

    /* InitializeConditions for DiscretePulseGenerator: '<Root>/Npxls Trig' */
    ATTN_DW.clockTickCounter_n = 0;

    /* InitializeConditions for DiscretePulseGenerator: '<Root>/Pupil Trig' */
    ATTN_DW.clockTickCounter_c = 0;

    /* InitializeConditions for DiscretePulseGenerator: '<Root>/Photometry_Trigger' */
    ATTN_DW.clockTickCounter_o = 0;

    /* SystemInitialize for MATLAB Function: '<Root>/MATLAB Function1' */
    ATTN_DW.sfEvent_b = ATTN_CALL_EVENT_n;
    ATTN_DW.is_active_c6_ATTN = 0U;

    /* SystemInitialize for MATLAB Function: '<Root>/MATLAB Function' */
    std::memcpy(&ATTN_DW.state[0], &tmp[0], 625U * sizeof(uint32_T));
    ATTN_DW.sfEvent_e = ATTN_CALL_EVENT_n;
    ATTN_DW.is_active_c1_ATTN = 0U;
    ATTN_DW.seed = 0U;
    ATTN_DW.seed_not_empty = true;
    ATTN_DW.method = 7U;
    ATTN_DW.method_not_empty = true;
    ATTN_DW.state_not_empty = true;
    ATTN_DW.state_k[0] = 362436069U;
    ATTN_DW.state_k[1] = 521288629U;
    ATTN_DW.state_not_empty_d = true;
    ATTN_DW.state_j = 1144108930U;
    ATTN_DW.state_not_empty_n = true;

    /* SystemInitialize for MATLAB Function: '<S4>/MATLAB Function1' */
    ATTN_MATLABFunction2_Init(&ATTN_DW.sf_MATLABFunction1_d);

    /* SystemInitialize for MATLAB Function: '<S3>/MATLAB Function2' */
    ATTN_MATLABFunction2_Init(&ATTN_DW.sf_MATLABFunction2);

    /* SystemInitialize for MATLAB Function: '<S5>/MATLAB Function1' */
    ATTN_DW.sfEvent_a = ATTN_CALL_EVENT_n;
    ATTN_DW.t0_not_empty_p = false;
    ATTN_DW.is_active_c5_ATTN = 0U;

    /* SystemInitialize for MATLAB Function: '<S6>/MATLAB Function1' */
    ATTN_DW.sfEvent = ATTN_CALL_EVENT_n;
    ATTN_DW.t0_not_empty = false;
    ATTN_DW.is_active_c2_ATTN = 0U;
  }
}

/* Model terminate function */
void ATTN_terminate(void)
{
  /* Terminate for S-Function (sg_IO191_setup_s): '<Root>/Setup ' */
  /* Level2 S-Function Block: '<Root>/Setup ' (sg_IO191_setup_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[0];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_ad_s): '<Root>/Analog input ' */
  /* Level2 S-Function Block: '<Root>/Analog input ' (sg_IO191_ad_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[1];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_da_s): '<Root>/Analog output ' */
  /* Level2 S-Function Block: '<Root>/Analog output ' (sg_IO191_da_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[2];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_do_s): '<Root>/Digital output ' */
  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[3];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_di_s): '<Root>/Digital input ' */
  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = ATTN_M->childSfunctions[4];
    sfcnTerminate(rts);
  }
}
