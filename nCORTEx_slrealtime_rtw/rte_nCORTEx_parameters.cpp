#include "rte_nCORTEx_parameters.h"
#include "nCORTEx.h"
#include "nCORTEx_cal.h"

extern nCORTEx_cal_type nCORTEx_cal_impl;
namespace slrealtime
{
  /* Description of SEGMENTS */
  SegmentVector segmentInfo {
    { (void*)&nCORTEx_cal_impl, (void**)&nCORTEx_cal, sizeof(nCORTEx_cal_type),
      2 }
  };

  SegmentVector &getSegmentVector(void)
  {
    return segmentInfo;
  }
}                                      // slrealtime
