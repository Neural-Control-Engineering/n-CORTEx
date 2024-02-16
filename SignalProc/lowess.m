function lws = lowess(raw)
    lws = [];
    % raw = raw';
    t = [1:length(raw)]';
    X = [raw, t];
    if ~isnan(raw)
        % fit(t,raw,'lowess')        
        lws = fLOESS(raw,0.12);
        % mslowess(raw, t')
    end
end