/*
 * SspNeuromod.cpp
 *
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * Code generation for model "SspNeuromod".
 *
 * Model version              : 1.138
 * Simulink Coder version : 9.9 (R2023a) 19-Nov-2022
 * C++ source code generated on : Tue Feb  6 16:15:13 2024
 *
 * Target selection: slrealtime.tlc
 * Note: GRT includes extra infrastructure and instrumentation for prototyping
 * Embedded hardware selection: Intel->x86-64 (Linux 64)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "SspNeuromod.h"
#include "rtwtypes.h"
#include "SspNeuromod_cal.h"
#include <cstring>
#include <cmath>

extern "C"
{

#include "rt_nonfinite.h"

}

#include "SspNeuromod_private.h"

/* Named constants for MATLAB Function: '<Root>/MATLAB Function' */
const int32_T SspNeuromod_CALL_EVENT = -1;
const real_T SspNeuromod_RGND = 0.0;   /* real_T ground */

/* Block signals (default storage) */
B_SspNeuromod_T SspNeuromod_B;

/* Block states (default storage) */
DW_SspNeuromod_T SspNeuromod_DW;

/* Real-time model */
RT_MODEL_SspNeuromod_T SspNeuromod_M_ = RT_MODEL_SspNeuromod_T();
RT_MODEL_SspNeuromod_T *const SspNeuromod_M = &SspNeuromod_M_;

/* Forward declaration for local functions */
static real_T SspNeuromod_rand(void);
static real_T SspNeuromod_mod(real_T x);

/* Function for MATLAB Function: '<Root>/MATLAB Function' */
static real_T SspNeuromod_rand(void)
{
  real_T r;
  uint32_T u[2];
  if (SspNeuromod_DW.method == 4U) {
    int32_T k;
    uint32_T mti;
    uint32_T y;
    k = static_cast<int32_T>(SspNeuromod_DW.state / 127773U);
    mti = (SspNeuromod_DW.state - static_cast<uint32_T>(k) * 127773U) * 16807U;
    y = 2836U * static_cast<uint32_T>(k);
    if (mti < y) {
      mti = ~(y - mti) & 2147483647U;
    } else {
      mti -= y;
    }

    r = static_cast<real_T>(mti) * 4.6566128752457969E-10;
    SspNeuromod_DW.state = mti;
  } else if (SspNeuromod_DW.method == 5U) {
    uint32_T mti;
    uint32_T y;
    mti = 69069U * SspNeuromod_DW.state_p[0] + 1234567U;
    y = SspNeuromod_DW.state_p[1] << 13 ^ SspNeuromod_DW.state_p[1];
    y ^= y >> 17;
    y ^= y << 5;
    SspNeuromod_DW.state_p[0] = mti;
    SspNeuromod_DW.state_p[1] = y;
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
        mti = SspNeuromod_DW.state_k[624] + 1U;
        if (mti >= 625U) {
          for (int32_T kk = 0; kk < 227; kk++) {
            mti = (SspNeuromod_DW.state_k[kk + 1] & 2147483647U) |
              (SspNeuromod_DW.state_k[kk] & 2147483648U);
            if ((mti & 1U) == 0U) {
              mti >>= 1U;
            } else {
              mti = mti >> 1U ^ 2567483615U;
            }

            SspNeuromod_DW.state_k[kk] = SspNeuromod_DW.state_k[kk + 397] ^ mti;
          }

          for (int32_T kk = 0; kk < 396; kk++) {
            mti = (SspNeuromod_DW.state_k[kk + 227] & 2147483648U) |
              (SspNeuromod_DW.state_k[kk + 228] & 2147483647U);
            if ((mti & 1U) == 0U) {
              mti >>= 1U;
            } else {
              mti = mti >> 1U ^ 2567483615U;
            }

            SspNeuromod_DW.state_k[kk + 227] = SspNeuromod_DW.state_k[kk] ^ mti;
          }

          mti = (SspNeuromod_DW.state_k[623] & 2147483648U) |
            (SspNeuromod_DW.state_k[0] & 2147483647U);
          if ((mti & 1U) == 0U) {
            mti >>= 1U;
          } else {
            mti = mti >> 1U ^ 2567483615U;
          }

          SspNeuromod_DW.state_k[623] = SspNeuromod_DW.state_k[396] ^ mti;
          mti = 1U;
        }

        y = SspNeuromod_DW.state_k[static_cast<int32_T>(mti) - 1];
        SspNeuromod_DW.state_k[624] = mti;
        y ^= y >> 11U;
        y ^= y << 7U & 2636928640U;
        y ^= y << 15U & 4022730752U;
        u[k] = y >> 18U ^ y;
      }

      r = (static_cast<real_T>(u[0] >> 5U) * 6.7108864E+7 + static_cast<real_T>
           (u[1] >> 6U)) * 1.1102230246251565E-16;
      if (r == 0.0) {
        boolean_T b_isvalid;
        if ((SspNeuromod_DW.state_k[624] >= 1U) && (SspNeuromod_DW.state_k[624] <
             625U)) {
          boolean_T exitg2;
          b_isvalid = false;
          k = 1;
          exitg2 = false;
          while ((!exitg2) && (k < 625)) {
            if (SspNeuromod_DW.state_k[k - 1] == 0U) {
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
          SspNeuromod_DW.state_k[0] = 5489U;
          for (k = 0; k < 623; k++) {
            mti = ((mti >> 30U ^ mti) * 1812433253U + static_cast<uint32_T>(k))
              + 1U;
            SspNeuromod_DW.state_k[k + 1] = mti;
          }

          SspNeuromod_DW.state_k[624] = 624U;
        }
      } else {
        exitg1 = 1;
      }
    } while (exitg1 == 0);
  }

  return r;
}

/* Function for MATLAB Function: '<Root>/MATLAB Function' */
static real_T SspNeuromod_mod(real_T x)
{
  real_T r;
  if (rtIsNaN(x) || rtIsInf(x)) {
    r = (rtNaN);
  } else if (x == 0.0) {
    r = 0.0;
  } else {
    boolean_T rEQ0;
    r = std::fmod(x, 0.033);
    rEQ0 = (r == 0.0);
    if (!rEQ0) {
      real_T q;
      q = std::abs(x / 0.033);
      rEQ0 = !(std::abs(q - std::floor(q + 0.5)) > 2.2204460492503131E-16 * q);
    }

    if (rEQ0) {
      r = 0.0;
    } else if (x < 0.0) {
      r += 0.033;
    }
  }

  return r;
}

