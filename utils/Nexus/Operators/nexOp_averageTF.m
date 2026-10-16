function DF_avg = nexOp_averageTF(TF, ptr, dimSel)    
    % trim all samples to identical length along dimSel
    % minLength = cellfun(@(x) size(x.df,dimSel), TF,"UniformOutput",true);
    % exclude empty entries
    isEmptyIdx = cellfun(@(x) isempty(x), TF);
    TF = TF(~isEmptyIdx);
    % exclude 'empty' lengths
    % minLength(minLength==0) = [];
    % minLength(minLength==1) = [];    
    % minLength = min(minLength);    
    % idxs = [1:minLength];
    % trim df
    % dfCol_trim = cellfun(@(x) nex_trimDf(x.df,dimSel,idxs),TF,"UniformOutput",false);
    [dfCol_trim, ax_trim] = nexOp_trimTF(TF);
    % dfCol_trim = cellfun(@(DF) DF.df, TF_trim, "UniformOutput", false);
    % trim ax
    %% TEST REMOVAL
    % ptrProps = properties(ptr);
    % ptrDims = cellfun(@(p) (ptr.(p).dim), ptrProps, 'UniformOutput', true);
    % axDim = find(ptrDims==dimSel); axDim = ptrProps{axDim};
    % axTrim = cellfun(@(x) nex_trimDf(x.ax.(axDim), 2, idxs), TF, "UniformOutput", false);
    %% TEST REMOVAL
    % ax_avg = TF{1}.ax;
    if isfield(TF{1},"labels")
        labels_avg = TF{1}.labels; %% TESTING, FIX SOON (not trimmed yet corresponding with ax_trim)
        DF_avg.labels=labels_avg;           
    end
    % ax_avg.(axDim) = ax_tririm{1};    
    catDim = ndims(dfCol_trim{1})+1;
    dfCol_avg = cat(catDim,dfCol_trim{:});
    % omitnan on both: after nexOp_alignCoAxes NaN-pads each trial to a
    % shared canonical width (e.g. REG='chans' union across sessions), any
    % one trial only covers a SUBSET of that width — a plain mean/std here
    % required EVERY trial in the group to have real data at a given
    % canonical position (intersection), so almost every position came
    % back NaN once the union was wider than any single trial's own
    % coverage. omitnan makes a position survive whenever ANY trial
    % recorded it (union), matching what nexOp_alignCoAxes's NaN-fill is
    % actually meant to represent ("this trial never recorded this
    % identity" — not "exclude this identity from every average"). SEM's
    % denominator uses the per-position valid-trial count (nValid), not
    % the group's total trial count — different canonical positions have
    % different numbers of contributing trials once coverage varies.
    nValid = sum(~isnan(dfCol_avg), catDim);
    dfCol_sem = std(dfCol_avg,0,catDim,'omitnan') ./ sqrt(nValid);
    dfCol_avg = mean(dfCol_avg,catDim,'omitnan');
    DF_avg.df = dfCol_avg;
    DF_avg.sem = dfCol_sem;
    % DF_avg.ax = ax_avg;
    % 'unit' no longer carries one meaningful real ID once this DF is an
    % average across a group — each canonical position (see
    % nexOp_alignCoAxes) has already blended together whichever different
    % real unit IDs happened to land there across sessions, or is a
    % structural-absence placeholder (0) for a channel most of the group
    % never recorded. ax_trim.unit, inherited from a single representative
    % trial, would otherwise read as a mostly-zero label list in any
    % selection bus built from it. Same fix nexAtlas_recomputePosteriors.m
    % already uses for the analogous "unit has no real per-position
    % identity here" case: a plain positional index instead.
    if isfield(ax_trim, 'unit')
        ax_trim.unit = (1:numel(ax_trim.unit))';
    end
    DF_avg.ax = ax_trim;

end