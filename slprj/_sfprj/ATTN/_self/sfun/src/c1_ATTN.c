/* Include files */

#include "ATTN_sfun.h"
#include "c1_ATTN.h"
#include "mwmathutil.h"
#define _SF_MEX_LISTEN_FOR_CTRL_C(S)   sf_mex_listen_for_ctrl_c(S);
#ifdef utFree
#undef utFree
#endif

#ifdef utMalloc
#undef utMalloc
#endif

#ifdef __cplusplus

extern "C" void *utMalloc(size_t size);
extern "C" void utFree(void*);

#else

extern void *utMalloc(size_t size);
extern void utFree(void*);

#endif

/* Forward Declarations */

/* Type Definitions */

/* Named Constants */
#define CALL_EVENT                     (-1)

/* Variable Declarations */

/* Variable Definitions */
static real_T _sfTime_;
static emlrtMCInfo c1_emlrtMCI = { 122,/* lineNo */
  13,                                  /* colNo */
  "rng",                               /* fName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/rng.m"/* pName */
};

static emlrtMCInfo c1_b_emlrtMCI = { 158,/* lineNo */
  17,                                  /* colNo */
  "eml_rand_mt19937ar",                /* fName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/eml_rand_mt19937ar.m"/* pName */
};

static emlrtMCInfo c1_c_emlrtMCI = { 14,/* lineNo */
  9,                                   /* colNo */
  "log",                               /* fName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/elfun/log.m"/* pName */
};

static emlrtMCInfo c1_d_emlrtMCI = { 13,/* lineNo */
  13,                                  /* colNo */
  "toLogicalCheck",                    /* fName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/eml/+coder/+internal/toLogicalCheck.m"/* pName */
};

static emlrtRSInfo c1_emlrtRSI = { 54, /* lineNo */
  "rng",                               /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/rng.m"/* pathName */
};

static emlrtRSInfo c1_b_emlrtRSI = { 113,/* lineNo */
  "rng",                               /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/rng.m"/* pathName */
};

static emlrtRSInfo c1_c_emlrtRSI = { 114,/* lineNo */
  "rng",                               /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/rng.m"/* pathName */
};

static emlrtRSInfo c1_d_emlrtRSI = { 116,/* lineNo */
  "rng",                               /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/rng.m"/* pathName */
};

static emlrtRSInfo c1_e_emlrtRSI = { 118,/* lineNo */
  "rng",                               /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/rng.m"/* pathName */
};

static emlrtRSInfo c1_f_emlrtRSI = { 120,/* lineNo */
  "rng",                               /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/rng.m"/* pathName */
};

static emlrtRSInfo c1_g_emlrtRSI = { 273,/* lineNo */
  "rng",                               /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/rng.m"/* pathName */
};

static emlrtRSInfo c1_h_emlrtRSI = { 275,/* lineNo */
  "rng",                               /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/rng.m"/* pathName */
};

static emlrtRSInfo c1_i_emlrtRSI = { 277,/* lineNo */
  "rng",                               /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/rng.m"/* pathName */
};

static emlrtRSInfo c1_j_emlrtRSI = { 278,/* lineNo */
  "rng",                               /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/rng.m"/* pathName */
};

static emlrtRSInfo c1_k_emlrtRSI = { 45,/* lineNo */
  "eml_rand_mt19937ar_stateful",       /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/private/eml_rand_mt19937ar_stateful.m"/* pathName */
};

static emlrtRSInfo c1_l_emlrtRSI = { 69,/* lineNo */
  "eml_rand_mt19937ar",                /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/eml_rand_mt19937ar.m"/* pathName */
};

static emlrtRSInfo c1_m_emlrtRSI = { 19,/* lineNo */
  "eml_rand_mcg16807_stateful",        /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/private/eml_rand_mcg16807_stateful.m"/* pathName */
};

static emlrtRSInfo c1_n_emlrtRSI = { 49,/* lineNo */
  "eml_rand_mcg16807",                 /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/private/eml_rand_mcg16807.m"/* pathName */
};

static emlrtRSInfo c1_o_emlrtRSI = { 7,/* lineNo */
  "negative_exp_rand",                 /* fcnName */
  "/home/electro/Code_Repo/n-CORTEx/negative_exp_rand.m"/* pathName */
};

static emlrtRSInfo c1_p_emlrtRSI = { 10,/* lineNo */
  "exprnd",                            /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/stats/eml/exprnd.m"/* pathName */
};

static emlrtRSInfo c1_q_emlrtRSI = { 1,/* lineNo */
  "rnd",                               /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/eml/+coder/+internal/rnd.p"/* pathName */
};

static emlrtRSInfo c1_r_emlrtRSI = { 1,/* lineNo */
  "exprnd",                            /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/eml/+coder/+internal/private/exprnd.p"/* pathName */
};

static emlrtRSInfo c1_s_emlrtRSI = { 107,/* lineNo */
  "rand",                              /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/rand.m"/* pathName */
};

static emlrtRSInfo c1_t_emlrtRSI = { 41,/* lineNo */
  "eml_rand",                          /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/private/eml_rand.m"/* pathName */
};

static emlrtRSInfo c1_u_emlrtRSI = { 43,/* lineNo */
  "eml_rand",                          /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/private/eml_rand.m"/* pathName */
};

static emlrtRSInfo c1_v_emlrtRSI = { 45,/* lineNo */
  "eml_rand",                          /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/private/eml_rand.m"/* pathName */
};

static emlrtRSInfo c1_w_emlrtRSI = { 23,/* lineNo */
  "eml_rand_shr3cong_stateful",        /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/private/eml_rand_shr3cong_stateful.m"/* pathName */
};

static emlrtRSInfo c1_x_emlrtRSI = { 29,/* lineNo */
  "eml_rand_shr3cong",                 /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/private/eml_rand_shr3cong.m"/* pathName */
};

static emlrtRSInfo c1_y_emlrtRSI = { 64,/* lineNo */
  "eml_rand_shr3cong",                 /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/private/eml_rand_shr3cong.m"/* pathName */
};

static emlrtRSInfo c1_ab_emlrtRSI = { 23,/* lineNo */
  "eml_rand_mt19937ar_stateful",       /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/private/eml_rand_mt19937ar_stateful.m"/* pathName */
};

static emlrtRSInfo c1_bb_emlrtRSI = { 51,/* lineNo */
  "eml_rand_mt19937ar",                /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/eml_rand_mt19937ar.m"/* pathName */
};

static emlrtRSInfo c1_cb_emlrtRSI = { 151,/* lineNo */
  "eml_rand_mt19937ar",                /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/eml_rand_mt19937ar.m"/* pathName */
};

static emlrtRSInfo c1_db_emlrtRSI = { 257,/* lineNo */
  "eml_rand_mt19937ar",                /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/eml_rand_mt19937ar.m"/* pathName */
};

static emlrtRSInfo c1_eb_emlrtRSI = { 263,/* lineNo */
  "eml_rand_mt19937ar",                /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/eml_rand_mt19937ar.m"/* pathName */
};

static emlrtRSInfo c1_fb_emlrtRSI = { 268,/* lineNo */
  "eml_rand_mt19937ar",                /* fcnName */
  "/usr/local/MATLAB/R2023a/toolbox/eml/lib/matlab/randfun/eml_rand_mt19937ar.m"/* pathName */
};

