function reg = nexLaunch_registry()
% nexLaunch_registry  Uniform figure-launch map.
%
% Each entry takes a categorical hub (ctg) and returns the constructed nexObj.
% This is the SINGLE place each figure constructor's (heterogeneous) signature
% is adapted to the common (ctg) call — every figure rides the categorical in
% its Parent/Partner slot, which supplies STAT + selection buses via compileSTAT.
%
% Add a figure type = add one line here. The dropdown in nexLaunch_panel is
% populated directly from fieldnames(reg), so no other file needs touching.
%
% ctg supplies both nexon (ctg.nexon) and source id (ctg.dfID_source).

    reg = struct();
    reg.monoGraph  = @(ctg) nexObj_monoGraph(ctg, [], ctg.nexon, ctg.dfID_source, [], [], []);
    reg.monoGram   = @(ctg) nexObj_monoGram(ctg.nexon, ctg, ctg.dfID_source, [], [], []);
    reg.stateSpace = @(ctg) nexObj_stateSpace(ctg.nexon, ctg, [], ctg.dfID_source, []);
    reg.pixelGram  = @(ctg) nexObj_pixelGram(ctg, ctg.nexon);   % ctg → Partner → Origin
end
