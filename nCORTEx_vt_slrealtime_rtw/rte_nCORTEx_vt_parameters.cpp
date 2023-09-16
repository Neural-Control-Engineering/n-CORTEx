#include "rte_nCORTEx_vt_parameters.h"
#include "nCORTEx_vt.h"
#include "nCORTEx_vt_cal.h"

extern nCORTEx_vt_cal_type nCORTEx_vt_cal_impl;
namespace slrealtime
{
  /* Description of SEGMENTS */
  SegmentVector segmentInfo {
    { (void*)&nCORTEx_vt_cal_impl, (void**)&nCORTEx_vt_cal, sizeof
      (nCORTEx_vt_cal_type), 2 }
  };

  SegmentVector &getSegmentVector(void)
  {
    return segmentInfo;
  }
}                                      // slrealtime