static emlrtRSInfo c1_gb_emlrtRSI = { 21,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_hb_emlrtRSI = { 45,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_ib_emlrtRSI = { 74,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_jb_emlrtRSI = { 75,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_kb_emlrtRSI = { 86,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_lb_emlrtRSI = { 115,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_mb_emlrtRSI = { 191,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_nb_emlrtRSI = { 215,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_ob_emlrtRSI = { 244,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_pb_emlrtRSI = { 245,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_qb_emlrtRSI = { 256,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_rb_emlrtRSI = { 283,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_sb_emlrtRSI = { 289,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_tb_emlrtRSI = { 312,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_ub_emlrtRSI = { 321,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_vb_emlrtRSI = { 398,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_wb_emlrtRSI = { 421,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_xb_emlrtRSI = { 423,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_yb_emlrtRSI = { 425,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_ac_emlrtRSI = { 456,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_bc_emlrtRSI = { 457,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_cc_emlrtRSI = { 468,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_dc_emlrtRSI = { 495,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_ec_emlrtRSI = { 501,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_fc_emlrtRSI = { 525,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_gc_emlrtRSI = { 534,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_hc_emlrtRSI = { 611,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_ic_emlrtRSI = { 634,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_jc_emlrtRSI = { 636,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_kc_emlrtRSI = { 638,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_lc_emlrtRSI = { 670,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_mc_emlrtRSI = { 671,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_nc_emlrtRSI = { 682,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_oc_emlrtRSI = { 694,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_pc_emlrtRSI = { 695,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_qc_emlrtRSI = { 706,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_rc_emlrtRSI = { 734,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_sc_emlrtRSI = { 740,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_tc_emlrtRSI = { 764,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_uc_emlrtRSI = { 773,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_vc_emlrtRSI = { 850,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_wc_emlrtRSI = { 912,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_xc_emlrtRSI = { 931,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_yc_emlrtRSI = { 956,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_ad_emlrtRSI = { 979,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_bd_emlrtRSI = { 998,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtRSInfo c1_cd_emlrtRSI = { 1024,/* lineNo */
  "MATLAB Function",                   /* fcnName */
  "#ATTN:51"                           /* pathName */
};

static emlrtDCInfo c1_emlrtDCI = { 17, /* lineNo */
  13,                                  /* colNo */
  "MATLAB Function",                   /* fName */
  "#ATTN:51",                          /* pName */
  1                                    /* checkKind */
};

static emlrtDCInfo c1_b_emlrtDCI = { 19,/* lineNo */
  21,                                  /* colNo */
  "MATLAB Function",                   /* fName */
  "#ATTN:51",                          /* pName */
  1                                    /* checkKind */
};

static emlrtDCInfo c1_c_emlrtDCI = { 189,/* lineNo */
  21,                                  /* colNo */
  "MATLAB Function",                   /* fName */
  "#ATTN:51",                          /* pName */
  1                                    /* checkKind */
};

static emlrtDCInfo c1_d_emlrtDCI = { 396,/* lineNo */
  21,                                  /* colNo */
  "MATLAB Function",                   /* fName */
  "#ATTN:51",                          /* pName */
  1                                    /* checkKind */
};

static emlrtDCInfo c1_e_emlrtDCI = { 609,/* lineNo */
  21,                                  /* colNo */
  "MATLAB Function",                   /* fName */
  "#ATTN:51",                          /* pName */
  1                                    /* checkKind */
};

static emlrtDCInfo c1_f_emlrtDCI = { 848,/* lineNo */
  21,                                  /* colNo */
  "MATLAB Function",                   /* fName */
  "#ATTN:51",                          /* pName */
  1                                    /* checkKind */
};

static emlrtDCInfo c1_g_emlrtDCI = { 910,/* lineNo */
  21,                                  /* colNo */
  "MATLAB Function",                   /* fName */
  "#ATTN:51",                          /* pName */
  1                                    /* checkKind */
};

static emlrtDCInfo c1_h_emlrtDCI = { 977,/* lineNo */
  21,                                  /* colNo */
  "MATLAB Function",                   /* fName */
  "#ATTN:51",                          /* pName */
  1                                    /* checkKind */
};

static uint32_T c1_uv[625] = { 5489U, 1301868182U, 2938499221U, 2950281878U,
  1875628136U, 751856242U, 944701696U, 2243192071U, 694061057U, 219885934U,
  2066767472U, 3182869408U, 485472502U, 2336857883U, 1071588843U, 3418470598U,
  951210697U, 3693558366U, 2923482051U, 1793174584U, 2982310801U, 1586906132U,
  1951078751U, 1808158765U, 1733897588U, 431328322U, 4202539044U, 530658942U,
  1714810322U, 3025256284U, 3342585396U, 1937033938U, 2640572511U, 1654299090U,
  3692403553U, 4233871309U, 3497650794U, 862629010U, 2943236032U, 2426458545U,
  1603307207U, 1133453895U, 3099196360U, 2208657629U, 2747653927U, 931059398U,
  761573964U, 3157853227U, 785880413U, 730313442U, 124945756U, 2937117055U,
  3295982469U, 1724353043U, 3021675344U, 3884886417U, 4010150098U, 4056961966U,
  699635835U, 2681338818U, 1339167484U, 720757518U, 2800161476U, 2376097373U,
  1532957371U, 3902664099U, 1238982754U, 3725394514U, 3449176889U, 3570962471U,
  4287636090U, 4087307012U, 3603343627U, 202242161U, 2995682783U, 1620962684U,
  3704723357U, 371613603U, 2814834333U, 2111005706U, 624778151U, 2094172212U,
  4284947003U, 1211977835U, 991917094U, 1570449747U, 2962370480U, 1259410321U,
  170182696U, 146300961U, 2836829791U, 619452428U, 2723670296U, 1881399711U,
  1161269684U, 1675188680U, 4132175277U, 780088327U, 3409462821U, 1036518241U,
  1834958505U, 3048448173U, 161811569U, 618488316U, 44795092U, 3918322701U,
  1924681712U, 3239478144U, 383254043U, 4042306580U, 2146983041U, 3992780527U,
  3518029708U, 3545545436U, 3901231469U, 1896136409U, 2028528556U, 2339662006U,
  501326714U, 2060962201U, 2502746480U, 561575027U, 581893337U, 3393774360U,
  1778912547U, 3626131687U, 2175155826U, 319853231U, 986875531U, 819755096U,
  2915734330U, 2688355739U, 3482074849U, 2736559U, 2296975761U, 1029741190U,
  2876812646U, 690154749U, 579200347U, 4027461746U, 1285330465U, 2701024045U,
  4117700889U, 759495121U, 3332270341U, 2313004527U, 2277067795U, 4131855432U,
  2722057515U, 1264804546U, 3848622725U, 2211267957U, 4100593547U, 959123777U,
  2130745407U, 3194437393U, 486673947U, 1377371204U, 17472727U, 352317554U,
  3955548058U, 159652094U, 1232063192U, 3835177280U, 49423123U, 3083993636U,
  733092U, 2120519771U, 2573409834U, 1112952433U, 3239502554U, 761045320U,
  1087580692U, 2540165110U, 641058802U, 1792435497U, 2261799288U, 1579184083U,
  627146892U, 2165744623U, 2200142389U, 2167590760U, 2381418376U, 1793358889U,
  3081659520U, 1663384067U, 2009658756U, 2689600308U, 739136266U, 2304581039U,
  3529067263U, 591360555U, 525209271U, 3131882996U, 294230224U, 2076220115U,
  3113580446U, 1245621585U, 1386885462U, 3203270426U, 123512128U, 12350217U,
  354956375U, 4282398238U, 3356876605U, 3888857667U, 157639694U, 2616064085U,
  1563068963U, 2762125883U, 4045394511U, 4180452559U, 3294769488U, 1684529556U,
  1002945951U, 3181438866U, 22506664U, 691783457U, 2685221343U, 171579916U,
  3878728600U, 2475806724U, 2030324028U, 3331164912U, 1708711359U, 1970023127U,
  2859691344U, 2588476477U, 2748146879U, 136111222U, 2967685492U, 909517429U,
  2835297809U, 3206906216U, 3186870716U, 341264097U, 2542035121U, 3353277068U,
  548223577U, 3170936588U, 1678403446U, 297435620U, 2337555430U, 466603495U,
  1132321815U, 1208589219U, 696392160U, 894244439U, 2562678859U, 470224582U,
  3306867480U, 201364898U, 2075966438U, 1767227936U, 2929737987U, 3674877796U,
  2654196643U, 3692734598U, 3528895099U, 2796780123U, 3048728353U, 842329300U,
  191554730U, 2922459673U, 3489020079U, 3979110629U, 1022523848U, 2202932467U,
  3583655201U, 3565113719U, 587085778U, 4176046313U, 3013713762U, 950944241U,
  396426791U, 3784844662U, 3477431613U, 3594592395U, 2782043838U, 3392093507U,
  3106564952U, 2829419931U, 1358665591U, 2206918825U, 3170783123U, 31522386U,
  2988194168U, 1782249537U, 1105080928U, 843500134U, 1225290080U, 1521001832U,
  3605886097U, 2802786495U, 2728923319U, 3996284304U, 903417639U, 1171249804U,
  1020374987U, 2824535874U, 423621996U, 1988534473U, 2493544470U, 1008604435U,
  1756003503U, 1488867287U, 1386808992U, 732088248U, 1780630732U, 2482101014U,
  976561178U, 1543448953U, 2602866064U, 2021139923U, 1952599828U, 2360242564U,
  2117959962U, 2753061860U, 2388623612U, 4138193781U, 2962920654U, 2284970429U,
  766920861U, 3457264692U, 2879611383U, 815055854U, 2332929068U, 1254853997U,
  3740375268U, 3799380844U, 4091048725U, 2006331129U, 1982546212U, 686850534U,
  1907447564U, 2682801776U, 2780821066U, 998290361U, 1342433871U, 4195430425U,
  607905174U, 3902331779U, 2454067926U, 1708133115U, 1170874362U, 2008609376U,
  3260320415U, 2211196135U, 433538229U, 2728786374U, 2189520818U, 262554063U,
  1182318347U, 3710237267U, 1221022450U, 715966018U, 2417068910U, 2591870721U,
  2870691989U, 3418190842U, 4238214053U, 1540704231U, 1575580968U, 2095917976U,
  4078310857U, 2313532447U, 2110690783U, 4056346629U, 4061784526U, 1123218514U,
  551538993U, 597148360U, 4120175196U, 3581618160U, 3181170517U, 422862282U,
  3227524138U, 1713114790U, 662317149U, 1230418732U, 928171837U, 1324564878U,
  1928816105U, 1786535431U, 2878099422U, 3290185549U, 539474248U, 1657512683U,
  552370646U, 1671741683U, 3655312128U, 1552739510U, 2605208763U, 1441755014U,
  181878989U, 3124053868U, 1447103986U, 3183906156U, 1728556020U, 3502241336U,
  3055466967U, 1013272474U, 818402132U, 1715099063U, 2900113506U, 397254517U,
  4194863039U, 1009068739U, 232864647U, 2540223708U, 2608288560U, 2415367765U,
  478404847U, 3455100648U, 3182600021U, 2115988978U, 434269567U, 4117179324U,
  3461774077U, 887256537U, 3545801025U, 286388911U, 3451742129U, 1981164769U,
  786667016U, 3310123729U, 3097811076U, 2224235657U, 2959658883U, 3370969234U,
  2514770915U, 3345656436U, 2677010851U, 2206236470U, 271648054U, 2342188545U,
  4292848611U, 3646533909U, 3754009956U, 3803931226U, 4160647125U, 1477814055U,
  4043852216U, 1876372354U, 3133294443U, 3871104810U, 3177020907U, 2074304428U,
  3479393793U, 759562891U, 164128153U, 1839069216U, 2114162633U, 3989947309U,
  3611054956U, 1333547922U, 835429831U, 494987340U, 171987910U, 1252001001U,
  370809172U, 3508925425U, 2535703112U, 1276855041U, 1922855120U, 835673414U,
  3030664304U, 613287117U, 171219893U, 3423096126U, 3376881639U, 2287770315U,
  1658692645U, 1262815245U, 3957234326U, 1168096164U, 2968737525U, 2655813712U,
  2132313144U, 3976047964U, 326516571U, 353088456U, 3679188938U, 3205649712U,
  2654036126U, 1249024881U, 880166166U, 691800469U, 2229503665U, 1673458056U,
  4032208375U, 1851778863U, 2563757330U, 376742205U, 1794655231U, 340247333U,
  1505873033U, 396524441U, 879666767U, 3335579166U, 3260764261U, 3335999539U,
  506221798U, 4214658741U, 975887814U, 2080536343U, 3360539560U, 571586418U,
  138896374U, 4234352651U, 2737620262U, 3928362291U, 1516365296U, 38056726U,
  3599462320U, 3585007266U, 3850961033U, 471667319U, 1536883193U, 2310166751U,
  1861637689U, 2530999841U, 4139843801U, 2710569485U, 827578615U, 2012334720U,
  2907369459U, 3029312804U, 2820112398U, 1965028045U, 35518606U, 2478379033U,
  643747771U, 1924139484U, 4123405127U, 3811735531U, 3429660832U, 3285177704U,
  1948416081U, 1311525291U, 1183517742U, 1739192232U, 3979815115U, 2567840007U,
  4116821529U, 213304419U, 4125718577U, 1473064925U, 2442436592U, 1893310111U,
  4195361916U, 3747569474U, 828465101U, 2991227658U, 750582866U, 1205170309U,
  1409813056U, 678418130U, 1171531016U, 3821236156U, 354504587U, 4202874632U,
  3882511497U, 1893248677U, 1903078632U, 26340130U, 2069166240U, 3657122492U,
  3725758099U, 831344905U, 811453383U, 3447711422U, 2434543565U, 4166886888U,
  3358210805U, 4142984013U, 2988152326U, 3527824853U, 982082992U, 2809155763U,
  190157081U, 3340214818U, 2365432395U, 2548636180U, 2894533366U, 3474657421U,
  2372634704U, 2845748389U, 43024175U, 2774226648U, 1987702864U, 3186502468U,
  453610222U, 4204736567U, 1392892630U, 2471323686U, 2470534280U, 3541393095U,
  4269885866U, 3909911300U, 759132955U, 1482612480U, 667715263U, 1795580598U,
  2337923983U, 3390586366U, 581426223U, 1515718634U, 476374295U, 705213300U,
  363062054U, 2084697697U, 2407503428U, 2292957699U, 2426213835U, 2199989172U,
  1987356470U, 4026755612U, 2147252133U, 270400031U, 1367820199U, 2369854699U,
  2844269403U, 79981964U, 624U };

/* Function Declarations */
static void initialize_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance);
static void initialize_params_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance);
static void mdl_start_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance);
static void mdl_terminate_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance);
static void mdl_setup_runtime_resources_c1_ATTN(SFc1_ATTNInstanceStruct
  *chartInstance);
static void mdl_cleanup_runtime_resources_c1_ATTN(SFc1_ATTNInstanceStruct
  *chartInstance);
static void enable_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance);
static void disable_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance);
static void sf_gateway_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance);
static void ext_mode_exec_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance);
static void c1_do_animation_call_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance);
static const mxArray *get_sim_state_c1_ATTN(SFc1_ATTNInstanceStruct
  *chartInstance);
static void set_sim_state_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance, const
  mxArray *c1_st);
static void initSimStructsc1_ATTN(SFc1_ATTNInstanceStruct *chartInstance);
static void initSubchartIOPointersc1_ATTN(SFc1_ATTNInstanceStruct *chartInstance);
static void c1_rng(SFc1_ATTNInstanceStruct *chartInstance, const emlrtStack
                   *c1_sp);
static real_T c1_now(SFc1_ATTNInstanceStruct *chartInstance);
static real_T c1_mod(SFc1_ATTNInstanceStruct *chartInstance, real_T c1_x);
static real_T c1_negative_exp_rand(SFc1_ATTNInstanceStruct *chartInstance, const
  emlrtStack *c1_sp, real_T c1_range_min, real_T c1_range_max);
static real_T c1_sumColumnB(SFc1_ATTNInstanceStruct *chartInstance, real_T c1_x
  [2], int32_T c1_col);
static real_T c1_rand(SFc1_ATTNInstanceStruct *chartInstance, const emlrtStack
                      *c1_sp);
static const mxArray *c1_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const real_T c1_u);
static const mxArray *c1_b_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[14]);
static const mxArray *c1_c_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[17]);
static const mxArray *c1_d_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[11]);
static const mxArray *c1_e_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[10]);
static const mxArray *c1_f_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[6]);
static const mxArray *c1_g_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[2]);
static const mxArray *c1_h_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[15]);
static real_T c1_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance, const
  mxArray *c1_b_counter_out, const char_T *c1_identifier);
static real_T c1_b_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance,
  const mxArray *c1_u, const emlrtMsgIdentifier *c1_parentId);
static uint32_T c1_c_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance,
  const mxArray *c1_b_method, const char_T *c1_identifier, boolean_T *c1_svPtr);
static uint32_T c1_d_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance,
  const mxArray *c1_u, const emlrtMsgIdentifier *c1_parentId, boolean_T
  *c1_svPtr);
static void c1_e_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance, const
  mxArray *c1_d_state, const char_T *c1_identifier, boolean_T *c1_svPtr,
  uint32_T c1_y[625]);
static void c1_f_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance, const
  mxArray *c1_u, const emlrtMsgIdentifier *c1_parentId, boolean_T *c1_svPtr,
  uint32_T c1_y[625]);
static void c1_g_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance, const
  mxArray *c1_d_state, const char_T *c1_identifier, boolean_T *c1_svPtr,
  uint32_T c1_y[2]);
static void c1_h_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance, const
  mxArray *c1_u, const emlrtMsgIdentifier *c1_parentId, boolean_T *c1_svPtr,
  uint32_T c1_y[2]);
static uint8_T c1_i_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance,
  const mxArray *c1_b_is_active_c1_ATTN, const char_T *c1_identifier);
static uint8_T c1_j_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance,
  const mxArray *c1_u, const emlrtMsgIdentifier *c1_parentId);
static void c1_chart_data_browse_helper(SFc1_ATTNInstanceStruct *chartInstance,
  int32_T c1_ssIdNumber, const mxArray **c1_mxData, uint8_T *c1_isValueTooBig);
static void init_dsm_address_info(SFc1_ATTNInstanceStruct *chartInstance);
static void init_simulink_io_address(SFc1_ATTNInstanceStruct *chartInstance);

/* Function Definitions */
static void initialize_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance)
{
  emlrtStack c1_st = { NULL,           /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  c1_st.tls = chartInstance->c1_fEmlrtCtx;
  emlrtLicenseCheckR2022a(&c1_st, "EMLRT:runTime:MexFunctionNeedsLicense",
    "statistics_toolbox", 2);
  sim_mode_is_external(chartInstance->S);
  chartInstance->c1_sfEvent = CALL_EVENT;
  _sfTime_ = sf_get_time(chartInstance->S);
  chartInstance->c1_seed_not_empty = false;
  chartInstance->c1_method_not_empty = false;
  chartInstance->c1_state_not_empty = false;
  chartInstance->c1_b_state_not_empty = false;
  chartInstance->c1_c_state_not_empty = false;
  chartInstance->c1_is_active_c1_ATTN = 0U;
}

static void initialize_params_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance)
{
  (void)chartInstance;
}

static void mdl_start_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance)
{
  sim_mode_is_external(chartInstance->S);
}

static void mdl_terminate_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance)
{
  (void)chartInstance;
}

static void mdl_setup_runtime_resources_c1_ATTN(SFc1_ATTNInstanceStruct
  *chartInstance)
{
  setDebuggerFlag(chartInstance->S, true);
  setDataBrowseFcn(chartInstance->S, (void *)&c1_chart_data_browse_helper);
}

static void mdl_cleanup_runtime_resources_c1_ATTN(SFc1_ATTNInstanceStruct
  *chartInstance)
{
  (void)chartInstance;
}

static void enable_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance)
{
  _sfTime_ = sf_get_time(chartInstance->S);
}

static void disable_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance)
{
  _sfTime_ = sf_get_time(chartInstance->S);
}

static void sf_gateway_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance)
{
  static char_T c1_cv10[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv11[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv12[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv14[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv15[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv16[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv17[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv18[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv19[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv2[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv20[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv21[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv22[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv23[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv27[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv28[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv29[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv3[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv30[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv31[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv32[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv33[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv34[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv35[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv36[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv38[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv4[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv40[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv41[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv5[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv6[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv7[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv8[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv9[19] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'n', 'o', 'l',
    'o', 'g', 'i', 'c', 'a', 'l', 'n', 'a', 'n' };

  static char_T c1_cv13[17] = { 'R', 'e', 'w', 'a', 'r', 'd', ' ', 'c', 'o', 'l',
    'l', 'e', 'c', 't', 'i', 'o', 'n' };

  static char_T c1_cv1[15] = { 'S', 't', 'a', 'r', 't', ' ', 'n', 'e', 'w', ' ',
    't', 'r', 'i', 'a', 'l' };

  static char_T c1_cv[14] = { 'D', 'e', 'l', 'i', 'v', 'e', 'r', ' ', 'R', 'e',
    'w', 'a', 'r', 'd' };

  static char_T c1_cv37[14] = { 'E', 'n', 'd', ' ', 'o', 'f', ' ', 'l', 'o', 'c',
    'k', 'o', 'u', 't' };

  static char_T c1_cv42[11] = { 'N', 'o', ' ', 'r', 'e', 's', 'p', 'o', 'n', 's',
    'e' };

  static char_T c1_cv24[10] = { 'E', 'n', 'd', ' ', 'o', 'f', ' ', 'I', 'T', 'I'
  };

  static char_T c1_cv26[10] = { 'D', 'i', 's', 't', 'r', 'a', 'c', 't', 'o', 'r'
  };

  static char_T c1_cv25[6] = { 'T', 'a', 'r', 'g', 'e', 't' };

  static char_T c1_cv39[2] = { 'C', 'R' };

  emlrtStack c1_b_st;
  emlrtStack c1_st = { NULL,           /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  const mxArray *c1_ab_y = NULL;
  const mxArray *c1_ac_y = NULL;
  const mxArray *c1_b_y = NULL;
  const mxArray *c1_bb_y = NULL;
  const mxArray *c1_bc_y = NULL;
  const mxArray *c1_c_y = NULL;
  const mxArray *c1_cb_y = NULL;
  const mxArray *c1_cc_y = NULL;
  const mxArray *c1_d_y = NULL;
  const mxArray *c1_db_y = NULL;
  const mxArray *c1_dc_y = NULL;
  const mxArray *c1_e_y = NULL;
  const mxArray *c1_eb_y = NULL;
  const mxArray *c1_ec_y = NULL;
  const mxArray *c1_f_y = NULL;
  const mxArray *c1_fb_y = NULL;
  const mxArray *c1_fc_y = NULL;
  const mxArray *c1_g_y = NULL;
  const mxArray *c1_gb_y = NULL;
  const mxArray *c1_gc_y = NULL;
  const mxArray *c1_h_y = NULL;
  const mxArray *c1_hb_y = NULL;
  const mxArray *c1_hc_y = NULL;
  const mxArray *c1_i_y = NULL;
  const mxArray *c1_ib_y = NULL;
  const mxArray *c1_ic_y = NULL;
  const mxArray *c1_j_y = NULL;
  const mxArray *c1_jb_y = NULL;
  const mxArray *c1_jc_y = NULL;
  const mxArray *c1_k_y = NULL;
  const mxArray *c1_kb_y = NULL;
  const mxArray *c1_kc_y = NULL;
  const mxArray *c1_l_y = NULL;
  const mxArray *c1_lb_y = NULL;
  const mxArray *c1_lc_y = NULL;
  const mxArray *c1_m_y = NULL;
  const mxArray *c1_mb_y = NULL;
  const mxArray *c1_mc_y = NULL;
  const mxArray *c1_n_y = NULL;
  const mxArray *c1_nb_y = NULL;
  const mxArray *c1_nc_y = NULL;
  const mxArray *c1_o_y = NULL;
  const mxArray *c1_ob_y = NULL;
  const mxArray *c1_oc_y = NULL;
  const mxArray *c1_p_y = NULL;
  const mxArray *c1_pb_y = NULL;
  const mxArray *c1_pc_y = NULL;
  const mxArray *c1_q_y = NULL;
  const mxArray *c1_qb_y = NULL;
  const mxArray *c1_qc_y = NULL;
  const mxArray *c1_r_y = NULL;
  const mxArray *c1_rb_y = NULL;
  const mxArray *c1_rc_y = NULL;
  const mxArray *c1_s_y = NULL;
  const mxArray *c1_sb_y = NULL;
  const mxArray *c1_t_y = NULL;
  const mxArray *c1_tb_y = NULL;
  const mxArray *c1_u_y = NULL;
  const mxArray *c1_ub_y = NULL;
  const mxArray *c1_v_y = NULL;
  const mxArray *c1_vb_y = NULL;
  const mxArray *c1_w_y = NULL;
  const mxArray *c1_wb_y = NULL;
  const mxArray *c1_x_y = NULL;
  const mxArray *c1_xb_y = NULL;
  const mxArray *c1_y = NULL;
  const mxArray *c1_y_y = NULL;
  const mxArray *c1_yb_y = NULL;
  real_T c1_b_counter_out;
  real_T c1_b_delay_in;
  real_T c1_b_delay_out;
  real_T c1_b_left_trigger_in;
  real_T c1_b_left_trigger_out;
  real_T c1_b_localTime_out;
  real_T c1_b_npxlsAcq_out;
  real_T c1_b_numLicks_out;
  real_T c1_b_reward_duration_in;
  real_T c1_b_right_trigger_out;
  real_T c1_b_sessionTime;
  real_T c1_b_state_out;
  real_T c1_b_stim_duration_in;
  real_T c1_b_trialNum_out;
  int32_T c1_b_reward_trigger_out;
  boolean_T c1_guard1;
  c1_st.tls = chartInstance->c1_fEmlrtCtx;
  c1_b_st.prev = &c1_st;
  c1_b_st.tls = c1_st.tls;
  chartInstance->c1_JITTransitionAnimation[0] = 0U;
  _sfTime_ = sf_get_time(chartInstance->S);
  chartInstance->c1_sfEvent = CALL_EVENT;
  c1_b_sessionTime = *chartInstance->c1_sessionTime;
  c1_b_delay_in = *chartInstance->c1_delay_in;
  c1_b_left_trigger_in = *chartInstance->c1_left_trigger_in;
  c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
  c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
  c1_b_counter_out = *chartInstance->c1_counter_in + 1.0;
  if (*chartInstance->c1_stage != (real_T)(int32_T)muDoubleScalarFloor
      (*chartInstance->c1_stage)) {
    emlrtIntegerCheckR2012b(*chartInstance->c1_stage, &c1_emlrtDCI, &c1_st);
  }

  switch ((int32_T)*chartInstance->c1_stage) {
   case 1:
    if (*chartInstance->c1_state_in != (real_T)(int32_T)muDoubleScalarFloor
        (*chartInstance->c1_state_in)) {
      emlrtIntegerCheckR2012b(*chartInstance->c1_state_in, &c1_b_emlrtDCI,
        &c1_st);
    }

    switch ((int32_T)*chartInstance->c1_state_in) {
     case 0:
      c1_b_st.site = &c1_gb_emlrtRSI;
      c1_rng(chartInstance, &c1_b_st);
      c1_b_state_out = 1.0;
      c1_b_npxlsAcq_out = 2.5;
      c1_b_localTime_out = 1.0;
      c1_b_trialNum_out = 0.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_out = 0.0;
      c1_b_numLicks_out = 0.0;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_in));
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 1:
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_state_out = 2.0;
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = 1.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_out = 0.0;
      c1_b_numLicks_out = 0.0;
      c1_b_st.site = &c1_hb_emlrtRSI;
      c1_b_delay_out = c1_b_sessionTime + c1_negative_exp_rand(chartInstance,
        &c1_b_st, 5.0, 9.0);
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_e_emlrt_marshallOut
                  (chartInstance, c1_cv24));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_out));
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      break;

     case 2:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
      } else {
        c1_b_state_out = 3.0;
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 3:
      c1_b_st.site = &c1_ib_emlrtRSI;
      if (c1_rand(chartInstance, &c1_b_st) <= 0.6) {
        c1_b_st.site = &c1_jb_emlrtRSI;
        if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
          c1_i_y = NULL;
          sf_mex_assign(&c1_i_y, sf_mex_create("y", c1_cv10, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          c1_eb_y = NULL;
          sf_mex_assign(&c1_eb_y, sf_mex_create("y", c1_cv10, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_i_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_eb_y)));
        }

        if (*chartInstance->c1_target_side != 0.0) {
          c1_b_right_trigger_out = 1.0;
          c1_b_left_trigger_out = 0.0;
        } else {
          c1_b_left_trigger_out = 1.0;
          c1_b_right_trigger_out = 0.0;
        }

        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_e_emlrt_marshallOut
                    (chartInstance, c1_cv26));
        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                    (chartInstance, c1_b_sessionTime));
        c1_b_left_trigger_in = 0.0;
      } else {
        c1_b_st.site = &c1_kb_emlrtRSI;
        if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
          c1_h_y = NULL;
          sf_mex_assign(&c1_h_y, sf_mex_create("y", c1_cv9, 10, 0U, 1U, 0U, 2, 1,
            19), false);
          c1_db_y = NULL;
          sf_mex_assign(&c1_db_y, sf_mex_create("y", c1_cv9, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_h_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_db_y)));
        }

        if (*chartInstance->c1_target_side != 0.0) {
          c1_b_left_trigger_out = 1.0;
          c1_b_right_trigger_out = 0.0;
        } else {
          c1_b_right_trigger_out = 1.0;
          c1_b_left_trigger_out = 0.0;
        }

        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_f_emlrt_marshallOut
                    (chartInstance, c1_cv25));
        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                    (chartInstance, c1_b_sessionTime));
        c1_b_left_trigger_in = 1.0;
      }

      c1_b_state_out = 4.0;
      c1_b_delay_out = *chartInstance->c1_sessionTime + 0.2;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_b_emlrt_marshallOut
                  (chartInstance, c1_cv37));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_out));
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_reward_trigger_out = 0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 4:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
        c1_b_delay_out = *chartInstance->c1_delay_in;
      } else {
        c1_b_st.site = &c1_lb_emlrtRSI;
        if (muDoubleScalarIsNaN(*chartInstance->c1_was_target_in)) {
          c1_g_y = NULL;
          sf_mex_assign(&c1_g_y, sf_mex_create("y", c1_cv8, 10, 0U, 1U, 0U, 2, 1,
            19), false);
          c1_v_y = NULL;
          sf_mex_assign(&c1_v_y, sf_mex_create("y", c1_cv8, 10, 0U, 1U, 0U, 2, 1,
            19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_g_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_v_y)));
        }

        if (*chartInstance->c1_was_target_in != 0.0) {
          c1_b_state_out = 5.0;
          c1_b_delay_out = *chartInstance->c1_sessionTime + 1.0;
        } else {
          c1_b_state_out = 6.0;
          c1_b_delay_out = *chartInstance->c1_sessionTime + 1.0;
        }
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_left_trigger_out = 0.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 5:
      c1_b_reward_trigger_out = 1;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_b_emlrt_marshallOut
                  (chartInstance, c1_cv));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_sessionTime));
      c1_b_state_out = 6.0;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 6:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
      } else {
        c1_b_state_out = 1.0;
        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_h_emlrt_marshallOut
                    (chartInstance, c1_cv1));
        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                    (chartInstance, c1_b_sessionTime));
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     default:
      c1_b_state_out = *chartInstance->c1_state_in;
      c1_b_localTime_out = *chartInstance->c1_localTime_in;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;
    }
    break;

   case 2:
    if (*chartInstance->c1_state_in != (real_T)(int32_T)muDoubleScalarFloor
        (*chartInstance->c1_state_in)) {
      emlrtIntegerCheckR2012b(*chartInstance->c1_state_in, &c1_c_emlrtDCI,
        &c1_st);
    }

    switch ((int32_T)*chartInstance->c1_state_in) {
     case 0:
      c1_b_st.site = &c1_mb_emlrtRSI;
      c1_rng(chartInstance, &c1_b_st);
      c1_b_state_out = 1.0;
      c1_b_npxlsAcq_out = 2.5;
      c1_b_localTime_out = 1.0;
      c1_b_trialNum_out = 0.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_out = 0.0;
      c1_b_numLicks_out = 0.0;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_in));
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 1:
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_state_out = 2.0;
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = 1.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_out = 0.0;
      c1_b_numLicks_out = 0.0;
      c1_b_st.site = &c1_nb_emlrtRSI;
      c1_b_delay_out = c1_b_sessionTime + c1_negative_exp_rand(chartInstance,
        &c1_b_st, 8.0, 12.0);
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_e_emlrt_marshallOut
                  (chartInstance, c1_cv24));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_out));
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      break;

     case 2:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
      } else {
        c1_b_state_out = 3.0;
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 3:
      c1_b_st.site = &c1_ob_emlrtRSI;
      if (c1_rand(chartInstance, &c1_b_st) <= 0.6) {
        c1_b_st.site = &c1_pb_emlrtRSI;
        if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
          c1_k_y = NULL;
          sf_mex_assign(&c1_k_y, sf_mex_create("y", c1_cv12, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          c1_gb_y = NULL;
          sf_mex_assign(&c1_gb_y, sf_mex_create("y", c1_cv12, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_k_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_gb_y)));
        }

        if (*chartInstance->c1_target_side != 0.0) {
          c1_b_right_trigger_out = 1.0;
          c1_b_left_trigger_out = 0.0;
        } else {
          c1_b_left_trigger_out = 1.0;
          c1_b_right_trigger_out = 0.0;
        }

        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_e_emlrt_marshallOut
                    (chartInstance, c1_cv26));
        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                    (chartInstance, c1_b_sessionTime));
        c1_b_left_trigger_in = 0.0;
      } else {
        c1_b_st.site = &c1_qb_emlrtRSI;
        if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
          c1_j_y = NULL;
          sf_mex_assign(&c1_j_y, sf_mex_create("y", c1_cv11, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          c1_fb_y = NULL;
          sf_mex_assign(&c1_fb_y, sf_mex_create("y", c1_cv11, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_j_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_fb_y)));
        }

        if (*chartInstance->c1_target_side != 0.0) {
          c1_b_left_trigger_out = 1.0;
          c1_b_right_trigger_out = 0.0;
        } else {
          c1_b_right_trigger_out = 1.0;
          c1_b_left_trigger_out = 0.0;
        }

        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_f_emlrt_marshallOut
                    (chartInstance, c1_cv25));
        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                    (chartInstance, c1_b_sessionTime));
        c1_b_left_trigger_in = 1.0;
      }

      c1_b_state_out = 4.0;
      c1_b_delay_out = *chartInstance->c1_sessionTime + 0.2;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_b_emlrt_marshallOut
                  (chartInstance, c1_cv37));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_out));
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_reward_trigger_out = 0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 4:
      c1_b_st.site = &c1_rb_emlrtRSI;
      if (muDoubleScalarIsNaN(*chartInstance->c1_lick)) {
        c1_y = NULL;
        sf_mex_assign(&c1_y, sf_mex_create("y", c1_cv2, 10, 0U, 1U, 0U, 2, 1, 19),
                      false);
        c1_l_y = NULL;
        sf_mex_assign(&c1_l_y, sf_mex_create("y", c1_cv2, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_l_y)));
      }

      if (*chartInstance->c1_lick != 0.0) {
        c1_b_numLicks_out = *chartInstance->c1_numLicks_in + 1.0;
      } else {
        c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      }

      c1_b_st.site = &c1_sb_emlrtRSI;
      if (muDoubleScalarIsNaN(c1_b_numLicks_out)) {
        c1_rb_y = NULL;
        sf_mex_assign(&c1_rb_y, sf_mex_create("y", c1_cv27, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        c1_ac_y = NULL;
        sf_mex_assign(&c1_ac_y, sf_mex_create("y", c1_cv27, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_rb_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_ac_y)));
      }

      if (c1_b_numLicks_out != 0.0) {
        c1_b_state_out = 7.0;
        c1_b_delay_out = *chartInstance->c1_sessionTime + 2.0;
      } else if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
        c1_b_delay_out = *chartInstance->c1_delay_in;
      } else {
        c1_b_state_out = 5.0;
        c1_b_delay_out = *chartInstance->c1_sessionTime + 1.5;
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_out = 0.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 5:
      c1_b_st.site = &c1_tb_emlrtRSI;
      if (muDoubleScalarIsNaN(*chartInstance->c1_lick)) {
        c1_b_y = NULL;
        sf_mex_assign(&c1_b_y, sf_mex_create("y", c1_cv3, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        c1_m_y = NULL;
        sf_mex_assign(&c1_m_y, sf_mex_create("y", c1_cv3, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_b_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_m_y)));
      }

      if (*chartInstance->c1_lick != 0.0) {
        c1_b_numLicks_out = *chartInstance->c1_numLicks_in + 1.0;
      } else {
        c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      }

      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
        c1_b_delay_out = *chartInstance->c1_delay_in;
      } else {
        c1_b_st.site = &c1_ub_emlrtRSI;
        if (muDoubleScalarIsNaN(c1_b_numLicks_out)) {
          c1_wb_y = NULL;
          sf_mex_assign(&c1_wb_y, sf_mex_create("y", c1_cv32, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          c1_fc_y = NULL;
          sf_mex_assign(&c1_fc_y, sf_mex_create("y", c1_cv32, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_wb_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_fc_y)));
        }

        c1_guard1 = false;
        if (c1_b_numLicks_out != 0.0) {
          c1_b_st.site = &c1_ub_emlrtRSI;
          if (muDoubleScalarIsNaN(*chartInstance->c1_was_target_in)) {
            c1_kc_y = NULL;
            sf_mex_assign(&c1_kc_y, sf_mex_create("y", c1_cv38, 10, 0U, 1U, 0U,
              2, 1, 19), false);
            c1_pc_y = NULL;
            sf_mex_assign(&c1_pc_y, sf_mex_create("y", c1_cv38, 10, 0U, 1U, 0U,
              2, 1, 19), false);
            sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_kc_y,
                        14, sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
              sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_pc_y)));
          }

          if (*chartInstance->c1_was_target_in != 0.0) {
            c1_b_state_out = 6.0;
            c1_b_delay_out = *chartInstance->c1_delay_in;
          } else {
            c1_guard1 = true;
          }
        } else {
          c1_guard1 = true;
        }

        if (c1_guard1) {
          c1_b_state_out = 7.0;
          c1_b_delay_out = *chartInstance->c1_sessionTime + 0.5;
          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_d_emlrt_marshallOut
                      (chartInstance, c1_cv42));
          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                      (chartInstance, c1_b_left_trigger_in));
        }
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 6:
      c1_b_reward_trigger_out = 1;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_b_emlrt_marshallOut
                  (chartInstance, c1_cv));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_sessionTime));
      c1_b_state_out = 7.0;
      c1_b_delay_out = *chartInstance->c1_sessionTime + 0.5;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_c_emlrt_marshallOut
                  (chartInstance, c1_cv13));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_out));
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 7:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
      } else {
        c1_b_state_out = 1.0;
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     default:
      c1_b_state_out = *chartInstance->c1_state_in;
      c1_b_localTime_out = *chartInstance->c1_localTime_in;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;
    }
    break;

   case 3:
    if (*chartInstance->c1_state_in != (real_T)(int32_T)muDoubleScalarFloor
        (*chartInstance->c1_state_in)) {
      emlrtIntegerCheckR2012b(*chartInstance->c1_state_in, &c1_d_emlrtDCI,
        &c1_st);
    }

    switch ((int32_T)*chartInstance->c1_state_in) {
     case 0:
      c1_b_st.site = &c1_vb_emlrtRSI;
      c1_rng(chartInstance, &c1_b_st);
      c1_b_state_out = 1.0;
      c1_b_npxlsAcq_out = 2.5;
      c1_b_localTime_out = 1.0;
      c1_b_trialNum_out = 0.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_out = 0.0;
      c1_b_numLicks_out = 0.0;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_in));
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 1:
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_state_out = 2.0;
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = 1.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_out = 0.0;
      c1_b_st.site = &c1_wb_emlrtRSI;
      if (muDoubleScalarIsNaN(*chartInstance->c1_was_target_in)) {
        c1_sb_y = NULL;
        sf_mex_assign(&c1_sb_y, sf_mex_create("y", c1_cv28, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        c1_bc_y = NULL;
        sf_mex_assign(&c1_bc_y, sf_mex_create("y", c1_cv28, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_sb_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_bc_y)));
      }

      c1_guard1 = false;
      if (!(*chartInstance->c1_was_target_in != 0.0)) {
        c1_b_st.site = &c1_wb_emlrtRSI;
        if (muDoubleScalarIsNaN(*chartInstance->c1_numLicks_in)) {
          c1_ic_y = NULL;
          sf_mex_assign(&c1_ic_y, sf_mex_create("y", c1_cv35, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          c1_nc_y = NULL;
          sf_mex_assign(&c1_nc_y, sf_mex_create("y", c1_cv35, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_ic_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_nc_y)));
        }

        if (!(*chartInstance->c1_numLicks_in != 0.0)) {
          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_g_emlrt_marshallOut
                      (chartInstance, c1_cv39));
          c1_b_st.site = &c1_xb_emlrtRSI;
          c1_b_delay_out = c1_b_sessionTime + c1_negative_exp_rand(chartInstance,
            &c1_b_st, 4.0, 6.0);
        } else {
          c1_guard1 = true;
        }
      } else {
        c1_guard1 = true;
      }

      if (c1_guard1) {
        c1_b_st.site = &c1_yb_emlrtRSI;
        c1_b_delay_out = c1_b_sessionTime + c1_negative_exp_rand(chartInstance,
          &c1_b_st, 8.0, 12.0);
      }

      c1_b_numLicks_out = 0.0;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_e_emlrt_marshallOut
                  (chartInstance, c1_cv24));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_out));
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      break;

     case 2:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
      } else {
        c1_b_state_out = 3.0;
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 3:
      c1_b_st.site = &c1_ac_emlrtRSI;
      if (c1_rand(chartInstance, &c1_b_st) <= 0.7) {
        c1_b_st.site = &c1_bc_emlrtRSI;
        if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
          c1_o_y = NULL;
          sf_mex_assign(&c1_o_y, sf_mex_create("y", c1_cv15, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          c1_ib_y = NULL;
          sf_mex_assign(&c1_ib_y, sf_mex_create("y", c1_cv15, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_o_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_ib_y)));
        }

        if (*chartInstance->c1_target_side != 0.0) {
          c1_b_right_trigger_out = 1.0;
          c1_b_left_trigger_out = 0.0;
        } else {
          c1_b_left_trigger_out = 1.0;
          c1_b_right_trigger_out = 0.0;
        }

        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_e_emlrt_marshallOut
                    (chartInstance, c1_cv26));
        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                    (chartInstance, c1_b_sessionTime));
        c1_b_left_trigger_in = 0.0;
      } else {
        c1_b_st.site = &c1_cc_emlrtRSI;
        if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
          c1_n_y = NULL;
          sf_mex_assign(&c1_n_y, sf_mex_create("y", c1_cv14, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          c1_hb_y = NULL;
          sf_mex_assign(&c1_hb_y, sf_mex_create("y", c1_cv14, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_n_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_hb_y)));
        }

        if (*chartInstance->c1_target_side != 0.0) {
          c1_b_left_trigger_out = 1.0;
          c1_b_right_trigger_out = 0.0;
        } else {
          c1_b_right_trigger_out = 1.0;
          c1_b_left_trigger_out = 0.0;
        }

        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_f_emlrt_marshallOut
                    (chartInstance, c1_cv25));
        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                    (chartInstance, c1_b_sessionTime));
        c1_b_left_trigger_in = 1.0;
      }

      c1_b_state_out = 4.0;
      c1_b_delay_out = *chartInstance->c1_sessionTime + 0.2;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_b_emlrt_marshallOut
                  (chartInstance, c1_cv37));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_out));
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_reward_trigger_out = 0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 4:
      c1_b_st.site = &c1_dc_emlrtRSI;
      if (muDoubleScalarIsNaN(*chartInstance->c1_lick)) {
        c1_c_y = NULL;
        sf_mex_assign(&c1_c_y, sf_mex_create("y", c1_cv4, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        c1_p_y = NULL;
        sf_mex_assign(&c1_p_y, sf_mex_create("y", c1_cv4, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_c_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_p_y)));
      }

      if (*chartInstance->c1_lick != 0.0) {
        c1_b_numLicks_out = *chartInstance->c1_numLicks_in + 1.0;
      } else {
        c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      }

      c1_b_st.site = &c1_ec_emlrtRSI;
      if (muDoubleScalarIsNaN(c1_b_numLicks_out)) {
        c1_tb_y = NULL;
        sf_mex_assign(&c1_tb_y, sf_mex_create("y", c1_cv29, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        c1_cc_y = NULL;
        sf_mex_assign(&c1_cc_y, sf_mex_create("y", c1_cv29, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_tb_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_cc_y)));
      }

      if (c1_b_numLicks_out != 0.0) {
        c1_b_state_out = 7.0;
        c1_b_delay_out = *chartInstance->c1_sessionTime + 1.5;
      } else if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
        c1_b_delay_out = *chartInstance->c1_delay_in;
      } else {
        c1_b_state_out = 5.0;
        c1_b_delay_out = *chartInstance->c1_sessionTime + 1.0;
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_out = 0.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 5:
      c1_b_st.site = &c1_fc_emlrtRSI;
      if (muDoubleScalarIsNaN(*chartInstance->c1_lick)) {
        c1_d_y = NULL;
        sf_mex_assign(&c1_d_y, sf_mex_create("y", c1_cv5, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        c1_q_y = NULL;
        sf_mex_assign(&c1_q_y, sf_mex_create("y", c1_cv5, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_d_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_q_y)));
      }

      if (*chartInstance->c1_lick != 0.0) {
        c1_b_numLicks_out = *chartInstance->c1_numLicks_in + 1.0;
      } else {
        c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      }

      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
        c1_b_delay_out = *chartInstance->c1_delay_in;
      } else {
        c1_b_st.site = &c1_gc_emlrtRSI;
        if (muDoubleScalarIsNaN(c1_b_numLicks_out)) {
          c1_xb_y = NULL;
          sf_mex_assign(&c1_xb_y, sf_mex_create("y", c1_cv33, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          c1_gc_y = NULL;
          sf_mex_assign(&c1_gc_y, sf_mex_create("y", c1_cv33, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_xb_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_gc_y)));
        }

        c1_guard1 = false;
        if (c1_b_numLicks_out != 0.0) {
          c1_b_st.site = &c1_gc_emlrtRSI;
          if (muDoubleScalarIsNaN(*chartInstance->c1_was_target_in)) {
            c1_lc_y = NULL;
            sf_mex_assign(&c1_lc_y, sf_mex_create("y", c1_cv40, 10, 0U, 1U, 0U,
              2, 1, 19), false);
            c1_qc_y = NULL;
            sf_mex_assign(&c1_qc_y, sf_mex_create("y", c1_cv40, 10, 0U, 1U, 0U,
              2, 1, 19), false);
            sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_lc_y,
                        14, sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
              sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_qc_y)));
          }

          if (*chartInstance->c1_was_target_in != 0.0) {
            c1_b_state_out = 6.0;
            c1_b_delay_out = *chartInstance->c1_delay_in;
          } else {
            c1_guard1 = true;
          }
        } else {
          c1_guard1 = true;
        }

        if (c1_guard1) {
          c1_b_state_out = 7.0;
          c1_b_delay_out = *chartInstance->c1_sessionTime + 0.5;
          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_d_emlrt_marshallOut
                      (chartInstance, c1_cv42));
          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                      (chartInstance, c1_b_left_trigger_in));
        }
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 6:
      c1_b_reward_trigger_out = 1;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_b_emlrt_marshallOut
                  (chartInstance, c1_cv));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_sessionTime));
      c1_b_state_out = 7.0;
      c1_b_delay_out = *chartInstance->c1_sessionTime + 0.5;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_c_emlrt_marshallOut
                  (chartInstance, c1_cv13));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_out));
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 7:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
      } else {
        c1_b_state_out = 1.0;
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     default:
      c1_b_state_out = *chartInstance->c1_state_in;
      c1_b_localTime_out = *chartInstance->c1_localTime_in;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;
    }
    break;

   case 4:
    if (*chartInstance->c1_state_in != (real_T)(int32_T)muDoubleScalarFloor
        (*chartInstance->c1_state_in)) {
      emlrtIntegerCheckR2012b(*chartInstance->c1_state_in, &c1_e_emlrtDCI,
        &c1_st);
    }

    switch ((int32_T)*chartInstance->c1_state_in) {
     case 0:
      c1_b_st.site = &c1_hc_emlrtRSI;
      c1_rng(chartInstance, &c1_b_st);
      c1_b_state_out = 1.0;
      c1_b_npxlsAcq_out = 2.5;
      c1_b_localTime_out = 1.0;
      c1_b_trialNum_out = 0.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_out = 0.0;
      c1_b_numLicks_out = 0.0;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_in));
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 1:
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_state_out = 2.0;
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = 1.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_out = 0.0;
      c1_b_st.site = &c1_ic_emlrtRSI;
      if (muDoubleScalarIsNaN(*chartInstance->c1_was_target_in)) {
        c1_ub_y = NULL;
        sf_mex_assign(&c1_ub_y, sf_mex_create("y", c1_cv30, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        c1_dc_y = NULL;
        sf_mex_assign(&c1_dc_y, sf_mex_create("y", c1_cv30, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_ub_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_dc_y)));
      }

      c1_guard1 = false;
      if (!(*chartInstance->c1_was_target_in != 0.0)) {
        c1_b_st.site = &c1_ic_emlrtRSI;
        if (muDoubleScalarIsNaN(*chartInstance->c1_numLicks_in)) {
          c1_jc_y = NULL;
          sf_mex_assign(&c1_jc_y, sf_mex_create("y", c1_cv36, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          c1_oc_y = NULL;
          sf_mex_assign(&c1_oc_y, sf_mex_create("y", c1_cv36, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_jc_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_oc_y)));
        }

        if (!(*chartInstance->c1_numLicks_in != 0.0)) {
          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_g_emlrt_marshallOut
                      (chartInstance, c1_cv39));
          c1_b_st.site = &c1_jc_emlrtRSI;
          c1_b_delay_out = c1_b_sessionTime + c1_negative_exp_rand(chartInstance,
            &c1_b_st, 4.0, 6.0);
        } else {
          c1_guard1 = true;
        }
      } else {
        c1_guard1 = true;
      }

      if (c1_guard1) {
        c1_b_st.site = &c1_kc_emlrtRSI;
        c1_b_delay_out = c1_b_sessionTime + c1_negative_exp_rand(chartInstance,
          &c1_b_st, 8.0, 12.0);
      }

      c1_b_numLicks_out = 0.0;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_e_emlrt_marshallOut
                  (chartInstance, c1_cv24));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_out));
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      break;

     case 2:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
      } else {
        c1_b_state_out = 3.0;
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 3:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_switch_time * 60.0)
      {
        c1_b_st.site = &c1_lc_emlrtRSI;
        if (c1_rand(chartInstance, &c1_b_st) <= 0.6) {
          c1_b_st.site = &c1_mc_emlrtRSI;
          if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
            c1_ab_y = NULL;
            sf_mex_assign(&c1_ab_y, sf_mex_create("y", c1_cv21, 10, 0U, 1U, 0U,
              2, 1, 19), false);
            c1_ob_y = NULL;
            sf_mex_assign(&c1_ob_y, sf_mex_create("y", c1_cv21, 10, 0U, 1U, 0U,
              2, 1, 19), false);
            sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_ab_y,
                        14, sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
              sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_ob_y)));
          }

          if (*chartInstance->c1_target_side != 0.0) {
            c1_b_right_trigger_out = 1.0;
            c1_b_left_trigger_out = 0.0;
          } else {
            c1_b_left_trigger_out = 1.0;
            c1_b_right_trigger_out = 0.0;
          }

          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_e_emlrt_marshallOut
                      (chartInstance, c1_cv26));
          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                      (chartInstance, c1_b_sessionTime));
          c1_b_left_trigger_in = 0.0;
        } else {
          c1_b_st.site = &c1_nc_emlrtRSI;
          if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
            c1_y_y = NULL;
            sf_mex_assign(&c1_y_y, sf_mex_create("y", c1_cv20, 10, 0U, 1U, 0U, 2,
              1, 19), false);
            c1_nb_y = NULL;
            sf_mex_assign(&c1_nb_y, sf_mex_create("y", c1_cv20, 10, 0U, 1U, 0U,
              2, 1, 19), false);
            sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_y_y,
                        14, sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
              sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_nb_y)));
          }

          if (*chartInstance->c1_target_side != 0.0) {
            c1_b_left_trigger_out = 1.0;
            c1_b_right_trigger_out = 0.0;
          } else {
            c1_b_right_trigger_out = 1.0;
            c1_b_left_trigger_out = 0.0;
          }

          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_f_emlrt_marshallOut
                      (chartInstance, c1_cv25));
          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                      (chartInstance, c1_b_sessionTime));
          c1_b_left_trigger_in = 1.0;
        }
      } else {
        c1_b_st.site = &c1_oc_emlrtRSI;
        if (c1_rand(chartInstance, &c1_b_st) <= 0.6) {
          c1_b_st.site = &c1_pc_emlrtRSI;
          if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
            c1_x_y = NULL;
            sf_mex_assign(&c1_x_y, sf_mex_create("y", c1_cv19, 10, 0U, 1U, 0U, 2,
              1, 19), false);
            c1_mb_y = NULL;
            sf_mex_assign(&c1_mb_y, sf_mex_create("y", c1_cv19, 10, 0U, 1U, 0U,
              2, 1, 19), false);
            sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_x_y,
                        14, sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
              sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_mb_y)));
          }

          if (*chartInstance->c1_target_side != 0.0) {
            c1_b_left_trigger_out = 1.0;
            c1_b_right_trigger_out = 0.0;
          } else {
            c1_b_right_trigger_out = 1.0;
            c1_b_left_trigger_out = 0.0;
          }

          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_e_emlrt_marshallOut
                      (chartInstance, c1_cv26));
          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                      (chartInstance, c1_b_sessionTime));
          c1_b_left_trigger_in = 0.0;
        } else {
          c1_b_st.site = &c1_qc_emlrtRSI;
          if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
            c1_w_y = NULL;
            sf_mex_assign(&c1_w_y, sf_mex_create("y", c1_cv18, 10, 0U, 1U, 0U, 2,
              1, 19), false);
            c1_lb_y = NULL;
            sf_mex_assign(&c1_lb_y, sf_mex_create("y", c1_cv18, 10, 0U, 1U, 0U,
              2, 1, 19), false);
            sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_w_y,
                        14, sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
              sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_lb_y)));
          }

          if (*chartInstance->c1_target_side != 0.0) {
            c1_b_right_trigger_out = 1.0;
            c1_b_left_trigger_out = 0.0;
          } else {
            c1_b_left_trigger_out = 1.0;
            c1_b_right_trigger_out = 0.0;
          }

          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_f_emlrt_marshallOut
                      (chartInstance, c1_cv25));
          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                      (chartInstance, c1_b_sessionTime));
          c1_b_left_trigger_in = 1.0;
        }
      }

      c1_b_state_out = 4.0;
      c1_b_delay_out = *chartInstance->c1_sessionTime + 0.2;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_b_emlrt_marshallOut
                  (chartInstance, c1_cv37));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_out));
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_reward_trigger_out = 0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 4:
      c1_b_st.site = &c1_rc_emlrtRSI;
      if (muDoubleScalarIsNaN(*chartInstance->c1_lick)) {
        c1_e_y = NULL;
        sf_mex_assign(&c1_e_y, sf_mex_create("y", c1_cv6, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        c1_r_y = NULL;
        sf_mex_assign(&c1_r_y, sf_mex_create("y", c1_cv6, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_e_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_r_y)));
      }

      if (*chartInstance->c1_lick != 0.0) {
        c1_b_numLicks_out = *chartInstance->c1_numLicks_in + 1.0;
      } else {
        c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      }

      c1_b_st.site = &c1_sc_emlrtRSI;
      if (muDoubleScalarIsNaN(c1_b_numLicks_out)) {
        c1_vb_y = NULL;
        sf_mex_assign(&c1_vb_y, sf_mex_create("y", c1_cv31, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        c1_ec_y = NULL;
        sf_mex_assign(&c1_ec_y, sf_mex_create("y", c1_cv31, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_vb_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_ec_y)));
      }

      if (c1_b_numLicks_out != 0.0) {
        c1_b_state_out = 7.0;
        c1_b_delay_out = *chartInstance->c1_sessionTime + 1.5;
      } else if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
        c1_b_delay_out = *chartInstance->c1_delay_in;
      } else {
        c1_b_state_out = 5.0;
        c1_b_delay_out = *chartInstance->c1_sessionTime + 1.0;
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_out = 0.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 5:
      c1_b_st.site = &c1_tc_emlrtRSI;
      if (muDoubleScalarIsNaN(*chartInstance->c1_lick)) {
        c1_f_y = NULL;
        sf_mex_assign(&c1_f_y, sf_mex_create("y", c1_cv7, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        c1_s_y = NULL;
        sf_mex_assign(&c1_s_y, sf_mex_create("y", c1_cv7, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_f_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_s_y)));
      }

      if (*chartInstance->c1_lick != 0.0) {
        c1_b_numLicks_out = *chartInstance->c1_numLicks_in + 1.0;
      } else {
        c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      }

      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
        c1_b_delay_out = *chartInstance->c1_delay_in;
      } else {
        c1_b_st.site = &c1_uc_emlrtRSI;
        if (muDoubleScalarIsNaN(c1_b_numLicks_out)) {
          c1_yb_y = NULL;
          sf_mex_assign(&c1_yb_y, sf_mex_create("y", c1_cv34, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          c1_hc_y = NULL;
          sf_mex_assign(&c1_hc_y, sf_mex_create("y", c1_cv34, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_yb_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_hc_y)));
        }

        c1_guard1 = false;
        if (c1_b_numLicks_out != 0.0) {
          c1_b_st.site = &c1_uc_emlrtRSI;
          if (muDoubleScalarIsNaN(*chartInstance->c1_was_target_in)) {
            c1_mc_y = NULL;
            sf_mex_assign(&c1_mc_y, sf_mex_create("y", c1_cv41, 10, 0U, 1U, 0U,
              2, 1, 19), false);
            c1_rc_y = NULL;
            sf_mex_assign(&c1_rc_y, sf_mex_create("y", c1_cv41, 10, 0U, 1U, 0U,
              2, 1, 19), false);
            sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_mc_y,
                        14, sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
              sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_rc_y)));
          }

          if (*chartInstance->c1_was_target_in != 0.0) {
            c1_b_state_out = 6.0;
            c1_b_delay_out = *chartInstance->c1_delay_in;
          } else {
            c1_guard1 = true;
          }
        } else {
          c1_guard1 = true;
        }

        if (c1_guard1) {
          c1_b_state_out = 7.0;
          c1_b_delay_out = *chartInstance->c1_sessionTime + 0.5;
          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_d_emlrt_marshallOut
                      (chartInstance, c1_cv42));
          sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                      (chartInstance, c1_b_left_trigger_in));
        }
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 6:
      c1_b_reward_trigger_out = 1;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_b_emlrt_marshallOut
                  (chartInstance, c1_cv));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_sessionTime));
      c1_b_state_out = 7.0;
      c1_b_delay_out = *chartInstance->c1_sessionTime + 0.5;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_c_emlrt_marshallOut
                  (chartInstance, c1_cv13));
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_out));
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 7:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
      } else {
        c1_b_state_out = 1.0;
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     default:
      c1_b_state_out = *chartInstance->c1_state_in;
      c1_b_localTime_out = *chartInstance->c1_localTime_in;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;
    }
    break;

   case 111:
    if (*chartInstance->c1_state_in != (real_T)(int32_T)muDoubleScalarFloor
        (*chartInstance->c1_state_in)) {
      emlrtIntegerCheckR2012b(*chartInstance->c1_state_in, &c1_f_emlrtDCI,
        &c1_st);
    }

    switch ((int32_T)*chartInstance->c1_state_in) {
     case 0:
      c1_b_st.site = &c1_vc_emlrtRSI;
      c1_rng(chartInstance, &c1_b_st);
      c1_b_state_out = 1.0;
      c1_b_npxlsAcq_out = 0.0;
      c1_b_localTime_out = 1.0;
      c1_b_trialNum_out = 1.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_out = 0.0;
      c1_b_numLicks_out = 0.0;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_in));
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 1:
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = 1.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_out = 0.0;
      c1_b_delay_out = *chartInstance->c1_sessionTime + 1.0;
      c1_b_numLicks_out = 0.0;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_sessionTime));
      c1_b_reward_trigger_out = 1;
      c1_b_left_trigger_in = 0.0;
      c1_b_reward_duration_in = 0.03;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, 0.03));
      c1_b_state_out = 2.0;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     default:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
        c1_b_reward_trigger_out = 0;
        c1_b_delay_out = *chartInstance->c1_delay_in;
        c1_b_reward_duration_in = 0.03;
      } else {
        c1_b_state_out = *chartInstance->c1_state_in + 1.0;
        c1_b_reward_trigger_out = 1;
        c1_b_delay_out = *chartInstance->c1_sessionTime + 1.0;
        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                    (chartInstance, c1_b_sessionTime));
        c1_b_reward_duration_in = 0.03;
        sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                    (chartInstance, 0.03));
      }

      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_left_trigger_out = *chartInstance->c1_left_trigger_in;
      c1_b_right_trigger_out = *chartInstance->c1_right_trigger_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;
    }
    break;

   case 222:
    if (*chartInstance->c1_state_in != (real_T)(int32_T)muDoubleScalarFloor
        (*chartInstance->c1_state_in)) {
      emlrtIntegerCheckR2012b(*chartInstance->c1_state_in, &c1_g_emlrtDCI,
        &c1_st);
    }

    switch ((int32_T)*chartInstance->c1_state_in) {
     case 0:
      c1_b_st.site = &c1_wc_emlrtRSI;
      c1_rng(chartInstance, &c1_b_st);
      c1_b_state_out = 1.0;
      c1_b_npxlsAcq_out = 0.0;
      c1_b_localTime_out = 1.0;
      c1_b_trialNum_out = 1.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_out = 0.0;
      c1_b_numLicks_out = 0.0;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_in));
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 1:
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = 1.0;
      c1_b_st.site = &c1_xc_emlrtRSI;
      if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
        c1_cb_y = NULL;
        sf_mex_assign(&c1_cb_y, sf_mex_create("y", c1_cv23, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        c1_qb_y = NULL;
        sf_mex_assign(&c1_qb_y, sf_mex_create("y", c1_cv23, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_cb_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_qb_y)));
      }

      if (*chartInstance->c1_target_side != 0.0) {
        c1_b_left_trigger_out = 1.0;
        c1_b_right_trigger_out = 0.0;
      } else {
        c1_b_right_trigger_out = 1.0;
        c1_b_left_trigger_out = 0.0;
      }

      c1_b_delay_out = *chartInstance->c1_sessionTime + 1.0;
      c1_b_numLicks_out = 0.0;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_state_out = 2.0;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     default:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
        c1_b_delay_out = *chartInstance->c1_delay_in;
        c1_b_left_trigger_out = 0.0;
        c1_b_right_trigger_out = 0.0;
      } else {
        c1_b_state_out = *chartInstance->c1_state_in + 1.0;
        c1_b_delay_out = *chartInstance->c1_sessionTime + 1.0;
        c1_b_st.site = &c1_yc_emlrtRSI;
        if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
          c1_bb_y = NULL;
          sf_mex_assign(&c1_bb_y, sf_mex_create("y", c1_cv22, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          c1_pb_y = NULL;
          sf_mex_assign(&c1_pb_y, sf_mex_create("y", c1_cv22, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_bb_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_pb_y)));
        }

        if (*chartInstance->c1_target_side != 0.0) {
          c1_b_left_trigger_out = 1.0;
          c1_b_right_trigger_out = 0.0;
        } else {
          c1_b_right_trigger_out = 1.0;
          c1_b_left_trigger_out = 0.0;
        }
      }

      c1_b_reward_trigger_out = 0;
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;
    }
    break;

   default:
    if (*chartInstance->c1_state_in != (real_T)(int32_T)muDoubleScalarFloor
        (*chartInstance->c1_state_in)) {
      emlrtIntegerCheckR2012b(*chartInstance->c1_state_in, &c1_h_emlrtDCI,
        &c1_st);
    }

    switch ((int32_T)*chartInstance->c1_state_in) {
     case 0:
      c1_b_st.site = &c1_ad_emlrtRSI;
      c1_rng(chartInstance, &c1_b_st);
      c1_b_state_out = 1.0;
      c1_b_npxlsAcq_out = 0.0;
      c1_b_localTime_out = 1.0;
      c1_b_trialNum_out = 1.0;
      c1_b_right_trigger_out = 0.0;
      c1_b_left_trigger_out = 0.0;
      c1_b_numLicks_out = 0.0;
      c1_b_delay_out = *chartInstance->c1_delay_in;
      sf_mex_call(&c1_st, NULL, "disp", 0U, 1U, 14, c1_emlrt_marshallOut
                  (chartInstance, c1_b_delay_in));
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      c1_b_stim_duration_in = *chartInstance->c1_stim_duration_in;
      break;

     case 1:
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = 1.0;
      c1_b_st.site = &c1_bd_emlrtRSI;
      if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
        c1_u_y = NULL;
        sf_mex_assign(&c1_u_y, sf_mex_create("y", c1_cv17, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        c1_kb_y = NULL;
        sf_mex_assign(&c1_kb_y, sf_mex_create("y", c1_cv17, 10, 0U, 1U, 0U, 2, 1,
          19), false);
        sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_u_y, 14,
                    sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
          sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_kb_y)));
      }

      if (*chartInstance->c1_target_side != 0.0) {
        c1_b_right_trigger_out = 1.0;
        c1_b_left_trigger_out = 0.0;
      } else {
        c1_b_left_trigger_out = 1.0;
        c1_b_right_trigger_out = 0.0;
      }

      c1_b_delay_out = *chartInstance->c1_sessionTime + 10.0;
      c1_b_numLicks_out = 0.0;
      c1_b_reward_trigger_out = 0;
      c1_b_left_trigger_in = 0.0;
      c1_b_stim_duration_in = 0.05;
      c1_b_state_out = 2.0;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      break;

     default:
      if (*chartInstance->c1_sessionTime < *chartInstance->c1_delay_in) {
        c1_b_state_out = *chartInstance->c1_state_in;
        c1_b_delay_out = *chartInstance->c1_delay_in;
        c1_b_left_trigger_out = 0.0;
        c1_b_right_trigger_out = 0.0;
        c1_b_stim_duration_in = 0.05 * (*chartInstance->c1_state_in - 1.0);
      } else {
        c1_b_state_out = *chartInstance->c1_state_in + 1.0;
        c1_b_delay_out = *chartInstance->c1_sessionTime + 10.0;
        c1_b_st.site = &c1_cd_emlrtRSI;
        if (muDoubleScalarIsNaN(*chartInstance->c1_target_side)) {
          c1_t_y = NULL;
          sf_mex_assign(&c1_t_y, sf_mex_create("y", c1_cv16, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          c1_jb_y = NULL;
          sf_mex_assign(&c1_jb_y, sf_mex_create("y", c1_cv16, 10, 0U, 1U, 0U, 2,
            1, 19), false);
          sf_mex_call(&c1_b_st, &c1_d_emlrtMCI, "error", 0U, 2U, 14, c1_t_y, 14,
                      sf_mex_call(&c1_b_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_b_st, NULL, "message", 1U, 1U, 14, c1_jb_y)));
        }

        if (*chartInstance->c1_target_side != 0.0) {
          c1_b_right_trigger_out = 1.0;
          c1_b_left_trigger_out = 0.0;
        } else {
          c1_b_left_trigger_out = 1.0;
          c1_b_right_trigger_out = 0.0;
        }

        c1_b_stim_duration_in = 0.05 * *chartInstance->c1_state_in;
      }

      c1_b_reward_trigger_out = 0;
      c1_b_localTime_out = *chartInstance->c1_localTime_in + 1.0;
      c1_b_trialNum_out = *chartInstance->c1_trialNum_in + 1.0;
      c1_b_npxlsAcq_out = *chartInstance->c1_npxlsAcq_in;
      c1_b_numLicks_out = *chartInstance->c1_numLicks_in;
      c1_b_left_trigger_in = *chartInstance->c1_was_target_in;
      c1_b_reward_duration_in = *chartInstance->c1_reward_duration_in;
      break;
    }
    break;
  }

  *chartInstance->c1_state_out = c1_b_state_out;
  *chartInstance->c1_localTime_out = c1_b_localTime_out;
  *chartInstance->c1_trialNum_out = c1_b_trialNum_out;
  *chartInstance->c1_npxlsAcq_out = c1_b_npxlsAcq_out;
  *chartInstance->c1_counter_out = c1_b_counter_out;
  *chartInstance->c1_numLicks_out = c1_b_numLicks_out;
  *chartInstance->c1_reward_trigger_out = (real_T)c1_b_reward_trigger_out;
  *chartInstance->c1_right_trigger_out = c1_b_right_trigger_out;
  *chartInstance->c1_left_trigger_out = c1_b_left_trigger_out;
  *chartInstance->c1_delay_out = c1_b_delay_out;
  *chartInstance->c1_was_target_out = c1_b_left_trigger_in;
  *chartInstance->c1_reward_duration_out = c1_b_reward_duration_in;
  *chartInstance->c1_stim_duration_out = c1_b_stim_duration_in;
  *chartInstance->c1_onsetTone_trig = 0.0;
  c1_do_animation_call_c1_ATTN(chartInstance);
}

