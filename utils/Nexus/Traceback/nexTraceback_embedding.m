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

    % Highlight the selected point
    % hold on;
    if isfield(nexObj.Figure.panel1.tiles.Axes, 'highlightMarker')
        if isvalid(nexObj.Figure.panel1.tiles.Axes.highlightMarker)
            delete(nexObj.Figure.panel1.tiles.Axes.highlightMarker); % Remove previous highlight
        end
    end
    hold(nexObj.Figure.panel1.tiles.Axes.embedding.Parent,"on");
    nexObj.Figure.panel1.tiles.Axes.highlightMarker = scatter3(nexObj.Figure.panel1.tiles.Axes.embedding.Parent, pointData(1), pointData(2), pointData(3), 100, 'r', 'filled');
    % hold off;

    % resconstruct sessionlabel
    [sessionLabel, trialNum] = nex_findSessionLabel(nexObj.nexon, labelData, nexObj.DF.labelKeys);
    sessionLabel_app = sprintf("%s_trial--%d",sessionLabel,trialNum);
    fprintf("SESSION SELECTED: %s\n",sessionLabel_app);
    % force router redirect to sessionlabel
    nexUpdate_router(nexObj.nexon, sessionLabel_app, convertCharsToStrings(labelData.Properties.VariableNames));
    % Display clicked point
    % fprintf('Clicked on point: (%.3f, %.3f)\n', x(idx), y(idx));
end
