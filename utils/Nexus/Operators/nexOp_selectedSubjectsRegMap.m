function regMap = nexOp_selectedSubjectsRegMap(nexon)
% Combined regMap (channel/region/depth atlas table) for the subject(s)
% currently selected in controlPanel.averagingSelection, vertically
% concatenated. Falls back to the first registry subject if the selection
% can't be resolved. Returns [] if the registry/selection is unavailable.
%
% Factored out of nex_axisColorFromRegistry.m (region color lookup) so
% nexOp_regionDepthOrder.m (bar-chart region depth ordering) can share the
% exact same "which subjects' atlas data applies right now" resolution
% instead of re-deriving it — both need the same pooled regMap, just for
% different columns (.color vs .Y).

    regMap = [];
    try
        reg = nexon.console.BASE.registry;
    catch
        return;
    end
    if ~isfield(reg, 'SUBJ'), return; end
    allSubjKeys = string(fieldnames(reg.SUBJ))';
    if isempty(allSubjKeys), return; end

    % ── Determine selected subjects from controlPanel averagingSelection ──
    selectedSubjKeys = {};
    try
        avgSel   = nexon.console.BASE.controlPanel.averagingSelection;
        subjAll  = avgSel.selKeys.subj;           % all subject strings
        subjIdx  = avgSel.selections.subj;        % selected indices (may be multi-select)
        selSubjs = string(subjAll(subjIdx));      % selected subject name(s)
        for i = 1:numel(selSubjs)
            k = sprintf('subj_%s', strrep(char(selSubjs(i)), '-', '_'));
            if ismember(string(k), allSubjKeys)
                selectedSubjKeys{end+1} = k; %#ok<AGROW>
            end
        end
    catch
    end
    % Fall back to first registry subject if nothing resolved
    if isempty(selectedSubjKeys)
        selectedSubjKeys = {char(allSubjKeys(1))};
    end

    % ── Load and combine regMaps from all selected subjects ───────────────
    for i = 1:numel(selectedSubjKeys)
        try
            rm = reg.SUBJ.(selectedSubjKeys{i}).regMap;
            if isempty(regMap)
                regMap = rm;
            else
                regMap = vertcat(regMap, rm);
            end
        catch
        end
    end
end
