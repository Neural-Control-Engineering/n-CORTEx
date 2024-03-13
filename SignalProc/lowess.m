function lws = lowess(raw)
    lws = [];
    % raw = raw';
    % span = 0.12;
    span = 0.02
    t = [1:length(raw)]';
    X = [raw, t];
    if ~isnan(raw)
        % fit(t,raw,'lowess')        
        lws = fLOESS(raw,span);
        % mslowess(raw, t')
    end
end