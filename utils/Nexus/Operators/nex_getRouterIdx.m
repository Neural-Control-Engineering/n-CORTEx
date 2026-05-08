function idxCond = nex_getRouterIdx(nexon)
    DTS    = nexon.console.BASE.DTS;
    ep     = nexon.console.BASE.router.entryParams;
    labels = DTS.sessionLabel;

    % Normalize subject → subj so iteration only sees one name
    if isfield(ep, 'subject') && ~isfield(ep, 'subj')
        ep.subj = ep.subject;
    end

    % 'trial' → numeric match on trialNumber; 'subject' → collapsed alias above
    skipFields = ["trial", "subject"];

    idxCond = true(height(DTS), 1);
    for f = string(fieldnames(ep))'
        if ismember(f, skipFields), continue; end
        val = string(ep.(f));
        if isempty(val) || val == "", continue; end
        idxCond = idxCond & contains(labels, val);
    end

    % Trial: exact numeric match
    if isfield(ep, 'trial') && ~isempty(ep.trial)
        idxCond = idxCond & (str2double(ep.trial) == DTS.trialNumber);
    end
end