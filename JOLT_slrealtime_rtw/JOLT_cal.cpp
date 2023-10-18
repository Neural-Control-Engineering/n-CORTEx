#include "JOLT_cal.h"
#include "JOLT.h"

/* Storage class 'PageSwitching' */
JOLT_cal_type JOLT_cal_impl = {
  /* Variable: T_npxls
   * Referenced by: '<Root>/Npxls Trig'
   */
  4.0,

  /* Expression: 0
   * Referenced by: '<Root>/Memory2'
   */
  0.0,

  /* Computed Parameter: Setup_P1_Size
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 1.0 },

  /* Expression: parPciSlot
   * Referenced by: '<Root>/Setup '
   */
  -1.0,

  /* Computed Parameter: Setup_P2_Size
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 1.0 },

  /* Expression: parModuleId
   * Referenced by: '<Root>/Setup '
   */
  1.0,

  /* Computed Parameter: Setup_P3_Size
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 1.0 },

  /* Expression: parTriggerSignal
   * Referenced by: '<Root>/Setup '
   */
  1.0,

  /* Computed Parameter: Setup_P4_Size
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 1.0 },

  /* Expression: parAdcChannels
   * Referenced by: '<Root>/Setup '
   */
  1.0,

  /* Computed Parameter: Setup_P5_Size
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 1.0 },

  /* Expression: parAdcMode
   * Referenced by: '<Root>/Setup '
   */
  2.0,

  /* Computed Parameter: Setup_P6_Size
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 1.0 },

  /* Expression: parAdcRanges
   * Referenced by: '<Root>/Setup '
   */
  4.0,

  /* Computed Parameter: Setup_P7_Size
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 2.0 },

  /* Expression: parDacChannels
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 2.0 },

  /* Computed Parameter: Setup_P8_Size
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 2.0 },

  /* Expression: parDacRanges
   * Referenced by: '<Root>/Setup '
   */
  { 4.0, 4.0 },

  /* Computed Parameter: Setup_P9_Size
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 8.0 },

  /* Expression: parDioFirstControl
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 9.0 },

  /* Expression: 1
   * Referenced by: '<Root>/Constant'
   */
  1.0,

  /* Expression: 0
   * Referenced by: '<Root>/Memory1'
   */
  0.0,

  /* Expression: 2.5
   * Referenced by: '<Root>/Npxls Trig'
   */
  2.5,

  /* Expression: 0
   * Referenced by: '<Root>/Npxls Trig'
   */
  0.0,

  /* Expression: 2.5
   * Referenced by: '<S5>/Constant'
   */
  2.5,

  /* Expression: 8
   * Referenced by: '<S5>/Constant1'
   */
  8.0,

  /* Expression: 1
   * Referenced by: '<S6>/Constant'
   */
  1.0,

  /* Expression: 1
   * Referenced by: '<S6>/Constant1'
   */
  1.0,

  /* Computed Parameter: Digitaloutput_P1_Size
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 1.0 },

  /* Expression: parModuleId
   * Referenced by: '<Root>/Digital output '
   */
  1.0,

  /* Computed Parameter: Digitaloutput_P2_Size
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 1.0 },

  /* Expression: parSampleTime
   * Referenced by: '<Root>/Digital output '
   */
  0.001,

  /* Computed Parameter: Digitaloutput_P3_Size
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 1.0 },

  /* Expression: parPciSlot
   * Referenced by: '<Root>/Digital output '
   */
  -1.0,

  /* Computed Parameter: Digitaloutput_P4_Size
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 15.0 },

  /* Expression: parDoChannels
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 15.0,
    16.0 },

  /* Computed Parameter: Digitaloutput_P5_Size
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 15.0 },

  /* Expression: parDoInitValues
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },

  /* Computed Parameter: Digitaloutput_P6_Size
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 15.0 },

  /* Expression: parDoResets
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 },

  /* Computed Parameter: Analoginput_P1_Size
   * Referenced by: '<Root>/Analog input '
   */
  { 1.0, 1.0 },

  /* Expression: parModuleId
   * Referenced by: '<Root>/Analog input '
   */
  1.0,

  /* Computed Parameter: Analoginput_P2_Size
   * Referenced by: '<Root>/Analog input '
   */
  { 1.0, 1.0 },

  /* Expression: parSampleTime
   * Referenced by: '<Root>/Analog input '
   */
  0.001,

  /* Computed Parameter: Analoginput_P3_Size
   * Referenced by: '<Root>/Analog input '
   */
  { 1.0, 1.0 },

  /* Expression: parPciSlot
   * Referenced by: '<Root>/Analog input '
   */
  -1.0,

  /* Computed Parameter: Analoginput_P4_Size
   * Referenced by: '<Root>/Analog input '
   */
  { 1.0, 1.0 },

  /* Expression: parAdcChannels
   * Referenced by: '<Root>/Analog input '
   */
  1.0,

  /* Computed Parameter: Analoginput_P5_Size
   * Referenced by: '<Root>/Analog input '
   */
  { 1.0, 1.0 },

  /* Expression: parAdcMode
   * Referenced by: '<Root>/Analog input '
   */
  2.0,

  /* Computed Parameter: Analoginput_P6_Size
   * Referenced by: '<Root>/Analog input '
   */
  { 1.0, 1.0 },

  /* Expression: parAdcRate
   * Referenced by: '<Root>/Analog input '
   */
  100000.0,

  /* Computed Parameter: Analoginput_P7_Size
   * Referenced by: '<Root>/Analog input '
   */
  { 1.0, 1.0 },

  /* Expression: parAdcRanges
   * Referenced by: '<Root>/Analog input '
   */
  4.0,

  /* Computed Parameter: Analoginput_P8_Size
   * Referenced by: '<Root>/Analog input '
   */
  { 1.0, 2.0 },

  /* Expression: parAdcInitValues
   * Referenced by: '<Root>/Analog input '
   */
  { 0.0, 0.0 },

  /* Computed Parameter: Analoginput_P9_Size
   * Referenced by: '<Root>/Analog input '
   */
  { 1.0, 2.0 },

  /* Expression: parAdcResets
   * Referenced by: '<Root>/Analog input '
   */
  { 1.0, 1.0 },

  /* Expression: 100
   * Referenced by: '<S7>/Constant2'
   */
  100.0,

  /* Expression: 1
   * Referenced by: '<S7>/Constant5'
   */
  1.0,

  /* Expression: 0
   * Referenced by: '<Root>/Constant4'
   */
  0.0,

  /* Expression: 0
   * Referenced by: '<Root>/Delay'
   */
  0.0,

  /* Expression: 1
   * Referenced by: '<Root>/Constant3'
   */
  1.0,

  /* Computed Parameter: Digitalinput_P1_Size
   * Referenced by: '<Root>/Digital input '
   */
  { 1.0, 1.0 },

  /* Expression: parModuleId
   * Referenced by: '<Root>/Digital input '
   */
  1.0,

  /* Computed Parameter: Digitalinput_P2_Size
   * Referenced by: '<Root>/Digital input '
   */
  { 1.0, 1.0 },

  /* Expression: parSampleTime
   * Referenced by: '<Root>/Digital input '
   */
  0.001,

  /* Computed Parameter: Digitalinput_P3_Size
   * Referenced by: '<Root>/Digital input '
   */
  { 1.0, 1.0 },

  /* Expression: parPciSlot
   * Referenced by: '<Root>/Digital input '
   */
  -1.0,

  /* Computed Parameter: Digitalinput_P4_Size
   * Referenced by: '<Root>/Digital input '
   */
  { 1.0, 1.0 },

  /* Expression: parDiChannels
   * Referenced by: '<Root>/Digital input '
   */
  14.0
};

JOLT_cal_type *JOLT_cal = &JOLT_cal_impl;
