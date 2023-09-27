#ifndef RTW_HEADER_nCORTEx_cal_h_
#define RTW_HEADER_nCORTEx_cal_h_
#include "rtwtypes.h"

/* Storage class 'PageSwitching', for system '<Root>' */
struct nCORTEx_cal_type {
  real_T SampleTime;                   /* Variable: SampleTime
                                        * Referenced by: '<Root>/Constant1'
                                        */
  real_T T_npxls;                      /* Variable: T_npxls
                                        * Referenced by: '<Root>/Npxls Trig'
                                        */
  real_T T_pupil;                      /* Variable: T_pupil
                                        * Referenced by: '<Root>/Pupil Trig'
                                        */
  real_T T_whisk;                      /* Variable: T_whisk
                                        * Referenced by: '<Root>/Whisker Trig'
                                        */
  real_T maxFrames;                    /* Variable: maxFrames
                                        * Referenced by: '<Root>/Constant'
                                        */
  real_T tStop;                        /* Variable: tStop
                                        * Referenced by: '<Root>/Constant2'
                                        */
  real_T WhiskerTrig_Amp;              /* Expression: 1
                                        * Referenced by: '<Root>/Whisker Trig'
                                        */
  real_T WhiskerTrig_PhaseDelay;       /* Expression: 0
                                        * Referenced by: '<Root>/Whisker Trig'
                                        */
  real_T NpxlsTrig_Amp;                /* Expression: 2.5
                                        * Referenced by: '<Root>/Npxls Trig'
                                        */
  real_T NpxlsTrig_PhaseDelay;         /* Expression: 0
                                        * Referenced by: '<Root>/Npxls Trig'
                                        */
  real_T PupilTrig_Amp;                /* Expression: 1
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
  real_T Memory3_InitialCondition;     /* Expression: 1
                                        * Referenced by: '<Root>/Memory3'
                                        */
  real_T Memory4_InitialCondition;     /* Expression: 1
                                        * Referenced by: '<Root>/Memory4'
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
  real_T Setup_P9[8];                  /* Expression: parDioFirstControl
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
  real_T Digitaloutput_P4[15];         /* Expression: parDoChannels
                                        * Referenced by: '<Root>/Digital output '
                                        */
  real_T Digitaloutput_P5_Size[2];  /* Computed Parameter: Digitaloutput_P5_Size
                                     * Referenced by: '<Root>/Digital output '
                                     */
  real_T Digitaloutput_P5[15];         /* Expression: parDoInitValues
                                        * Referenced by: '<Root>/Digital output '
                                        */
  real_T Digitaloutput_P6_Size[2];  /* Computed Parameter: Digitaloutput_P6_Size
                                     * Referenced by: '<Root>/Digital output '
                                     */
  real_T Digitaloutput_P6[15];         /* Expression: parDoResets
                                        * Referenced by: '<Root>/Digital output '
                                        */
  real_T Digitalinput_P1_Size[2];    /* Computed Parameter: Digitalinput_P1_Size
                                      * Referenced by: '<Root>/Digital input '
                                      */
  real_T Digitalinput_P1;              /* Expression: parModuleId
                                        * Referenced by: '<Root>/Digital input '
                                        */
  real_T Digitalinput_P2_Size[2];    /* Computed Parameter: Digitalinput_P2_Size
                                      * Referenced by: '<Root>/Digital input '
                                      */
  real_T Digitalinput_P2;              /* Expression: parSampleTime
                                        * Referenced by: '<Root>/Digital input '
                                        */
  real_T Digitalinput_P3_Size[2];    /* Computed Parameter: Digitalinput_P3_Size
                                      * Referenced by: '<Root>/Digital input '
                                      */
  real_T Digitalinput_P3;              /* Expression: parPciSlot
                                        * Referenced by: '<Root>/Digital input '
                                        */
  real_T Digitalinput_P4_Size[2];    /* Computed Parameter: Digitalinput_P4_Size
                                      * Referenced by: '<Root>/Digital input '
                                      */
  real_T Digitalinput_P4;              /* Expression: parDiChannels
                                        * Referenced by: '<Root>/Digital input '
                                        */
};

/* Storage class 'PageSwitching' */
extern nCORTEx_cal_type nCORTEx_cal_impl;
extern nCORTEx_cal_type *nCORTEx_cal;

#endif                                 /* RTW_HEADER_nCORTEx_cal_h_ */
