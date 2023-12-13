#ifndef RTW_HEADER_ATTN_cal_h_
#define RTW_HEADER_ATTN_cal_h_
#include "rtwtypes.h"

/* Storage class 'PageSwitching', for system '<Root>' */
struct ATTN_cal_type {
  real_T SampleTime;                   /* Variable: SampleTime
                                        * Referenced by: '<Root>/SampleTime'
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
  real_T maxFrame;                     /* Variable: maxFrame
                                        * Referenced by: '<Root>/Constant'
                                        */
  real_T rewardDuration;               /* Variable: rewardDuration
                                        * Referenced by: '<Root>/rewardDuration'
                                        */
  real_T targetSide;                   /* Variable: targetSide
                                        * Referenced by: '<Root>/targetSide'
                                        */
  real_T trainingStage;                /* Variable: trainingStage
                                        * Referenced by: '<Root>/trainingStage'
                                        */
  real_T triangleAmplitude;            /* Variable: triangleAmplitude
                                        * Referenced by: '<Root>/triangleAmplitude'
                                        */
  real_T triangleDuration;             /* Variable: triangleDuration
                                        * Referenced by: '<Root>/triangleDuration'
                                        */
  real_T Memory8_InitialCondition;     /* Expression: 0
                                        * Referenced by: '<Root>/Memory8'
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
  real_T Setup_P9[8];                  /* Expression: parDioFirstControl
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
  real_T DiscreteFIRFilter1_InitialState;/* Expression: 0
                                          * Referenced by: '<Root>/Discrete FIR Filter1'
                                          */
  real_T DiscreteFIRFilter1_Coefficients[301];
  /* Expression: [0.000509209659813881	0.000513020363516288	0.000517670368947169	0.000523165080954807	0.000529502229018688	0.000536671671801312	0.000544655221147270	0.000553426486192940	0.000562950738202937	0.000573184796705857	0.000584076937451232	0.000595566822662082	0.000607585454003714	0.000620055148640238	0.000632889538692870	0.000645993594362183	0.000659263670918790	0.000672587579711404	0.000685844683282220	0.000698906014624052	0.000711634420552287	0.000723884729108370	0.000735503940850524	0.000746331443831085	0.000756199251997085	0.000764932266696426	0.000772348560909980	0.000778259685775497	0.000782470998908148	0.000784782013971788	0.000784986770893603	0.000782874226066079	0.000778228661822321	0.000770830114425020	0.000760454819751434	0.000746875675816741	0.000729862721224160	0.000709183628589956	0.000684604211945086	0.000655888947078721	0.000622801503743497	0.000585105288613380	0.000542563997844639	0.000494942178064139	0.000442005794573363	0.000383522805539736	0.000319263740912520	0.000249002284787882	0.000172515859925459	8.95862131054925e-05	5.45168614075448e-18	-9.64506317709920e-05	-0.000199967462741528	-0.000310745626200165	-0.000428973038633825	-0.000554829837350212	-0.000688487826618691	-0.000830109933647946	-0.000979849675716531	-0.00113785063974888	-0.00130424597562156	-0.00147915790444734	-0.00166269724307814	-0.00185496294602501	-0.00205604166597637	-0.00226600733404635	-0.00248492076087141	-0.00271282925961045	-0.00294976629188174	-0.00319575113761551	-0.00345078858976082	-0.00371486867472770	-0.00398796639941099	-0.00427004152556951	-0.00456103837229735	-0.00486088564725125	-0.00516949630725661	-0.00548676744883370	-0.00581258022914647	-0.00614679981779084	-0.00648927537979570	-0.00683984009012495	-0.00719831117991946	-0.00756449001463563	-0.00793816220418173	-0.00831909774507425	-0.00870705119457714	-0.00910176187670536	-0.00950295411992184	-0.00991033752626848	-0.0103236072716214	-0.0107424444366745	-0.0111665163682081	-0.0115954770701071	-0.0120289676235540	-0.0124666166357312	-0.0129080407163268	-0.0133528449810529	-0.0138006235813448	-0.0142509602593316	-0.0147034289271262	-0.0151575942694157	-0.0156130123682884	-0.0160692313491674	-0.0165257920466955	-0.0169822286893392	-0.0174380696014635	-0.0178928379215595	-0.0183460523353019	-0.0187972278220320	-0.0192458764132781	-0.0196915079618489	-0.0201336309200466	-0.0205717531254864	-0.0210053825930238	-0.0214340283112369	-0.0218572010419305	-0.0222744141210855	-0.0226851842596981	-0.0230890323429240	-0.0234854842259615	-0.0238740715250873	-0.0242543324022972	-0.0246258123419687	-0.0249880649180215	-0.0253406525500261	-0.0256831472467622	-0.0260151313357288	-0.0263361981771474	-0.0266459528610113	-0.0269440128857977	-0.0272300088174485	-0.0275035849273105	-0.0277643998077268	-0.0280121269640498	-0.0282464553818590	-0.0284670900682462	-0.0286737525660541	-0.0288661814400394	-0.0290441327339537	-0.0292073803976255	-0.0293557166831566	-0.0294889525094456	-0.0296069177942718	-0.0297094617532802	-0.0297964531652410	-0.0298677806030557	-0.0299233526300232	-0.0299630979609781	-0.0299869655879580	2.96949756214538	-0.0299869655879580	-0.0299630979609781	-0.0299233526300232	-0.0298677806030557	-0.0297964531652410	-0.0297094617532802	-0.0296069177942718	-0.0294889525094456	-0.0293557166831566	-0.0292073803976255	-0.0290441327339537	-0.0288661814400394	-0.0286737525660541	-0.0284670900682462	-0.0282464553818590	-0.0280121269640498	-0.0277643998077268	-0.0275035849273105	-0.0272300088174485	-0.0269440128857977	-0.0266459528610113	-0.0263361981771474	-0.0260151313357288	-0.0256831472467622	-0.0253406525500261	-0.0249880649180215	-0.0246258123419687	-0.0242543324022972	-0.0238740715250873	-0.0234854842259615	-0.0230890323429240	-0.0226851842596981	-0.0222744141210855	-0.0218572010419305	-0.0214340283112369	-0.0210053825930238	-0.0205717531254864	-0.0201336309200466	-0.0196915079618489	-0.0192458764132781	-0.0187972278220320	-0.0183460523353019	-0.0178928379215595	-0.0174380696014635	-0.0169822286893392	-0.0165257920466955	-0.0160692313491674	-0.0156130123682884	-0.0151575942694157	-0.0147034289271262	-0.0142509602593316	-0.0138006235813448	-0.0133528449810529	-0.0129080407163268	-0.0124666166357312	-0.0120289676235540	-0.0115954770701071	-0.0111665163682081	-0.0107424444366745	-0.0103236072716214	-0.00991033752626848	-0.00950295411992184	-0.00910176187670536	-0.00870705119457714	-0.00831909774507425	-0.00793816220418173	-0.00756449001463563	-0.00719831117991946	-0.00683984009012495	-0.00648927537979570	-0.00614679981779084	-0.00581258022914647	-0.00548676744883370	-0.00516949630725661	-0.00486088564725125	-0.00456103837229735	-0.00427004152556951	-0.00398796639941099	-0.00371486867472770	-0.00345078858976082	-0.00319575113761551	-0.00294976629188174	-0.00271282925961045	-0.00248492076087141	-0.00226600733404635	-0.00205604166597637	-0.00185496294602501	-0.00166269724307814	-0.00147915790444734	-0.00130424597562156	-0.00113785063974888	-0.000979849675716531	-0.000830109933647946	-0.000688487826618691	-0.000554829837350212	-0.000428973038633825	-0.000310745626200165	-0.000199967462741528	-9.64506317709920e-05	5.45168614075448e-18	8.95862131054925e-05	0.000172515859925459	0.000249002284787882	0.000319263740912520	0.000383522805539736	0.000442005794573363	0.000494942178064139	0.000542563997844639	0.000585105288613380	0.000622801503743497	0.000655888947078721	0.000684604211945086	0.000709183628589956	0.000729862721224160	0.000746875675816741	0.000760454819751434	0.000770830114425020	0.000778228661822321	0.000782874226066079	0.000784986770893603	0.000784782013971788	0.000782470998908148	0.000778259685775497	0.000772348560909980	0.000764932266696426	0.000756199251997085	0.000746331443831085	0.000735503940850524	0.000723884729108370	0.000711634420552287	0.000698906014624052	0.000685844683282220	0.000672587579711404	0.000659263670918790	0.000645993594362183	0.000632889538692870	0.000620055148640238	0.000607585454003714	0.000595566822662082	0.000584076937451232	0.000573184796705857	0.000562950738202937	0.000553426486192940	0.000544655221147270	0.000536671671801312	0.000529502229018688	0.000523165080954807	0.000517670368947169	0.000513020363516288	0.000509209659813881]
   * Referenced by: '<Root>/Discrete FIR Filter1'
   */
  real_T Thrd_Value;                   /* Expression: 0.05
                                        * Referenced by: '<Root>/Thrd'
                                        */
  real_T Memory11_InitialCondition;    /* Expression: 0
                                        * Referenced by: '<Root>/Memory11'
                                        */
  real_T Memory7_InitialCondition;     /* Expression: 0
                                        * Referenced by: '<Root>/Memory7'
                                        */
  real_T Memory3_InitialCondition;     /* Expression: 1
                                        * Referenced by: '<Root>/Memory3'
                                        */
  real_T Memory4_InitialCondition;     /* Expression: 1
                                        * Referenced by: '<Root>/Memory4'
                                        */
  real_T Memory9_InitialCondition;     /* Expression: 0
                                        * Referenced by: '<Root>/Memory9'
                                        */
  real_T Memory5_InitialCondition;     /* Expression: 0
                                        * Referenced by: '<Root>/Memory5'
                                        */
  real_T Memory6_InitialCondition;     /* Expression: 0
                                        * Referenced by: '<Root>/Memory6'
                                        */
  real_T Memory10_InitialCondition;    /* Expression: 0
                                        * Referenced by: '<Root>/Memory10'
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
  real_T Constant4_Value;              /* Expression: 1
                                        * Referenced by: '<S5>/Constant4'
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
extern ATTN_cal_type ATTN_cal_impl;
extern ATTN_cal_type *ATTN_cal;

#endif                                 /* RTW_HEADER_ATTN_cal_h_ */