static void ext_mode_exec_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance)
{
  c1_do_animation_call_c1_ATTN(chartInstance);
}

static void c1_do_animation_call_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance)
{
  sfDoAnimationWrapper(chartInstance->S, false, true);
  sfDoAnimationWrapper(chartInstance->S, false, false);
}

static const mxArray *get_sim_state_c1_ATTN(SFc1_ATTNInstanceStruct
  *chartInstance)
{
  const mxArray *c1_b_y = NULL;
  const mxArray *c1_c_y = NULL;
  const mxArray *c1_d_y = NULL;
  const mxArray *c1_e_y = NULL;
  const mxArray *c1_f_y = NULL;
  const mxArray *c1_g_y = NULL;
  const mxArray *c1_h_y = NULL;
  const mxArray *c1_i_y = NULL;
  const mxArray *c1_j_y = NULL;
  const mxArray *c1_k_y = NULL;
  const mxArray *c1_l_y = NULL;
  const mxArray *c1_m_y = NULL;
  const mxArray *c1_n_y = NULL;
  const mxArray *c1_o_y = NULL;
  const mxArray *c1_p_y = NULL;
  const mxArray *c1_q_y = NULL;
  const mxArray *c1_r_y = NULL;
  const mxArray *c1_s_y = NULL;
  const mxArray *c1_st;
  const mxArray *c1_t_y = NULL;
  const mxArray *c1_u_y = NULL;
  const mxArray *c1_y = NULL;
  c1_st = NULL;
  c1_st = NULL;
  c1_y = NULL;
  sf_mex_assign(&c1_y, sf_mex_createcellmatrix(20, 1), false);
  c1_b_y = NULL;
  sf_mex_assign(&c1_b_y, sf_mex_create("y", chartInstance->c1_counter_out, 0, 0U,
    0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 0, c1_b_y);
  c1_c_y = NULL;
  sf_mex_assign(&c1_c_y, sf_mex_create("y", chartInstance->c1_delay_out, 0, 0U,
    0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 1, c1_c_y);
  c1_d_y = NULL;
  sf_mex_assign(&c1_d_y, sf_mex_create("y", chartInstance->c1_left_trigger_out,
    0, 0U, 0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 2, c1_d_y);
  c1_e_y = NULL;
  sf_mex_assign(&c1_e_y, sf_mex_create("y", chartInstance->c1_localTime_out, 0,
    0U, 0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 3, c1_e_y);
  c1_f_y = NULL;
  sf_mex_assign(&c1_f_y, sf_mex_create("y", chartInstance->c1_npxlsAcq_out, 0,
    0U, 0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 4, c1_f_y);
  c1_g_y = NULL;
  sf_mex_assign(&c1_g_y, sf_mex_create("y", chartInstance->c1_numLicks_out, 0,
    0U, 0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 5, c1_g_y);
  c1_h_y = NULL;
  sf_mex_assign(&c1_h_y, sf_mex_create("y", chartInstance->c1_onsetTone_trig, 0,
    0U, 0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 6, c1_h_y);
  c1_i_y = NULL;
  sf_mex_assign(&c1_i_y, sf_mex_create("y",
    chartInstance->c1_reward_duration_out, 0, 0U, 0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 7, c1_i_y);
  c1_j_y = NULL;
  sf_mex_assign(&c1_j_y, sf_mex_create("y", chartInstance->c1_reward_trigger_out,
    0, 0U, 0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 8, c1_j_y);
  c1_k_y = NULL;
  sf_mex_assign(&c1_k_y, sf_mex_create("y", chartInstance->c1_right_trigger_out,
    0, 0U, 0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 9, c1_k_y);
  c1_l_y = NULL;
  sf_mex_assign(&c1_l_y, sf_mex_create("y", chartInstance->c1_state_out, 0, 0U,
    0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 10, c1_l_y);
  c1_m_y = NULL;
  sf_mex_assign(&c1_m_y, sf_mex_create("y", chartInstance->c1_stim_duration_out,
    0, 0U, 0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 11, c1_m_y);
  c1_n_y = NULL;
  sf_mex_assign(&c1_n_y, sf_mex_create("y", chartInstance->c1_trialNum_out, 0,
    0U, 0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 12, c1_n_y);
  c1_o_y = NULL;
  sf_mex_assign(&c1_o_y, sf_mex_create("y", chartInstance->c1_was_target_out, 0,
    0U, 0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 13, c1_o_y);
  c1_p_y = NULL;
  if (!chartInstance->c1_method_not_empty) {
    sf_mex_assign(&c1_p_y, sf_mex_create("y", NULL, 0, 0U, 1U, 0U, 2, 0, 0),
                  false);
  } else {
    sf_mex_assign(&c1_p_y, sf_mex_create("y", &chartInstance->c1_method, 7, 0U,
      0U, 0U, 0), false);
  }

  sf_mex_setcell(c1_y, 14, c1_p_y);
  c1_q_y = NULL;
  if (!chartInstance->c1_method_not_empty) {
    sf_mex_assign(&c1_q_y, sf_mex_create("y", NULL, 0, 0U, 1U, 0U, 2, 0, 0),
                  false);
  } else {
    sf_mex_assign(&c1_q_y, sf_mex_create("y", &chartInstance->c1_seed, 7, 0U, 0U,
      0U, 0), false);
  }

  sf_mex_setcell(c1_y, 15, c1_q_y);
  c1_r_y = NULL;
  if (!chartInstance->c1_method_not_empty) {
    sf_mex_assign(&c1_r_y, sf_mex_create("y", NULL, 0, 0U, 1U, 0U, 2, 0, 0),
                  false);
  } else {
    sf_mex_assign(&c1_r_y, sf_mex_create("y", &chartInstance->c1_c_state, 7, 0U,
      0U, 0U, 0), false);
  }

  sf_mex_setcell(c1_y, 16, c1_r_y);
  c1_s_y = NULL;
  if (!chartInstance->c1_state_not_empty) {
    sf_mex_assign(&c1_s_y, sf_mex_create("y", NULL, 0, 0U, 1U, 0U, 2, 0, 0),
                  false);
  } else {
    sf_mex_assign(&c1_s_y, sf_mex_create("y", chartInstance->c1_state, 7, 0U, 1U,
      0U, 1, 625), false);
  }

  sf_mex_setcell(c1_y, 17, c1_s_y);
  c1_t_y = NULL;
  if (!chartInstance->c1_b_state_not_empty) {
    sf_mex_assign(&c1_t_y, sf_mex_create("y", NULL, 0, 0U, 1U, 0U, 2, 0, 0),
                  false);
  } else {
    sf_mex_assign(&c1_t_y, sf_mex_create("y", chartInstance->c1_b_state, 7, 0U,
      1U, 0U, 1, 2), false);
  }

  sf_mex_setcell(c1_y, 18, c1_t_y);
  c1_u_y = NULL;
  sf_mex_assign(&c1_u_y, sf_mex_create("y", &chartInstance->c1_is_active_c1_ATTN,
    3, 0U, 0U, 0U, 0), false);
  sf_mex_setcell(c1_y, 19, c1_u_y);
  sf_mex_assign(&c1_st, c1_y, false);
  return c1_st;
}

static void set_sim_state_c1_ATTN(SFc1_ATTNInstanceStruct *chartInstance, const
  mxArray *c1_st)
{
  const mxArray *c1_u;
  chartInstance->c1_doneDoubleBufferReInit = true;
  c1_u = sf_mex_dup(c1_st);
  *chartInstance->c1_counter_out = c1_emlrt_marshallIn(chartInstance, sf_mex_dup
    (sf_mex_getcell(c1_u, 0)), "counter_out");
  *chartInstance->c1_delay_out = c1_emlrt_marshallIn(chartInstance, sf_mex_dup
    (sf_mex_getcell(c1_u, 1)), "delay_out");
  *chartInstance->c1_left_trigger_out = c1_emlrt_marshallIn(chartInstance,
    sf_mex_dup(sf_mex_getcell(c1_u, 2)), "left_trigger_out");
  *chartInstance->c1_localTime_out = c1_emlrt_marshallIn(chartInstance,
    sf_mex_dup(sf_mex_getcell(c1_u, 3)), "localTime_out");
  *chartInstance->c1_npxlsAcq_out = c1_emlrt_marshallIn(chartInstance,
    sf_mex_dup(sf_mex_getcell(c1_u, 4)), "npxlsAcq_out");
  *chartInstance->c1_numLicks_out = c1_emlrt_marshallIn(chartInstance,
    sf_mex_dup(sf_mex_getcell(c1_u, 5)), "numLicks_out");
  *chartInstance->c1_onsetTone_trig = c1_emlrt_marshallIn(chartInstance,
    sf_mex_dup(sf_mex_getcell(c1_u, 6)), "onsetTone_trig");
  *chartInstance->c1_reward_duration_out = c1_emlrt_marshallIn(chartInstance,
    sf_mex_dup(sf_mex_getcell(c1_u, 7)), "reward_duration_out");
  *chartInstance->c1_reward_trigger_out = c1_emlrt_marshallIn(chartInstance,
    sf_mex_dup(sf_mex_getcell(c1_u, 8)), "reward_trigger_out");
  *chartInstance->c1_right_trigger_out = c1_emlrt_marshallIn(chartInstance,
    sf_mex_dup(sf_mex_getcell(c1_u, 9)), "right_trigger_out");
  *chartInstance->c1_state_out = c1_emlrt_marshallIn(chartInstance, sf_mex_dup
    (sf_mex_getcell(c1_u, 10)), "state_out");
  *chartInstance->c1_stim_duration_out = c1_emlrt_marshallIn(chartInstance,
    sf_mex_dup(sf_mex_getcell(c1_u, 11)), "stim_duration_out");
  *chartInstance->c1_trialNum_out = c1_emlrt_marshallIn(chartInstance,
    sf_mex_dup(sf_mex_getcell(c1_u, 12)), "trialNum_out");
  *chartInstance->c1_was_target_out = c1_emlrt_marshallIn(chartInstance,
    sf_mex_dup(sf_mex_getcell(c1_u, 13)), "was_target_out");
  chartInstance->c1_method = c1_c_emlrt_marshallIn(chartInstance, sf_mex_dup
    (sf_mex_getcell(c1_u, 14)), "method", &chartInstance->c1_method_not_empty);
  chartInstance->c1_seed = c1_c_emlrt_marshallIn(chartInstance, sf_mex_dup
    (sf_mex_getcell(c1_u, 15)), "seed", &chartInstance->c1_seed_not_empty);
  chartInstance->c1_c_state = c1_c_emlrt_marshallIn(chartInstance, sf_mex_dup
    (sf_mex_getcell(c1_u, 16)), "state", &chartInstance->c1_c_state_not_empty);
  c1_e_emlrt_marshallIn(chartInstance, sf_mex_dup(sf_mex_getcell(c1_u, 17)),
                        "state", &chartInstance->c1_state_not_empty,
                        chartInstance->c1_state);
  c1_g_emlrt_marshallIn(chartInstance, sf_mex_dup(sf_mex_getcell(c1_u, 18)),
                        "state", &chartInstance->c1_b_state_not_empty,
                        chartInstance->c1_b_state);
  chartInstance->c1_is_active_c1_ATTN = c1_i_emlrt_marshallIn(chartInstance,
    sf_mex_dup(sf_mex_getcell(c1_u, 19)), "is_active_c1_ATTN");
  sf_mex_destroy(&c1_u);
  sf_mex_destroy(&c1_st);
}

static void initSimStructsc1_ATTN(SFc1_ATTNInstanceStruct *chartInstance)
{
  (void)chartInstance;
}

static void initSubchartIOPointersc1_ATTN(SFc1_ATTNInstanceStruct *chartInstance)
{
  (void)chartInstance;
}

static void c1_rng(SFc1_ATTNInstanceStruct *chartInstance, const emlrtStack
                   *c1_sp)
{
  static char_T c1_cv[22] = { 'M', 'A', 'T', 'L', 'A', 'B', ':', 'r', 'n', 'g',
    ':', 'b', 'a', 'd', 'S', 'e', 't', 't', 'i', 'n', 'g', 's' };

  time_t c1_b_eTime;
  time_t c1_eTime;
  const mxArray *c1_b_y = NULL;
  const mxArray *c1_c_y = NULL;
  real_T c1_s;
  real_T c1_y;
  int32_T c1_b_r;
  int32_T c1_exitg1;
  int32_T c1_t;
  uint32_T c1_r;
  if (!chartInstance->c1_seed_not_empty) {
    chartInstance->c1_seed = 0U;
    chartInstance->c1_seed_not_empty = true;
  }

  if (!chartInstance->c1_method_not_empty) {
    chartInstance->c1_method = 7U;
    chartInstance->c1_method_not_empty = true;
  }

  c1_y = c1_now(chartInstance) * 8.64E+6;
  c1_y = muDoubleScalarFloor(c1_y);
  c1_s = c1_mod(chartInstance, c1_y);
  c1_eTime = time(NULL);
  do {
    c1_exitg1 = 0;
    c1_b_eTime = time(NULL);
    if ((int32_T)c1_b_eTime <= (int32_T)c1_eTime + 1) {
      c1_y = c1_now(chartInstance) * 8.64E+6;
      c1_y = muDoubleScalarFloor(c1_y);
      if (c1_s != c1_mod(chartInstance, c1_y)) {
        c1_exitg1 = 1;
      }
    } else {
      c1_exitg1 = 1;
    }
  } while (c1_exitg1 == 0);

  c1_y = muDoubleScalarRound(c1_s);
  if (c1_y < 4.294967296E+9) {
    if (c1_y >= 0.0) {
      c1_r = (uint32_T)c1_y;
    } else {
      c1_r = 0U;
    }
  } else if (c1_y >= 4.294967296E+9) {
    c1_r = MAX_uint32_T;
  } else {
    c1_r = 0U;
  }

  chartInstance->c1_seed = c1_r;
  if (!chartInstance->c1_method_not_empty) {
    chartInstance->c1_method = 7U;
    chartInstance->c1_method_not_empty = true;
  }

  if (chartInstance->c1_method == 7U) {
    if (!chartInstance->c1_state_not_empty) {
      for (c1_b_r = 0; c1_b_r < 625; c1_b_r++) {
        chartInstance->c1_state[c1_b_r] = c1_uv[c1_b_r];
      }

      chartInstance->c1_state_not_empty = true;
    }

    c1_r = chartInstance->c1_seed;
    chartInstance->c1_state[0] = chartInstance->c1_seed;
    for (c1_b_r = 0; c1_b_r < 623; c1_b_r++) {
      c1_r = ((c1_r ^ c1_r >> 30U) * 1812433253U + (uint32_T)c1_b_r) + 1U;
      chartInstance->c1_state[c1_b_r + 1] = c1_r;
    }

    chartInstance->c1_state[624] = 624U;
  } else if (chartInstance->c1_method == 5U) {
    if (!chartInstance->c1_b_state_not_empty) {
      for (c1_b_r = 0; c1_b_r < 2; c1_b_r++) {
        chartInstance->c1_b_state[c1_b_r] = 158852560U * (uint32_T)c1_b_r +
          362436069U;
      }

      chartInstance->c1_b_state_not_empty = true;
    }

    chartInstance->c1_b_state[0] = 362436069U;
    chartInstance->c1_b_state[1] = chartInstance->c1_seed;
    if (chartInstance->c1_b_state[1] == 0U) {
      chartInstance->c1_b_state[1] = 521288629U;
    }
  } else if (chartInstance->c1_method == 4U) {
    if (!chartInstance->c1_c_state_not_empty) {
      chartInstance->c1_c_state = 1144108930U;
      chartInstance->c1_c_state_not_empty = true;
    }

    c1_b_r = (int32_T)(chartInstance->c1_seed >> 16U);
    c1_t = (int32_T)(chartInstance->c1_seed & 32768U);
    c1_r = ((((chartInstance->c1_seed - ((uint32_T)c1_b_r << 16U)) - (uint32_T)
              c1_t) << 16U) + (uint32_T)c1_t) + (uint32_T)c1_b_r;
    if (c1_r < 1U) {
      c1_r = 1144108930U;
    } else if (c1_r > 2147483646U) {
      c1_r = 2147483646U;
    }

    chartInstance->c1_c_state = c1_r;
  } else {
    c1_b_y = NULL;
    sf_mex_assign(&c1_b_y, sf_mex_create("y", c1_cv, 10, 0U, 1U, 0U, 2, 1, 22),
                  false);
    c1_c_y = NULL;
    sf_mex_assign(&c1_c_y, sf_mex_create("y", c1_cv, 10, 0U, 1U, 0U, 2, 1, 22),
                  false);
    sf_mex_call(c1_sp, &c1_emlrtMCI, "error", 0U, 2U, 14, c1_b_y, 14,
                sf_mex_call(c1_sp, NULL, "getString", 1U, 1U, 14, sf_mex_call
      (c1_sp, NULL, "message", 1U, 1U, 14, c1_c_y)));
  }
}

static real_T c1_now(SFc1_ATTNInstanceStruct *chartInstance)
{
  time_t c1_rawtime;
  struct tm c1_expl_temp;
  real_T c1_dDateNum;
  int32_T c1_r;
  int16_T c1_cDaysMonthWise[12];
  boolean_T c1_guard1;
  (void)chartInstance;
  c1_cDaysMonthWise[0] = 0;
  c1_cDaysMonthWise[1] = 31;
  c1_cDaysMonthWise[2] = 59;
  c1_cDaysMonthWise[3] = 90;
  c1_cDaysMonthWise[4] = 120;
  c1_cDaysMonthWise[5] = 151;
  c1_cDaysMonthWise[6] = 181;
  c1_cDaysMonthWise[7] = 212;
  c1_cDaysMonthWise[8] = 243;
  c1_cDaysMonthWise[9] = 273;
  c1_cDaysMonthWise[10] = 304;
  c1_cDaysMonthWise[11] = 334;
  time(&c1_rawtime);
  c1_expl_temp = *localtime(&c1_rawtime);
  c1_dDateNum = ((((365.0 * (real_T)(c1_expl_temp.tm_year + 1900) +
                    muDoubleScalarCeil((real_T)(c1_expl_temp.tm_year + 1900) /
    4.0)) - muDoubleScalarCeil((real_T)(c1_expl_temp.tm_year + 1900) / 100.0)) +
                  muDoubleScalarCeil((real_T)(c1_expl_temp.tm_year + 1900) /
    400.0)) + (real_T)c1_cDaysMonthWise[c1_expl_temp.tm_mon]) + (real_T)
    c1_expl_temp.tm_mday;
  if (c1_expl_temp.tm_mon + 1 > 2) {
    if (c1_expl_temp.tm_year + 1900 == 0) {
      c1_r = 0;
    } else {
      c1_r = (int32_T)muDoubleScalarRem((real_T)(c1_expl_temp.tm_year + 1900),
        4.0);
      if (c1_r == 0) {
        c1_r = 0;
      } else if (c1_expl_temp.tm_year + 1900 < 0) {
        c1_r += 4;
      }
    }

    c1_guard1 = false;
    if (c1_r == 0) {
      if (c1_expl_temp.tm_year + 1900 == 0) {
        c1_r = 0;
      } else {
        c1_r = (int32_T)muDoubleScalarRem((real_T)(c1_expl_temp.tm_year + 1900),
          100.0);
        if (c1_r == 0) {
          c1_r = 0;
        } else if (c1_expl_temp.tm_year + 1900 < 0) {
          c1_r += 100;
        }
      }

      if (c1_r != 0) {
        c1_dDateNum++;
      } else {
        c1_guard1 = true;
      }
    } else {
      c1_guard1 = true;
    }

    if (c1_guard1) {
      if (c1_expl_temp.tm_year + 1900 == 0) {
        c1_r = 0;
      } else {
        c1_r = (int32_T)muDoubleScalarRem((real_T)(c1_expl_temp.tm_year + 1900),
          400.0);
        if (c1_r == 0) {
          c1_r = 0;
        } else if (c1_expl_temp.tm_year + 1900 < 0) {
          c1_r += 400;
        }
      }

      if (c1_r == 0) {
        c1_dDateNum++;
      }
    }
  }

  return c1_dDateNum + (((real_T)c1_expl_temp.tm_hour * 3600.0 + (real_T)
    c1_expl_temp.tm_min * 60.0) + (real_T)c1_expl_temp.tm_sec) / 86400.0;
}

static real_T c1_mod(SFc1_ATTNInstanceStruct *chartInstance, real_T c1_x)
{
  real_T c1_r;
  (void)chartInstance;
  if (muDoubleScalarIsNaN(c1_x) || muDoubleScalarIsInf(c1_x)) {
    c1_r = rtNaN;
  } else if (c1_x == 0.0) {
    c1_r = 0.0;
  } else {
    c1_r = muDoubleScalarRem(c1_x, 2.147483647E+9);
    if (c1_r == 0.0) {
      c1_r = 0.0;
    } else if (c1_x < 0.0) {
      c1_r += 2.147483647E+9;
    }
  }

  return c1_r;
}

static real_T c1_negative_exp_rand(SFc1_ATTNInstanceStruct *chartInstance, const
  emlrtStack *c1_sp, real_T c1_range_min, real_T c1_range_max)
{
  static char_T c1_cv[30] = { 'C', 'o', 'd', 'e', 'r', ':', 't', 'o', 'o', 'l',
    'b', 'o', 'x', ':', 'E', 'l', 'F', 'u', 'n', 'D', 'o', 'm', 'a', 'i', 'n',
    'E', 'r', 'r', 'o', 'r' };

  static char_T c1_cv1[3] = { 'l', 'o', 'g' };

  emlrtStack c1_b_st;
  emlrtStack c1_c_st;
  emlrtStack c1_d_st;
  emlrtStack c1_e_st;
  emlrtStack c1_st;
  const mxArray *c1_b_y = NULL;
  const mxArray *c1_c_y = NULL;
  const mxArray *c1_y = NULL;
  real_T c1_b_range_min[2];
  real_T c1_mu;
  real_T c1_random_number;
  real_T c1_x;
  c1_st.prev = c1_sp;
  c1_st.tls = c1_sp->tls;
  c1_b_st.prev = &c1_st;
  c1_b_st.tls = c1_st.tls;
  c1_c_st.prev = &c1_b_st;
  c1_c_st.tls = c1_b_st.tls;
  c1_d_st.prev = &c1_c_st;
  c1_d_st.tls = c1_c_st.tls;
  c1_e_st.prev = &c1_d_st;
  c1_e_st.tls = c1_d_st.tls;
  c1_b_range_min[0] = c1_range_min;
  c1_b_range_min[1] = c1_range_max;
  c1_mu = c1_sumColumnB(chartInstance, c1_b_range_min, 1) / 2.0;
  c1_random_number = c1_range_min - 1.0;
  while ((c1_random_number >= c1_range_max) || (c1_random_number <= c1_range_min))
  {
    c1_st.site = &c1_o_emlrtRSI;
    c1_b_st.site = &c1_p_emlrtRSI;
    c1_c_st.site = &c1_q_emlrtRSI;
    c1_d_st.site = &c1_r_emlrtRSI;
    c1_e_st.site = &c1_r_emlrtRSI;
    c1_x = c1_rand(chartInstance, &c1_e_st);
    if (c1_x < 0.0) {
      c1_y = NULL;
      sf_mex_assign(&c1_y, sf_mex_create("y", c1_cv, 10, 0U, 1U, 0U, 2, 1, 30),
                    false);
      c1_b_y = NULL;
      sf_mex_assign(&c1_b_y, sf_mex_create("y", c1_cv, 10, 0U, 1U, 0U, 2, 1, 30),
                    false);
      c1_c_y = NULL;
      sf_mex_assign(&c1_c_y, sf_mex_create("y", c1_cv1, 10, 0U, 1U, 0U, 2, 1, 3),
                    false);
      sf_mex_call(&c1_d_st, &c1_c_emlrtMCI, "error", 0U, 2U, 14, c1_y, 14,
                  sf_mex_call(&c1_d_st, NULL, "getString", 1U, 1U, 14,
        sf_mex_call(&c1_d_st, NULL, "message", 1U, 2U, 14, c1_b_y, 14, c1_c_y)));
    }

    c1_x = muDoubleScalarLog(c1_x);
    c1_random_number = -c1_mu * c1_x;
    if (c1_mu < 0.0) {
      c1_random_number = rtNaN;
    }

    _SF_MEX_LISTEN_FOR_CTRL_C(chartInstance->S);
  }

  return c1_random_number;
}

static real_T c1_sumColumnB(SFc1_ATTNInstanceStruct *chartInstance, real_T c1_x
  [2], int32_T c1_col)
{
  int32_T c1_i0;
  (void)chartInstance;
  c1_i0 = (c1_col - 1) << 1;
  return c1_x[c1_i0] + c1_x[c1_i0 + 1];
}

static real_T c1_rand(SFc1_ATTNInstanceStruct *chartInstance, const emlrtStack
                      *c1_sp)
{
  static char_T c1_cv[37] = { 'C', 'o', 'd', 'e', 'r', ':', 'M', 'A', 'T', 'L',
    'A', 'B', ':', 'r', 'a', 'n', 'd', '_', 'i', 'n', 'v', 'a', 'l', 'i', 'd',
    'T', 'w', 'i', 's', 't', 'e', 'r', 'S', 't', 'a', 't', 'e' };

  emlrtStack c1_b_st;
  emlrtStack c1_c_st;
  emlrtStack c1_d_st;
  emlrtStack c1_st;
  const mxArray *c1_b_y = NULL;
  const mxArray *c1_c_y = NULL;
  real_T c1_r;
  int32_T c1_exitg1;
  int32_T c1_k;
  int32_T c1_kk;
  uint32_T c1_u[2];
  uint32_T c1_mti;
  uint32_T c1_y;
  boolean_T c1_exitg2;
  boolean_T c1_isvalid;
  c1_st.prev = c1_sp;
  c1_st.tls = c1_sp->tls;
  c1_b_st.prev = &c1_st;
  c1_b_st.tls = c1_st.tls;
  c1_c_st.prev = &c1_b_st;
  c1_c_st.tls = c1_b_st.tls;
  c1_d_st.prev = &c1_c_st;
  c1_d_st.tls = c1_c_st.tls;
  c1_st.site = &c1_s_emlrtRSI;
  if (!chartInstance->c1_method_not_empty) {
    chartInstance->c1_method = 7U;
    chartInstance->c1_method_not_empty = true;
  }

  if (chartInstance->c1_method == 4U) {
    c1_b_st.site = &c1_t_emlrtRSI;
    if (!chartInstance->c1_c_state_not_empty) {
      chartInstance->c1_c_state = 1144108930U;
      chartInstance->c1_c_state_not_empty = true;
    }

    c1_k = (int32_T)(chartInstance->c1_c_state / 127773U);
    c1_mti = 16807U * (chartInstance->c1_c_state - (uint32_T)c1_k * 127773U);
    c1_y = 2836U * (uint32_T)c1_k;
    if (c1_mti < c1_y) {
      c1_mti = ~(c1_y - c1_mti) & 2147483647U;
    } else {
      c1_mti -= c1_y;
    }

    c1_r = (real_T)c1_mti * 4.6566128752457969E-10;
    chartInstance->c1_c_state = c1_mti;
  } else if (chartInstance->c1_method == 5U) {
    c1_b_st.site = &c1_u_emlrtRSI;
    if (!chartInstance->c1_b_state_not_empty) {
      for (c1_k = 0; c1_k < 2; c1_k++) {
        chartInstance->c1_b_state[c1_k] = 158852560U * (uint32_T)c1_k +
          362436069U;
      }

      chartInstance->c1_b_state_not_empty = true;
    }

    c1_c_st.site = &c1_w_emlrtRSI;
    c1_d_st.site = &c1_x_emlrtRSI;
    c1_mti = 69069U * chartInstance->c1_b_state[0] + 1234567U;
    c1_y = chartInstance->c1_b_state[1] ^ chartInstance->c1_b_state[1] << 13;
    c1_y ^= c1_y >> 17;
    c1_y ^= c1_y << 5;
    c1_u[0] = c1_mti;
    c1_u[1] = c1_y;
    c1_r = (real_T)(c1_mti + c1_y) * 2.328306436538696E-10;
    for (c1_k = 0; c1_k < 2; c1_k++) {
      chartInstance->c1_b_state[c1_k] = c1_u[c1_k];
    }
  } else {
    c1_b_st.site = &c1_v_emlrtRSI;
    if (!chartInstance->c1_state_not_empty) {
      for (c1_k = 0; c1_k < 625; c1_k++) {
        chartInstance->c1_state[c1_k] = c1_uv[c1_k];
      }

      chartInstance->c1_state_not_empty = true;
    }

    c1_c_st.site = &c1_ab_emlrtRSI;
    c1_d_st.site = &c1_bb_emlrtRSI;

    /* ========================= COPYRIGHT NOTICE ============================ */
    /*  This is a uniform (0,1) pseudorandom number generator based on:        */
    /*                                                                         */
    /*  A C-program for MT19937, with initialization improved 2002/1/26.       */
    /*  Coded by Takuji Nishimura and Makoto Matsumoto.                        */
    /*                                                                         */
    /*  Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura,      */
    /*  All rights reserved.                                                   */
    /*                                                                         */
    /*  Redistribution and use in source and binary forms, with or without     */
    /*  modification, are permitted provided that the following conditions     */
    /*  are met:                                                               */
    /*                                                                         */
    /*    1. Redistributions of source code must retain the above copyright    */
    /*       notice, this list of conditions and the following disclaimer.     */
    /*                                                                         */
    /*    2. Redistributions in binary form must reproduce the above copyright */
    /*       notice, this list of conditions and the following disclaimer      */
    /*       in the documentation and/or other materials provided with the     */
    /*       distribution.                                                     */
    /*                                                                         */
    /*    3. The names of its contributors may not be used to endorse or       */
    /*       promote products derived from this software without specific      */
    /*       prior written permission.                                         */
    /*                                                                         */
    /*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    */
    /*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      */
    /*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  */
    /*  A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT  */
    /*  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,  */
    /*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       */
    /*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  */
    /*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  */
    /*  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    */
    /*  (INCLUDING  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE */
    /*  OF THIS  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  */
    /*                                                                         */
    /* =============================   END   ================================= */
    do {
      c1_exitg1 = 0;
      for (c1_k = 0; c1_k < 2; c1_k++) {
        c1_mti = chartInstance->c1_state[624] + 1U;
        if (c1_mti >= 625U) {
          for (c1_kk = 0; c1_kk < 227; c1_kk++) {
            c1_y = (chartInstance->c1_state[c1_kk] & 2147483648U) |
              (chartInstance->c1_state[c1_kk + 1] & 2147483647U);
            if ((c1_y & 1U) == 0U) {
              c1_y >>= 1U;
            } else {
              c1_y = c1_y >> 1U ^ 2567483615U;
            }

            chartInstance->c1_state[c1_kk] = chartInstance->c1_state[c1_kk + 397]
              ^ c1_y;
          }

          for (c1_kk = 0; c1_kk < 396; c1_kk++) {
            c1_y = (chartInstance->c1_state[c1_kk + 227] & 2147483648U) |
              (chartInstance->c1_state[c1_kk + 228] & 2147483647U);
            if ((c1_y & 1U) == 0U) {
              c1_y >>= 1U;
            } else {
              c1_y = c1_y >> 1U ^ 2567483615U;
            }

            chartInstance->c1_state[c1_kk + 227] = chartInstance->c1_state[c1_kk]
              ^ c1_y;
          }

          c1_y = (chartInstance->c1_state[623] & 2147483648U) |
            (chartInstance->c1_state[0] & 2147483647U);
          if ((c1_y & 1U) == 0U) {
            c1_y >>= 1U;
          } else {
            c1_y = c1_y >> 1U ^ 2567483615U;
          }

          chartInstance->c1_state[623] = chartInstance->c1_state[396] ^ c1_y;
          c1_mti = 1U;
        }

        c1_y = chartInstance->c1_state[(int32_T)c1_mti - 1];
        chartInstance->c1_state[624] = c1_mti;
        c1_y ^= c1_y >> 11U;
        c1_y ^= c1_y << 7U & 2636928640U;
        c1_y ^= c1_y << 15U & 4022730752U;
        c1_u[c1_k] = c1_y ^ c1_y >> 18U;
      }

      c1_r = 1.1102230246251565E-16 * ((real_T)(c1_u[0] >> 5U) * 6.7108864E+7 +
        (real_T)(c1_u[1] >> 6U));
      if (c1_r == 0.0) {
        if ((chartInstance->c1_state[624] >= 1U) && (chartInstance->c1_state[624]
             < 625U)) {
          c1_isvalid = true;
        } else {
          c1_isvalid = false;
        }

        if (c1_isvalid) {
          c1_isvalid = false;
          c1_k = 1;
          c1_exitg2 = false;
          while ((!c1_exitg2) && (c1_k < 625)) {
            if (chartInstance->c1_state[c1_k - 1] == 0U) {
              c1_k++;
            } else {
              c1_isvalid = true;
              c1_exitg2 = true;
            }
          }
        }

        if (!c1_isvalid) {
          c1_b_y = NULL;
          sf_mex_assign(&c1_b_y, sf_mex_create("y", c1_cv, 10, 0U, 1U, 0U, 2, 1,
            37), false);
          c1_c_y = NULL;
          sf_mex_assign(&c1_c_y, sf_mex_create("y", c1_cv, 10, 0U, 1U, 0U, 2, 1,
            37), false);
          sf_mex_call(&c1_d_st, &c1_b_emlrtMCI, "error", 0U, 2U, 14, c1_b_y, 14,
                      sf_mex_call(&c1_d_st, NULL, "getString", 1U, 1U, 14,
            sf_mex_call(&c1_d_st, NULL, "message", 1U, 1U, 14, c1_c_y)));
        }
      } else {
        c1_exitg1 = 1;
      }
    } while (c1_exitg1 == 0);
  }

  return c1_r;
}

const mxArray *sf_c1_ATTN_get_eml_resolved_functions_info(void)
{
  const mxArray *c1_nameCaptureInfo = NULL;
  const char_T *c1_data[4] = {
    "789ce5534b4f8430182c66dd787075bd18ff8472f4ac04120f3e0278d11896a59f42a42d812e41ff8127affe5cc3a33c6a1a8c442fce65980ced4cbfb448bbb8"
    "d410427ba8c6d1bce645a3970d6fa121645f53b0c0369a0dd609ffbde180510e05af05f509b42b312311f529775f124029642cce0157ce6314831b1170fae2aa",
    "54c4ea59ad28adf2db082178763604a561d6358cfba29dc74a71ded9c83c64c8f390ff1379c50ff3c4fe072379c2a7f0e4f328070f8ac44b7d8aa51eab893de6"
    "ca1eb583d9661d4397f73131ef549937f4efcd073d6404748821e029d30d86c1b321613a3d36ae6dd72cf42fb33921a373d9ff664fd5fb58a09d8adf766fabab",
    "ff577902ff256feafb3a54e42d25fffc3570d2ac006c9ef138cfd6fe9d9d5856d7e3662467ac0752e8dfdeff135d9155a8",
    "" };

  c1_nameCaptureInfo = NULL;
  emlrtNameCaptureMxArrayR2016a(&c1_data[0], 1584U, &c1_nameCaptureInfo);
  return c1_nameCaptureInfo;
}

static const mxArray *c1_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const real_T c1_u)
{
  const mxArray *c1_y = NULL;
  (void)chartInstance;
  c1_y = NULL;
  sf_mex_assign(&c1_y, sf_mex_create("y", &c1_u, 0, 0U, 0U, 0U, 0), false);
  return c1_y;
}

static const mxArray *c1_b_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[14])
{
  const mxArray *c1_y = NULL;
  (void)chartInstance;
  c1_y = NULL;
  sf_mex_assign(&c1_y, sf_mex_create("y", c1_u, 10, 0U, 1U, 0U, 2, 1, 14), false);
  return c1_y;
}

static const mxArray *c1_c_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[17])
{
  const mxArray *c1_y = NULL;
  (void)chartInstance;
  c1_y = NULL;
  sf_mex_assign(&c1_y, sf_mex_create("y", c1_u, 10, 0U, 1U, 0U, 2, 1, 17), false);
  return c1_y;
}

static const mxArray *c1_d_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[11])
{
  const mxArray *c1_y = NULL;
  (void)chartInstance;
  c1_y = NULL;
  sf_mex_assign(&c1_y, sf_mex_create("y", c1_u, 10, 0U, 1U, 0U, 2, 1, 11), false);
  return c1_y;
}

static const mxArray *c1_e_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[10])
{
  const mxArray *c1_y = NULL;
  (void)chartInstance;
  c1_y = NULL;
  sf_mex_assign(&c1_y, sf_mex_create("y", c1_u, 10, 0U, 1U, 0U, 2, 1, 10), false);
  return c1_y;
}

static const mxArray *c1_f_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[6])
{
  const mxArray *c1_y = NULL;
  (void)chartInstance;
  c1_y = NULL;
  sf_mex_assign(&c1_y, sf_mex_create("y", c1_u, 10, 0U, 1U, 0U, 2, 1, 6), false);
  return c1_y;
}

static const mxArray *c1_g_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[2])
{
  const mxArray *c1_y = NULL;
  (void)chartInstance;
  c1_y = NULL;
  sf_mex_assign(&c1_y, sf_mex_create("y", c1_u, 10, 0U, 1U, 0U, 2, 1, 2), false);
  return c1_y;
}

static const mxArray *c1_h_emlrt_marshallOut(SFc1_ATTNInstanceStruct
  *chartInstance, const char_T c1_u[15])
{
  const mxArray *c1_y = NULL;
  (void)chartInstance;
  c1_y = NULL;
  sf_mex_assign(&c1_y, sf_mex_create("y", c1_u, 10, 0U, 1U, 0U, 2, 1, 15), false);
  return c1_y;
}

static real_T c1_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance, const
  mxArray *c1_b_counter_out, const char_T *c1_identifier)
{
  emlrtMsgIdentifier c1_thisId;
  real_T c1_y;
  c1_thisId.fIdentifier = (const char_T *)c1_identifier;
  c1_thisId.fParent = NULL;
  c1_thisId.bParentIsCell = false;
  c1_y = c1_b_emlrt_marshallIn(chartInstance, sf_mex_dup(c1_b_counter_out),
    &c1_thisId);
  sf_mex_destroy(&c1_b_counter_out);
  return c1_y;
}

static real_T c1_b_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance,
  const mxArray *c1_u, const emlrtMsgIdentifier *c1_parentId)
{
  real_T c1_d;
  real_T c1_y;
  (void)chartInstance;
  sf_mex_import(c1_parentId, sf_mex_dup(c1_u), &c1_d, 1, 0, 0U, 0, 0U, 0);
  c1_y = c1_d;
  sf_mex_destroy(&c1_u);
  return c1_y;
}

static uint32_T c1_c_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance,
  const mxArray *c1_b_method, const char_T *c1_identifier, boolean_T *c1_svPtr)
{
  emlrtMsgIdentifier c1_thisId;
  uint32_T c1_y;
  c1_thisId.fIdentifier = (const char_T *)c1_identifier;
  c1_thisId.fParent = NULL;
  c1_thisId.bParentIsCell = false;
  c1_y = c1_d_emlrt_marshallIn(chartInstance, sf_mex_dup(c1_b_method),
    &c1_thisId, c1_svPtr);
  sf_mex_destroy(&c1_b_method);
  return c1_y;
}

static uint32_T c1_d_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance,
  const mxArray *c1_u, const emlrtMsgIdentifier *c1_parentId, boolean_T
  *c1_svPtr)
{
  uint32_T c1_b_u;
  uint32_T c1_y;
  (void)chartInstance;
  if (mxIsEmpty(c1_u)) {
    *c1_svPtr = false;
  } else {
    *c1_svPtr = true;
    sf_mex_import(c1_parentId, sf_mex_dup(c1_u), &c1_b_u, 1, 7, 0U, 0, 0U, 0);
    c1_y = c1_b_u;
  }

  sf_mex_destroy(&c1_u);
  return c1_y;
}

static void c1_e_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance, const
  mxArray *c1_d_state, const char_T *c1_identifier, boolean_T *c1_svPtr,
  uint32_T c1_y[625])
{
  emlrtMsgIdentifier c1_thisId;
  c1_thisId.fIdentifier = (const char_T *)c1_identifier;
  c1_thisId.fParent = NULL;
  c1_thisId.bParentIsCell = false;
  c1_f_emlrt_marshallIn(chartInstance, sf_mex_dup(c1_d_state), &c1_thisId,
                        c1_svPtr, c1_y);
  sf_mex_destroy(&c1_d_state);
}

static void c1_f_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance, const
  mxArray *c1_u, const emlrtMsgIdentifier *c1_parentId, boolean_T *c1_svPtr,
  uint32_T c1_y[625])
{
  int32_T c1_i;
  uint32_T c1_b_uv[625];
  (void)chartInstance;
  if (mxIsEmpty(c1_u)) {
    *c1_svPtr = false;
  } else {
    *c1_svPtr = true;
    sf_mex_import(c1_parentId, sf_mex_dup(c1_u), c1_b_uv, 1, 7, 0U, 1, 0U, 1,
                  625);
    for (c1_i = 0; c1_i < 625; c1_i++) {
      c1_y[c1_i] = c1_b_uv[c1_i];
    }
  }

  sf_mex_destroy(&c1_u);
}

static void c1_g_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance, const
  mxArray *c1_d_state, const char_T *c1_identifier, boolean_T *c1_svPtr,
  uint32_T c1_y[2])
{
  emlrtMsgIdentifier c1_thisId;
  c1_thisId.fIdentifier = (const char_T *)c1_identifier;
  c1_thisId.fParent = NULL;
  c1_thisId.bParentIsCell = false;
  c1_h_emlrt_marshallIn(chartInstance, sf_mex_dup(c1_d_state), &c1_thisId,
                        c1_svPtr, c1_y);
  sf_mex_destroy(&c1_d_state);
}

