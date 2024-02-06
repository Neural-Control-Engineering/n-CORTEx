#include "rte_DEV2P_parameters.h"
#include "DEV2P.h"
#include "DEV2P_cal.h"

extern DEV2P_cal_type DEV2P_cal_impl;
namespace slrealtime
{
  /* Description of SEGMENTS */
  SegmentVector segmentInfo {
    { (void*)&DEV2P_cal_impl, (void**)&DEV2P_cal, sizeof(DEV2P_cal_type), 2 }
  };

  SegmentVector &getSegmentVector(void)
  {
    return segmentInfo;
  }
}                                      // slrealtime
