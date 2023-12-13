#include "ATTN_cal.h"
#include "ATTN.h"

/* Storage class 'PageSwitching' */
ATTN_cal_type ATTN_cal_impl = {
  /* Variable: SampleTime
   * Referenced by: '<Root>/SampleTime'
   */
  0.001,

  /* Variable: T_npxls
   * Referenced by: '<Root>/Npxls Trig'
   */
  4.0,

  /* Variable: T_pupil
   * Referenced by: '<Root>/Pupil Trig'
   */
  100.0,

  /* Variable: T_whisk
   * Referenced by: '<Root>/Whisker Trig'
   */
  20.0,

  /* Variable: maxFrame
   * Referenced by: '<Root>/Constant'
   */
  3.6E+6,

  /* Variable: rewardDuration
   * Referenced by: '<Root>/rewardDuration'
   */
  0.05,

  /* Variable: targetSide
   * Referenced by: '<Root>/targetSide'
   */
  0.0,

  /* Variable: trainingStage
   * Referenced by: '<Root>/trainingStage'
   */
  1.0,

  /* Variable: triangleAmplitude
   * Referenced by: '<Root>/triangleAmplitude'
   */
  10.0,

  /* Variable: triangleDuration
   * Referenced by: '<Root>/triangleDuration'
   */
  0.1,

  /* Expression: 0
   * Referenced by: '<Root>/Memory8'
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
  { 1.0, 3.0 },

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
  -1.0,

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
  { 1.0, 2.0 },

  /* Expression: parAdcChannels
   * Referenced by: '<Root>/Analog input '
   */
  { 1.0, 2.0 },

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
  { 1.0, 2.0 },

  /* Expression: parAdcRanges
   * Referenced by: '<Root>/Analog input '
   */
  { 3.0, 3.0 },

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

  /* Expression: 0
   * Referenced by: '<Root>/Discrete FIR Filter1'
   */
  0.0,

  /* Expression: [0.000509209659813881	0.000513020363516288	0.000517670368947169	0.000523165080954807	0.000529502229018688	0.000536671671801312	0.000544655221147270	0.000553426486192940	0.000562950738202937	0.000573184796705857	0.000584076937451232	0.000595566822662082	0.000607585454003714	0.000620055148640238	0.000632889538692870	0.000645993594362183	0.000659263670918790	0.000672587579711404	0.000685844683282220	0.000698906014624052	0.000711634420552287	0.000723884729108370	0.000735503940850524	0.000746331443831085	0.000756199251997085	0.000764932266696426	0.000772348560909980	0.000778259685775497	0.000782470998908148	0.000784782013971788	0.000784986770893603	0.000782874226066079	0.000778228661822321	0.000770830114425020	0.000760454819751434	0.000746875675816741	0.000729862721224160	0.000709183628589956	0.000684604211945086	0.000655888947078721	0.000622801503743497	0.000585105288613380	0.000542563997844639	0.000494942178064139	0.000442005794573363	0.000383522805539736	0.000319263740912520	0.000249002284787882	0. */
  { 0.000509209659813881, 0.000513020363516288, 0.000517670368947169,
    0.000523165080954807, 0.000529502229018688, 0.000536671671801312,
    0.00054465522114727, 0.00055342648619294, 0.000562950738202937,
    0.000573184796705857, 0.000584076937451232, 0.000595566822662082,
    0.000607585454003714, 0.000620055148640238, 0.00063288953869287,
    0.000645993594362183, 0.00065926367091879, 0.000672587579711404,
    0.00068584468328222, 0.000698906014624052, 0.000711634420552287,
    0.00072388472910837, 0.000735503940850524, 0.000746331443831085,
    0.000756199251997085, 0.000764932266696426, 0.00077234856090998,
    0.000778259685775497, 0.000782470998908148, 0.000784782013971788,
    0.000784986770893603, 0.000782874226066079, 0.000778228661822321,
    0.00077083011442502, 0.000760454819751434, 0.000746875675816741,
    0.00072986272122416, 0.000709183628589956, 0.000684604211945086,
    0.000655888947078721, 0.000622801503743497, 0.00058510528861338,
    0.000542563997844639, 0.000494942178064139, 0.000442005794573363,
    0.000383522805539736, 0.00031926374091252, 0.000249002284787882,
    0.000172515859925459, 8.95862131054925E-5, 5.45168614075448E-18,
    -9.6450631770992E-5, -0.000199967462741528, -0.000310745626200165,
    -0.000428973038633825, -0.000554829837350212, -0.000688487826618691,
    -0.000830109933647946, -0.000979849675716531, -0.00113785063974888,
    -0.00130424597562156, -0.00147915790444734, -0.00166269724307814,
    -0.00185496294602501, -0.00205604166597637, -0.00226600733404635,
    -0.00248492076087141, -0.00271282925961045, -0.00294976629188174,
    -0.00319575113761551, -0.00345078858976082, -0.0037148686747277,
    -0.00398796639941099, -0.00427004152556951, -0.00456103837229735,
    -0.00486088564725125, -0.00516949630725661, -0.0054867674488337,
    -0.00581258022914647, -0.00614679981779084, -0.0064892753797957,
    -0.00683984009012495, -0.00719831117991946, -0.00756449001463563,
    -0.00793816220418173, -0.00831909774507425, -0.00870705119457714,
    -0.00910176187670536, -0.00950295411992184, -0.00991033752626848,
    -0.0103236072716214, -0.0107424444366745, -0.0111665163682081,
    -0.0115954770701071, -0.012028967623554, -0.0124666166357312,
    -0.0129080407163268, -0.0133528449810529, -0.0138006235813448,
    -0.0142509602593316, -0.0147034289271262, -0.0151575942694157,
    -0.0156130123682884, -0.0160692313491674, -0.0165257920466955,
    -0.0169822286893392, -0.0174380696014635, -0.0178928379215595,
    -0.0183460523353019, -0.018797227822032, -0.0192458764132781,
    -0.0196915079618489, -0.0201336309200466, -0.0205717531254864,
    -0.0210053825930238, -0.0214340283112369, -0.0218572010419305,
    -0.0222744141210855, -0.0226851842596981, -0.023089032342924,
    -0.0234854842259615, -0.0238740715250873, -0.0242543324022972,
    -0.0246258123419687, -0.0249880649180215, -0.0253406525500261,
    -0.0256831472467622, -0.0260151313357288, -0.0263361981771474,
    -0.0266459528610113, -0.0269440128857977, -0.0272300088174485,
    -0.0275035849273105, -0.0277643998077268, -0.0280121269640498,
    -0.028246455381859, -0.0284670900682462, -0.0286737525660541,
    -0.0288661814400394, -0.0290441327339537, -0.0292073803976255,
    -0.0293557166831566, -0.0294889525094456, -0.0296069177942718,
    -0.0297094617532802, -0.029796453165241, -0.0298677806030557,
    -0.0299233526300232, -0.0299630979609781, -0.029986965587958,
    2.96949756214538, -0.029986965587958, -0.0299630979609781,
    -0.0299233526300232, -0.0298677806030557, -0.029796453165241,
    -0.0297094617532802, -0.0296069177942718, -0.0294889525094456,
    -0.0293557166831566, -0.0292073803976255, -0.0290441327339537,
    -0.0288661814400394, -0.0286737525660541, -0.0284670900682462,
    -0.028246455381859, -0.0280121269640498, -0.0277643998077268,
    -0.0275035849273105, -0.0272300088174485, -0.0269440128857977,
    -0.0266459528610113, -0.0263361981771474, -0.0260151313357288,
    -0.0256831472467622, -0.0253406525500261, -0.0249880649180215,
    -0.0246258123419687, -0.0242543324022972, -0.0238740715250873,
    -0.0234854842259615, -0.023089032342924, -0.0226851842596981,
    -0.0222744141210855, -0.0218572010419305, -0.0214340283112369,
    -0.0210053825930238, -0.0205717531254864, -0.0201336309200466,
    -0.0196915079618489, -0.0192458764132781, -0.018797227822032,
    -0.0183460523353019, -0.0178928379215595, -0.0174380696014635,
    -0.0169822286893392, -0.0165257920466955, -0.0160692313491674,
    -0.0156130123682884, -0.0151575942694157, -0.0147034289271262,
    -0.0142509602593316, -0.0138006235813448, -0.0133528449810529,
    -0.0129080407163268, -0.0124666166357312, -0.012028967623554,
    -0.0115954770701071, -0.0111665163682081, -0.0107424444366745,
    -0.0103236072716214, -0.00991033752626848, -0.00950295411992184,
    -0.00910176187670536, -0.00870705119457714, -0.00831909774507425,
    -0.00793816220418173, -0.00756449001463563, -0.00719831117991946,
    -0.00683984009012495, -0.0064892753797957, -0.00614679981779084,
    -0.00581258022914647, -0.0054867674488337, -0.00516949630725661,
    -0.00486088564725125, -0.00456103837229735, -0.00427004152556951,
    -0.00398796639941099, -0.0037148686747277, -0.00345078858976082,
    -0.00319575113761551, -0.00294976629188174, -0.00271282925961045,
    -0.00248492076087141, -0.00226600733404635, -0.00205604166597637,
    -0.00185496294602501, -0.00166269724307814, -0.00147915790444734,
    -0.00130424597562156, -0.00113785063974888, -0.000979849675716531,
    -0.000830109933647946, -0.000688487826618691, -0.000554829837350212,
    -0.000428973038633825, -0.000310745626200165, -0.000199967462741528,
    -9.6450631770992E-5, 5.45168614075448E-18, 8.95862131054925E-5,
    0.000172515859925459, 0.000249002284787882, 0.00031926374091252,
    0.000383522805539736, 0.000442005794573363, 0.000494942178064139,
    0.000542563997844639, 0.00058510528861338, 0.000622801503743497,
    0.000655888947078721, 0.000684604211945086, 0.000709183628589956,
    0.00072986272122416, 0.000746875675816741, 0.000760454819751434,
    0.00077083011442502, 0.000778228661822321, 0.000782874226066079,
    0.000784986770893603, 0.000784782013971788, 0.000782470998908148,
    0.000778259685775497, 0.00077234856090998, 0.000764932266696426,
    0.000756199251997085, 0.000746331443831085, 0.000735503940850524,
    0.00072388472910837, 0.000711634420552287, 0.000698906014624052,
    0.00068584468328222, 0.000672587579711404, 0.00065926367091879,
    0.000645993594362183, 0.00063288953869287, 0.000620055148640238,
    0.000607585454003714, 0.000595566822662082, 0.000584076937451232,
    0.000573184796705857, 0.000562950738202937, 0.00055342648619294,
    0.00054465522114727, 0.000536671671801312, 0.000529502229018688,
    0.000523165080954807, 0.000517670368947169, 0.000513020363516288,
    0.000509209659813881 },

  /* Expression: 0.05
   * Referenced by: '<Root>/Thrd'
   */
  0.05,

  /* Expression: 0
   * Referenced by: '<Root>/Memory11'
   */
  0.0,

  /* Expression: 0
   * Referenced by: '<Root>/Memory7'
   */
  0.0,

  /* Expression: 1
   * Referenced by: '<Root>/Memory3'
   */
  1.0,

  /* Expression: 1
   * Referenced by: '<Root>/Memory4'
   */
  1.0,

  /* Expression: 0
   * Referenced by: '<Root>/Memory9'
   */
  0.0,

  /* Expression: 0
   * Referenced by: '<Root>/Memory5'
   */
  0.0,

  /* Expression: 0
   * Referenced by: '<Root>/Memory6'
   */
  0.0,

  /* Expression: 0
   * Referenced by: '<Root>/Memory10'
   */
  0.0,

  /* Computed Parameter: Analogoutput_P1_Size
   * Referenced by: '<Root>/Analog output '
   */
  { 1.0, 1.0 },

  /* Expression: parModuleId
   * Referenced by: '<Root>/Analog output '
   */
  1.0,

  /* Computed Parameter: Analogoutput_P2_Size
   * Referenced by: '<Root>/Analog output '
   */
  { 1.0, 1.0 },

  /* Expression: parSampleTime
   * Referenced by: '<Root>/Analog output '
   */
  -1.0,

  /* Computed Parameter: Analogoutput_P3_Size
   * Referenced by: '<Root>/Analog output '
   */
  { 1.0, 1.0 },

  /* Expression: parPciSlot
   * Referenced by: '<Root>/Analog output '
   */
  -1.0,

  /* Computed Parameter: Analogoutput_P4_Size
   * Referenced by: '<Root>/Analog output '
   */
  { 1.0, 2.0 },

  /* Expression: parDacChannels
   * Referenced by: '<Root>/Analog output '
   */
  { 1.0, 3.0 },

  /* Computed Parameter: Analogoutput_P5_Size
   * Referenced by: '<Root>/Analog output '
   */
  { 1.0, 2.0 },

  /* Expression: parDacRanges
   * Referenced by: '<Root>/Analog output '
   */
  { 4.0, 4.0 },

  /* Computed Parameter: Analogoutput_P6_Size
   * Referenced by: '<Root>/Analog output '
   */
  { 1.0, 2.0 },

  /* Expression: parDacInitValues
   * Referenced by: '<Root>/Analog output '
   */
  { 0.0, 0.0 },

  /* Computed Parameter: Analogoutput_P7_Size
   * Referenced by: '<Root>/Analog output '
   */
  { 1.0, 2.0 },

  /* Expression: parDacResets
   * Referenced by: '<Root>/Analog output '
   */
  { 1.0, 1.0 },

  /* Expression: 1
   * Referenced by: '<Root>/Whisker Trig'
   */
  1.0,

  /* Expression: 0
   * Referenced by: '<Root>/Whisker Trig'
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

  /* Expression: 1
   * Referenced by: '<Root>/Pupil Trig'
   */
  1.0,

  /* Expression: 0
   * Referenced by: '<Root>/Pupil Trig'
   */
  0.0,

  /* Expression: 1
   * Referenced by: '<S5>/Constant4'
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

ATTN_cal_type *ATTN_cal = &ATTN_cal_impl;
