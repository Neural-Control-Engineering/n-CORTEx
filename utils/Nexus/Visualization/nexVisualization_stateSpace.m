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
    S = nexOp_sliceSTATE(nexObj.STATE, factorSel, dimSel);
    X = S{:,1}; Y = S{:,2}; % Z = S(:,3);
    Z = [];
    % Extract data for the specified dimensions
    % nexObj.Figure.panel0.tiles.graphics.canvas.SizeData=100;
    % nexObj.Figure.panel0.tiles.graphics.canvas.CData=nexObj.nexon.settings.Colors.cyberGreen;    
    nexObj.Figure.panel0.tiles.graphics.canvas.XData = X;
    nexObj.Figure.panel0.tiles.graphics.canvas.YData = Y;
    nexObj.Figure.panel0.tiles.graphics.canvas.ZData = Z;    
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.XLim = [0, axLim];
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.YLim = [0, axLim];
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.ZLim = [0, axLim];    
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.XLabel.String = S.Properties.VariableNames{1};    
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.YLabel.String = S.Properties.VariableNames{2};    
    dfID_source = strrep(nexObj.Partners.ctg.dfID_source,"_","-");
    subjects = unique(nexObj.STATE.sessionLabel_subj);
    subj_csv = strjoin(subjects, ", ");
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.Title.String=sprintf("%s subject(s): %s", dfID_source, subj_csv);
    % nexObj.Figure.panel0.tiles.graphics.canvas.Parent.ZLabel.String = S.Properties.VariableNames{3};    
end