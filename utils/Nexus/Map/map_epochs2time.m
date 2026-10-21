function Map = map_epochs2time(tAxis, duringWidthProportion)
% map_epochs2time  Build a poolMap mapID table for the "epoch" scheme on
% the `t` axis -- three named, trial-relative segments (before/during/
% after) derived proportionally from THIS trial's own real t-axis span,
% centered on t=0 (whatever alignment event already puts zero there).
% Sibling to map_regions2chans.m/map_events2time.m -- same 3-column
% {axID, mapID, color} table contract nexObj_poolMap.getBinEdges's mapID
% branch expects (confirmed directly against map_regions2chans.m, the
% complete/working reference -- map_events2time.m's own table is missing
% the axID column entirely, via buildLUT_map, and would not actually
% survive a real getBinEdges call; not mirrored here for that reason).
% See WIP.md #16 for the full design context/open questions.
%
% MUST be called FRESH per trial, not cached -- unlike map_regions2chans.m
% (anatomy is genuinely fixed per subject) or map_events2time.m (which
% assumes one global, non-trial-varying Map despite real event timing
% varying trial-to-trial -- a latent bug WIP #16 found, not a pattern to
% copy here). Wiring that "resolve fresh per trial" call site (mirroring
% nexObj_poolMap.resolveSubjectMap_'s existing on-demand-resolve pattern,
% keyed by trial context instead of subject) is separate, not-yet-started
% work -- this function is the pure, stateless Map-builder half only.
%
%   tAxis                 : real t-axis values for ONE trial (e.g.
%                           DF.ax.t) -- not positions, not assumed shared
%                           across trials with differing span/alignment.
%   duringWidthProportion : scalar in (0,1), exclusive. "during"'s full
%                           width as a fraction of this trial's own
%                           (max(tAxis) - min(tAxis)) span, centered on
%                           t=0.
%
%   Map : table, columns {axID, mapID, color} -- axID holds each
%         segment's real-valued START boundary (getBinEdges sorts these
%         itself; the order here is for readability only, not
%         load-bearing), mapID holds ["before";"during";"after"], color
%         holds a fixed, deterministic hex string per segment (NOT
%         buildLUT_map's random-color generator -- deliberately: this
%         Map is rebuilt fresh every trial per the header above, and
%         random colors would make the same label flicker a different
%         hue trial to trial instead of staying visually constant).
%
% OPEN QUESTION (WIP #16, not resolved here): before/after currently abut
% during's edges directly (flush partition, no gap) -- "safely outside
% the event range" may have meant an explicit buffer instead. If a buffer
% is wanted later, add it as a 3rd optional arg (e.g. bufferProportion,
% default 0) subtracted/added when computing duringStart/duringEnd below
% -- the rest of this function doesn't need to change.

    if nargin < 2 || isempty(duringWidthProportion)
        error('map_epochs2time:missingWidth', ...
            'duringWidthProportion is required (fraction of this trial''s own span, in (0,1)).');
    end
    if duringWidthProportion <= 0 || duringWidthProportion >= 1
        error('map_epochs2time:badWidth', ...
            ['duringWidthProportion must be strictly between 0 and 1 (got %.4g) -- ' ...
             '0 or 1 would make "before"/"after" (or "during") genuinely empty.'], ...
            duringWidthProportion);
    end
    tAxis = double(tAxis(:));
    if numel(tAxis) < 2
        error('map_epochs2time:tooFewSamples', ...
            'tAxis needs at least 2 samples to define a span (got %d).', numel(tAxis));
    end

    tMin = min(tAxis);
    tMax = max(tAxis);
    if ~(tMin < 0 && tMax > 0)
        error('map_epochs2time:zeroOutOfRange', ...
            ['t=0 (the alignment event) must fall strictly inside this trial''s own ' ...
             'axis range [%.4g, %.4g] for "during" to be centered on it -- this trial ' ...
             'doesn''t have a usable zero to center on.'], tMin, tMax);
    end

    span            = tMax - tMin;
    duringHalfWidth = duringWidthProportion * span / 2;
    duringStart     = -duringHalfWidth;
    duringEnd       =  duringHalfWidth;

    if duringStart <= tMin || duringEnd >= tMax
        error('map_epochs2time:duringTooWide', ...
            ['duringWidthProportion=%.4g produces a "during" window [%.4g, %.4g] that ' ...
             'doesn''t leave room for both "before" and "after" within this trial''s ' ...
             'own range [%.4g, %.4g] -- lower the proportion.'], ...
            duringWidthProportion, duringStart, duringEnd, tMin, tMax);
    end

    % Start-boundary-only convention (same as map_regions2chans.m): each
    % row marks where that label's segment BEGINS; the segment ENDS where
    % the next row's segment begins (or at the true axis max, for the
    % last row). getBinEdges extends the first row's boundary down to the
    % axis's true min automatically, so tMin here is for readability
    % only, not load-bearing.
    axID  = [tMin; duringStart; duringEnd];
    mapID = ["before"; "during"; "after"];
    color = {'808080'; '3DF075'; '808080'};   % before/after neutral grey, during = cyberGreen

    Map = table(axID, mapID, color, 'VariableNames', {'axID','mapID','color'});
end
