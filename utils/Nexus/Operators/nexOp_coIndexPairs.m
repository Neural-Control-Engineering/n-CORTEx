function pairs = nexOp_coIndexPairs(ax)
% Bootstrap registry for co-indexed axis pairs.
%
% PRIMARY USE: called once by dtsIO_composeDF to write DF.coIdx.
% At runtime, nexOp_coAlign reads DF.coIdx directly — this function is only
% invoked as a fallback for DFs that predate the coIdx field.
%
% To register a new pair, add it to allPairs. dtsIO_composeDF will filter
% to only pairs where both axes are present in the specific DF.
%
% {'feature', <name>} entries (Nexus WIP.md #11): a reduced "feature" axis
% (nexAnalysis_cvPermute.m's R.ax_W.feature, non-swept FTR case only — see
% that file's own comment on why the swept case can't do this) is literally
% the same index as whichever real identity axis fed domain.FTR this run
% (e.g. "chans" or "unit" for a region reduction — domain.REG can be either
% depending on pre/post-unitMatch, see mdlObj/CLAUDE.md's Domain
% Convention — or "f" for a band reduction) — not just a similarly-shaped
% sibling. Listing every candidate identity name here is harmless even
% though only one is ever actually present in a given ax struct (the
% isfield/ismember filter below already restricts to pairs where both axes
% exist) — it just lets "feature" resolve to real registry color via
% nex_axisColorFromRegistry regardless of which one fed it, without a
% viewer needing to know in advance. NOT transitive: {'feature','chans'}
% plus {'chans','unit'} does NOT imply a usable feature<->unit link —
% nexVis_resolveClrAxis (nexVisualization_monoGram.m) only ever checks one
% pair deep from whatever key it's resolving — so 'unit' is listed
% explicitly here too rather than relying on 'chans' as an implied bridge.
    allPairs = {{'chans', 'unit'}, {'feature', 'chans'}, {'feature', 'unit'}, ...
                {'feature', 'f'}, {'feature', 'map'}, {'feature', 'dropout'}};
    pairs    = {};
    if nargin < 1 || isempty(ax), return; end
    axFields = fieldnames(ax);
    for p = 1:numel(allPairs)
        pair = allPairs{p};
        if all(ismember(pair, axFields))
            pairs{end+1} = pair;  %#ok<AGROW>
        end
    end
end