static void c1_h_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance, const
  mxArray *c1_u, const emlrtMsgIdentifier *c1_parentId, boolean_T *c1_svPtr,
  uint32_T c1_y[2])
{
  int32_T c1_i;
  uint32_T c1_b_uv[2];
  (void)chartInstance;
  if (mxIsEmpty(c1_u)) {
    *c1_svPtr = false;
  } else {
    *c1_svPtr = true;
    sf_mex_import(c1_parentId, sf_mex_dup(c1_u), c1_b_uv, 1, 7, 0U, 1, 0U, 1, 2);
    for (c1_i = 0; c1_i < 2; c1_i++) {
      c1_y[c1_i] = c1_b_uv[c1_i];
    }
  }

  sf_mex_destroy(&c1_u);
}

static uint8_T c1_i_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance,
  const mxArray *c1_b_is_active_c1_ATTN, const char_T *c1_identifier)
{
  emlrtMsgIdentifier c1_thisId;
  uint8_T c1_y;
  c1_thisId.fIdentifier = (const char_T *)c1_identifier;
  c1_thisId.fParent = NULL;
  c1_thisId.bParentIsCell = false;
  c1_y = c1_j_emlrt_marshallIn(chartInstance, sf_mex_dup(c1_b_is_active_c1_ATTN),
    &c1_thisId);
  sf_mex_destroy(&c1_b_is_active_c1_ATTN);
  return c1_y;
}

