/* Main generated for Simulink Real-Time model DEV2P */
#include <ModelInfo.hpp>
#include <utilities.hpp>
#include "DEV2P.h"
#include "rte_DEV2P_parameters.h"

/* Task descriptors */
slrealtime::TaskInfo task_1( 0u, std::bind(DEV2P_step), slrealtime::TaskInfo::PERIODIC, 0.001, 0, 40);

/* Executable base address for XCP */
#ifdef __linux__
extern char __executable_start;
static uintptr_t const base_address = reinterpret_cast<uintptr_t>(&__executable_start);
#else
/* Set 0 as placeholder, to be parsed later from /proc filesystem */
static uintptr_t const base_address = 0;
#endif

/* Model descriptor */
slrealtime::ModelInfo DEV2P_Info =
{
    "DEV2P",
    DEV2P_initialize,
    DEV2P_terminate,
    []()->char const*& { return DEV2P_M->errorStatus; },
    []()->unsigned char& { return DEV2P_M->Timing.stopRequestedFlag; },
    { task_1 },
    slrealtime::getSegmentVector()
};

int main(int argc, char *argv[]) {
    slrealtime::BaseAddress::set(base_address);
    return slrealtime::runModel(argc, argv, DEV2P_Info);
}
