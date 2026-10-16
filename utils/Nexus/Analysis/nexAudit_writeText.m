function nexAudit_writeText(auditDir, relPath, content)
% nexAudit_writeText  Write text content to <auditDir>/<relPath>, creating
% parent directories as needed. Small shared helper for nexAnalysis_cvPermute's
% opt-in audit trail (cvCfg.auditDir) — every audit call site uses this
% instead of hand-rolling fopen/mkdir, so the directory layout stays
% consistent and callers stay one-liners.
%
%   nexAudit_writeText(auditDir, 'combo_L-hind-paw/summary.txt', txt)
    fullPath = fullfile(auditDir, relPath);
    d = fileparts(fullPath);
    if ~isempty(d) && ~isfolder(d), mkdir(d); end
    fid = fopen(fullPath, 'w');
    if fid == -1
        warning('[nexAudit_writeText] could not open %s for writing.', fullPath);
        return;
    end
    fprintf(fid, '%s', content);
    fclose(fid);
end
