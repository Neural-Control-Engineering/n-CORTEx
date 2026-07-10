function startNcortexHeartbeat(app, periodSec)
% startNcortexHeartbeat  Keep the host->target ncortex link warm.
%
%   startNcortexHeartbeat(app)            % 30 s period
%   startNcortexHeartbeat(app, periodSec)
%
% The host reaches the target over a routed/NAT'd, Wi-Fi-uplinked path
% (ip route get <target> = "via <gw> dev wlo1"). Every stateful hop on that
% path — NAT/conntrack at the gateway, campus ARP, Wi-Fi power save — ages its
% state out on idle (~5-15 min), after which the link goes unreachable until
% the target is rebooted. This timer sends a benign "heartbeat" transmission to
% every connected target on a period well under those timeouts, so the flow
% never idles long enough to be evicted. Round-trip (host writes / target acks)
% keeps the state warm in both directions.
%
% Pair with stopNcortexHeartbeat(app) on disconnect / app close. Requires the
% target-side proxy_ncortex.heartbeat method.

    if nargin < 2 || isempty(periodSec), periodSec = 30; end

    stopNcortexHeartbeat(app);   % never run two

    t = timer("ExecutionMode","fixedRate", "BusyMode","drop", ...
              "Period", periodSec, "Name","ncortexHeartbeat", ...
              "TimerFcn", @(~,~) ncortexHeartbeat_tick(app));
    app.params.heartbeatTimer = t;
    start(t);
end
