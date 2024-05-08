function delayCmdReturn(sgSrv, PVrx, delay)    
    cmdTimer = timer("ExecutionMode","SingleShot","StartDelay",delay,"TimerFcn",@(~,~)flagCmdComplete(sgSrv,PVrx));
    start(cmdTimer);
end