static uint8_T c1_j_emlrt_marshallIn(SFc1_ATTNInstanceStruct *chartInstance,
  const mxArray *c1_u, const emlrtMsgIdentifier *c1_parentId)
{
  uint8_T c1_b_u;
  uint8_T c1_y;
  (void)chartInstance;
  sf_mex_import(c1_parentId, sf_mex_dup(c1_u), &c1_b_u, 1, 3, 0U, 0, 0U, 0);
  c1_y = c1_b_u;
  sf_mex_destroy(&c1_u);
  return c1_y;
}

static void c1_chart_data_browse_helper(SFc1_ATTNInstanceStruct *chartInstance,
  int32_T c1_ssIdNumber, const mxArray **c1_mxData, uint8_T *c1_isValueTooBig)
{
  *c1_mxData = NULL;
  *c1_mxData = NULL;
  *c1_isValueTooBig = 0U;
  switch (c1_ssIdNumber) {
   case 4U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData", chartInstance->c1_state_in,
      0, 0U, 0U, 0U, 0), false);
    break;

   case 6U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_localTime_in, 0, 0U, 0U, 0U, 0), false);
    break;

   case 7U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_trialNum_in, 0, 0U, 0U, 0U, 0), false);
    break;

   case 44U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData", chartInstance->c1_lick, 0,
      0U, 0U, 0U, 0), false);
    break;

   case 12U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_sessionTime, 0, 0U, 0U, 0U, 0), false);
    break;

   case 14U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_npxlsAcq_in, 0, 0U, 0U, 0U, 0), false);
    break;

   case 5U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData", chartInstance->c1_state_out,
      0, 0U, 0U, 0U, 0), false);
    break;

   case 9U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_localTime_out, 0, 0U, 0U, 0U, 0), false);
    break;

   case 10U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_trialNum_out, 0, 0U, 0U, 0U, 0), false);
    break;

   case 13U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_npxlsAcq_out, 0, 0U, 0U, 0U, 0), false);
    break;

   case 16U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_counter_in, 0, 0U, 0U, 0U, 0), false);
    break;

   case 27U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_numLicks_in, 0, 0U, 0U, 0U, 0), false);
    break;

   case 19U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData", chartInstance->c1_delay_in,
      0, 0U, 0U, 0U, 0), false);
    break;

   case 22U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_right_trigger_in, 0, 0U, 0U, 0U, 0), false);
    break;

   case 23U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_left_trigger_in, 0, 0U, 0U, 0U, 0), false);
    break;

   case 17U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_sampleTime, 0, 0U, 0U, 0U, 0), false);
    break;

   case 18U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_counter_out, 0, 0U, 0U, 0U, 0), false);
    break;

   case 28U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_numLicks_out, 0, 0U, 0U, 0U, 0), false);
    break;

   case 29U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_reward_trigger_out, 0, 0U, 0U, 0U, 0), false);
    break;

   case 25U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_right_trigger_out, 0, 0U, 0U, 0U, 0), false);
    break;

   case 26U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_left_trigger_out, 0, 0U, 0U, 0U, 0), false);
    break;

   case 20U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData", chartInstance->c1_delay_out,
      0, 0U, 0U, 0U, 0), false);
    break;

   case 33U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_was_target_in, 0, 0U, 0U, 0U, 0), false);
    break;

   case 34U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_was_target_out, 0, 0U, 0U, 0U, 0), false);
    break;

   case 35U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_target_side, 0, 0U, 0U, 0U, 0), false);
    break;

   case 38U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_reward_duration_in, 0, 0U, 0U, 0U, 0), false);
    break;

   case 40U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_stim_duration_in, 0, 0U, 0U, 0U, 0), false);
    break;

   case 45U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_switch_time, 0, 0U, 0U, 0U, 0), false);
    break;

   case 37U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData", chartInstance->c1_stage, 0,
      0U, 0U, 0U, 0), false);
    break;

   case 39U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_reward_duration_out, 0, 0U, 0U, 0U, 0), false);
    break;

   case 41U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_stim_duration_out, 0, 0U, 0U, 0U, 0), false);
    break;

   case 42U:
    sf_mex_assign(c1_mxData, sf_mex_create("mxData",
      chartInstance->c1_onsetTone_trig, 0, 0U, 0U, 0U, 0), false);
    break;
  }
}

