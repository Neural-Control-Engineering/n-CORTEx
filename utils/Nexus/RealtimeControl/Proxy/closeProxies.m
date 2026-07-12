function closeProxies(proxon)
    prxtype1 = fieldnames(proxon.index_type1);
    prxtype2 = fieldnames(proxon.index_type2);
    prxObjFields = [prxtype1; prxtype2];
    proxObjs = mergeStructs(proxon.index_type1, proxon.index_type2);
    for i = 1:length(prxObjFields)
        proxObjName = prxObjFields{i};
        proxObj = proxObjs.(proxObjName);
        if isprop(proxObj,"Server") && isa(proxObj.Server,"tcpserver.internal.TCPServer")
            try
                delete(proxObj.Server);   % releases the OS socket/port
                proxObj.Server = [];
                fprintf("closing %s\n", proxObjName);
            catch e
                disp(getReport(e));
            end
        end
    end

end