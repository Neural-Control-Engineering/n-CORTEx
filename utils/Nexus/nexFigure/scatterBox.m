function scatterBox(calibration, DTS, dfID, phases, subjects, scope, pltMethod)
    % df = DTS.(dfID);
    switch scope
        case "single"
            figure
            tl = tiledlayout(1,length(subjects));        
            sgtitle(dfID);
            for i=1:length(subjects)% for each subject                
                subj = subjects(i);
                subjData = DTS(contains(DTS.sessionLabel,subj),:);
                tAx = nexttile(tl);
                data = [];
                groups = [];
                groupLabels={};
                for j = 1:length(phases)
                    phase=phases(j);
                    phaseData = subjData(contains(subjData.sessionLabel,phase),:);
                    phaseData = phaseData.(dfID);                    
                    if iscell(phaseData)
                        phaseData = cell2mat(phaseData);
                    end
                    if ~isempty(phaseData)
                        % phaseData = phaseData * calibration.fit(1); %+ calibration.fit(2);
                        data = [data; phaseData];
                        phaseTag = repelem(j,length(phaseData))';
                        groups = [groups; phaseTag];
                        groupLabels=[groupLabels,phase];
                    end
                end
                switch pltMethod
                    case "box"
                        boxchart(tAx,groups,data,"BoxWidth",0.5);
                        hold on
                        scatter(tAx,groups, data, 'filled', 'MarkerFaceAlpha', 0.5, 'jitter','on', 'jitterAmount',0.1);
                    case "violin"
                        daviolinplot(data,"groups",groups)
                end
                title(subj);
                xticks(1:4);
                xticklabels(groupLabels);
                title(subj);
                tAx.YLim = [-5, 50];
            end
        case "group"
    end
end

% % Combine data into a single vector
% data = [group1; group2; group3; group4];
% 
% % Create a grouping variable (1, 2, 3, 4) for each group
% groups = [ones(size(group1)); 
%           2 * ones(size(group2)); 
%           3 * ones(size(group3)); 
%           4 * ones(size(group4))];
% 
% % Create the box chart
% figure;
% boxchart(groups, data, 'BoxWidth', 0.5);
% hold on;
% 
% % Overlay scatter plot for each group
% scatter(groups, data, 'filled', 'MarkerFaceAlpha', 0.5, 'jitter','on', 'jitterAmount',0.1);
% DTS_new = DTS2(contains(DTS2.sessionLabel,"2024-10"),:);