static void init_dsm_address_info(SFc1_ATTNInstanceStruct *chartInstance)
{
  (void)chartInstance;
}

static void init_simulink_io_address(SFc1_ATTNInstanceStruct *chartInstance)
{
  chartInstance->c1_fEmlrtCtx = (void *)sfrtGetEmlrtCtx(chartInstance->S);
  chartInstance->c1_state_in = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 0);
  chartInstance->c1_localTime_in = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 1);
  chartInstance->c1_trialNum_in = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 2);
  chartInstance->c1_lick = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 3);
  chartInstance->c1_sessionTime = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 4);
  chartInstance->c1_npxlsAcq_in = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 5);
  chartInstance->c1_state_out = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 1);
  chartInstance->c1_localTime_out = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 2);
  chartInstance->c1_trialNum_out = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 3);
  chartInstance->c1_npxlsAcq_out = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 4);
  chartInstance->c1_counter_in = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 6);
  chartInstance->c1_numLicks_in = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 7);
  chartInstance->c1_delay_in = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 8);
  chartInstance->c1_right_trigger_in = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 9);
  chartInstance->c1_left_trigger_in = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 10);
  chartInstance->c1_sampleTime = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 11);
  chartInstance->c1_counter_out = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 5);
  chartInstance->c1_numLicks_out = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 6);
  chartInstance->c1_reward_trigger_out = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 7);
  chartInstance->c1_right_trigger_out = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 8);
  chartInstance->c1_left_trigger_out = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 9);
  chartInstance->c1_delay_out = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 10);
  chartInstance->c1_was_target_in = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 12);
  chartInstance->c1_was_target_out = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 11);
  chartInstance->c1_target_side = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 13);
  chartInstance->c1_reward_duration_in = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 14);
  chartInstance->c1_stim_duration_in = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 15);
  chartInstance->c1_switch_time = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 16);
  chartInstance->c1_stage = (real_T *)ssGetInputPortSignal_wrapper
    (chartInstance->S, 17);
  chartInstance->c1_reward_duration_out = (real_T *)
    ssGetOutputPortSignal_wrapper(chartInstance->S, 12);
  chartInstance->c1_stim_duration_out = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 13);
  chartInstance->c1_onsetTone_trig = (real_T *)ssGetOutputPortSignal_wrapper
    (chartInstance->S, 14);
}

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* SFunction Glue Code */
void sf_c1_ATTN_get_check_sum(mxArray *plhs[])
{
  ((real_T *)mxGetPr((plhs[0])))[0] = (real_T)(1880797247U);
  ((real_T *)mxGetPr((plhs[0])))[1] = (real_T)(1099753482U);
  ((real_T *)mxGetPr((plhs[0])))[2] = (real_T)(2093135121U);
  ((real_T *)mxGetPr((plhs[0])))[3] = (real_T)(1197276972U);
}

