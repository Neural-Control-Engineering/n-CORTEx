function nexVisualization_embedding_single(nexObj, args)
    
    % CFG HEADER
    timeRange_start = args.timeRange_start; % default = 1
    timeRange_end = args.timeRange_end; % default = 5500
    
    len_trail=40;

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
    timeRange_end = 4800;
    df = nexObj.DF_postOp.df(1:timeRange_end,:);
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
    % update marker
    markerSlice = [nexObj.frameNum: nexObj.frameNum+(len_trail-1)];
    Z = nexObj.DF_postOp.df;
    try
        Z_marker = Z(markerSlice,:);
    catch e
        keyboard
    end
    nexObj.Figure.panel0.tiles.graphics.tMarker0.graphic.XData = Z_marker(:,dimIdx(1));
    nexObj.Figure.panel0.tiles.graphics.tMarker0.graphic.YData = Z_marker(:,dimIdx(2));
    nexObj.Figure.panel0.tiles.graphics.tMarker0.graphic.ZData = Z_marker(:,dimIdx(3));

    time = nexObj.frameNum / nexObj.Partners.npxTC.UserData.Fs - nexObj.Partners.npxTC.UserData.preBufferLen;
    title(nexObj.Figure.panel0.tiles.ax,sprintf("%f (s)", time),"Color",nexObj.nexon.settings.Colors.cyberGreen);
    % Add colorbar if CData is not empty
    % if ~isempty(cData)
    %     colorbar(nexObj.Figure.panel0.tiles.graphics.canvas.Parent,"Color",nexon.settings.Colors.cyberGreen); % Add colorbar to the same axes        
    %     % colormap(nexObj.Figure.panel1.tiles.graphics.canvas.Parent, 'turbo'); % Set colormap (change if needed)
    % end

    
end