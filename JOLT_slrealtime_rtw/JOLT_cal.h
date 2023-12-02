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
  real_T Constant5_Value;              /* Expression: 1.5
                                        * Referenced by: '<Root>/Constant5'
                                        */
  real_T DiscreteFilter_NumCoef[501];
  /* Expression: [0.000225702073991021	0.000226941692700600	0.000228073287794944	0.000229094394896881	0.000230001025806862	0.000230787649113105	0.000231447175105064	0.000231970945074563	0.000232348725080504	0.000232568704244421	0.000232617497635240	0.000232480153792668	0.000232140166929364	0.000231579493842769	0.000230778575557996	0.000229716363713601	0.000228370351692414	0.000226716610489856	0.000224729829302366	0.000222383360808750	0.000219649271107363	0.000216498394262206	0.000212900391401155	0.000208823814299713	0.000204236173373925	0.000199104009996386	0.000193392973039663	0.000187067899541950	0.000180092899380403	0.000172431443828326	0.000164046457863377	0.000154900416084959	0.000144955442090363	0.000134173411150651	0.000122516056019064	0.000109945075696683	9.64222469723577e-05	8.19095385463890e-05	6.63692275403348e-05	4.97640181883689e-05	3.20571624991370e-05	1.32125826707841e-05	-6.80500496398180e-06	-2.80299646914686e-05	-5.04956151029706e-05	-7.42341019516690e-05	-9.92762704232763e-05	-0.000125651537067215	-0.000153387761638575	-0.000182511119104207	-0.000213045972068947	-0.000245014743880103	-0.000278437792670180	-0.000313333286598986	-0.000349717080557181	-0.000387602594593620	-0.000427000694328744	-0.000467919573615688	-0.000510364639709676	-0.000554338401204762	-0.000599840358994912	-0.000646866900513922	-0.000695411197505717	-0.000745463107573071	-0.000797009079748875	-0.000850032064329690	-0.000904511427206446	-0.000960422868921823	-0.00101773834867808	-0.00107642601351286	-0.00113645013285391	-0.00119777103865641	-0.00126034507131930	-0.00132412453156891	-0.00138905763848997	-0.00145508849387536	-0.00152215705305684	-0.00159019910236961	-0.00165914624339381	-0.00172892588410581	-0.00179946123706178	-0.00187067132472540	-0.00194247099204039	-0.00201477092633729	-0.00208747768465241	-0.00216049372852516	-0.00223371746632778	-0.00230704330316955	-0.00238036169840505	-0.00245355923076355	-0.00252651867110405	-0.00259911906278754	-0.00267123580964543	-0.00274274077151004	-0.00281350236726000	-0.00288338568532052	-0.00295225260154550	-0.00301996190439523	-0.00308636942731078	-0.00315132818817294	-0.00321468853572103	-0.00327629830279398	-0.00333600296624359	-0.00339364581335732	-0.00344906811461580	-0.00350210930259806	-0.00355260715683556	-0.00360039799440460	-0.00364531686603512	-0.00368719775750284	-0.00372587379606085	-0.00376117746165624	-0.00379294080266718	-0.00382099565588594	-0.00384517387046395	-0.00386530753552598	-0.00388122921115160	-0.00389277216241404	-0.00389977059615879	-0.00390205990019657	-0.00389947688457888	-0.00389186002461753	-0.00387904970530374	-0.00386088846677717	-0.00383722125049002	-0.00380789564570727	-0.00377276213597999	-0.00373167434522583	-0.00368448928304747	-0.00363106758891829	-0.00357127377486242	-0.00350497646625564	-0.00343204864037311	-0.00335236786230991	-0.00326581651790142	-0.00317228204327166	-0.00307165715063977	-0.00296384005001729	-0.00284873466643215	-0.00272625085231876	-0.00259630459471808	-0.00245881821693644	-0.00231372057431720	-0.00216094724378546	-0.00200044070683266	-0.00183215052561509	-0.00165603351184777	-0.00147205388818393	-0.00128018344177853	-0.00108040166974393	-0.000872695916215616	-0.000657061500755791	-0.000433501837834050	-0.000202028547135036	3.73384455450693e-05	0.000284570817039217	0.000539631765400961	0.000802475938547229	0.00107304937313973	0.00135128944387858	0.00163712482336771	0.00193047545269738	0.00223125252287434	0.00253935846721538	0.00285468696480480	0.00317712295510096	0.00350654266376141	0.00384281363974042	0.00418579480369659	0.00453533650773227	0.00489128060647039	0.00525346053945768	0.00562170142486737	0.00599582016445753	0.00637562555972535	0.00676091843918081	0.00715149179664711	0.00754713094047876	0.00794761365357224	0.00835271036402771	0.00876218432630468	0.00917579181269851	0.00959328231494903	0.0100143987557773	0.0104388777101313	0.0108664496359064	0.0112968391138921	0.0117297650966820	0.0121649411662697	0.0126020758000410	0.0130408726448579	0.0134810307989176	0.0139222451010591	0.0143642064271741	0.0148066019933716	0.0152491156655328	0.0156914282748800	0.0161332179391791	0.0165741603891789	0.0170139292998864	0.0174521966262677	0.0178886329429541	0.0183229077875298	0.0187546900069669	0.0191836481067704	0.0196094506023890	0.0200317663724432	0.0204502650133184	0.0208646171946660	0.0212744950153552	0.0216795723594125	0.0220795252514893	0.0224740322113904	0.0228627746072046	0.0232454370065709	0.0236217075256210	0.0239912781751371	0.0243538452034697	0.0247091094357590	0.0250567766090132	0.0253965577025959	0.0257281692636831	0.0260513337272578	0.0263657797302108	0.0266712424191306	0.0269674637513685	0.0272541927889740	0.0275311859851066	0.0277982074625370	0.0280550292838636	0.0283014317130783	0.0285372034681286	0.0287621419641341	0.0289760535469288	0.0291787537166112	0.0293700673407995	0.0295498288573027	0.0297178824659314	0.0298740823091876	0.0300182926415878	0.0301503879873876	0.0302702532864951	0.0303777840283714	0.0304728863737374	0.0305554772639200	0.0306254845176881	0.0306828469154475	0.0307275142706770	0.0307594474885113	0.0307786186113878	0.0307850108516965	0.0307786186113878	0.0307594474885113	0.0307275142706770	0.0306828469154475	0.0306254845176881	0.0305554772639200	0.0304728863737374	0.0303777840283714	0.0302702532864951	0.0301503879873876	0.0300182926415878	0.0298740823091876	0.0297178824659314	0.0295498288573027	0.0293700673407995	0.0291787537166112	0.0289760535469288	0.0287621419641341	0.0285372034681286	0.0283014317130783	0.0280550292838636	0.0277982074625370	0.0275311859851066	0.0272541927889740	0.0269674637513685	0.0266712424191306	0.0263657797302108	0.0260513337272578	0.0257281692636831	0.0253965577025959	0.0250567766090132	0.0247091094357590	0.0243538452034697	0.0239912781751371	0.0236217075256210	0.0232454370065709	0.0228627746072046	0.0224740322113904	0.0220795252514893	0.0216795723594125	0.0212744950153552	0.0208646171946660	0.0204502650133184	0.0200317663724432	0.0196094506023890	0.0191836481067704	0.0187546900069669	0.0183229077875298	0.0178886329429541	0.0174521966262677	0.0170139292998864	0.0165741603891789	0.0161332179391791	0.0156914282748800	0.0152491156655328	0.0148066019933716	0.0143642064271741	0.0139222451010591	0.0134810307989176	0.0130408726448579	0.0126020758000410	0.0121649411662697	0.0117297650966820	0.0112968391138921	0.0108664496359064	0.0104388777101313	0.0100143987557773	0.00959328231494903	0.00917579181269851	0.00876218432630468	0.00835271036402771	0.00794761365357224	0.00754713094047876	0.00715149179664711	0.00676091843918081	0.00637562555972535	0.00599582016445753	0.00562170142486737	0.00525346053945768	0.00489128060647039	0.00453533650773227	0.00418579480369659	0.00384281363974042	0.00350654266376141	0.00317712295510096	0.00285468696480480	0.00253935846721538	0.00223125252287434	0.00193047545269738	0.00163712482336771	0.00135128944387858	0.00107304937313973	0.000802475938547229	0.000539631765400961	0.000284570817039217	3.73384455450693e-05	-0.000202028547135036	-0.000433501837834050	-0.000657061500755791	-0.000872695916215616	-0.00108040166974393	-0.00128018344177853	-0.00147205388818393	-0.00165603351184777	-0.00183215052561509	-0.00200044070683266	-0.00216094724378546	-0.00231372057431720	-0.00245881821693644	-0.00259630459471808	-0.00272625085231876	-0.00284873466643215	-0.00296384005001729	-0.00307165715063977	-0.00317228204327166	-0.00326581651790142	-0.00335236786230991	-0.00343204864037311	-0.00350497646625564	-0.00357127377486242	-0.00363106758891829	-0.00368448928304747	-0.00373167434522583	-0.00377276213597999	-0.00380789564570727	-0.00383722125049002	-0.00386088846677717	-0.00387904970530374	-0.00389186002461753	-0.00389947688457888	-0.00390205990019657	-0.00389977059615879	-0.00389277216241404	-0.00388122921115160	-0.00386530753552598	-0.00384517387046395	-0.00382099565588594	-0.00379294080266718	-0.00376117746165624	-0.00372587379606085	-0.00368719775750284	-0.00364531686603512	-0.00360039799440460	-0.00355260715683556	-0.00350210930259806	-0.00344906811461580	-0.00339364581335732	-0.00333600296624359	-0.00327629830279398	-0.00321468853572103	-0.00315132818817294	-0.00308636942731078	-0.00301996190439523	-0.00295225260154550	-0.00288338568532052	-0.00281350236726000	-0.00274274077151004	-0.00267123580964543	-0.00259911906278754	-0.00252651867110405	-0.00245355923076355	-0.00238036169840505	-0.00230704330316955	-0.00223371746632778	-0.00216049372852516	-0.00208747768465241	-0.00201477092633729	-0.00194247099204039	-0.00187067132472540	-0.00179946123706178	-0.00172892588410581	-0.00165914624339381	-0.00159019910236961	-0.00152215705305684	-0.00145508849387536	-0.00138905763848997	-0.00132412453156891	-0.00126034507131930	-0.00119777103865641	-0.00113645013285391	-0.00107642601351286	-0.00101773834867808	-0.000960422868921823	-0.000904511427206446	-0.000850032064329690	-0.000797009079748875	-0.000745463107573071	-0.000695411197505717	-0.000646866900513922	-0.000599840358994912	-0.000554338401204762	-0.000510364639709676	-0.000467919573615688	-0.000427000694328744	-0.000387602594593620	-0.000349717080557181	-0.000313333286598986	-0.000278437792670180	-0.000245014743880103	-0.000213045972068947	-0.000182511119104207	-0.000153387761638575	-0.000125651537067215	-9.92762704232763e-05	-7.42341019516690e-05	-5.04956151029706e-05	-2.80299646914686e-05	-6.80500496398180e-06	1.32125826707841e-05	3.20571624991370e-05	4.97640181883689e-05	6.63692275403348e-05	8.19095385463890e-05	9.64222469723577e-05	0.000109945075696683	0.000122516056019064	0.000134173411150651	0.000144955442090363	0.000154900416084959	0.000164046457863377	0.000172431443828326	0.000180092899380403	0.000187067899541950	0.000193392973039663	0.000199104009996386	0.000204236173373925	0.000208823814299713	0.000212900391401155	0.000216498394262206	0.000219649271107363	0.000222383360808750	0.000224729829302366	0.000226716610489856	0.000228370351692414	0.000229716363713601	0.000230778575557996	0.000231579493842769	0.000232140166929364	0.000232480153792668	0.000232617497635240	0.000232568704244421	0.000232348725080504	0.000231970945074563	0.000231447175105064	0.000230787649113105	0.000230001025806862	0.000229094394896881	0.000228073287794944	0.000226941692700600	0.000225702073991021]
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
  real_T Constant5_Value_k;            /* Expression: 2
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
