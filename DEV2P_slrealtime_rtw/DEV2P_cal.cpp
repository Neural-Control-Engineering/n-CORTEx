#include "DEV2P_cal.h"
#include "DEV2P.h"

/* Storage class 'PageSwitching' */
DEV2P_cal_type DEV2P_cal_impl = {
  /* Variable: T_pupil
   * Referenced by: '<Root>/Pupil Trig'
   */
  100.0,

  /* Variable: maxFrames
   * Referenced by: '<Root>/Constant'
   */
  1.8E+6,

  /* Expression: 1
   * Referenced by: '<Root>/Pupil Trig'
   */
  1.0,

  /* Expression: 0
   * Referenced by: '<Root>/Pupil Trig'
   */
  0.0,

  /* Expression: 1
   * Referenced by: '<Root>/imAcq_outTst'
   */
  1.0,

  /* Expression: 5000
   * Referenced by: '<Root>/imAcq_outTst'
   */
  5000.0,

  /* Expression: 2500
   * Referenced by: '<Root>/imAcq_outTst'
   */
  2500.0,

  /* Expression: 0
   * Referenced by: '<Root>/imAcq_outTst'
   */
  0.0,

  /* Expression: 1
   * Referenced by: '<Root>/Memory2'
   */
  1.0,

  /* Expression: 0
   * Referenced by: '<Root>/Memory1'
   */
  0.0,

  /* Expression: 0
   * Referenced by: '<Root>/Memory'
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
  { 1.0, 2.0 },

  /* Expression: parAdcChannels
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 2.0 },

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
  { 1.0, 2.0 },

  /* Expression: parAdcRanges
   * Referenced by: '<Root>/Setup '
   */
  { 3.0, 3.0 },

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
  { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },

  /* Computed Parameter: Digitaloutput_P6_Size
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 15.0 },

  /* Expression: parDoResets
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 },

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

DEV2P_cal_type *DEV2P_cal = &DEV2P_cal_impl;
