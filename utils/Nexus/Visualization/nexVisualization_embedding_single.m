function nexVisualization_embedding_single(nexObj, args)
    
    % CFG HEADER
    timeRange_start = args.timeRange_start; % default = 1
    timeRange_end = args.timeRange_end; % default = 5500

    % update scatter plot based on DF_postOp
    % subselect rows    
    % compile both rowSels and visSels       
    % labelSelKeys = fieldnames(nexObj.labelSelection.selKeys);
    % selCond = [1:size(nexObj.DF_postOp.Y,1)]';
    % for i = 1:length(labelSelKeys)
    %     key = labelSelKeys{i};
    %     if isfield(nexObj.labelSelection.selections,key)
    %         keySel = nexObj.labelSelection.selections.(key);
    %         matchingRows = find(ismember(nexObj.DF_postOp.Y.(key),keySel));
    %         selCond = intersect(selCond,matchingRows);
    %     end        
    % end
    % % COLOR MAPPING
    %  if isfield(nexObj.visSelection.selections,"label")
    %     colorLabel = nexObj.visSelection.selections.label;
    %     cData = table2array(nexObj.DF_postOp.Y(selCond,colorLabel));
    % else
    %     cData = [];
    %  end
    df = nexObj.DF_postOp.df;
    tCond = [timeRange_start:timeRange_end];
    % dimIdx = nexObj.visSelection.selKeys.dimensions;
    dimIdx=[1,2,3];
    xData = df(tCond,dimIdx(1));
    yData = df(tCond,dimIdx(2));
    zData = df(tCond,dimIdx(3));
    cData = nexObj.DF_postOp.ax.t(tCond);

    % save selection for interactive methods
    nexObj.UserData.DF_postOp_sel.df = [xData, yData, zData];
    
    % update data
    nexObj.Figure.panel0.tiles.graphics.canvas.XData = xData;
    nexObj.Figure.panel0.tiles.graphics.canvas.YData = yData;
    nexObj.Figure.panel0.tiles.graphics.canvas.ZData = zData;
    nexObj.Figure.panel0.tiles.graphics.canvas.CData = cData;

    % Add colorbar if CData is not empty
    % if ~isempty(cData)
    %     colorbar(nexObj.Figure.panel0.tiles.graphics.canvas.Parent,"Color",nexon.settings.Colors.cyberGreen); % Add colorbar to the same axes        
    %     % colormap(nexObj.Figure.panel1.tiles.graphics.canvas.Parent, 'turbo'); % Set colormap (change if needed)
    % end

    
end