/* Model step function */
void SspNeuromod_step(void)
{
  {
    real_T random_number;

    /* Reset subsysRan breadcrumbs */
    srClearBC(SspNeuromod_DW.EnabledSubsystem_SubsysRanBC);

    /* Memory: '<Root>/Memory5' */
    SspNeuromod_B.Memory5 = SspNeuromod_DW.Memory5_PreviousInput;

    /* Memory: '<Root>/Memory4' */
    SspNeuromod_B.Memory4 = SspNeuromod_DW.Memory4_PreviousInput;

    /* Memory: '<Root>/Memory6' */
    SspNeuromod_B.delay_in = SspNeuromod_DW.Memory6_PreviousInput;

    /* Clock: '<Root>/Clock' */
    SspNeuromod_B.clock_time = SspNeuromod_M->Timing.t[0];

    /* Constant: '<Root>/baselineTime' */
    SspNeuromod_B.baselineTime = SspNeuromod_cal->baselineTime;

    /* Memory: '<Root>/Memory3' */
    SspNeuromod_B.Memory3 = SspNeuromod_DW.Memory3_PreviousInput;

    /* Memory: '<Root>/Memory2' */
    SspNeuromod_B.Memory2 = SspNeuromod_DW.Memory2_PreviousInput;

    /* Memory: '<Root>/Memory1' */
    SspNeuromod_B.Memory1 = SspNeuromod_DW.Memory1_PreviousInput;

    /* Memory: '<Root>/Memory' */
    SspNeuromod_B.Memory = SspNeuromod_DW.Memory_PreviousInput;

    /* MATLAB Function: '<Root>/MATLAB Function' incorporates:
     *  Constant: '<Root>/LEDstimTime'
     */
    SspNeuromod_DW.sfEvent = SspNeuromod_CALL_EVENT;
    switch (static_cast<int32_T>(SspNeuromod_B.Memory5)) {
     case 1:
      SspNeuromod_B.localTime_out = 0.001;
      SspNeuromod_B.state_out = 2.0;
      SspNeuromod_B.imAcq_out = 0.0;
      SspNeuromod_B.LEDStim_out = 0.0;
      SspNeuromod_B.whiskStim_out = 0.0;
      SspNeuromod_B.trialNum_out = 1.0;
      random_number = 5999.0;
      while ((random_number >= 10000.0) || (random_number <= 6000.0)) {
        random_number = SspNeuromod_rand();
        random_number = std::log(random_number);
        random_number *= -8000.0;
      }

      SspNeuromod_B.delay_out = SspNeuromod_B.clock_time + random_number;
      break;

     case 2:
      if (SspNeuromod_B.clock_time < 1000.0) {
        SspNeuromod_B.state_out = SspNeuromod_B.Memory5;
      } else {
        SspNeuromod_B.state_out = 3.0;
      }

      SspNeuromod_B.localTime_out = SspNeuromod_B.Memory4 + 0.001;
      SspNeuromod_B.imAcq_out = SspNeuromod_B.Memory3;
      SspNeuromod_B.LEDStim_out = SspNeuromod_B.Memory2;
      SspNeuromod_B.whiskStim_out = SspNeuromod_B.Memory1;
      SspNeuromod_B.trialNum_out = SspNeuromod_B.Memory;
      SspNeuromod_B.delay_out = SspNeuromod_B.delay_in;
      break;

     case 3:
      if (SspNeuromod_mod(SspNeuromod_B.clock_time) < 2.2204460492503131E-16) {
        SspNeuromod_B.imAcq_out = 5.0;
      } else {
        SspNeuromod_B.imAcq_out = 0.0;
      }

      if (SspNeuromod_B.clock_time < SspNeuromod_B.baselineTime + 1000.0) {
        SspNeuromod_B.state_out = SspNeuromod_B.Memory5;
      } else {
        SspNeuromod_B.state_out = 4.0;
      }

      SspNeuromod_B.localTime_out = SspNeuromod_B.Memory4 + 0.001;
      SspNeuromod_B.LEDStim_out = 0.0;
      SspNeuromod_B.whiskStim_out = 0.0;
      SspNeuromod_B.trialNum_out = SspNeuromod_B.Memory;
      SspNeuromod_B.delay_out = SspNeuromod_B.delay_in;
      break;

     case 4:
      if (SspNeuromod_B.clock_time < (SspNeuromod_B.baselineTime + 1000.0) +
          SspNeuromod_cal->LEDstimTime) {
        SspNeuromod_B.state_out = SspNeuromod_B.Memory5;
      } else {
        SspNeuromod_B.state_out = 5.0;
      }

      SspNeuromod_B.localTime_out = SspNeuromod_B.Memory4 + 0.001;
      SspNeuromod_B.imAcq_out = 0.0;
      SspNeuromod_B.LEDStim_out = 1.0;
      SspNeuromod_B.whiskStim_out = 0.0;
      SspNeuromod_B.trialNum_out = SspNeuromod_B.Memory + 1.0;
      SspNeuromod_B.delay_out = SspNeuromod_B.delay_in;
      break;

     case 5:
      if (SspNeuromod_mod(SspNeuromod_B.clock_time) < 2.2204460492503131E-16) {
        SspNeuromod_B.imAcq_out = 5.0;
      } else {
        SspNeuromod_B.imAcq_out = 0.0;
      }

      if (SspNeuromod_B.clock_time < SspNeuromod_B.delay_in + 60000.0) {
        SspNeuromod_B.state_out = SspNeuromod_B.Memory5;
      } else {
        SspNeuromod_B.state_out = 4.0;
      }

      SspNeuromod_B.localTime_out = SspNeuromod_B.Memory4 + 1.0;
      SspNeuromod_B.LEDStim_out = 0.0;
      SspNeuromod_B.whiskStim_out = 1.0;
      SspNeuromod_B.trialNum_out = SspNeuromod_B.Memory;
      SspNeuromod_B.delay_out = SspNeuromod_B.delay_in;
      break;

     default:
      SspNeuromod_B.state_out = SspNeuromod_B.Memory5;
      SspNeuromod_B.localTime_out = SspNeuromod_B.Memory4;
      SspNeuromod_B.trialNum_out = SspNeuromod_B.Memory;
      SspNeuromod_B.imAcq_out = SspNeuromod_B.Memory3;
      SspNeuromod_B.LEDStim_out = SspNeuromod_B.Memory2;
      SspNeuromod_B.whiskStim_out = SspNeuromod_B.Memory1;
      SspNeuromod_B.delay_out = SspNeuromod_B.delay_in;
      break;
    }

    /* End of MATLAB Function: '<Root>/MATLAB Function' */
    /* S-Function (sg_IO191_setup_s): '<Root>/Setup ' */

    /* Level2 S-Function Block: '<Root>/Setup ' (sg_IO191_setup_s) */
    {
      SimStruct *rts = SspNeuromod_M->childSfunctions[0];
      sfcnOutputs(rts,0);
    }

    /* S-Function (sg_IO191_ad_s): '<Root>/Analog input ' */

    /* Level2 S-Function Block: '<Root>/Analog input ' (sg_IO191_ad_s) */
    {
      SimStruct *rts = SspNeuromod_M->childSfunctions[1];
      sfcnOutputs(rts,0);
    }

    /* S-Function (sg_IO191_da_s): '<Root>/Analog output ' */

    /* Level2 S-Function Block: '<Root>/Analog output ' (sg_IO191_da_s) */
    {
      SimStruct *rts = SspNeuromod_M->childSfunctions[2];
      sfcnOutputs(rts,0);
    }

    /* S-Function (sg_IO191_do_s): '<Root>/Digital output ' */

    /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
    {
      SimStruct *rts = SspNeuromod_M->childSfunctions[3];
      sfcnOutputs(rts,0);
    }

    /* S-Function (sg_IO191_di_s): '<Root>/Digital input ' */

    /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
    {
      SimStruct *rts = SspNeuromod_M->childSfunctions[4];
      sfcnOutputs(rts,0);
    }

    /* DiscretePulseGenerator: '<Root>/Whisk Stim' */
    SspNeuromod_B.WhiskStim = (SspNeuromod_DW.clockTickCounter <
      SspNeuromod_cal->WhiskStim_Duty) && (SspNeuromod_DW.clockTickCounter >= 0)
      ? SspNeuromod_cal->WhiskStim_Amp : 0.0;

    /* DiscretePulseGenerator: '<Root>/Whisk Stim' */
    if (SspNeuromod_DW.clockTickCounter >= SspNeuromod_cal->WhiskStim_Period -
        1.0) {
      SspNeuromod_DW.clockTickCounter = 0;
    } else {
      SspNeuromod_DW.clockTickCounter++;
    }

    /* Sin: '<Root>/Sine Wave' */
    if (SspNeuromod_DW.systemEnable != 0) {
      random_number = SspNeuromod_cal->SineWave_Freq * SspNeuromod_M->Timing.t[1];
      SspNeuromod_DW.lastSin = std::sin(random_number);
      SspNeuromod_DW.lastCos = std::cos(random_number);
      SspNeuromod_DW.systemEnable = 0;
    }

    /* Sin: '<Root>/Sine Wave' */
    SspNeuromod_B.SineWave = ((SspNeuromod_DW.lastSin *
      SspNeuromod_cal->SineWave_PCos + SspNeuromod_DW.lastCos *
      SspNeuromod_cal->SineWave_PSin) * SspNeuromod_cal->SineWave_HCos +
      (SspNeuromod_DW.lastCos * SspNeuromod_cal->SineWave_PCos -
       SspNeuromod_DW.lastSin * SspNeuromod_cal->SineWave_PSin) *
      SspNeuromod_cal->SineWave_Hsin) * SspNeuromod_cal->SineWave_Amp +
      SspNeuromod_cal->SineWave_Bias;

    /* Product: '<Root>/Product' */
    SspNeuromod_B.Product = SspNeuromod_B.WhiskStim * SspNeuromod_B.SineWave;

    /* Outputs for Enabled SubSystem: '<Root>/Enabled Subsystem' incorporates:
     *  EnablePort: '<S1>/Enable'
     */
    if (SspNeuromod_B.whiskStim_out > 0.0) {
      SspNeuromod_DW.EnabledSubsystem_MODE = true;

      /* SignalConversion generated from: '<S1>/whiskStim_out' */
      SspNeuromod_B.whiskStim_out_h = SspNeuromod_B.Product;
      srUpdateBC(SspNeuromod_DW.EnabledSubsystem_SubsysRanBC);
    } else {
      SspNeuromod_DW.EnabledSubsystem_MODE = false;
    }

    /* End of Outputs for SubSystem: '<Root>/Enabled Subsystem' */
    /* DiscretePulseGenerator: '<Root>/Pupil Trig' */
    random_number = SspNeuromod_cal->T_pupil / 2.0;

    /* DiscretePulseGenerator: '<Root>/Pupil Trig' */
    SspNeuromod_B.pupilCam_trig = (SspNeuromod_DW.clockTickCounter_l <
      random_number) && (SspNeuromod_DW.clockTickCounter_l >= 0) ?
      SspNeuromod_cal->PupilTrig_Amp : 0.0;

    /* DiscretePulseGenerator: '<Root>/Pupil Trig' */
    if (SspNeuromod_DW.clockTickCounter_l >= SspNeuromod_cal->T_pupil - 1.0) {
      SspNeuromod_DW.clockTickCounter_l = 0;
    } else {
      SspNeuromod_DW.clockTickCounter_l++;
    }
  }

  {
    real_T HoldCosine;
    real_T HoldSine;

    /* Update for Memory: '<Root>/Memory5' */
    SspNeuromod_DW.Memory5_PreviousInput = SspNeuromod_B.state_out;

    /* Update for Memory: '<Root>/Memory4' */
    SspNeuromod_DW.Memory4_PreviousInput = SspNeuromod_B.localTime_out;

    /* Update for Memory: '<Root>/Memory6' */
    SspNeuromod_DW.Memory6_PreviousInput = SspNeuromod_B.delay_out;

    /* Update for Memory: '<Root>/Memory3' */
    SspNeuromod_DW.Memory3_PreviousInput = SspNeuromod_B.imAcq_out;

    /* Update for Memory: '<Root>/Memory2' */
    SspNeuromod_DW.Memory2_PreviousInput = SspNeuromod_B.LEDStim_out;

    /* Update for Memory: '<Root>/Memory1' */
    SspNeuromod_DW.Memory1_PreviousInput = SspNeuromod_B.whiskStim_out;

    /* Update for Memory: '<Root>/Memory' */
    SspNeuromod_DW.Memory_PreviousInput = SspNeuromod_B.trialNum_out;

    /* Update for Sin: '<Root>/Sine Wave' */
    HoldSine = SspNeuromod_DW.lastSin;
    HoldCosine = SspNeuromod_DW.lastCos;
    SspNeuromod_DW.lastSin = HoldSine * SspNeuromod_cal->SineWave_HCos +
      HoldCosine * SspNeuromod_cal->SineWave_Hsin;
    SspNeuromod_DW.lastCos = HoldCosine * SspNeuromod_cal->SineWave_HCos -
      HoldSine * SspNeuromod_cal->SineWave_Hsin;
  }

  /* Update absolute time for base rate */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   * Timer of this task consists of two 32 bit unsigned integers.
   * The two integers represent the low bits Timing.clockTick0 and the high bits
   * Timing.clockTickH0. When the low bit overflows to 0, the high bits increment.
   */
  if (!(++SspNeuromod_M->Timing.clockTick0)) {
    ++SspNeuromod_M->Timing.clockTickH0;
  }

  SspNeuromod_M->Timing.t[0] = SspNeuromod_M->Timing.clockTick0 *
    SspNeuromod_M->Timing.stepSize0 + SspNeuromod_M->Timing.clockTickH0 *
    SspNeuromod_M->Timing.stepSize0 * 4294967296.0;

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
    if (!(++SspNeuromod_M->Timing.clockTick1)) {
      ++SspNeuromod_M->Timing.clockTickH1;
    }

    SspNeuromod_M->Timing.t[1] = SspNeuromod_M->Timing.clockTick1 *
      SspNeuromod_M->Timing.stepSize1 + SspNeuromod_M->Timing.clockTickH1 *
      SspNeuromod_M->Timing.stepSize1 * 4294967296.0;
  }
}

