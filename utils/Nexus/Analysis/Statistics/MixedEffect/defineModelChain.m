function chain = defineModelChain(formulas)
% defineModelChain  Build a linear model-chain struct for mdlObj_lme from a
% cell array of Wilkinson formula strings, one per step (m0, m1, m2, ...).
%
% Formulas reference REAL live column names directly (e.g.
% "df ~ 1 + h5_responseThreshold_g + (1|sessionLabel_subj)") -- "df" is
% always the literal response-column token (Nexus's own .df convention;
% buildLongSTAT.m populates a column with that exact name), never
% renamed per-call the way build_bandPowerRegionTable.m renames its
% response to "bandPower"/"condition"/"subject" today.
%
%   formulas : cell array of Wilkinson formula strings, step order = chain
%              order (formulas{1} = m0, formulas{2} = m1, ...).
%
%   chain.steps    : struct array, chain.steps(i).step = "m<i-1>",
%                     chain.steps(i).formula = formulas{i}.
%   chain.variables    : deduped string array of every real-column token
%                        referenced across every formula (fixed-effect
%                        terms AND random-effect grouping variables),
%                        excluding "df" and Wilkinson syntax (~ + 1 | ( )
%                        : *) -- the single source of truth
%                        buildLongSTAT.m uses for which columns to pull
%                        from the compiled STAT/G table.
%   chain.groupingVars : deduped string array of just the random-effect
%                        grouping variables -- tokens appearing after "|"
%                        inside a "(...|...)" term (e.g.
%                        "sessionLabel_subj" in "(1|sessionLabel_subj)").
%                        Used for the per-cell "too few groups" skip guard
%                        and for telling fixed vs. random terms apart when
%                        flattening mdlStep labels (computeSignificance).
%
% WORKED EXAMPLE (reused throughout mdlObj_lme.m/buildLongSTAT.m/
% nexFit_lme.m's own comments):
%   formulas = { ...
%       "df ~ 1 + (1|sessionLabel_subj)", ...
%       "df ~ 1 + h5_responseThreshold_g + (1|sessionLabel_subj)", ...
%       "df ~ 1 + h5_responseThreshold_g + (1 + h5_responseThreshold_g|sessionLabel_subj)"};
%   chain = defineModelChain(formulas);
%   chain.steps(1) = struct('step',"m0", 'formula',"df ~ 1 + (1|sessionLabel_subj)")
%   chain.steps(2) = struct('step',"m1", 'formula',"df ~ 1 + h5_responseThreshold_g + (1|sessionLabel_subj)")
%   chain.steps(3) = struct('step',"m2", 'formula',"df ~ 1 + h5_responseThreshold_g + (1 + h5_responseThreshold_g|sessionLabel_subj)")
%   chain.variables    = ["sessionLabel_subj"; "h5_responseThreshold_g"]
%   chain.groupingVars = ["sessionLabel_subj"]
% (mdlObj_lme.computeSignificance later turns this into the flattened
% mdlStep labels ["m0"; "m1_fe_h5_responseThreshold_g"; "m2_re_h5_responseThreshold_g"]
% by diffing each step's formula against the previous one -- not done
% here, since that diff also needs each PAIR of consecutive formulas, not
% just the deduped variable set this function produces.)

    nSteps = numel(formulas);
    steps  = struct('step', {}, 'formula', {});
    allVars  = strings(0, 1);
    grpVars  = strings(0, 1);
    for i = 1:nSteps
        f = string(formulas{i});
        steps(i).step    = sprintf("m%d", i - 1);
        steps(i).formula = f;
        toks = string(regexp(char(f), '[A-Za-z_]\w*', 'match'));
        toks = toks(toks ~= "df");
        allVars = [allVars; toks(:)]; %#ok<AGROW>

        reTerms = regexp(char(f), '\(([^()]*)\)', 'match');
        for ri = 1:numel(reTerms)
            parts = split(string(reTerms{ri}(2:end-1)), '|');
            if numel(parts) == 2
                gToks = string(regexp(char(parts(2)), '[A-Za-z_]\w*', 'match'));
                grpVars = [grpVars; gToks(:)]; %#ok<AGROW>
            end
        end
    end
    chain.steps        = steps;
    chain.variables    = unique(allVars, 'stable');
    chain.groupingVars = unique(grpVars, 'stable');
end