mxArray *sf_c1_ATTN_third_party_uses_info(void)
{
  mxArray * mxcell3p = mxCreateCellMatrix(1,0);
  return(mxcell3p);
}

mxArray *sf_c1_ATTN_jit_fallback_info(void)
{
  const char *infoFields[] = { "fallbackType", "fallbackReason",
    "hiddenFallbackType", "hiddenFallbackReason", "incompatibleSymbol" };

  mxArray *mxInfo = mxCreateStructMatrix(1, 1, 5, infoFields);
  mxArray *fallbackType = mxCreateString("late");
  mxArray *fallbackReason = mxCreateString("ir_vars");
  mxArray *hiddenFallbackType = mxCreateString("");
  mxArray *hiddenFallbackReason = mxCreateString("");
  mxArray *incompatibleSymbol = mxCreateString("rawtime");
  mxSetField(mxInfo, 0, infoFields[0], fallbackType);
  mxSetField(mxInfo, 0, infoFields[1], fallbackReason);
  mxSetField(mxInfo, 0, infoFields[2], hiddenFallbackType);
  mxSetField(mxInfo, 0, infoFields[3], hiddenFallbackReason);
  mxSetField(mxInfo, 0, infoFields[4], incompatibleSymbol);
  return mxInfo;
}

mxArray *sf_c1_ATTN_updateBuildInfo_args_info(void)
{
  mxArray *mxBIArgs = mxCreateCellMatrix(1,0);
  return mxBIArgs;
}