/* Model initialize function */
void SspNeuromod_initialize(void)
{
  /* Registration code */

  /* initialize non-finites */
  rt_InitInfAndNaN(sizeof(real_T));

  {
    /* Setup solver object */
    rtsiSetSimTimeStepPtr(&SspNeuromod_M->solverInfo,
                          &SspNeuromod_M->Timing.simTimeStep);
    rtsiSetTPtr(&SspNeuromod_M->solverInfo, &rtmGetTPtr(SspNeuromod_M));
    rtsiSetStepSizePtr(&SspNeuromod_M->solverInfo,
                       &SspNeuromod_M->Timing.stepSize0);
    rtsiSetErrorStatusPtr(&SspNeuromod_M->solverInfo, (&rtmGetErrorStatus
      (SspNeuromod_M)));
    rtsiSetRTModelPtr(&SspNeuromod_M->solverInfo, SspNeuromod_M);
  }

  rtsiSetSimTimeStep(&SspNeuromod_M->solverInfo, MAJOR_TIME_STEP);
  rtsiSetSolverName(&SspNeuromod_M->solverInfo,"FixedStepDiscrete");
  SspNeuromod_M->solverInfoPtr = (&SspNeuromod_M->solverInfo);

  /* Initialize timing info */
  {
    int_T *mdlTsMap = SspNeuromod_M->Timing.sampleTimeTaskIDArray;
    mdlTsMap[0] = 0;
    mdlTsMap[1] = 1;

    /* polyspace +2 MISRA2012:D4.1 [Justified:Low] "SspNeuromod_M points to
       static memory which is guaranteed to be non-NULL" */
    SspNeuromod_M->Timing.sampleTimeTaskIDPtr = (&mdlTsMap[0]);
    SspNeuromod_M->Timing.sampleTimes = (&SspNeuromod_M->
      Timing.sampleTimesArray[0]);
    SspNeuromod_M->Timing.offsetTimes = (&SspNeuromod_M->
      Timing.offsetTimesArray[0]);

    /* task periods */
    SspNeuromod_M->Timing.sampleTimes[0] = (0.0);
    SspNeuromod_M->Timing.sampleTimes[1] = (0.001);

    /* task offsets */
    SspNeuromod_M->Timing.offsetTimes[0] = (0.0);
    SspNeuromod_M->Timing.offsetTimes[1] = (0.0);
  }

  rtmSetTPtr(SspNeuromod_M, &SspNeuromod_M->Timing.tArray[0]);

  {
    int_T *mdlSampleHits = SspNeuromod_M->Timing.sampleHitArray;
    mdlSampleHits[0] = 1;
    mdlSampleHits[1] = 1;
    SspNeuromod_M->Timing.sampleHits = (&mdlSampleHits[0]);
  }

  rtmSetTFinal(SspNeuromod_M, -1);
  SspNeuromod_M->Timing.stepSize0 = 0.001;
  SspNeuromod_M->Timing.stepSize1 = 0.001;
  SspNeuromod_M->solverInfoPtr = (&SspNeuromod_M->solverInfo);
  SspNeuromod_M->Timing.stepSize = (0.001);
  rtsiSetFixedStepSize(&SspNeuromod_M->solverInfo, 0.001);
  rtsiSetSolverMode(&SspNeuromod_M->solverInfo, SOLVER_MODE_SINGLETASKING);

  /* block I/O */
  (void) std::memset((static_cast<void *>(&SspNeuromod_B)), 0,
                     sizeof(B_SspNeuromod_T));

  /* states (dwork) */
  (void) std::memset(static_cast<void *>(&SspNeuromod_DW), 0,
                     sizeof(DW_SspNeuromod_T));

  /* child S-Function registration */
  {
    RTWSfcnInfo *sfcnInfo = &SspNeuromod_M->NonInlinedSFcns.sfcnInfo;
    SspNeuromod_M->sfcnInfo = (sfcnInfo);
    rtssSetErrorStatusPtr(sfcnInfo, (&rtmGetErrorStatus(SspNeuromod_M)));
    SspNeuromod_M->Sizes.numSampTimes = (2);
    rtssSetNumRootSampTimesPtr(sfcnInfo, &SspNeuromod_M->Sizes.numSampTimes);
    SspNeuromod_M->NonInlinedSFcns.taskTimePtrs[0] = (&rtmGetTPtr(SspNeuromod_M)
      [0]);
    SspNeuromod_M->NonInlinedSFcns.taskTimePtrs[1] = (&rtmGetTPtr(SspNeuromod_M)
      [1]);
    rtssSetTPtrPtr(sfcnInfo,SspNeuromod_M->NonInlinedSFcns.taskTimePtrs);
    rtssSetTStartPtr(sfcnInfo, &rtmGetTStart(SspNeuromod_M));
    rtssSetTFinalPtr(sfcnInfo, &rtmGetTFinal(SspNeuromod_M));
    rtssSetTimeOfLastOutputPtr(sfcnInfo, &rtmGetTimeOfLastOutput(SspNeuromod_M));
    rtssSetStepSizePtr(sfcnInfo, &SspNeuromod_M->Timing.stepSize);
    rtssSetStopRequestedPtr(sfcnInfo, &rtmGetStopRequested(SspNeuromod_M));
    rtssSetDerivCacheNeedsResetPtr(sfcnInfo,
      &SspNeuromod_M->derivCacheNeedsReset);
    rtssSetZCCacheNeedsResetPtr(sfcnInfo, &SspNeuromod_M->zCCacheNeedsReset);
    rtssSetContTimeOutputInconsistentWithStateAtMajorStepPtr(sfcnInfo,
      &SspNeuromod_M->CTOutputIncnstWithState);
    rtssSetSampleHitsPtr(sfcnInfo, &SspNeuromod_M->Timing.sampleHits);
    rtssSetPerTaskSampleHitsPtr(sfcnInfo,
      &SspNeuromod_M->Timing.perTaskSampleHits);
    rtssSetSimModePtr(sfcnInfo, &SspNeuromod_M->simMode);
    rtssSetSolverInfoPtr(sfcnInfo, &SspNeuromod_M->solverInfoPtr);
  }

  SspNeuromod_M->Sizes.numSFcns = (5);

  /* register each child */
  {
    (void) std::memset(static_cast<void *>
                       (&SspNeuromod_M->NonInlinedSFcns.childSFunctions[0]), 0,
                       5*sizeof(SimStruct));
    SspNeuromod_M->childSfunctions =
      (&SspNeuromod_M->NonInlinedSFcns.childSFunctionPtrs[0]);

    {
      int_T i;
      for (i = 0; i < 5; i++) {
        SspNeuromod_M->childSfunctions[i] =
          (&SspNeuromod_M->NonInlinedSFcns.childSFunctions[i]);
      }
    }

    /* Level2 S-Function Block: SspNeuromod/<Root>/Setup  (sg_IO191_setup_s) */
    {
      SimStruct *rts = SspNeuromod_M->childSfunctions[0];

      /* timing info */
      time_T *sfcnPeriod = SspNeuromod_M->NonInlinedSFcns.Sfcn0.sfcnPeriod;
      time_T *sfcnOffset = SspNeuromod_M->NonInlinedSFcns.Sfcn0.sfcnOffset;
      int_T *sfcnTsMap = SspNeuromod_M->NonInlinedSFcns.Sfcn0.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &SspNeuromod_M->NonInlinedSFcns.blkInfo2[0]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &SspNeuromod_M->NonInlinedSFcns.inputOutputPortInfo2[0]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, SspNeuromod_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &SspNeuromod_M->NonInlinedSFcns.methods2[0]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &SspNeuromod_M->NonInlinedSFcns.methods3[0]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &SspNeuromod_M->NonInlinedSFcns.methods4[0]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &SspNeuromod_M->NonInlinedSFcns.statesInfo2[0]);
        ssSetPeriodicStatesInfo(rts,
          &SspNeuromod_M->NonInlinedSFcns.periodicStatesInfo[0]);
      }

      /* path info */
      ssSetModelName(rts, "Setup ");
      ssSetPath(rts, "SspNeuromod/Setup ");
      ssSetRTModel(rts,SspNeuromod_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn0.params;
        ssSetSFcnParamsCount(rts, 9);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)SspNeuromod_cal->Setup_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)SspNeuromod_cal->Setup_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)SspNeuromod_cal->Setup_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)SspNeuromod_cal->Setup_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)SspNeuromod_cal->Setup_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)SspNeuromod_cal->Setup_P6_Size);
        ssSetSFcnParam(rts, 6, (mxArray*)SspNeuromod_cal->Setup_P7_Size);
        ssSetSFcnParam(rts, 7, (mxArray*)SspNeuromod_cal->Setup_P8_Size);
        ssSetSFcnParam(rts, 8, (mxArray*)SspNeuromod_cal->Setup_P9_Size);
      }

      /* work vectors */
      ssSetRWork(rts, (real_T *) &SspNeuromod_DW.Setup_RWORK[0]);
      ssSetPWork(rts, (void **) &SspNeuromod_DW.Setup_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn0.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn0.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 2);

        /* RWORK */
        ssSetDWorkWidthAsInt(rts, 0, 2);
        ssSetDWorkDataType(rts, 0,SS_DOUBLE);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &SspNeuromod_DW.Setup_RWORK[0]);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 1, 1);
        ssSetDWorkDataType(rts, 1,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 1, 0);
        ssSetDWork(rts, 1, &SspNeuromod_DW.Setup_PWORK);
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

    /* Level2 S-Function Block: SspNeuromod/<Root>/Analog input  (sg_IO191_ad_s) */
    {
      SimStruct *rts = SspNeuromod_M->childSfunctions[1];

      /* timing info */
      time_T *sfcnPeriod = SspNeuromod_M->NonInlinedSFcns.Sfcn1.sfcnPeriod;
      time_T *sfcnOffset = SspNeuromod_M->NonInlinedSFcns.Sfcn1.sfcnOffset;
      int_T *sfcnTsMap = SspNeuromod_M->NonInlinedSFcns.Sfcn1.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &SspNeuromod_M->NonInlinedSFcns.blkInfo2[1]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &SspNeuromod_M->NonInlinedSFcns.inputOutputPortInfo2[1]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, SspNeuromod_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &SspNeuromod_M->NonInlinedSFcns.methods2[1]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &SspNeuromod_M->NonInlinedSFcns.methods3[1]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &SspNeuromod_M->NonInlinedSFcns.methods4[1]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &SspNeuromod_M->NonInlinedSFcns.statesInfo2[1]);
        ssSetPeriodicStatesInfo(rts,
          &SspNeuromod_M->NonInlinedSFcns.periodicStatesInfo[1]);
      }

      /* outputs */
      {
        ssSetPortInfoForOutputs(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn1.outputPortInfo[0]);
        ssSetPortInfoForOutputs(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn1.outputPortInfo[0]);
        _ssSetNumOutputPorts(rts, 2);
        _ssSetPortInfo2ForOutputUnits(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn1.outputPortUnits[0]);
        ssSetOutputPortUnit(rts, 0, 0);
        ssSetOutputPortUnit(rts, 1, 0);
        _ssSetPortInfo2ForOutputCoSimAttribute(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn1.outputPortCoSimAttribute[0]);
        ssSetOutputPortIsContinuousQuantity(rts, 0, 0);
        ssSetOutputPortIsContinuousQuantity(rts, 1, 0);

        /* port 0 */
        {
          _ssSetOutputPortNumDimensions(rts, 0, 1);
          ssSetOutputPortWidthAsInt(rts, 0, 1);
          ssSetOutputPortSignal(rts, 0, ((real_T *)
            &SspNeuromod_B.Analoginput_o1));
        }

        /* port 1 */
        {
          _ssSetOutputPortNumDimensions(rts, 1, 1);
          ssSetOutputPortWidthAsInt(rts, 1, 1);
          ssSetOutputPortSignal(rts, 1, ((real_T *)
            &SspNeuromod_B.Analoginput_o2));
        }
      }

      /* path info */
      ssSetModelName(rts, "Analog input ");
      ssSetPath(rts, "SspNeuromod/Analog input ");
      ssSetRTModel(rts,SspNeuromod_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn1.params;
        ssSetSFcnParamsCount(rts, 9);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)SspNeuromod_cal->Analoginput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)SspNeuromod_cal->Analoginput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)SspNeuromod_cal->Analoginput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)SspNeuromod_cal->Analoginput_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)SspNeuromod_cal->Analoginput_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)SspNeuromod_cal->Analoginput_P6_Size);
        ssSetSFcnParam(rts, 6, (mxArray*)SspNeuromod_cal->Analoginput_P7_Size);
        ssSetSFcnParam(rts, 7, (mxArray*)SspNeuromod_cal->Analoginput_P8_Size);
        ssSetSFcnParam(rts, 8, (mxArray*)SspNeuromod_cal->Analoginput_P9_Size);
      }

      /* work vectors */
      ssSetIWork(rts, (int_T *) &SspNeuromod_DW.Analoginput_IWORK[0]);
      ssSetPWork(rts, (void **) &SspNeuromod_DW.Analoginput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn1.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn1.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 2);

        /* IWORK */
        ssSetDWorkWidthAsInt(rts, 0, 2);
        ssSetDWorkDataType(rts, 0,SS_INTEGER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &SspNeuromod_DW.Analoginput_IWORK[0]);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 1, 1);
        ssSetDWorkDataType(rts, 1,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 1, 0);
        ssSetDWork(rts, 1, &SspNeuromod_DW.Analoginput_PWORK);
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
      _ssSetOutputPortConnected(rts, 1, 0);
      _ssSetOutputPortBeingMerged(rts, 0, 0);
      _ssSetOutputPortBeingMerged(rts, 1, 0);

      /* Update the BufferDstPort flags for each input port */
    }

    /* Level2 S-Function Block: SspNeuromod/<Root>/Analog output  (sg_IO191_da_s) */
    {
      SimStruct *rts = SspNeuromod_M->childSfunctions[2];

      /* timing info */
      time_T *sfcnPeriod = SspNeuromod_M->NonInlinedSFcns.Sfcn2.sfcnPeriod;
      time_T *sfcnOffset = SspNeuromod_M->NonInlinedSFcns.Sfcn2.sfcnOffset;
      int_T *sfcnTsMap = SspNeuromod_M->NonInlinedSFcns.Sfcn2.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &SspNeuromod_M->NonInlinedSFcns.blkInfo2[2]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &SspNeuromod_M->NonInlinedSFcns.inputOutputPortInfo2[2]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, SspNeuromod_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &SspNeuromod_M->NonInlinedSFcns.methods2[2]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &SspNeuromod_M->NonInlinedSFcns.methods3[2]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &SspNeuromod_M->NonInlinedSFcns.methods4[2]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &SspNeuromod_M->NonInlinedSFcns.statesInfo2[2]);
        ssSetPeriodicStatesInfo(rts,
          &SspNeuromod_M->NonInlinedSFcns.periodicStatesInfo[2]);
      }

      /* inputs */
      {
        _ssSetNumInputPorts(rts, 2);
        ssSetPortInfoForInputs(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn2.inputPortInfo[0]);
        ssSetPortInfoForInputs(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn2.inputPortInfo[0]);
        _ssSetPortInfo2ForInputUnits(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn2.inputPortUnits[0]);
        ssSetInputPortUnit(rts, 0, 0);
        ssSetInputPortUnit(rts, 1, 0);
        _ssSetPortInfo2ForInputCoSimAttribute(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn2.inputPortCoSimAttribute[0]);
        ssSetInputPortIsContinuousQuantity(rts, 0, 0);
        ssSetInputPortIsContinuousQuantity(rts, 1, 0);

        /* port 0 */
        {
          ssSetInputPortRequiredContiguous(rts, 0, 1);
          ssSetInputPortSignal(rts, 0, (const_cast<real_T*>(&SspNeuromod_RGND)));
          _ssSetInputPortNumDimensions(rts, 0, 1);
          ssSetInputPortWidthAsInt(rts, 0, 1);
        }

        /* port 1 */
        {
          ssSetInputPortRequiredContiguous(rts, 1, 1);
          ssSetInputPortSignal(rts, 1, (const_cast<real_T*>(&SspNeuromod_RGND)));
          _ssSetInputPortNumDimensions(rts, 1, 1);
          ssSetInputPortWidthAsInt(rts, 1, 1);
        }
      }

      /* path info */
      ssSetModelName(rts, "Analog output ");
      ssSetPath(rts, "SspNeuromod/Analog output ");
      ssSetRTModel(rts,SspNeuromod_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn2.params;
        ssSetSFcnParamsCount(rts, 7);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)SspNeuromod_cal->Analogoutput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)SspNeuromod_cal->Analogoutput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)SspNeuromod_cal->Analogoutput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)SspNeuromod_cal->Analogoutput_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)SspNeuromod_cal->Analogoutput_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)SspNeuromod_cal->Analogoutput_P6_Size);
        ssSetSFcnParam(rts, 6, (mxArray*)SspNeuromod_cal->Analogoutput_P7_Size);
      }

      /* work vectors */
      ssSetPWork(rts, (void **) &SspNeuromod_DW.Analogoutput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn2.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn2.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 1);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 0, 1);
        ssSetDWorkDataType(rts, 0,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &SspNeuromod_DW.Analogoutput_PWORK);
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
      _ssSetInputPortConnected(rts, 0, 0);
      _ssSetInputPortConnected(rts, 1, 0);

      /* Update the BufferDstPort flags for each input port */
      ssSetInputPortBufferDstPort(rts, 0, -1);
      ssSetInputPortBufferDstPort(rts, 1, -1);
    }

    /* Level2 S-Function Block: SspNeuromod/<Root>/Digital output  (sg_IO191_do_s) */
    {
      SimStruct *rts = SspNeuromod_M->childSfunctions[3];

      /* timing info */
      time_T *sfcnPeriod = SspNeuromod_M->NonInlinedSFcns.Sfcn3.sfcnPeriod;
      time_T *sfcnOffset = SspNeuromod_M->NonInlinedSFcns.Sfcn3.sfcnOffset;
      int_T *sfcnTsMap = SspNeuromod_M->NonInlinedSFcns.Sfcn3.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &SspNeuromod_M->NonInlinedSFcns.blkInfo2[3]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &SspNeuromod_M->NonInlinedSFcns.inputOutputPortInfo2[3]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, SspNeuromod_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &SspNeuromod_M->NonInlinedSFcns.methods2[3]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &SspNeuromod_M->NonInlinedSFcns.methods3[3]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &SspNeuromod_M->NonInlinedSFcns.methods4[3]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &SspNeuromod_M->NonInlinedSFcns.statesInfo2[3]);
        ssSetPeriodicStatesInfo(rts,
          &SspNeuromod_M->NonInlinedSFcns.periodicStatesInfo[3]);
      }

      /* inputs */
      {
        _ssSetNumInputPorts(rts, 12);
        ssSetPortInfoForInputs(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn3.inputPortInfo[0]);
        ssSetPortInfoForInputs(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn3.inputPortInfo[0]);
        _ssSetPortInfo2ForInputUnits(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn3.inputPortUnits[0]);
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
        _ssSetPortInfo2ForInputCoSimAttribute(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn3.inputPortCoSimAttribute[0]);
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

        /* port 0 */
        {
          ssSetInputPortRequiredContiguous(rts, 0, 1);
          ssSetInputPortSignal(rts, 0, (const_cast<real_T*>(&SspNeuromod_RGND)));
          _ssSetInputPortNumDimensions(rts, 0, 1);
          ssSetInputPortWidthAsInt(rts, 0, 1);
        }

        /* port 1 */
        {
          ssSetInputPortRequiredContiguous(rts, 1, 1);
          ssSetInputPortSignal(rts, 1, (const_cast<real_T*>(&SspNeuromod_RGND)));
          _ssSetInputPortNumDimensions(rts, 1, 1);
          ssSetInputPortWidthAsInt(rts, 1, 1);
        }

        /* port 2 */
        {
          ssSetInputPortRequiredContiguous(rts, 2, 1);
          ssSetInputPortSignal(rts, 2, (const_cast<real_T*>(&SspNeuromod_RGND)));
          _ssSetInputPortNumDimensions(rts, 2, 1);
          ssSetInputPortWidthAsInt(rts, 2, 1);
        }

        /* port 3 */
        {
          ssSetInputPortRequiredContiguous(rts, 3, 1);
          ssSetInputPortSignal(rts, 3, (const_cast<real_T*>(&SspNeuromod_RGND)));
          _ssSetInputPortNumDimensions(rts, 3, 1);
          ssSetInputPortWidthAsInt(rts, 3, 1);
        }

        /* port 4 */
        {
          ssSetInputPortRequiredContiguous(rts, 4, 1);
          ssSetInputPortSignal(rts, 4, (const_cast<real_T*>(&SspNeuromod_RGND)));
          _ssSetInputPortNumDimensions(rts, 4, 1);
          ssSetInputPortWidthAsInt(rts, 4, 1);
        }

        /* port 5 */
        {
          ssSetInputPortRequiredContiguous(rts, 5, 1);
          ssSetInputPortSignal(rts, 5, (const_cast<real_T*>(&SspNeuromod_RGND)));
          _ssSetInputPortNumDimensions(rts, 5, 1);
          ssSetInputPortWidthAsInt(rts, 5, 1);
        }

        /* port 6 */
        {
          ssSetInputPortRequiredContiguous(rts, 6, 1);
          ssSetInputPortSignal(rts, 6, (const_cast<real_T*>(&SspNeuromod_RGND)));
          _ssSetInputPortNumDimensions(rts, 6, 1);
          ssSetInputPortWidthAsInt(rts, 6, 1);
        }

        /* port 7 */
        {
          ssSetInputPortRequiredContiguous(rts, 7, 1);
          ssSetInputPortSignal(rts, 7, (const_cast<real_T*>(&SspNeuromod_RGND)));
          _ssSetInputPortNumDimensions(rts, 7, 1);
          ssSetInputPortWidthAsInt(rts, 7, 1);
        }

        /* port 8 */
        {
          ssSetInputPortRequiredContiguous(rts, 8, 1);
          ssSetInputPortSignal(rts, 8, &SspNeuromod_B.imAcq_out);
          _ssSetInputPortNumDimensions(rts, 8, 1);
          ssSetInputPortWidthAsInt(rts, 8, 1);
        }

        /* port 9 */
        {
          ssSetInputPortRequiredContiguous(rts, 9, 1);
          ssSetInputPortSignal(rts, 9, &SspNeuromod_B.LEDStim_out);
          _ssSetInputPortNumDimensions(rts, 9, 1);
          ssSetInputPortWidthAsInt(rts, 9, 1);
        }

        /* port 10 */
        {
          ssSetInputPortRequiredContiguous(rts, 10, 1);
          ssSetInputPortSignal(rts, 10, &SspNeuromod_B.whiskStim_out);
          _ssSetInputPortNumDimensions(rts, 10, 1);
          ssSetInputPortWidthAsInt(rts, 10, 1);
        }

        /* port 11 */
        {
          ssSetInputPortRequiredContiguous(rts, 11, 1);
          ssSetInputPortSignal(rts, 11, (const_cast<real_T*>(&SspNeuromod_RGND)));
          _ssSetInputPortNumDimensions(rts, 11, 1);
          ssSetInputPortWidthAsInt(rts, 11, 1);
        }
      }

      /* path info */
      ssSetModelName(rts, "Digital output ");
      ssSetPath(rts, "SspNeuromod/Digital output ");
      ssSetRTModel(rts,SspNeuromod_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn3.params;
        ssSetSFcnParamsCount(rts, 6);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)SspNeuromod_cal->Digitaloutput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)SspNeuromod_cal->Digitaloutput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)SspNeuromod_cal->Digitaloutput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)SspNeuromod_cal->Digitaloutput_P4_Size);
        ssSetSFcnParam(rts, 4, (mxArray*)SspNeuromod_cal->Digitaloutput_P5_Size);
        ssSetSFcnParam(rts, 5, (mxArray*)SspNeuromod_cal->Digitaloutput_P6_Size);
      }

      /* work vectors */
      ssSetPWork(rts, (void **) &SspNeuromod_DW.Digitaloutput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn3.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn3.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 1);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 0, 1);
        ssSetDWorkDataType(rts, 0,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &SspNeuromod_DW.Digitaloutput_PWORK);
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
      _ssSetInputPortConnected(rts, 2, 0);
      _ssSetInputPortConnected(rts, 3, 0);
      _ssSetInputPortConnected(rts, 4, 0);
      _ssSetInputPortConnected(rts, 5, 0);
      _ssSetInputPortConnected(rts, 6, 0);
      _ssSetInputPortConnected(rts, 7, 0);
      _ssSetInputPortConnected(rts, 8, 1);
      _ssSetInputPortConnected(rts, 9, 1);
      _ssSetInputPortConnected(rts, 10, 1);
      _ssSetInputPortConnected(rts, 11, 0);

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
    }

    /* Level2 S-Function Block: SspNeuromod/<Root>/Digital input  (sg_IO191_di_s) */
    {
      SimStruct *rts = SspNeuromod_M->childSfunctions[4];

      /* timing info */
      time_T *sfcnPeriod = SspNeuromod_M->NonInlinedSFcns.Sfcn4.sfcnPeriod;
      time_T *sfcnOffset = SspNeuromod_M->NonInlinedSFcns.Sfcn4.sfcnOffset;
      int_T *sfcnTsMap = SspNeuromod_M->NonInlinedSFcns.Sfcn4.sfcnTsMap;
      (void) std::memset(static_cast<void*>(sfcnPeriod), 0,
                         sizeof(time_T)*1);
      (void) std::memset(static_cast<void*>(sfcnOffset), 0,
                         sizeof(time_T)*1);
      ssSetSampleTimePtr(rts, &sfcnPeriod[0]);
      ssSetOffsetTimePtr(rts, &sfcnOffset[0]);
      ssSetSampleTimeTaskIDPtr(rts, sfcnTsMap);

      {
        ssSetBlkInfo2Ptr(rts, &SspNeuromod_M->NonInlinedSFcns.blkInfo2[4]);
      }

      _ssSetBlkInfo2PortInfo2Ptr(rts,
        &SspNeuromod_M->NonInlinedSFcns.inputOutputPortInfo2[4]);

      /* Set up the mdlInfo pointer */
      ssSetRTWSfcnInfo(rts, SspNeuromod_M->sfcnInfo);

      /* Allocate memory of model methods 2 */
      {
        ssSetModelMethods2(rts, &SspNeuromod_M->NonInlinedSFcns.methods2[4]);
      }

      /* Allocate memory of model methods 3 */
      {
        ssSetModelMethods3(rts, &SspNeuromod_M->NonInlinedSFcns.methods3[4]);
      }

      /* Allocate memory of model methods 4 */
      {
        ssSetModelMethods4(rts, &SspNeuromod_M->NonInlinedSFcns.methods4[4]);
      }

      /* Allocate memory for states auxilliary information */
      {
        ssSetStatesInfo2(rts, &SspNeuromod_M->NonInlinedSFcns.statesInfo2[4]);
        ssSetPeriodicStatesInfo(rts,
          &SspNeuromod_M->NonInlinedSFcns.periodicStatesInfo[4]);
      }

      /* outputs */
      {
        ssSetPortInfoForOutputs(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn4.outputPortInfo[0]);
        ssSetPortInfoForOutputs(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn4.outputPortInfo[0]);
        _ssSetNumOutputPorts(rts, 4);
        _ssSetPortInfo2ForOutputUnits(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn4.outputPortUnits[0]);
        ssSetOutputPortUnit(rts, 0, 0);
        ssSetOutputPortUnit(rts, 1, 0);
        ssSetOutputPortUnit(rts, 2, 0);
        ssSetOutputPortUnit(rts, 3, 0);
        _ssSetPortInfo2ForOutputCoSimAttribute(rts,
          &SspNeuromod_M->NonInlinedSFcns.Sfcn4.outputPortCoSimAttribute[0]);
        ssSetOutputPortIsContinuousQuantity(rts, 0, 0);
        ssSetOutputPortIsContinuousQuantity(rts, 1, 0);
        ssSetOutputPortIsContinuousQuantity(rts, 2, 0);
        ssSetOutputPortIsContinuousQuantity(rts, 3, 0);

        /* port 0 */
        {
          _ssSetOutputPortNumDimensions(rts, 0, 1);
          ssSetOutputPortWidthAsInt(rts, 0, 1);
          ssSetOutputPortSignal(rts, 0, ((real_T *)
            &SspNeuromod_B.Digitalinput_o1));
        }

        /* port 1 */
        {
          _ssSetOutputPortNumDimensions(rts, 1, 1);
          ssSetOutputPortWidthAsInt(rts, 1, 1);
          ssSetOutputPortSignal(rts, 1, ((real_T *)
            &SspNeuromod_B.Digitalinput_o2));
        }

        /* port 2 */
        {
          _ssSetOutputPortNumDimensions(rts, 2, 1);
          ssSetOutputPortWidthAsInt(rts, 2, 1);
          ssSetOutputPortSignal(rts, 2, ((real_T *)
            &SspNeuromod_B.Digitalinput_o3));
        }

        /* port 3 */
        {
          _ssSetOutputPortNumDimensions(rts, 3, 1);
          ssSetOutputPortWidthAsInt(rts, 3, 1);
          ssSetOutputPortSignal(rts, 3, ((real_T *)
            &SspNeuromod_B.Digitalinput_o4));
        }
      }

      /* path info */
      ssSetModelName(rts, "Digital input ");
      ssSetPath(rts, "SspNeuromod/Digital input ");
      ssSetRTModel(rts,SspNeuromod_M);
      ssSetParentSS(rts, (NULL));
      ssSetRootSS(rts, rts);
      ssSetVersion(rts, SIMSTRUCT_VERSION_LEVEL2);

      /* parameters */
      {
        mxArray **sfcnParams = (mxArray **)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn4.params;
        ssSetSFcnParamsCount(rts, 4);
        ssSetSFcnParamsPtr(rts, &sfcnParams[0]);
        ssSetSFcnParam(rts, 0, (mxArray*)SspNeuromod_cal->Digitalinput_P1_Size);
        ssSetSFcnParam(rts, 1, (mxArray*)SspNeuromod_cal->Digitalinput_P2_Size);
        ssSetSFcnParam(rts, 2, (mxArray*)SspNeuromod_cal->Digitalinput_P3_Size);
        ssSetSFcnParam(rts, 3, (mxArray*)SspNeuromod_cal->Digitalinput_P4_Size);
      }

      /* work vectors */
      ssSetPWork(rts, (void **) &SspNeuromod_DW.Digitalinput_PWORK);

      {
        struct _ssDWorkRecord *dWorkRecord = (struct _ssDWorkRecord *)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn4.dWork;
        struct _ssDWorkAuxRecord *dWorkAuxRecord = (struct _ssDWorkAuxRecord *)
          &SspNeuromod_M->NonInlinedSFcns.Sfcn4.dWorkAux;
        ssSetSFcnDWork(rts, dWorkRecord);
        ssSetSFcnDWorkAux(rts, dWorkAuxRecord);
        ssSetNumDWorkAsInt(rts, 1);

        /* PWORK */
        ssSetDWorkWidthAsInt(rts, 0, 1);
        ssSetDWorkDataType(rts, 0,SS_POINTER);
        ssSetDWorkComplexSignal(rts, 0, 0);
        ssSetDWork(rts, 0, &SspNeuromod_DW.Digitalinput_PWORK);
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
      _ssSetOutputPortConnected(rts, 0, 0);
      _ssSetOutputPortConnected(rts, 1, 0);
      _ssSetOutputPortConnected(rts, 2, 0);
      _ssSetOutputPortConnected(rts, 3, 0);
      _ssSetOutputPortBeingMerged(rts, 0, 0);
      _ssSetOutputPortBeingMerged(rts, 1, 0);
      _ssSetOutputPortBeingMerged(rts, 2, 0);
      _ssSetOutputPortBeingMerged(rts, 3, 0);

      /* Update the BufferDstPort flags for each input port */
    }
  }

  /* Start for Constant: '<Root>/baselineTime' */
  SspNeuromod_B.baselineTime = SspNeuromod_cal->baselineTime;

  /* Start for S-Function (sg_IO191_setup_s): '<Root>/Setup ' */
  /* Level2 S-Function Block: '<Root>/Setup ' (sg_IO191_setup_s) */
  {
    SimStruct *rts = SspNeuromod_M->childSfunctions[0];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_ad_s): '<Root>/Analog input ' */
  /* Level2 S-Function Block: '<Root>/Analog input ' (sg_IO191_ad_s) */
  {
    SimStruct *rts = SspNeuromod_M->childSfunctions[1];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_da_s): '<Root>/Analog output ' */
  /* Level2 S-Function Block: '<Root>/Analog output ' (sg_IO191_da_s) */
  {
    SimStruct *rts = SspNeuromod_M->childSfunctions[2];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_do_s): '<Root>/Digital output ' */
  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = SspNeuromod_M->childSfunctions[3];
    sfcnStart(rts);
    if (ssGetErrorStatus(rts) != (NULL))
      return;
  }

  /* Start for S-Function (sg_IO191_di_s): '<Root>/Digital input ' */
  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = SspNeuromod_M->childSfunctions[4];
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

    /* InitializeConditions for Memory: '<Root>/Memory5' */
    SspNeuromod_DW.Memory5_PreviousInput =
      SspNeuromod_cal->Memory5_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory4' */
    SspNeuromod_DW.Memory4_PreviousInput =
      SspNeuromod_cal->Memory4_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory6' */
    SspNeuromod_DW.Memory6_PreviousInput =
      SspNeuromod_cal->Memory6_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory3' */
    SspNeuromod_DW.Memory3_PreviousInput =
      SspNeuromod_cal->Memory3_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory2' */
    SspNeuromod_DW.Memory2_PreviousInput =
      SspNeuromod_cal->Memory2_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory1' */
    SspNeuromod_DW.Memory1_PreviousInput =
      SspNeuromod_cal->Memory1_InitialCondition;

    /* InitializeConditions for Memory: '<Root>/Memory' */
    SspNeuromod_DW.Memory_PreviousInput =
      SspNeuromod_cal->Memory_InitialCondition;

    /* InitializeConditions for DiscretePulseGenerator: '<Root>/Whisk Stim' */
    SspNeuromod_DW.clockTickCounter = 0;

    /* InitializeConditions for DiscretePulseGenerator: '<Root>/Pupil Trig' */
    SspNeuromod_DW.clockTickCounter_l = 0;

    /* SystemInitialize for MATLAB Function: '<Root>/MATLAB Function' */
    std::memcpy(&SspNeuromod_DW.state_k[0], &tmp[0], 625U * sizeof(uint32_T));
    SspNeuromod_DW.sfEvent = SspNeuromod_CALL_EVENT;
    SspNeuromod_DW.is_active_c1_SspNeuromod = 0U;
    SspNeuromod_DW.method = 7U;
    SspNeuromod_DW.method_not_empty = true;
    SspNeuromod_DW.state = 1144108930U;
    SspNeuromod_DW.state_not_empty = true;
    SspNeuromod_DW.state_p[0] = 362436069U;
    SspNeuromod_DW.state_p[1] = 521288629U;
    SspNeuromod_DW.state_not_empty_k = true;
    SspNeuromod_DW.state_not_empty_d = true;

    /* SystemInitialize for Enabled SubSystem: '<Root>/Enabled Subsystem' */
    /* SystemInitialize for SignalConversion generated from: '<S1>/whiskStim_out' incorporates:
     *  Outport: '<S1>/Out1'
     */
    SspNeuromod_B.whiskStim_out_h = SspNeuromod_cal->Out1_Y0;

    /* End of SystemInitialize for SubSystem: '<Root>/Enabled Subsystem' */
  }

  /* Enable for Sin: '<Root>/Sine Wave' */
  SspNeuromod_DW.systemEnable = 1;
}

