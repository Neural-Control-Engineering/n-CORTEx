/* Main generated for Simulink Real-Time model nCORTEx_vt */
#include <ModelInfo.hpp>
#include <utilities.hpp>
#include "nCORTEx_vt.h"
#include "rte_nCORTEx_vt_parameters.h"

/* Task descriptors */
slrealtime::TaskInfo task_1( 0u, std::bind(nCORTEx_vt_step), slrealtime::TaskInfo::PERIODIC, 0.001, 0, 40);

/* Executable base address for XCP */
#ifdef __linux__
extern char __executable_start;
static uintptr_t const base_address = reinterpret_cast<uintptr_t>(&__executable_start);
#else
/* Set 0 as placeholder, to be parsed later from /proc filesystem */
static uintptr_t const base_address = 0;
#endif

/* Model descriptor */
slrealtime::ModelInfo nCORTEx_vt_Info =
{
    "nCORTEx_vt",
    nCORTEx_vt_initialize,
    nCORTEx_vt_terminate,
    []()->char const*& { return nCORTEx_vt_M->errorStatus; },
    []()->unsigned char& { return nCORTEx_vt_M->Timing.stopRequestedFlag; },
    { task_1 },
    slrealtime::getSegmentVector()
};

int main(int argc, char *argv[]) {
    slrealtime::BaseAddress::set(base_address);
    return slrealtime::runModel(argc, argv, nCORTEx_vt_Info);
}
