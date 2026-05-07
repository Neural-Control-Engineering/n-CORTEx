function STAT = nexOp_sessionLabel_brainSense(STAT)
    try
        dates  = datetime(STAT.DateTime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''');
    catch
        try
            dates = datetime(STAT.FirstPacketDateTime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''');
        catch
            dates = datetime(STAT.FirstPacketDateTime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''');
        end
    end
    dateStrs = string(datestr(dates, 'yyyy-mm-dd'));
    subj   = cellfun(@(s) strrep(s, 'SUBJ', ''), STAT.SubjectName, 'UniformOutput', false);
    subj   = string(subj);
    site = STAT.Hemisphere;
    if iscell(site)
        site = convertCharsToStrings(site);
    end
    phase  = repmat("CA", height(STAT), 1);   % clinical assessment
    STAT.sessionLabel = arrayfun(@(d, s, p, l) sprintf('date--%s_subj--%s_phase--%s_site--%s', d, s, p, l), ...
                                 dateStrs, subj, phase, site, "UniformOutput", false);
end