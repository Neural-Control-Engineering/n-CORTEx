#ifndef RTW_HEADER_nCORTEx_vt_cal_h_
#define RTW_HEADER_nCORTEx_vt_cal_h_
#include "rtwtypes.h"

/* Storage class 'PageSwitching', for system '<Root>' */
struct nCORTEx_vt_cal_type {
  real_T WhiskerTrig_Amp;              /* Expression: 1
                                        * Referenced by: '<Root>/Whisker Trig'
                                        */
  real_T WhiskerTrig_Period;           /* Expression: 20
                                        * Referenced by: '<Root>/Whisker Trig'
                                        */
  real_T WhiskerTrig_Duty;             /* Expression: 10
                                        * Referenced by: '<Root>/Whisker Trig'
                                        */
  real_T WhiskerTrig_PhaseDelay;       /* Expression: 0
                                        * Referenced by: '<Root>/Whisker Trig'
                                        */
  real_T NpxlsTrig_Amp;                /* Expression: 1
                                        * Referenced by: '<Root>/Npxls Trig'
                                        */
  real_T NpxlsTrig_Period;             /* Expression: 4
                                        * Referenced by: '<Root>/Npxls Trig'
                                        */
  real_T NpxlsTrig_Duty;               /* Expression: 2
                                        * Referenced by: '<Root>/Npxls Trig'
                                        */
  real_T NpxlsTrig_PhaseDelay;         /* Expression: 0
                                        * Referenced by: '<Root>/Npxls Trig'
                                        */
  real_T PupilTrig_Amp;                /* Expression: 1
                                        * Referenced by: '<Root>/Pupil Trig'
                                        */
  real_T PupilTrig_Period;             /* Expression: 100
                                        * Referenced by: '<Root>/Pupil Trig'
                                        */
  real_T PupilTrig_Duty;               /* Expression: 50
                                        * Referenced by: '<Root>/Pupil Trig'
                                        */
  real_T PupilTrig_PhaseDelay;         /* Expression: 0
                                        * Referenced by: '<Root>/Pupil Trig'
                                        */
  real_T Memory2_InitialCondition;     /* Expression: 1
                                        * Referenced by: '<Root>/Memory2'
                                        */
  real_T Memory1_InitialCondition;     /* Expression: 0
                                        * Referenced by: '<Root>/Memory1'
                                        */
  real_T Memory_InitialCondition;      /* Expression: 0
                                        * Referenced by: '<Root>/Memory'
                                        */
  real_T Setup_P1_Size[2];             /* Computed Parameter: Setup_P1_Size
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P1;                     /* Expression: parPciSlot
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P2_Size[2];             /* Computed Parameter: Setup_P2_Size
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P2;                     /* Expression: parModuleId
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P3_Size[2];             /* Computed Parameter: Setup_P3_Size
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P3;                     /* Expression: parTriggerSignal
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P4_Size[2];             /* Computed Parameter: Setup_P4_Size
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P4[2];                  /* Expression: parAdcChannels
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P5_Size[2];             /* Computed Parameter: Setup_P5_Size
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P5;                     /* Expression: parAdcMode
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P6_Size[2];             /* Computed Parameter: Setup_P6_Size
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P6[2];                  /* Expression: parAdcRanges
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P7_Size[2];             /* Computed Parameter: Setup_P7_Size
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P7[2];                  /* Expression: parDacChannels
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P8_Size[2];             /* Computed Parameter: Setup_P8_Size
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P8[2];                  /* Expression: parDacRanges
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P9_Size[2];             /* Computed Parameter: Setup_P9_Size
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Setup_P9[9];                  /* Expression: parDioFirstControl
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Digitaloutput_P1_Size[2];  /* Computed Parameter: Digitaloutput_P1_Size
                                     * Referenced by: '<Root>/Digital output '
                                     */
  real_T Digitaloutput_P1;             /* Expression: parModuleId
                                        * Referenced by: '<Root>/Digital output '
                                        */
  real_T Digitaloutput_P2_Size[2];  /* Computed Parameter: Digitaloutput_P2_Size
                                     * Referenced by: '<Root>/Digital output '
                                     */
  real_T Digitaloutput_P2;             /* Expression: parSampleTime
                                        * Referenced by: '<Root>/Digital output '
                                        */
  real_T Digitaloutput_P3_Size[2];  /* Computed Parameter: Digitaloutput_P3_Size
                                     * Referenced by: '<Root>/Digital output '
                                     */
  real_T Digitaloutput_P3;             /* Expression: parPciSlot
                                        * Referenced by: '<Root>/Digital output '
                                        */
  real_T Digitaloutput_P4_Size[2];  /* Computed Parameter: Digitaloutput_P4_Size
                                     * Referenced by: '<Root>/Digital output '
                                     */
  real_T Digitaloutput_P4[16];         /* Expression: parDoChannels
                                        * Referenced by: '<Root>/Digital output '
                                        */
  real_T Digitaloutput_P5_Size[2];  /* Computed Parameter: Digitaloutput_P5_Size
                                     * Referenced by: '<Root>/Digital output '
                                     */
  real_T Digitaloutput_P5[16];         /* Expression: parDoInitValues
                                        * Referenced by: '<Root>/Digital output '
                                        */
  real_T Digitaloutput_P6_Size[2];  /* Computed Parameter: Digitaloutput_P6_Size
                                     * Referenced by: '<Root>/Digital output '
                                     */
  real_T Digitaloutput_P6[16];         /* Expression: parDoResets
                                        * Referenced by: '<Root>/Digital output '
                                        */
  real_T Constant_Value;               /* Expression: 1800
                                        * Referenced by: '<S2>/Constant'
                                        */
};

/* Storage class 'PageSwitching' */
extern nCORTEx_vt_cal_type nCORTEx_vt_cal_impl;
extern nCORTEx_vt_cal_type *nCORTEx_vt_cal;

#endif                                 /* RTW_HEADER_nCORTEx_vt_cal_h_ */
