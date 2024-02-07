#ifndef RTW_HEADER_SspNeuromod_cal_h_
#define RTW_HEADER_SspNeuromod_cal_h_
#include "rtwtypes.h"

/* Storage class 'PageSwitching', for system '<Root>' */
struct SspNeuromod_cal_type {
  real_T LEDstimTime;                  /* Variable: LEDstimTime
                                        * Referenced by: '<Root>/LEDstimTime'
                                        */
  real_T SampleTime;                   /* Variable: SampleTime
                                        * Referenced by: '<Root>/SampleTime'
                                        */
  real_T T_pupil;                      /* Variable: T_pupil
                                        * Referenced by: '<Root>/Pupil Trig'
                                        */
  real_T baselineTime;                 /* Variable: baselineTime
                                        * Referenced by: '<Root>/baselineTime'
                                        */
  real_T Out1_Y0;                      /* Computed Parameter: Out1_Y0
                                        * Referenced by: '<S1>/Out1'
                                        */
  real_T Memory5_InitialCondition;     /* Expression: 1
                                        * Referenced by: '<Root>/Memory5'
                                        */
  real_T Memory4_InitialCondition;     /* Expression: 0
                                        * Referenced by: '<Root>/Memory4'
                                        */
  real_T Memory6_InitialCondition;     /* Expression: 0
                                        * Referenced by: '<Root>/Memory6'
                                        */
  real_T Memory3_InitialCondition;     /* Expression: 0
                                        * Referenced by: '<Root>/Memory3'
                                        */
  real_T Memory2_InitialCondition;     /* Expression: 0
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
  real_T Setup_P9[5];                  /* Expression: parDioFirstControl
                                        * Referenced by: '<Root>/Setup '
                                        */
  real_T Analoginput_P1_Size[2];      /* Computed Parameter: Analoginput_P1_Size
                                       * Referenced by: '<Root>/Analog input '
                                       */
  real_T Analoginput_P1;               /* Expression: parModuleId
                                        * Referenced by: '<Root>/Analog input '
                                        */
  real_T Analoginput_P2_Size[2];      /* Computed Parameter: Analoginput_P2_Size
                                       * Referenced by: '<Root>/Analog input '
                                       */
  real_T Analoginput_P2;               /* Expression: parSampleTime
                                        * Referenced by: '<Root>/Analog input '
                                        */
  real_T Analoginput_P3_Size[2];      /* Computed Parameter: Analoginput_P3_Size
                                       * Referenced by: '<Root>/Analog input '
                                       */
  real_T Analoginput_P3;               /* Expression: parPciSlot
                                        * Referenced by: '<Root>/Analog input '
                                        */
  real_T Analoginput_P4_Size[2];      /* Computed Parameter: Analoginput_P4_Size
                                       * Referenced by: '<Root>/Analog input '
                                       */
  real_T Analoginput_P4[2];            /* Expression: parAdcChannels
                                        * Referenced by: '<Root>/Analog input '
                                        */
  real_T Analoginput_P5_Size[2];      /* Computed Parameter: Analoginput_P5_Size
                                       * Referenced by: '<Root>/Analog input '
                                       */
  real_T Analoginput_P5;               /* Expression: parAdcMode
                                        * Referenced by: '<Root>/Analog input '
                                        */
  real_T Analoginput_P6_Size[2];      /* Computed Parameter: Analoginput_P6_Size
                                       * Referenced by: '<Root>/Analog input '
                                       */
  real_T Analoginput_P6;               /* Expression: parAdcRate
                                        * Referenced by: '<Root>/Analog input '
                                        */
  real_T Analoginput_P7_Size[2];      /* Computed Parameter: Analoginput_P7_Size
                                       * Referenced by: '<Root>/Analog input '
                                       */
  real_T Analoginput_P7[2];            /* Expression: parAdcRanges
                                        * Referenced by: '<Root>/Analog input '
                                        */
  real_T Analoginput_P8_Size[2];      /* Computed Parameter: Analoginput_P8_Size
                                       * Referenced by: '<Root>/Analog input '
                                       */
  real_T Analoginput_P8[2];            /* Expression: parAdcInitValues
                                        * Referenced by: '<Root>/Analog input '
                                        */
  real_T Analoginput_P9_Size[2];      /* Computed Parameter: Analoginput_P9_Size
                                       * Referenced by: '<Root>/Analog input '
                                       */
  real_T Analoginput_P9[2];            /* Expression: parAdcResets
                                        * Referenced by: '<Root>/Analog input '
                                        */
  real_T Analogoutput_P1_Size[2];    /* Computed Parameter: Analogoutput_P1_Size
                                      * Referenced by: '<Root>/Analog output '
                                      */
  real_T Analogoutput_P1;              /* Expression: parModuleId
                                        * Referenced by: '<Root>/Analog output '
                                        */
  real_T Analogoutput_P2_Size[2];    /* Computed Parameter: Analogoutput_P2_Size
                                      * Referenced by: '<Root>/Analog output '
                                      */
  real_T Analogoutput_P2;              /* Expression: parSampleTime
                                        * Referenced by: '<Root>/Analog output '
                                        */
  real_T Analogoutput_P3_Size[2];    /* Computed Parameter: Analogoutput_P3_Size
                                      * Referenced by: '<Root>/Analog output '
                                      */
  real_T Analogoutput_P3;              /* Expression: parPciSlot
                                        * Referenced by: '<Root>/Analog output '
                                        */
  real_T Analogoutput_P4_Size[2];    /* Computed Parameter: Analogoutput_P4_Size
                                      * Referenced by: '<Root>/Analog output '
                                      */
  real_T Analogoutput_P4[2];           /* Expression: parDacChannels
                                        * Referenced by: '<Root>/Analog output '
                                        */
  real_T Analogoutput_P5_Size[2];    /* Computed Parameter: Analogoutput_P5_Size
                                      * Referenced by: '<Root>/Analog output '
                                      */
  real_T Analogoutput_P5[2];           /* Expression: parDacRanges
                                        * Referenced by: '<Root>/Analog output '
                                        */
  real_T Analogoutput_P6_Size[2];    /* Computed Parameter: Analogoutput_P6_Size
                                      * Referenced by: '<Root>/Analog output '
                                      */
  real_T Analogoutput_P6[2];           /* Expression: parDacInitValues
                                        * Referenced by: '<Root>/Analog output '
                                        */
  real_T Analogoutput_P7_Size[2];    /* Computed Parameter: Analogoutput_P7_Size
                                      * Referenced by: '<Root>/Analog output '
                                      */
  real_T Analogoutput_P7[2];           /* Expression: parDacResets
                                        * Referenced by: '<Root>/Analog output '
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
  real_T Digitaloutput_P4[12];         /* Expression: parDoChannels
                                        * Referenced by: '<Root>/Digital output '
                                        */
  real_T Digitaloutput_P5_Size[2];  /* Computed Parameter: Digitaloutput_P5_Size
                                     * Referenced by: '<Root>/Digital output '
                                     */
  real_T Digitaloutput_P5[12];         /* Expression: parDoInitValues
                                        * Referenced by: '<Root>/Digital output '
                                        */
  real_T Digitaloutput_P6_Size[2];  /* Computed Parameter: Digitaloutput_P6_Size
                                     * Referenced by: '<Root>/Digital output '
                                     */
  real_T Digitaloutput_P6[12];         /* Expression: parDoResets
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
  real_T Digitalinput_P4[4];           /* Expression: parDiChannels
                                        * Referenced by: '<Root>/Digital input '
                                        */
  real_T WhiskStim_Amp;                /* Expression: 1
                                        * Referenced by: '<Root>/Whisk Stim'
                                        */
  real_T WhiskStim_Period;             /* Expression: 5500
                                        * Referenced by: '<Root>/Whisk Stim'
                                        */
  real_T WhiskStim_Duty;               /* Expression: 1000
                                        * Referenced by: '<Root>/Whisk Stim'
                                        */
  real_T WhiskStim_PhaseDelay;         /* Expression: 0
                                        * Referenced by: '<Root>/Whisk Stim'
                                        */
  real_T SineWave_Amp;                 /* Expression: 5
                                        * Referenced by: '<Root>/Sine Wave'
                                        */
  real_T SineWave_Bias;                /* Expression: 0
                                        * Referenced by: '<Root>/Sine Wave'
                                        */
  real_T SineWave_Freq;                /* Expression: 415
                                        * Referenced by: '<Root>/Sine Wave'
                                        */
  real_T SineWave_Hsin;                /* Computed Parameter: SineWave_Hsin
                                        * Referenced by: '<Root>/Sine Wave'
                                        */
  real_T SineWave_HCos;                /* Computed Parameter: SineWave_HCos
                                        * Referenced by: '<Root>/Sine Wave'
                                        */
  real_T SineWave_PSin;                /* Computed Parameter: SineWave_PSin
                                        * Referenced by: '<Root>/Sine Wave'
                                        */
  real_T SineWave_PCos;                /* Computed Parameter: SineWave_PCos
                                        * Referenced by: '<Root>/Sine Wave'
                                        */
  real_T PupilTrig_Amp;                /* Expression: 1
                                        * Referenced by: '<Root>/Pupil Trig'
                                        */
  real_T PupilTrig_PhaseDelay;         /* Expression: 0
                                        * Referenced by: '<Root>/Pupil Trig'
                                        */
};

/* Storage class 'PageSwitching' */
extern SspNeuromod_cal_type SspNeuromod_cal_impl;
extern SspNeuromod_cal_type *SspNeuromod_cal;

#endif                                 /* RTW_HEADER_SspNeuromod_cal_h_ */
