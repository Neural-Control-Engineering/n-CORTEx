function obj = nexLaunchAdapt_violin(ctg)
% Launch adapter: open a ctg-sourced nexObj_violin, wired to the
% categorical hub itself (not just ctg.nexon, unlike nexLaunchAdapt_bar.m
% -- this entry point actually compiles its own STAT off ctg's live
% selectionBus via compileAndVisualize(), so it needs the real ctg object
% as Parent, not just a bare Nexon for colours). Auto-discovered by
% nexLaunch_registry (figType = "violin").
%
% Flow: select categories/items in ctg as usual, pick CTG grouping
% column(s) in the violin figure's own View panel once "Build violin" has
% compiled a first table, then press "Build violin" again after any
% further pMap/category changes to recompile.
    obj = nexObj_violin(ctg);
end
