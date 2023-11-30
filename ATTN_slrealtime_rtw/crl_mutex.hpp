/* Copyright 2018-2019 The MathWorks, Inc. */

/* File: crl_mutex.hpp
 *
 * Abstract:
 *  Implement mutex and semaphore for Simulink Real-Time CRL
 */

#ifndef crl_mutex_hpp
#define crl_mutex_hpp

void rtw_slrealtime_mutex_init(void** mutexDW);
void rtw_slrealtime_mutex_lock(void* mutexDW);
void rtw_slrealtime_mutex_unlock(void* mutexDW);
void rtw_slrealtime_mutex_destroy(void* mutexDW);

void rtw_slrealtime_sem_init(void** semaphoreDW, unsigned int initVal);
void rtw_slrealtime_sem_wait(void* semaphoreDW );
void rtw_slrealtime_sem_post(void* semaphoreDW );
void rtw_slrealtime_sem_destroy(void* semaphoreDW );

#endif

