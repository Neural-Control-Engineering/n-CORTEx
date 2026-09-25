function obj = nexLaunchAdapt_fitScope(ctg)
% Launch adapter: build nexObj_fitScope from the categorical hub. Auto-
% discovered by nexLaunch_registry (figType = "fitScope").
%
% dfID_source is the raw PSD patch (e.g. an rtPMTM dfID); dfID_ap/dfID_pe
% default to "specparam_ap_"/"specparam_pe_" + dfID_source — the same
% naming convention nexObj_fitScope.saveFit itself writes new output
% patches under (see nexObj_channelGram.mlio_writeDS's own call site for
% the same pattern). Edit here if your AP/PE fit patches for this source
% live under different names.
%
% Requires an active router trial selection — nexObj_fitScope reads the
% CURRENT trial (nex_getRouterIdx), not the whole DTS.
    dfID_ap = "specparam_ap_" + string(ctg.dfID_source);
    dfID_pe = "specparam_pe_" + string(ctg.dfID_source);
    obj = nexObj_fitScope(ctg, ctg.dfID_source, dfID_ap, dfID_pe);
end
