#ifndef RTW_HEADER_JOLT_cal_h_
#define RTW_HEADER_JOLT_cal_h_
#include "rtwtypes.h"

/* Storage class 'PageSwitching', for system '<Root>' */
struct JOLT_cal_type {
  real_T T_npxls;                      /* Variable: T_npxls
                                        * Referenced by: '<Root>/Npxls Trig'
                                        */
  real_T Memory2_InitialCondition;     /* Expression: 0
                                        * Referenced by: '<Root>/Memory2'
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
  real_T Constant_Value;               /* Expression: 1
                                        * Referenced by: '<Root>/Constant'
                                        */
  real_T Memory1_InitialCondition;     /* Expression: 0
                                        * Referenced by: '<Root>/Memory1'
                                        */
  real_T NpxlsTrig_Amp;                /* Expression: 2.5
                                        * Referenced by: '<Root>/Npxls Trig'
                                        */
  real_T NpxlsTrig_PhaseDelay;         /* Expression: 0
                                        * Referenced by: '<Root>/Npxls Trig'
                                        */
  real_T Constant_Value_c;             /* Expression: 2.5
                                        * Referenced by: '<S6>/Constant'
                                        */
  real_T Constant1_Value;              /* Expression: 8
                                        * Referenced by: '<S6>/Constant1'
                                        */
  real_T Constant_Value_a;             /* Expression: 1
                                        * Referenced by: '<S8>/Constant'
                                        */
  real_T Constant1_Value_p;            /* Expression: 4
                                        * Referenced by: '<S8>/Constant1'
                                        */
  real_T Constant_Value_j;             /* Expression: 1
                                        * Referenced by: '<S7>/Constant'
                                        */
  real_T Constant1_Value_k;            /* Expression: 1
                                        * Referenced by: '<S7>/Constant1'
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
  real_T DiscreteFilter_NumCoef[501];
  /* Expression: [-0.000353831426673119	-0.000354925768921706	-0.000355754366012507	-0.000356310243649574	-0.000356584181542816	-0.000356564704906741	-0.000356238090461231	-0.000355588387123981	-0.000354597451526591	-0.000353244998427493	-0.000351508666035362	-0.000349364096196338	-0.000346785029337693	-0.000343743413999592	-0.000340209530725563	-0.000336152130021442	-0.000331538584032050	-0.000326335051524955	-0.000320506655711566	-0.000314017674377647	-0.000306831741738490	-0.000298912061378422	-0.000290221629580491	-0.000280723468300077	-0.000270380866986140	-0.000259157632405919	-0.000247018345583469	-0.000233928624919437	-0.000219855394519360	-0.000204767156720392	-0.000188634267772200	-0.000171429215596652	-0.000153126898523231	-0.000133704903872869	-0.000113143785242178	-9.14273373231303e-05	-6.85428670799782e-05	-4.44814600959497e-05	-1.92382408968169e-05	7.18737394288373e-06	3.47914311025357e-05	6.35652054117620e-05	9.34949755142414e-05	0.000124561811457761	0.000156741375350128	0.000190003736197180	0.000224313200011782	0.000259628156251178	0.000295900941604663	0.000333077722114045	0.000371098394566201	0.000409896508049898	0.000449399206518456	0.000489527193145484	0.000530194717203360	0.000571309584133126	0.000612773189410427	0.000654480576745128	0.000696320521082406	0.000738175636800738	0.000779922511427360	0.000821431865114812	0.000862568736043082	0.000903192691831227	0.000943158066959858	0.000982314226122418	0.00102050585333837	0.00105757326657596	0.00109335275754614	0.00112767695624287	0.00116037521971850	0.00119127404449684	0.00122019750194076	0.00124696769580600	0.00127140524112918	0.00129332976351503	0.00131256041780674	0.00132891642504428	0.00134221762653760	0.00135228505380731	0.00135894151307273	0.00136201218289744	0.00136132522353632	0.00135671239646465	0.00134800969251002	0.00133505796695212	0.00131770357990319	0.00129579904023430	0.00126920365126902	0.00123778415642689	0.00120141538296528	0.00115998088193823	0.00111337356246677	0.00106149631839592	0.00100426264539926	0.000941597246583430	0.000873436624641548	0.000799729658606772	0.000720438163265029	0.000635537429299247	0.000545016742256606	0.000448879878454842	0.000347145575974143	0.000239847978916954	0.000127037053159792	8.77897186797635e-06	-0.000114843530902945	-0.000243730840137610	-0.000377766174878230	-0.000516815339815740	-0.000660726514868096	-0.000809330084080694	-0.000962438505100900	-0.00111984622039107	-0.00128132961125245	-0.00144664699563627	-0.00161553867061831	-0.00178772700030946	-0.00196291654986757	-0.00214079426616561	-0.00232102970555775	-0.00250327530906897	-0.00268716672521553	-0.00287232318054328	-0.00305834789784844	-0.00324482856192205	-0.00343133783253443	-0.00361743390425045	-0.00380266111254037	-0.00398655058552487	-0.00416862094056687	-0.00434837902479728	-0.00452532069853723	-0.00469893166045615	-0.00486868831318288	-0.00503405866796754	-0.00519450328687392	-0.00534947626086713	-0.00549842622204901	-0.00564079738818492	-0.00577603063756000	-0.00590356461210132	-0.00602283684660506	-0.00613328492181472	-0.00623434763900824	-0.00632546621366844	-0.00640608548573339	-0.00647565514385085	-0.00653363096099392	-0.00657947603873473	-0.00661266205741819	-0.00663267052942962	-0.00663899405270874	-0.00663113756162733	-0.00660861957232020	-0.00657097341953782	-0.00651774848207534	-0.00644851139382596	-0.00636284723750723	-0.00626036071811688	-0.00614067731319020	-0.00600344439695351	-0.00584833233549876	-0.00567503555014152	-0.00548327354616969	-0.00527279190424233	-0.00504336323175746	-0.00479478807157392	-0.00452689576554616	-0.00423954527041090	-0.00393262592365166	-0.00360605815706066	-0.00325979415581768	-0.00289381846101099	-0.00250814851363794	-0.00210283513823989	-0.00167796296444938	-0.00123365078485535	-0.000770051847725404	-0.000287354083261241	0.000214219737794554	0.000734411914236958	0.00127292979404929	0.00182944582436131	0.00240359767229438	0.00299498841711557	0.00360318681396319	0.00422772762924424	0.00486811204764207	0.00552380815050822	0.00619425146524849	0.00687884558514899	0.00757696285892348	0.00828794514910028	0.00901110465820450	0.00974572482153073	0.0104910612651423	0.0112463428275768	0.0120107726435833	0.0127835292880672	0.0135637679782693	0.0143506218320643	0.0151432031801237	0.0159406049295534	0.0167419019764879	0.0175461526649971	0.0183524002895432	0.0191596746381147	0.0199669935730532	0.0207733646464953	0.0215777867472505	0.0223792517758579	0.0231767463444790	0.0239692534982170	0.0247557544543851	0.0255352303561949	0.0263066640372835	0.0270690417934619	0.0278213551580332	0.0285626026770073	0.0292917916805251	0.0300079400467960	0.0307100779548594	0.0313972496224878	0.0320685150255725	0.0327229515953579	0.0333596558899303	0.0339777452364096	0.0345763593403479	0.0351546618589005	0.0357118419344030	0.0362471156850695	0.0367597276496091	0.0372489521826544	0.0377140947979933	0.0381544934567065	0.0385695197974252	0.0389585803060465	0.0393211174223717	0.0396566105812651	0.0399645771860731	0.0402445735121859	0.0404961955387755	0.0407190797068981	0.0409129036023091	0.0410773865614994	0.0412122901996327	0.0413174188592285	0.0413926199786116	0.0414377843793234	0.0414528464718648	0.0414377843793234	0.0413926199786116	0.0413174188592285	0.0412122901996327	0.0410773865614994	0.0409129036023091	0.0407190797068981	0.0404961955387755	0.0402445735121859	0.0399645771860731	0.0396566105812651	0.0393211174223717	0.0389585803060465	0.0385695197974252	0.0381544934567065	0.0377140947979933	0.0372489521826544	0.0367597276496091	0.0362471156850695	0.0357118419344030	0.0351546618589005	0.0345763593403479	0.0339777452364096	0.0333596558899303	0.0327229515953579	0.0320685150255725	0.0313972496224878	0.0307100779548594	0.0300079400467960	0.0292917916805251	0.0285626026770073	0.0278213551580332	0.0270690417934619	0.0263066640372835	0.0255352303561949	0.0247557544543851	0.0239692534982170	0.0231767463444790	0.0223792517758579	0.0215777867472505	0.0207733646464953	0.0199669935730532	0.0191596746381147	0.0183524002895432	0.0175461526649971	0.0167419019764879	0.0159406049295534	0.0151432031801237	0.0143506218320643	0.0135637679782693	0.0127835292880672	0.0120107726435833	0.0112463428275768	0.0104910612651423	0.00974572482153073	0.00901110465820450	0.00828794514910028	0.00757696285892348	0.00687884558514899	0.00619425146524849	0.00552380815050822	0.00486811204764207	0.00422772762924424	0.00360318681396319	0.00299498841711557	0.00240359767229438	0.00182944582436131	0.00127292979404929	0.000734411914236958	0.000214219737794554	-0.000287354083261241	-0.000770051847725404	-0.00123365078485535	-0.00167796296444938	-0.00210283513823989	-0.00250814851363794	-0.00289381846101099	-0.00325979415581768	-0.00360605815706066	-0.00393262592365166	-0.00423954527041090	-0.00452689576554616	-0.00479478807157392	-0.00504336323175746	-0.00527279190424233	-0.00548327354616969	-0.00567503555014152	-0.00584833233549876	-0.00600344439695351	-0.00614067731319020	-0.00626036071811688	-0.00636284723750723	-0.00644851139382596	-0.00651774848207534	-0.00657097341953782	-0.00660861957232020	-0.00663113756162733	-0.00663899405270874	-0.00663267052942962	-0.00661266205741819	-0.00657947603873473	-0.00653363096099392	-0.00647565514385085	-0.00640608548573339	-0.00632546621366844	-0.00623434763900824	-0.00613328492181472	-0.00602283684660506	-0.00590356461210132	-0.00577603063756000	-0.00564079738818492	-0.00549842622204901	-0.00534947626086713	-0.00519450328687392	-0.00503405866796754	-0.00486868831318288	-0.00469893166045615	-0.00452532069853723	-0.00434837902479728	-0.00416862094056687	-0.00398655058552487	-0.00380266111254037	-0.00361743390425045	-0.00343133783253443	-0.00324482856192205	-0.00305834789784844	-0.00287232318054328	-0.00268716672521553	-0.00250327530906897	-0.00232102970555775	-0.00214079426616561	-0.00196291654986757	-0.00178772700030946	-0.00161553867061831	-0.00144664699563627	-0.00128132961125245	-0.00111984622039107	-0.000962438505100900	-0.000809330084080694	-0.000660726514868096	-0.000516815339815740	-0.000377766174878230	-0.000243730840137610	-0.000114843530902945	8.77897186797635e-06	0.000127037053159792	0.000239847978916954	0.000347145575974143	0.000448879878454842	0.000545016742256606	0.000635537429299247	0.000720438163265029	0.000799729658606772	0.000873436624641548	0.000941597246583430	0.00100426264539926	0.00106149631839592	0.00111337356246677	0.00115998088193823	0.00120141538296528	0.00123778415642689	0.00126920365126902	0.00129579904023430	0.00131770357990319	0.00133505796695212	0.00134800969251002	0.00135671239646465	0.00136132522353632	0.00136201218289744	0.00135894151307273	0.00135228505380731	0.00134221762653760	0.00132891642504428	0.00131256041780674	0.00129332976351503	0.00127140524112918	0.00124696769580600	0.00122019750194076	0.00119127404449684	0.00116037521971850	0.00112767695624287	0.00109335275754614	0.00105757326657596	0.00102050585333837	0.000982314226122418	0.000943158066959858	0.000903192691831227	0.000862568736043082	0.000821431865114812	0.000779922511427360	0.000738175636800738	0.000696320521082406	0.000654480576745128	0.000612773189410427	0.000571309584133126	0.000530194717203360	0.000489527193145484	0.000449399206518456	0.000409896508049898	0.000371098394566201	0.000333077722114045	0.000295900941604663	0.000259628156251178	0.000224313200011782	0.000190003736197180	0.000156741375350128	0.000124561811457761	9.34949755142414e-05	6.35652054117620e-05	3.47914311025357e-05	7.18737394288373e-06	-1.92382408968169e-05	-4.44814600959497e-05	-6.85428670799782e-05	-9.14273373231303e-05	-0.000113143785242178	-0.000133704903872869	-0.000153126898523231	-0.000171429215596652	-0.000188634267772200	-0.000204767156720392	-0.000219855394519360	-0.000233928624919437	-0.000247018345583469	-0.000259157632405919	-0.000270380866986140	-0.000280723468300077	-0.000290221629580491	-0.000298912061378422	-0.000306831741738490	-0.000314017674377647	-0.000320506655711566	-0.000326335051524955	-0.000331538584032050	-0.000336152130021442	-0.000340209530725563	-0.000343743413999592	-0.000346785029337693	-0.000349364096196338	-0.000351508666035362	-0.000353244998427493	-0.000354597451526591	-0.000355588387123981	-0.000356238090461231	-0.000356564704906741	-0.000356584181542816	-0.000356310243649574	-0.000355754366012507	-0.000354925768921706	-0.000353831426673119]
   * Referenced by: '<Root>/Discrete Filter'
   */
  real_T DiscreteFilter_DenCoef;       /* Expression: 1
                                        * Referenced by: '<Root>/Discrete Filter'
                                        */
  real_T DiscreteFilter_InitialStates; /* Expression: 0
                                        * Referenced by: '<Root>/Discrete Filter'
                                        */
  real_T Constant1_Value_d;            /* Expression: 0.5
                                        * Referenced by: '<S10>/Constant1'
                                        */
  real_T Constant2_Value;              /* Expression: 80
                                        * Referenced by: '<S10>/Constant2'
                                        */
  real_T Constant5_Value;              /* Expression: 2
                                        * Referenced by: '<S10>/Constant5'
                                        */
  real_T Constant4_Value;              /* Expression: 0
                                        * Referenced by: '<Root>/Constant4'
                                        */
  real_T Constant2_Value_c;            /* Expression: 1
                                        * Referenced by: '<Root>/Constant2'
                                        */
  real_T Delay_InitialCondition;       /* Expression: 0
                                        * Referenced by: '<Root>/Delay'
                                        */
  real_T Constant1_Value_b;            /* Expression: 2
                                        * Referenced by: '<Root>/Constant1'
                                        */
  real_T Constant_Value_n;             /* Expression: 1
                                        * Referenced by: '<S9>/Constant'
                                        */
  real_T Constant1_Value_bz;           /* Expression: 0.002
                                        * Referenced by: '<S9>/Constant1'
                                        */
  real_T Constant3_Value;              /* Expression: 1
                                        * Referenced by: '<Root>/Constant3'
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
extern JOLT_cal_type JOLT_cal_impl;
extern JOLT_cal_type *JOLT_cal;

#endif                                 /* RTW_HEADER_JOLT_cal_h_ */
