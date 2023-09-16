#include "nCORTEx_vt_cal.h"
#include "nCORTEx_vt.h"

/* Storage class 'PageSwitching' */
nCORTEx_vt_cal_type nCORTEx_vt_cal_impl = {
  /* Expression: 1
   * Referenced by: '<Root>/Whisker Trig'
   */
  1.0,

  /* Expression: 20
   * Referenced by: '<Root>/Whisker Trig'
   */
  20.0,

  /* Expression: 10
   * Referenced by: '<Root>/Whisker Trig'
   */
  10.0,

  /* Expression: 0
   * Referenced by: '<Root>/Whisker Trig'
   */
  0.0,

  /* Expression: 1
   * Referenced by: '<Root>/Npxls Trig'
   */
  1.0,

  /* Expression: 4
   * Referenced by: '<Root>/Npxls Trig'
   */
  4.0,

  /* Expression: 2
   * Referenced by: '<Root>/Npxls Trig'
   */
  2.0,

  /* Expression: 0
   * Referenced by: '<Root>/Npxls Trig'
   */
  0.0,

  /* Expression: 1
   * Referenced by: '<Root>/Pupil Trig'
   */
  1.0,

  /* Expression: 100
   * Referenced by: '<Root>/Pupil Trig'
   */
  100.0,

  /* Expression: 50
   * Referenced by: '<Root>/Pupil Trig'
   */
  50.0,

  /* Expression: 0
   * Referenced by: '<Root>/Pupil Trig'
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
  { 1.0, 9.0 },

  /* Expression: parDioFirstControl
   * Referenced by: '<Root>/Setup '
   */
  { 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0 },

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
  { 1.0, 16.0 },

  /* Expression: parDoChannels
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0,
    15.0, 16.0 },

  /* Computed Parameter: Digitaloutput_P5_Size
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 16.0 },

  /* Expression: parDoInitValues
   * Referenced by: '<Root>/Digital output '
   */
  { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0 },

  /* Computed Parameter: Digitaloutput_P6_Size
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 16.0 },

  /* Expression: parDoResets
   * Referenced by: '<Root>/Digital output '
   */
  { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
    1.0 },

  /* Expression: 1800
   * Referenced by: '<S2>/Constant'
   */
  1800.0
};

nCORTEx_vt_cal_type *nCORTEx_vt_cal = &nCORTEx_vt_cal_impl;
