function atlas = nexAtlas_initFromPrior(regMap)
% Bootstrap atlas from hard NTE channel-region assignments.
%
%   regMap  MATLAB table with columns channel, X, Y, region, color (from NTE).
%           Y = µm from probe tip; 0 = tip (deepest), increases toward surface.
%
%   atlas   struct — see nexAtlas_load for field definitions.

    % Sort channels by depth, tip first (ascending Y)
    [~, ord]   = sort(regMap.Y, 'ascend');
    rm         = regMap(ord, :);

    depths     = double(rm.Y);
    chanIdx    = double(rm.channel);
    hardLabels = string(rm.region);
    hexColors  = string(rm.color);

    % Unique regions ordered by mean depth (tip → surface)
    [uniqRegs, ~, regID] = unique(hardLabels, 'stable');
    n_ch  = numel(depths);
    n_reg = numel(uniqRegs);

    % Hard indicator matrix then Gaussian-blur at boundaries (σ = 50 µm)
    P_hard = zeros(n_ch, n_reg);
    for i = 1:n_ch
        P_hard(i, regID(i)) = 1;
    end
    P_soft = nexAtlas_gaussSmooth(P_hard, depths, 50);

    % Representative color per region (first channel in that region)
    regColors = strings(1, n_reg);
    for r = 1:n_reg
        idx = find(regID == r, 1);
        regColors(r) = hexColors(idx);
    end

    prior.channel_indices = chanIdx;
    prior.channel_depths  = depths;
    prior.channel_regions = hardLabels;
    prior.region_acronyms = uniqRegs;
    prior.region_colors   = regColors;
    prior.P               = P_soft;      % (n_ch × n_reg)

    atlas.prior                    = prior;
    atlas.posteriors.canonical     = P_soft;   % initialised to prior; sharpens with sessions
    atlas.reference                = struct();
    atlas.sessions                 = struct();
end
