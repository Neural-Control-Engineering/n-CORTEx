function stopNcortexHeartbeat(app)
% stopNcortexHeartbeat  Stop and clear the ncortex keep-alive timer.
% Safe to call when no timer is running. See startNcortexHeartbeat.

    if isfield(app.params, "heartbeatTimer") && ~isempty(app.params.heartbeatTimer) ...
            && isa(app.params.heartbeatTimer, "timer") && isvalid(app.params.heartbeatTimer)
        stop(app.params.heartbeatTimer);
        delete(app.params.heartbeatTimer);
    end
    app.params.heartbeatTimer = [];
end
