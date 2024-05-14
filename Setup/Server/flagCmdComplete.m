function flagCmdComplete(sgSrv, PVrx)    
    write(sgSrv, PVrx);
    write(sgSrv, zeros(size(PVrx,1),1));
end