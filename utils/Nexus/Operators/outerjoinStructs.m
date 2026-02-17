function SJ = outerjoinStructs(S1, S2)
    fields = convertCharsToStrings(fieldnames(S1))';
    SJ=struct;
    % values = cellfun(@(f) myFunction(S1.(f), S2.(f)), fields, 'UniformOutput', false);
    % values = cellfun(@(f) SJ.(S1.(f)) = S2.(f), fields, 'UniformOutput', false);
    for f = fields
        Key = S1.(f);
        % safe formatting
        Key = strrep(Key,"--","_");
        SJ.(Key) = S2.(f);
    end    

end