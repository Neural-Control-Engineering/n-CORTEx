function obj = nexLaunchAdapt_lme(ctg)
% Launch adapter: build mdlObj_lme from the categorical hub. Auto-discovered
% by nexLaunch_registry (figType = "lme").
%
% Flow: select categories/items in ctg as usual (compileSTAT() reads from
% there), set domain.CTG to the real stratification columns (e.g. "cci",
% "side") in the View panel, type a chain into the Chain panel ("Set
% Chain"), then "Fit chain". Launch nexObj_violin / nexObj_monoGram from
% the Open Viewer dropdown (nexLaunch_registryMdl, auto-discovered the
% same way) to see the result.
    obj = mdlObj_lme(ctg, [], ctg.dfID_source);
end
