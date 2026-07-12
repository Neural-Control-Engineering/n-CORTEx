function nexObj = nexLaunch(nexon, dfID, figType)
% nexLaunch  Launch one Nexus figure on a DF source. The atomic primitive.
%
%   nexObj = nexLaunch(nexon, dfID, figType)
%
% Builds (or reuses) the source's categorical hub and constructs the named
% figure on it — the exact backend the INSPECT panel's Launch button runs, and
% the unit that nexLaunch_auto composes for pipeline automation. Drop this call
% anywhere you want a figure to appear.
%
%   dfID    : DF source id present in the DTS (e.g. "lfp", "RTS_spk_activity_df")
%   figType : a fieldname of nexLaunch_registry (e.g. "monoGraph", "monoGram")
%
% Returns the constructed nexObj, or errors if figType is not registered.

    reg     = nexLaunch_registry();
    figType = char(figType);
    if ~isfield(reg, figType)
        error("nexLaunch:unknownFigure", ...
            "'%s' is not a registered figure. Available: %s", ...
            figType, strjoin(string(fieldnames(reg)), ", "));
    end
    ctg    = nexLaunch_getCategorical(nexon, dfID);
    nexObj = reg.(figType)(ctg);
    nexRegister_figure(nexon, nexObj);   % reachable registry for router traversal
end
