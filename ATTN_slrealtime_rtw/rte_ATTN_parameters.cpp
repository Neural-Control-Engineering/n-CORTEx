#include "rte_ATTN_parameters.h"
#include "ATTN.h"
#include "ATTN_cal.h"

extern ATTN_cal_type ATTN_cal_impl;
namespace slrealtime
{
  /* Description of SEGMENTS */
  SegmentVector segmentInfo {
    { (void*)&ATTN_cal_impl, (void**)&ATTN_cal, sizeof(ATTN_cal_type), 2 }
  };

  SegmentVector &getSegmentVector(void)
  {
    return segmentInfo;
  }
}                                      // slrealtime
