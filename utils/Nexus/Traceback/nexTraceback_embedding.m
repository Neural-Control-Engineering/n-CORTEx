function nexTraceback_embedding(src, event, nexObj)
        % Get clicked point coordinates
    clickedPoint = event.IntersectionPoint(1:2); % Extract X and Y
    
    % Find the closest data point in the scatter plot
    dfSel = nexObj.UserData.DF_postOp_sel.df;
    x = dfSel(:,1); y = dfSel(:,2); z = dfSel(:,3);
    distances = vecnorm([x(:), y(:), z(:)] - clickedPoint, 2, 2); % Euclidean distance
    [~, idx] = min(distances); % Find index of nearest point
    pointData = nexObj.UserData.DF_postOp_sel.df(idx,:);
    % isolate point data
    [isFound, pointIdx] = ismember(nexObj.DF_postOp.df,pointData,'rows');
    % locate point label data in primary df (postOp)
    if isFound
        labelData = nexObj.DF_postOp.Y(pointIdx,:);
    end
    % resconstruct sessionlabel
    sessionLabel = nex_findSessionLabel(nexObj.nexon, labelData, nexObj.DF.labelKeys);
    % force router redirect to sessionlabel
    
    % Display clicked point
    % fprintf('Clicked on point: (%.3f, %.3f)\n', x(idx), y(idx));
end