tg=slrealtime
tg.ProfilerStatus
tg.connect
tg.ProfilerStatus

slbuild('nCORTEx')
load(tg,'nCORTEx')
start(tg)

stop(tg)
tg.disconnect
tg.ProfilerStatus