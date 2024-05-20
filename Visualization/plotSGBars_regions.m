function plotSGBars_regions(regMap, P, groups, groupLabels)
    regs = unique(regMap.region);
    % figure;
    % T = tiledlayout(length(regs),length(P));        
    % tset =
    for i = 1:length(regs)
        % nexttile(T);
        reg = regs{i};
        regChans = regMap(contains(regMap.region,reg),"channel");
        ch = table2mat(regChans);
        regColor = unique(regMap(contains(regMap.region,reg),"color"));
        regColor = string(regColor.color);
        % for j = 1:size(groups,2)
        %     SG = groups{j};
        %     sgLabel = groupLabels(j);
        %     regData = SG(ch,:,:);
        %     for k = 1:length(P)
        %         specParam = P{k};
        %         specData = regData(:,k,:);
        %     end
        %     % plot bars
        % end
        set(gcf,"Position",[29,1025,3762,504]);
        figure; t = tiledlayout(1,length(P));
        title(t,sprintf("%s",reg))
        for j = 1:length(P)
            nexttile(t);
            specParam = P{j};            
            specMean = [];
            specStd = [];
            for k = 1:size(groups,2)
                SG = groups{k};
                sgLabel = groupLabels(k);
                sgData = cell2mat(squeeze(SG(ch,j,:)));
                % Average across channels and trials
                sgMean = mean(sgData,1,"omitmissing");
                sgMean = mean(sgMean,2,"omitmissing");
                % Standard deviation across channels and trials
                std1 = std(sgData,1,1,"omitmissing");
                std1 = mean(std1,"omitmissing");
                std2 = std(sgData,1,2,"omitmissing");
                std2 = mean(std2,"omitmissing");
                sgStd = sqrt(std1.^2 + std2.^2);
                % compile
                specMean = [specMean, sgMean];
                specStd = [specStd, sgStd];
            end
            % PLOT BARS
            b = bar(categorical(groupLabels),specMean);
            b.FaceColor = strcat("#",regColor);
            hold on;    
            er = errorbar(categorical(groupLabels),specMean,specStd);
            er.Color = [0 0 0];
            er.LineStyle = 'none';
            hold off;
            title(sprintf("%s",specParam));
        end
    end
    % plot bars together
end