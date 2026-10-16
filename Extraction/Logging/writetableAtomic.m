function writetableAtomic(T, filepath)
% writetableAtomic  Write a table to filepath without ever leaving a
% partially-written file on disk if the write is interrupted.
%
% writetable() truncates filepath immediately and writes progressively —
% not atomic. If anything interrupts the write partway through (a crash,
% a timeout, a parallel pool tearing down mid-run, Ctrl+C), the file is
% left truncated — this is the extraction-log "header gets clipped" bug.
% Writing to a temp file in the SAME directory first, then movefile()-ing
% it onto filepath, is atomic at the OS level (a same-filesystem rename):
% any reader always sees either the complete old file or the complete
% new one, never a partial write. The temp file must live alongside
% filepath, not in the system temp directory — a move across filesystems
% (e.g. local temp -> a network/cloud-mounted drive) degrades to a
% copy+delete and loses the atomicity this exists to guarantee.
    [d, n, e] = fileparts(filepath);
    [~, uniqueName] = fileparts(tempname());
    tmpPath = fullfile(d, sprintf('.%s_%s%s', n, uniqueName, e));

    writetable(T, tmpPath);
    movefile(tmpPath, filepath);
end
