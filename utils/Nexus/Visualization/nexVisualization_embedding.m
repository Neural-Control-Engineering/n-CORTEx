function nexVisualization_embedding(nexon, nexObj, args)
    % update scatter plot based on DF_postOp
    % subselect rows    
    % compile both rowSels and visSels       
    labelSelKeys = fieldnames(nexObj.labelSelection.selKeys);
    selCond = [1:size(nexObj.DF_postOp.Y,1)]';
    for i = 1:length(labelSelKeys)
        key = labelSelKeys{i};
        if isfield(nexObj.labelSelection.selections,key)
            keySel = nexObj.labelSelection.selections.(key);
            matchingRows = find(ismember(nexObj.DF_postOp.Y.(key),keySel));
            selCond = intersect(selCond,matchingRows);
        end        
    end
    % COLOR MAPPING
     if isfield(nexObj.visSelection.selections,"label")
        colorLabel = nexObj.visSelection.selections.label;
        cData = table2array(nexObj.DF_postOp.Y(selCond,colorLabel));
    else
        cData = [];
     end
        
    dimIdx = nexObj.visSelection.selKeys.dimensions;
    xData = nexObj.DF_postOp.df(selCond,dimIdx(1));
    yData = nexObj.DF_postOp.df(selCond,dimIdx(2));
    zData = nexObj.DF_postOp.df(selCond,dimIdx(3));

    % save selection for interactive methods
    nexObj.UserData.DF_postOp_sel.df = [xData, yData, zData];
    
    % update data
    nexObj.Figure.panel1.tiles.Axes.embedding.XData = xData;
    nexObj.Figure.panel1.tiles.Axes.embedding.YData = yData;
    nexObj.Figure.panel1.tiles.Axes.embedding.ZData = zData;
    nexObj.Figure.panel1.tiles.Axes.embedding.CData = cData;

    % Add colorbar if CData is not empty
    if ~isempty(cData)
        colorbar(nexObj.Figure.panel1.tiles.Axes.embedding.Parent,"Color",nexon.settings.Colors.cyberGreen); % Add colorbar to the same axes        
        colormap(nexObj.Figure.panel1.tiles.Axes.embedding.Parent, 'turbo'); % Set colormap (change if needed)
    end

end