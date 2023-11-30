/* Main generated for Simulink Real-Time model ATTN */
#include <ModelInfo.hpp>
#include <utilities.hpp>
#include "ATTN.h"
#include "rte_ATTN_parameters.h"

/* Task descriptors */
<<<<<<< HEAD
slrealtime::TaskInfo task_1( 0u, std::bind(ATTN_step), slrealtime::TaskInfo::PERIODIC, 0.001, 0, 40);
=======
slrealtime::TaskInfo task_1( 0u, std::bind(ATTN_step0), slrealtime::TaskInfo::PERIODIC, 0.001, 0, 40);
slrealtime::TaskInfo task_2( 1u, std::bind(ATTN_step2), slrealtime::TaskInfo::PERIODIC, 1000, 0, 39);
>>>>>>> ATTN_integration

/* Executable base address for XCP */
#ifdef __linux__
extern char __executable_start;
static uintptr_t const base_address = reinterpret_cast<uintptr_t>(&__executable_start);
#else
/* Set 0 as placeholder, to be parsed later from /proc filesystem */
static uintptr_t const base_address = 0;
#endif

/* Model descriptor */
slrealtime::ModelInfo ATTN_Info =
{
    "ATTN",
    ATTN_initialize,
    ATTN_terminate,
    []()->char const*& { return ATTN_M->errorStatus; },
    []()->unsigned char& { return ATTN_M->Timing.stopRequestedFlag; },
<<<<<<< HEAD
    { task_1 },
=======
    { task_1, task_2 },
>>>>>>> ATTN_integration
    slrealtime::getSegmentVector()
};

int main(int argc, char *argv[]) {
    slrealtime::BaseAddress::set(base_address);
    return slrealtime::runModel(argc, argv, ATTN_Info);
}
