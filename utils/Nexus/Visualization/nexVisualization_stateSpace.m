function nexVisualization_stateSpace(nexObj, args)
    
    % CFG HEADER
    % axLim = args.axLim; % default = 40

    axLim=5;
    % Assign X Y Z Data
    % use ax, factor, and dim selections
    xDim="L-hind-paw";
    yDim="R-hind-paw";
    zDim=[];
    % slice state dataframes
    % test input
    factorSel_IDs = ["L-hind-paw","R-hind-paw"]';
    % factorSel_IDs = ["L-hind-paw-CCI","R-hind-paw-CCI"]';
    factorSel_props = ["sessionLabel_phase","sessionLabel_phase"]'; 
    factorSel = table(factorSel_IDs, factorSel_props,'VariableNames',{'ID','Property'});   
    dimSel=[];    
    %% PLOT AVG
    %% PLOT DF
    % STATE = nexOp_buildSTATE(nexObj);
    %% assemble (use AVG, DF, S/STAT)
    STATE = nexObj.buildSTATE();
    %% select dimension (use pointer)
    try
        STATE = nexObj.filterSTATE();
    catch e
        disp(getReport(e));
    end
    gCond = find(ismember(STATE.G.(nexObj.collector.AVG), nexObj.collector.VW));
    STATE.Z=STATE.Z(gCond,:);
    STATE.G=STATE.G(gCond,:);    
    %% select factor (use domain)
    % S = nexOp_sliceSTATE(nexObj.STAT, factorSel, dimSel);
    % X = S{:,1}; Y = S{:,2}; % Z = S(:,3);
    % Z = [];
    % d1=2; d2=3; d3=4;
    d1=1; d2=2; d3=3;
    %% select color (use collector, convert G to C with external LUT)
    G_sel = STATE.G.(nexObj.collector.CLR);
    phaseLUT = nexObj.nexon.console.BASE.map_phase; % temporary
    C = arrayfun(@(g) phaseLUT.color(ismember(phaseLUT.phase,g)), G_sel);
    C_rgb = arrayfun(@(c) hex2rgb(c), C, "UniformOutput",false);
    C = cat(1,C_rgb{:});
    % C = arrayfun(@(c) strcat("#",c), C);
    % Extract data for the specified dimensions
    % nexObj.Figure.panel0.tiles.graphics.canvas.SizeData=100;
    % nexObj.Figure.panel0.tiles.graphics.canvas.CData=nexObj.nexon.settings.Colors.cyberGreen;    
    nexObj.Figure.panel0.tiles.graphics.canvas.CData = C;    
    nexObj.Figure.panel0.tiles.graphics.canvas.XData = STATE.Z(:,d1);
    nexObj.Figure.panel0.tiles.graphics.canvas.YData = STATE.Z(:,d2);
    nexObj.Figure.panel0.tiles.graphics.canvas.ZData = STATE.Z(:,d3);    
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.XLim = [0, axLim];
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.YLim = [0, axLim];
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.ZLim = [0, axLim];    
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.XLabel.String = S.Properties.VariableNames{1};    
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.YLabel.String = S.Properties.VariableNames{2};    
    dfID_source = strrep(nexObj.Partners.ctg.dfID_source,"_","-");
    subjects = unique(nexObj.STAT.sessionLabel_subj);
    subj_csv = strjoin(subjects, ", ");
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.Title.String=sprintf("%s subject(s): %s", dfID_source, subj_csv);
    % nexObj.Figure.panel0.tiles.graphics.canvas.Parent.ZLabel.String = S.Properties.VariableNames{3};    
end