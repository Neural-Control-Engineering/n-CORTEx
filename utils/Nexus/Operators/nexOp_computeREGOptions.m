function regOpts = nexOp_computeREGOptions(ftrAxes, ax) %#ok<INUSD>
% Candidate REG (cross-sample identity canonicalization) axis options.
%
% REG candidates = "None" union every real axis except "t"/time (never a
% valid REG axis) and "latent" (an embedding's own coordinates -- not a
% real cross-session identity; two different fits' latent spaces aren't
% alignable). Previously restricted to co-indexed partners of the
% CURRENTLY-SELECTED FTR axis (ftrAxes) -- that coupling was purely a
% UI-candidate-list artifact: the actual alignment logic
% (nexOp_alignCoAxes, called from nexOp_compileSTAT) operates entirely
% off domain.REG's own value plus its OWN internally-resolved co-indexed
% sibling (via nexOp_coIndexPairs) -- it never reads domain.FTR at all.
% Removing the coupling here changes which options appear in the REG
% dropdown, not how alignment behaves, for any mdlObj/nexObject type.
%
% Most existing callers (nexObj_polyGraph/waterfall/monoGram/monoGraph/
% stateSpace, nexObject.refreshPointer) already pass the FULL axis list
% here, not an FTR-narrowed one -- for those this is a no-op. Only the
% FTR-scoped callers (mdlObject.refreshREG/initDomainBus, nexFigure_ssm)
% actually change behavior: REG now offers every real axis, not just
% ones related to whatever FTR happens to be selected -- e.g. picking
% FTR="None" (as mdlObj_lme now defaults to; LME has no feature-axis
% consumer) no longer collapses REG down to "None" only.
%
% ftrAxes is kept as a parameter purely for call-site compatibility
% (every existing caller still passes it) -- no longer read.
%
% REG stays single-select everywhere (nexOp_alignCoAxes/nexOp_compileSTAT
% both take domain.REG as one scalar axis name). A genuine multi-axis
% co-registration/canonicalization capability -- independently
% canonicalizing several axes at once, not just resolving one
% co-indexed pair -- would need changes to that core shared pipeline.
% Deliberately deferred: not needed yet.
%
% NOTE: The co-index registry (nexOp_coIndexPairs) still seeds only from
% {chans, unit} -- the minimum pair for channel-position and unit-ID
% cross-session alignment -- and still governs nexOp_alignCoAxes' own
% sibling resolution once ONE of a pair is picked as REG. Extending that
% registry (probe geometry, multi-area hierarchies, matched stimulus IDs,
% ...) only ever requires updating nexOp_coIndexPairs; this function and
% the REG bus need no changes for that.
    regOpts = "None";
    if isempty(ax), return; end
    axNames = string(fieldnames(ax))';
    axNames = axNames(~ismember(axNames, ["t", "latent"]));
    regOpts = union(regOpts, axNames, 'stable');
end
