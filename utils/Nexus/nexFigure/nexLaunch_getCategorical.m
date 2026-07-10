function ctg = nexLaunch_getCategorical(nexon, dfID)
% nexLaunch_getCategorical  One categorical hub per dfID, built on first use.
%
% Returns the session's categorical for dfID, constructing it lazily the first
% time that source is launched and caching it on the nexon so every subsequent
% figure launched on the same dfID shares one hub (one STAT compile, one
% category/item selection surface). Rebuilds if the cached hub's window was
% closed.
%
% Cache lives at nexon.UserData.launchCategoricals (containers.Map keyed by the
% raw dfID string, so ids containing '--' are safe).

    key = char(string(dfID));

    if ~isfield(nexon.UserData, 'launchCategoricals') || ...
            ~isa(nexon.UserData.launchCategoricals, 'containers.Map')
        nexon.UserData.launchCategoricals = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    store = nexon.UserData.launchCategoricals;   % handle — updates in place

    if isKey(store, key)
        ctg = store(key);
        if isvalid(ctg) && ctgFigureAlive(ctg)
            return;
        end
    end

    ctg = nexObj_categorical(nexon, [], string(dfID), [], []);
    store(key) = ctg;
end

function alive = ctgFigureAlive(ctg)
    alive = false;
    try
        alive = isvalid(ctg.Figure.fh);
    catch
    end
end
