function closeProxies(proxon)
    prxtype1 = fieldnames(proxon.index_type1);
    prxtype2 = fieldnames(proxon.index_type2);
    prxObjFields = [prxtype1; prxtype2];
    proxObjs = mergeStructs(proxon.index_type1, proxon.index_type2);
    for i = 1:length(prxObjFields)
        proxObjName = prxObjFields{i};
        proxObj = proxObjs.(proxObjName);
        % Stop any off-thread work this proxy runs (timers, sidecar sockets)
        % before the app tears down. proxy_npxls holds live timers
        % (writeBuffer/capTimer) and the rtSort client socket that must be
        % released here or they keep firing / leak the port. Mirrors the
        % host-relayed closeAllRealtimeThreads path.
        if ismethod(proxObj,"closeAllRealtimeThreads")
            try, proxObj.closeAllRealtimeThreads([],[]); catch e, disp(getReport(e)); end
        end
        % NOTE: the slrt/ncortex command tcpservers are deliberately NOT torn
        % down here. They are persistent listeners that the next cortex("target")
        % re-adopts via proxy.buildServer (groot registry). Deleting one would
        % neither free the OS port (MATLAB won't release it while a dropped peer
        % socket lingers in CLOSE_WAIT) nor permit a clean re-bind next launch —
        % reuse is the only reliable path. See proxy_slrt/proxy_ncortex.buildServer.
    end

end