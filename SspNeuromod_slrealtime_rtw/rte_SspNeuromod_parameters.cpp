#include "rte_SspNeuromod_parameters.h"
#include "SspNeuromod.h"
#include "SspNeuromod_cal.h"

extern SspNeuromod_cal_type SspNeuromod_cal_impl;
namespace slrealtime
{
  /* Description of SEGMENTS */
  SegmentVector segmentInfo {
    { (void*)&SspNeuromod_cal_impl, (void**)&SspNeuromod_cal, sizeof
      (SspNeuromod_cal_type), 2 }
  };

  SegmentVector &getSegmentVector(void)
  {
    return segmentInfo;
  }
}                                      // slrealtime