static const mxArray *sf_get_sim_state_info_c1_ATTN(void)
{
  const char *infoFields[] = { "chartChecksum", "varInfo" };

  mxArray *mxInfo = mxCreateStructMatrix(1, 1, 2, infoFields);
  mxArray *mxVarInfo = sf_mex_decode(
    "eNrtl01v0zAYx9OqrZiAqYxJXCvEiQPpC2IroiLlRaJomxDqgcOmzE3cNMKJi+1s3S1Hjv0IfBQ"
    "+DkeOHInzsnVuRaI0ogbNkmU9rp6n+j3+559YKQ0OlWBsB1N7oCi1YL0VzLISjWocl4K5G6/Rfu"
    "VyvxFMdjGFfJ8SY2AGqwucMAbebOCOcVh/X7mqX1tRv7RQfyvej8bPl+vlt7WQbyG/siL/9kJ+P"
    "Y4N7LkMEh17TEn6lKyb43maiWdL4OGxCRG4uKSRhed5Jp66wMMngmOmM2JbVnRIcvA8zMRzV+Dh"
    "McIGQEPbgfEZycHzOBPPHYGHx+50hmjf+JJITg6eF/l5POfANj5TuXjeZuLZFnh4jF0K2RC7MHy"
    "IJOHxX4c871J47gs8PCbwHBBTNz0CmI1dyXy7l4lrR+DaueJacDqZ/LubieuewMXjgGfClrEk4d"
    "rN/Z6lDDAoG4//Jvc5UWY7y0+VLOf0KLefB8oD6Mhz5PLzfm4/PwdUZ4BYkEVExfDUtfXyl/9/F"
    "U9N4OGxA9kEm1H+h9Kf7ycl4X5SXqiLFFuZJvecFI6ywFFPID75Wrh+9bUi9OGn9OO90A8eqx4l"
    "aviRqB72hwf9V+rHdrPdASrDGI3wTIUOUpE9Uh3AEBipBLjm2HPVKbHPAkfiP+t874kjjy6aKX2"
    "oXOtDRaEQmuE5bloPP+aRHn7NC9HDNKUPPUEPvTX0QFwrlMC/4AtVgbuavF/j/NNN68A3Ix00YC"
    "E6mKf041jox3GBvqA7htV6tt/c08MOjz0UOcWNTgrQyfdYJ6d/RycnQj9OCtUJa3W7nT1ArgvlR"
    "icF6ORbrBPtP/ATOiEdA7tWoX7SKEQnee5BNtWBwewzqBstvT8cHgn3oN/3lV++"
    );
  mxArray *mxChecksum = mxCreateDoubleMatrix(1, 4, mxREAL);
  sf_c1_ATTN_get_check_sum(&mxChecksum);
  mxSetField(mxInfo, 0, infoFields[0], mxChecksum);
  mxSetField(mxInfo, 0, infoFields[1], mxVarInfo);
  return mxInfo;
}

static const char* sf_get_instance_specialization(void)
{
  return "sFpT6RN7I5n25K3lkQTHoKH";
}

static void sf_opaque_initialize_c1_ATTN(void *chartInstanceVar)
{
  initialize_params_c1_ATTN((SFc1_ATTNInstanceStruct*) chartInstanceVar);
  initialize_c1_ATTN((SFc1_ATTNInstanceStruct*) chartInstanceVar);
}

static void sf_opaque_enable_c1_ATTN(void *chartInstanceVar)
{
  enable_c1_ATTN((SFc1_ATTNInstanceStruct*) chartInstanceVar);
}

static void sf_opaque_disable_c1_ATTN(void *chartInstanceVar)
{
  disable_c1_ATTN((SFc1_ATTNInstanceStruct*) chartInstanceVar);
}

static void sf_opaque_gateway_c1_ATTN(void *chartInstanceVar)
{
  sf_gateway_c1_ATTN((SFc1_ATTNInstanceStruct*) chartInstanceVar);
}

static const mxArray* sf_opaque_get_sim_state_c1_ATTN(SimStruct* S)
{
  return get_sim_state_c1_ATTN((SFc1_ATTNInstanceStruct *)
    sf_get_chart_instance_ptr(S));     /* raw sim ctx */
}

static void sf_opaque_set_sim_state_c1_ATTN(SimStruct* S, const mxArray *st)
{
  set_sim_state_c1_ATTN((SFc1_ATTNInstanceStruct*)sf_get_chart_instance_ptr(S),
                        st);
}

static void sf_opaque_cleanup_runtime_resources_c1_ATTN(void *chartInstanceVar)
{
  if (chartInstanceVar!=NULL) {
    SimStruct *S = ((SFc1_ATTNInstanceStruct*) chartInstanceVar)->S;
    if (sim_mode_is_rtw_gen(S) || sim_mode_is_external(S)) {
      sf_clear_rtw_identifier(S);
      unload_ATTN_optimization_info();
    }

    mdl_cleanup_runtime_resources_c1_ATTN((SFc1_ATTNInstanceStruct*)
      chartInstanceVar);
    utFree(chartInstanceVar);
    if (ssGetUserData(S)!= NULL) {
      sf_free_ChartRunTimeInfo(S);
    }

    ssSetUserData(S,NULL);
  }
}

static void sf_opaque_mdl_start_c1_ATTN(void *chartInstanceVar)
{
  mdl_start_c1_ATTN((SFc1_ATTNInstanceStruct*) chartInstanceVar);
  if (chartInstanceVar) {
    sf_reset_warnings_ChartRunTimeInfo(((SFc1_ATTNInstanceStruct*)
      chartInstanceVar)->S);
  }
}

static void sf_opaque_mdl_terminate_c1_ATTN(void *chartInstanceVar)
{
  mdl_terminate_c1_ATTN((SFc1_ATTNInstanceStruct*) chartInstanceVar);
}

extern unsigned int sf_machine_global_initializer_called(void);
static void mdlProcessParameters_c1_ATTN(SimStruct *S)
{
  int i;
  for (i=0;i<ssGetNumRunTimeParams(S);i++) {
    if (ssGetSFcnParamTunable(S,i)) {
      ssUpdateDlgParamAsRunTimeParam(S,i);
    }
  }

  sf_warn_if_symbolic_dimension_param_changed(S);
  if (sf_machine_global_initializer_called()) {
    initialize_params_c1_ATTN((SFc1_ATTNInstanceStruct*)
      sf_get_chart_instance_ptr(S));
    initSubchartIOPointersc1_ATTN((SFc1_ATTNInstanceStruct*)
      sf_get_chart_instance_ptr(S));
  }
}

const char* sf_c1_ATTN_get_post_codegen_info(void)
{
  int i;
  const char* encStrCodegen [34] = {
    "eNrtWk1vG0UY3oQ0EDUJbVrRCxIVohJCKk4T2rSohTiOTU3zReyUqrRyJ7uvvaPMzmxnZh2n4pA",
    "jnOiBKxInzvwE/gI37lyQ4NBjj8zsrp3N2q13NyYxVVdynNn1MzPPO8/7MbtrjJRXDXVMq8+9Oc",
    "MYV99vqc+oERynwvZI5BOcHzNuhu1vTxuGySxoAK149TpuGekO6jkbiCNHGOkPihzYBMGIJzGjZ",
    "VpnybGY1oEDNVUHLuMy1bgCOx7BdKfkUVOPLL62sWlXbOYRa0l1iKx1SvZeNK7ryQ014jLmYMoS",
    "gCVtzryGXSKo8XIrcLlbsMHcEZ6T2lYCZMVzNVWx6hGJXQLFFphlKiRSVhB9+FYkklCQrXRG1nx",
    "FpY1mjkswosltbSNRAVepQ8KWa6m/655U1kuENW3E5RLYqAliBe/4ozMKiUbHQv16G1MkGceIFB",
    "1S0L0l5LtBFMdV5RIk7Ropvksc0I7LMJUpHaJSUnYuUrRNYBm2vUbKcSvw2NPecBfDLvB061svs",
    "CZw1IB1mm7O/hoVW74oO76UECuxA3cRz5tKuwKsdHFDOZ2oICVHqKpuUmHBN3FZVDluKm2kjXVl",
    "7f6ZYp3nBOoXmbD+uMUmpNZVZ9ySSQuIEJEOW2XuCjSB+OMvI4kyYIPxU4CFwFaVKXXoaJMyYnk",
    "UK08IsQVGLZxclc0Yyk9saypJJYBjR7sBWMrMnal3OurnR56QzCmokLO8spJwvG5smUrgdWRC4h",
    "zDERagJuzrKuW4FhbakRRaWUn6LBP3EPhgJqgh6h5d3mV8R9k4bTI7sJX2hHRosBoqMEvwg1xRq",
    "fsuIl7COTuiofxHyWNLqCibblyF1f6TCWwi0wZLZ05MYFXFWdVB0iUWOuXnFdsmlnvLIEyO3aSe",
    "5KmArpKutlJ1z4UtukPZLi1x5lTCyuslugJQUQNximljSaVwvldSk082aw6Pq350T1vkaDsjSdC",
    "21sYXQFU21Fx11YBM5VVFqkpkNaGjYCv4iSpiqMBCqkS9F6T6IO/p+v26cVC/j/Wo39+M1O9nwr",
    "Z5pZavVtd8/GwEP5mg/m+P++sb6fYNU2H7Bz0+UyGnJQ+K+YNVZI5aOyr18qtlUSV+M+Rax0HSr",
    "kQba7rllCKXOg19Sf/vB7WKCmrcjoiBRBtddojbsX1E7djG3e5j/7Mx3Fm/DmmotW5CDVpujSNq",
    "Rfrrt57jsf7Gfat5ShMB3u6DX4jhdfub4sOczRzIAVFxirOclmRNb5By9HJhfbNabOW65vyx0zX",
    "ft/voYCo8//3kFvTimxRvvMBeJ4Hvt/7vxOyt20tPzAoXLRXs8pI0xTa6v+mWSkF/H0b6G+nRX1",
    "SHWX6fFRflOTF6+PczMTuNts91HQf9LUb6m4qNPxbrbzy03YObv5ydvfz3n7//dKn84z+XduN+G",
    "5/XSNe8Rvz/Ne7ZhXTxazpsv9vev3SqpWZXQZFEFxdiutBtUXKr1zbXFspX6dzVO/Nk56vqbXbn",
    "dmCvPvM9H5tv+/xFvWfS0VT3z82yFQm5yAv29XE/GO9jj4lDfvDs86Ph5xbjeuhlr9Mxe53284i",
    "na9caC+8NTL/Ar4+XzyeJ+EzE+Ez4NQxBex02w8Ln00R8zsT46A+BuqxJjhuNYJGGg8/7ifhMxf",
    "joNmEmIrq4CNdoOPh8lIjPZIyPblO3RUTefNyW3HDwuZmdj+esYBWUh4tPMRGf6Rgf3VZVP8gqo",
    "+A70ZDw2S8sJslv52J8zvn7rF3ErZrlBVudIYvbtxLxmonxmjngFYl0wxS/byxm3acoPrbspjUk",
    "vM5nzrP+PYph47O/nHmdhMROt1cNyzp9kDmeS/0UZs1zhiue5zPH810kahLxBsiA0WD4nFk8Gj7",
    "7fQcHpM2sAL8xkm4/NRrplxjYcHvsC3vxGI3xaN+LMe7tL/rf3+0vDkIf+33s8WXMHrqd8wTP+U",
    "VibjVfXckv5TbnZufmUU4yRrZZKwcOyRG8nQtu/OX0bZS6R3Mux00VkfTl9q2VodHFbB87jB2yw",
    "5ghACx/HU9aD389DfTw/OlA9OD2scOtmB5uHUEPnDZ8Cfwf4sKpGO9T7fwa4h+dtA72rUAHF2Eg",
    "Onjaxx4PYvZ4MMC4UHPMxpVr12cXar6F6x4JIsVrnQxAJ7+FOnl0PDp5GLPHw4HqRF65cWN+AfH",
    "DQnmtkwHo5OdQJ4uvQDwRNp83GW0MNJ5cHIhOsuyDsKgh039I1X7C2b0Pyvq8IC3OeI17jTsGXC",
    "99JnmOP5MRN50RZxwz7qj8/uvnsMP2+6zvPwwbj5fF+8kevEZi/Q4rrz+MdHXPe2H7s857kQUbE",
    "6vHm1nh5RVA9V5XXxF9P09pv/bz+aK2X/gC/f35PEVkT+Dg5aH26Q2u34PuXOKARO/33U4inxyl",
    "7t6qli5fP0Je+hfeqKnO",
    ""
  };

  static char newstr [2421] = "";
  newstr[0] = '\0';
  for (i = 0; i < 34; i++) {
    strcat(newstr, encStrCodegen[i]);
  }

  return newstr;
}

static void mdlSetWorkWidths_c1_ATTN(SimStruct *S)
{
  const char* newstr = sf_c1_ATTN_get_post_codegen_info();
  sf_set_work_widths(S, newstr);
  ssSetChecksum0(S,(296107100U));
  ssSetChecksum1(S,(3823840560U));
  ssSetChecksum2(S,(1227202001U));
  ssSetChecksum3(S,(1998974100U));
}

static void mdlRTW_c1_ATTN(SimStruct *S)
{
  if (sim_mode_is_rtw_gen(S)) {
    ssWriteRTWStrParam(S, "StateflowChartType", "Embedded MATLAB");
  }
}

static void mdlSetupRuntimeResources_c1_ATTN(SimStruct *S)
{
  SFc1_ATTNInstanceStruct *chartInstance;
  chartInstance = (SFc1_ATTNInstanceStruct *)utMalloc(sizeof
    (SFc1_ATTNInstanceStruct));
  if (chartInstance==NULL) {
    sf_mex_error_message("Could not allocate memory for chart instance.");
  }

  memset(chartInstance, 0, sizeof(SFc1_ATTNInstanceStruct));
  chartInstance->chartInfo.chartInstance = chartInstance;
  if (ssGetSampleTime(S, 0) == CONTINUOUS_SAMPLE_TIME && ssGetOffsetTime(S, 0) ==
      0 && sfHasContStates(S)> 0 &&
      !supportsLegacyBehaviorForPersistentVarInContinuousTime(S)) {
    sf_error_out_about_continuous_sample_time_with_persistent_vars(S);
  }

  chartInstance->chartInfo.isEMLChart = 1;
  chartInstance->chartInfo.chartInitialized = 0;
  chartInstance->chartInfo.sFunctionGateway = sf_opaque_gateway_c1_ATTN;
  chartInstance->chartInfo.initializeChart = sf_opaque_initialize_c1_ATTN;
  chartInstance->chartInfo.mdlStart = sf_opaque_mdl_start_c1_ATTN;
  chartInstance->chartInfo.mdlTerminate = sf_opaque_mdl_terminate_c1_ATTN;
  chartInstance->chartInfo.mdlCleanupRuntimeResources =
    sf_opaque_cleanup_runtime_resources_c1_ATTN;
  chartInstance->chartInfo.enableChart = sf_opaque_enable_c1_ATTN;
  chartInstance->chartInfo.disableChart = sf_opaque_disable_c1_ATTN;
  chartInstance->chartInfo.getSimState = sf_opaque_get_sim_state_c1_ATTN;
  chartInstance->chartInfo.setSimState = sf_opaque_set_sim_state_c1_ATTN;
  chartInstance->chartInfo.getSimStateInfo = sf_get_sim_state_info_c1_ATTN;
  chartInstance->chartInfo.zeroCrossings = NULL;
  chartInstance->chartInfo.outputs = NULL;
  chartInstance->chartInfo.derivatives = NULL;
  chartInstance->chartInfo.mdlRTW = mdlRTW_c1_ATTN;
  chartInstance->chartInfo.mdlSetWorkWidths = mdlSetWorkWidths_c1_ATTN;
  chartInstance->chartInfo.extModeExec = NULL;
  chartInstance->chartInfo.restoreLastMajorStepConfiguration = NULL;
  chartInstance->chartInfo.restoreBeforeLastMajorStepConfiguration = NULL;
  chartInstance->chartInfo.storeCurrentConfiguration = NULL;
  chartInstance->chartInfo.callAtomicSubchartUserFcn = NULL;
  chartInstance->chartInfo.callAtomicSubchartAutoFcn = NULL;
  chartInstance->chartInfo.callAtomicSubchartEventFcn = NULL;
  chartInstance->S = S;
  chartInstance->chartInfo.dispatchToExportedFcn = NULL;
  sf_init_ChartRunTimeInfo(S, &(chartInstance->chartInfo), false, 0,
    chartInstance->c1_JITStateAnimation,
    chartInstance->c1_JITTransitionAnimation);
  init_dsm_address_info(chartInstance);
  init_simulink_io_address(chartInstance);
  if (!sim_mode_is_rtw_gen(S)) {
  }

  mdl_setup_runtime_resources_c1_ATTN(chartInstance);
}

void c1_ATTN_method_dispatcher(SimStruct *S, int_T method, void *data)
{
  switch (method) {
   case SS_CALL_MDL_SETUP_RUNTIME_RESOURCES:
    mdlSetupRuntimeResources_c1_ATTN(S);
    break;

   case SS_CALL_MDL_SET_WORK_WIDTHS:
    mdlSetWorkWidths_c1_ATTN(S);
    break;

   case SS_CALL_MDL_PROCESS_PARAMETERS:
    mdlProcessParameters_c1_ATTN(S);
    break;

   default:
    /* Unhandled method */
    sf_mex_error_message("Stateflow Internal Error:\n"
                         "Error calling c1_ATTN_method_dispatcher.\n"
                         "Can't handle method %d.\n", method);
    break;
  }
}
