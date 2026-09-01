function nexAtlas_queryIBL_run(subjectDir, args)
% MATLAB wrapper for nexAtlas_queryIBL.py — populate /reference/ in ephys_atlas.h5.
%
%   subjectDir   fully-resolved subject directory (contains npxls/ephys_atlas.h5).
%                Pass [] to pick via uigetdir.
%
% Optional args fields:
%   regions        cell/string array of Allen CCF acronyms  (default: read from atlas prior)
%   max_sessions   integer cap on IBL sessions per region   (default: 80)
%   fallback_only  logical — skip IBL query, use literature priors (default: false)
%   base_url       Alyx server URL string                   (default: alyx.internationalbrainlab.org)
%
% Example — fast literature-prior seed:
%   nexAtlas_queryIBL_run(subjectDir, struct('fallback_only', true))
%
% Example — full IBL query for specific regions:
%   nexAtlas_queryIBL_run(subjectDir, struct('regions', {{'STN','ZI','VPM'}}))

    if nargin < 2 || isempty(args), args = struct(); end

    % ── Resolve subjectDir ────────────────────────────────────────────────────
    if isempty(subjectDir)
        subjectDir = uigetdir('', 'Select subject directory');
        if isequal(subjectDir, 0)
            fprintf('[nexAtlas_queryIBL_run] cancelled.\n');
            return;
        end
    end

    atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');
    if ~isfile(atlasFile)
        error('nexAtlas_queryIBL_run:noAtlas', ...
            'ephys_atlas.h5 not found — run nexAtlas_createAtlas first.\n  %s', atlasFile);
    end

    % ── Python path (cross-platform, nexus conda env) ────────────────────────
    if ispc
        homeDir   = getenv('USERPROFILE');
        pyVersion = fullfile(homeDir, 'miniconda3', 'envs', 'nexus', 'python.exe');
    else
        homeDir   = getenv('HOME');
        pyVersion = fullfile(homeDir, 'miniconda3', 'envs', 'nexus', 'bin', 'python');
    end

    pyScript  = fullfile(fileparts(mfilename('fullpath')), 'nexAtlas_queryIBL.py');

    % ── Build command ─────────────────────────────────────────────────────────
    cmd = sprintf('"%s" "%s" "%s"', pyVersion, pyScript, atlasFile);

    if isfield(args, 'regions') && ~isempty(args.regions)
        regions = string(args.regions);
        cmd = [cmd ' --regions ' strjoin(regions, ' ')];
    end

    if isfield(args, 'max_sessions') && ~isempty(args.max_sessions)
        cmd = [cmd sprintf(' --max_sessions %d', args.max_sessions)];
    end

    if isfield(args, 'spontaneous_only') && args.spontaneous_only
        cmd = [cmd ' --spontaneous_only'];
    end

    if isfield(args, 'fallback_only') && args.fallback_only
        cmd = [cmd ' --fallback_only'];
    end

    if isfield(args, 'base_url') && ~isempty(args.base_url)
        cmd = [cmd sprintf(' --base_url "%s"', args.base_url)];
    end

    % ── Run (echo live so long-running IBL queries show progress) ────────────
    fprintf('[nexAtlas_queryIBL_run] %s\n', cmd);
    status = system(cmd, '-echo');
    if status ~= 0
        error('nexAtlas_queryIBL_run:failed', ...
            'nexAtlas_queryIBL.py exited with status %d', status);
    end
end
