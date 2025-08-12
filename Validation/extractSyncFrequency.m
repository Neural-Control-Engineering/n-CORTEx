function F = extractSyncFrequency(synchTitle)
    F = split(synchTitle,"_");
    F = convertCharsToStrings(F{2});
    F = strrep(F,"Hz","");
    F = str2double(F);
end