function nexFit_lme(mdlObj, args)
% nexFit_lme  mdlObj_lme's cfg.fitCfg.fcn -- called once per combo-child by
% the INHERITED, unmodified mdlObject.fit()/fitByCombo() (chain is just
% another fit-governing parameter, same convention as nexFit_lda.m's
% n_components/shrinkage; see mdlObj_lme.m's class header / this session's
% plan decision 5).
%
% When called via fitByCombo (the normal path), args is this ONE combo-
% child's own cfg.fitCfg.entryParams -- inherited verbatim from the parent
% mdlObj_lme (fitByCombo copies child.cfg = mdlObj.cfg wholesale before
% calling this), e.g.:
%   args.chain = defineModelChain({"df ~ 1 + (1|sessionLabel_subj)", ...})  % same chain.steps/.variables/.groupingVars shape documented in defineModelChain.m
% mdlObj itself (the "mdlObj" argument here) is the COMBO-CHILD, not the
% top-level object -- mdlObj.STAT is already sliced to this one combo
% (e.g. cci=0,side="L") by fitByCombo before this function ever runs.
% fitByCombo also copies child.domain = mdlObj.domain wholesale, so
% domain.SWP (read below) is this same combo-child's own value.
%
% Grid dimensions (beyond the feature axis) come from domain.SWP, not a
% bespoke cfg parameter -- subsumes an earlier standalone "gridCols" text
% entry in nexFigure_lme.m, now removed. SWP's own established role
% (verified directly in nexAnalysis_cvPermute.m's fold x SWP loop: a
% genuinely separate fit PER axis-combo, assembled into one array indexed
% by those axes) is exactly the operation computeSignificance needs for
% its grid -- not a coincidence of convenient shape, but the same
% underlying "independent per-combo analysis, multiple-comparisons-style"
% operation, just with fitlme+LRT standing in for cvPermute's fit+score.
% See WIP.md #12 observation 7 for the fuller DN-vs-SWP reasoning.

    % CFG HEADER
    chain = args.chain;   % default = []
    % extractMethodCfg.m (the CFG HEADER parser) only evaluates numeric/
    % "[]"/quoted-string defaults -- a struct-array default here would be
    % stored as the literal, un-evaluated text of the call, not a real
    % chain struct. "[]" is the one default it correctly produces, so
    % chain MUST be set via mdlObj.setChain(...) before fitting rather
    % than relying on any auto-constructed default.
    if isempty(chain)
        error('nexFit_lme:noChain', ...
            'mdlObj.cfg.fitCfg.entryParams.chain is empty -- call mdlObj.setChain(defineModelChain({...})) before fitting.');
    end

    swpSel   = string(mdlObj.domain.SWP);
    gridCols = cellstr(swpSel(swpSel ~= "None"))';

    % targetInfo built from this (combo-child) mdlObj's own Target bus --
    % buildLongSTAT itself no longer reads mdlObj.collector.Target
    % directly (generalized to work for any caller holding a compiled
    % STAT, not just an mdlObj -- see DESIGN.md section 4 / Operators/
    % buildLongSTAT.m's own header).
    targetInfo = [];
    try
        targetInfo = struct('name', mdlObj.collector.Target.Y, 'nBins', mdlObj.collector.Target.nBins);
    catch
    end

    T_long   = buildLongSTAT(mdlObj.STAT, chain.variables, gridCols, targetInfo);
    mdlObj.W = mdlObj.computeSignificance(T_long, chain);
end
