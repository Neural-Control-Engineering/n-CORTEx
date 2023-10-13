#include "rte_JOLT_parameters.h"
#include "JOLT.h"
#include "JOLT_cal.h"

extern JOLT_cal_type JOLT_cal_impl;
namespace slrealtime
{
  /* Description of SEGMENTS */
  SegmentVector segmentInfo {
    { (void*)&JOLT_cal_impl, (void**)&JOLT_cal, sizeof(JOLT_cal_type), 2 }
  };

  SegmentVector &getSegmentVector(void)
  {
    return segmentInfo;
  }
}                                      // slrealtime
