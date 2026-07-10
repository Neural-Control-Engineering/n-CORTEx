function ncortexHeartbeat_tick(app)
% ncortexHeartbeat_tick  One keep-alive round to every connected target.
% Timer callback for startNcortexHeartbeat. Sends the benign "heartbeat"
% method over each target's cortexClient so the idle-sensitive link stays warm.

    % Guard the shared command socket: skip if a real transmission is in flight.
    % (Set app.params.txBusy true/false around command sends to arm this — see
    % startNcortexHeartbeat header. Without it the guard is simply inactive; the
    % heartbeat is a valid transmission on its own, it just isn't serialized
    % against concurrent user commands.)
    if isfield(app.params, "txBusy") && isequal(app.params.txBusy, true)
        return;
    end

    if ~isfield(app.params, "connectedClients") || isempty(app.params.connectedClients)
        return;
    end
    targets = app.params.connectedClients;

    for i = 1:numel(targets)
        target = targets(i);
        if ~isprop(app, target) && ~isfield(app, target), continue; end
        if ~isfield(app.(target), "cortexClient") || ~isvalid(app.(target).cortexClient)
            continue;
        end
        client = app.(target).cortexClient;
        try
            hb.stamp = datetime("now");                     % non-empty payload
            writeTransmission_helper(client, "heartbeat", hb);
        catch e
            fprintf("[heartbeat] %s link unreachable: %s\n", target, e.message);
        end
    end
end
