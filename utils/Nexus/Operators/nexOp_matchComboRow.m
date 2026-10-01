function mask = nexOp_matchComboRow(T, key)
% Logical mask over table T's rows matching every field in struct `key`
% (e.g. one row of a CTG combo table, or a saved mdlObj.comboFits(k).key).
% Shared by mdlObject.fitByCombo (partition STAT by combo at fit time) and
% scaleApply_transform's per-trial combo lookup (does this DTS row match a
% fitted combo, at transform time) — one matching rule, used both ways.
%
% A key field absent from T's own columns means "can't possibly match" —
% returns all-false rather than erroring, which is exactly the behavior
% scaleApply_transform wants for "skip trials this mdlObj's combos don't
% cover" (e.g. a raw DTS row missing a STAT-only derived CTG column).
%
% Cell-wrapped string columns are handled the same way
% nexAnalysis_cvPermute's own matchesSWPValue does.
%
%   T    : table (STAT, or a single DTS row) to test
%   key  : struct, one field per CTG column, e.g. from
%          table2struct(comboTbl(ci,:))
%
%   mask : height(T) x 1 logical
    fn   = fieldnames(key);
    mask = true(height(T), 1);
    for i = 1:numel(fn)
        f = fn{i};
        if ~ismember(f, T.Properties.VariableNames)
            mask(:) = false;
            return;
        end
        colVals = T.(f);
        target  = key.(f);
        if iscell(target), target = target{1}; end
        if iscell(colVals)
            mask = mask & strcmp(colVals, target);
        else
            mask = mask & (colVals == target);
        end
    end
end