/* Model terminate function */
void SspNeuromod_terminate(void)
{
  /* Terminate for S-Function (sg_IO191_setup_s): '<Root>/Setup ' */
  /* Level2 S-Function Block: '<Root>/Setup ' (sg_IO191_setup_s) */
  {
    SimStruct *rts = SspNeuromod_M->childSfunctions[0];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_ad_s): '<Root>/Analog input ' */
  /* Level2 S-Function Block: '<Root>/Analog input ' (sg_IO191_ad_s) */
  {
    SimStruct *rts = SspNeuromod_M->childSfunctions[1];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_da_s): '<Root>/Analog output ' */
  /* Level2 S-Function Block: '<Root>/Analog output ' (sg_IO191_da_s) */
  {
    SimStruct *rts = SspNeuromod_M->childSfunctions[2];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_do_s): '<Root>/Digital output ' */
  /* Level2 S-Function Block: '<Root>/Digital output ' (sg_IO191_do_s) */
  {
    SimStruct *rts = SspNeuromod_M->childSfunctions[3];
    sfcnTerminate(rts);
  }

  /* Terminate for S-Function (sg_IO191_di_s): '<Root>/Digital input ' */
  /* Level2 S-Function Block: '<Root>/Digital input ' (sg_IO191_di_s) */
  {
    SimStruct *rts = SspNeuromod_M->childSfunctions[4];
    sfcnTerminate(rts);
  }
}
