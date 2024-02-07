/* Main generated for Simulink Real-Time model SspNeuromod */
#include <ModelInfo.hpp>
#include <utilities.hpp>
#include "SspNeuromod.h"
#include "rte_SspNeuromod_parameters.h"

/* Task descriptors */
slrealtime::TaskInfo task_1( 0u, std::bind(SspNeuromod_step), slrealtime::TaskInfo::PERIODIC, 0.001, 0, 40);

/* Executable base address for XCP */
#ifdef __linux__
extern char __executable_start;
static uintptr_t const base_address = reinterpret_cast<uintptr_t>(&__executable_start);
#else
/* Set 0 as placeholder, to be parsed later from /proc filesystem */
static uintptr_t const base_address = 0;
#endif

/* Model descriptor */
slrealtime::ModelInfo SspNeuromod_Info =
{
    "SspNeuromod",
    SspNeuromod_initialize,
    SspNeuromod_terminate,
    []()->char const*& { return SspNeuromod_M->errorStatus; },
    []()->unsigned char& { return SspNeuromod_M->Timing.stopRequestedFlag; },
    { task_1 },
    slrealtime::getSegmentVector()
};

int main(int argc, char *argv[]) {
    slrealtime::BaseAddress::set(base_address);
    return slrealtime::runModel(argc, argv, SspNeuromod_Info);
}
