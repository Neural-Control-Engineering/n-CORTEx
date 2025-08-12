function nexTraceback_embedding(src, event, nexObj)
        % Get clicked point coordinates
    clickedPoint = event.IntersectionPoint(:)'; % Extract X and Y
    
    % Find the closest data point in the scatter plot
    dfSel = nexObj.UserData.DF_postOp_sel.df;
    x = dfSel(:,1); y = dfSel(:,2); z = dfSel(:,3);
    distances = vecnorm([x(:), y(:), z(:)] - clickedPoint, 2, 2); % Euclidean distance
    [~, idx] = min(distances); % Find index of nearest point
    pointData = nexObj.UserData.DF_postOp_sel.df(idx,:);
    % isolate point data
    [pointIdx, isFound] = find(ismember(nexObj.DF_postOp.df,pointData,'rows'));
    % locate point label data in primary df (postOp)
    if any(isFound)
        labelData = nexObj.DF_postOp.Y(pointIdx,:);
    end

    % resconstruct sessionlabel
    [sessionLabel, trialNum, rowIdx] = nex_findSessionLabel(nexObj.nexon, labelData, nexObj.DF.labelKeys);
    sessionLabel_app = sprintf("%s_trial--%d",sessionLabel,trialNum);
    fprintf("SESSION SELECTED: %s\n",sessionLabel_app);

     % Check if additional point was selected (Check if 'Ctrl' key was
     % pressed)
    % isCtrlPressed = isfield(event, 'Modifier') && any(strcmp(event.Modifier, 'control'));
    isCtrlPressed = nexObj.keyListener.isCtrlPressed;
    % Highlight the selected point
    % hold on;
    if isfield(nexObj.Figure.panel1.tiles.Axes, 'highlightMarker')
        if isvalid(nexObj.Figure.panel1.tiles.Axes.highlightMarker)
            if isCtrlPressed % add point               
                pointsData = [nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.pointsData; pointData];                
                nexObj.Figure.panel1.tiles.Axes.highlightMarker.XData=pointsData(:,1);
                nexObj.Figure.panel1.tiles.Axes.highlightMarker.YData=pointsData(:,2);
                nexObj.Figure.panel1.tiles.Axes.highlightMarker.ZData=pointsData(:,3);
                nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.pointsData = pointsData;
                nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.sessionLabels = [nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.sessionLabels; sessionLabel_app];
                nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.trialIdxs = [nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.trialIdxs; rowIdx];
            else % replace all points with new point
                % delete(nexObj.Figure.panel1.tiles.Axes.highlightMarker); % Remove previous highlight
                nexObj.Figure.panel1.tiles.Axes.highlightMarker.XData=pointData(1);
                nexObj.Figure.panel1.tiles.Axes.highlightMarker.YData=pointData(2);
                nexObj.Figure.panel1.tiles.Axes.highlightMarker.ZData=pointData(3);
                % reset pointData and sessionLabel accumulators
                nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.pointsData = pointData;
                nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.sessionLabels =  sessionLabel_app;
                nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.trialIdxs = rowIdx;
            end
        end
    else % generate a highlightMarker plot
        hold(nexObj.Figure.panel1.tiles.Axes.embedding.Parent,"on");
        nexObj.Figure.panel1.tiles.Axes.highlightMarker = scatter3(nexObj.Figure.panel1.tiles.Axes.embedding.Parent, pointData(1), pointData(2), pointData(3), 100, 'w', 'filled');
        hold(nexObj.Figure.panel1.tiles.Axes.embedding.Parent,"off");
        nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.pointsData = pointData;
        nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.sessionLabels =  sessionLabel_app;  
        nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.trialIdxs = rowIdx;
    end        
    
    % if multiple points selected do
    % AVERAGE AND RETURN
    if size(nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.sessionLabels,1) > 1
        selIdx = nexObj.Figure.panel1.tiles.Axes.highlightMarker.UserData.trialIdxs;
        nexCompute_nexonAverages(nexObj.nexon, selIdx);
        return
    end
    % SUBTRACTION

    % if only single point selected (instead)
    % force router redirect to sessionlabel
    nexUpdate_router(nexObj.nexon, sessionLabel_app, convertCharsToStrings(labelData.Properties.VariableNames));
    % Display clicked point
    % fprintf('Clicked on point: (%.3f, %.3f)\n', x(idx), y(idx));    
    
end
