function plotSGBars_channels(regMap, P, groups, groupLabels)
    regMapFlip = flip(regMap,1);
    regs = (regMapFlip.region);    
    % figure;
    % T = tiledlayout(length(regs),length(P));        
    % tset =
    for i = 1:height(regMapFlip)
        % nexttile(T);
        reg = regs{i};
        regChans = regMap(contains(regMapFlip.region,reg),"channel");
        % ch = table2mat(regChans);
        ch = i;
        regColor = unique(regMapFlip(contains(regMapFlip.region,reg),"color"));
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
        % set(gcf,"Position",[29,1025,3762,504]);        
        figure; t = tiledlayout(1,length(P));
        title(t,sprintf("ch%d--(%s)",i,reg))
        for j = 1:length(P)
            nexttile(t);
            specParam = P{j};            
            specMean = [];
            specSem = [];
            for k = 1:size(groups,2)
                SG = groups{k};
                sgLabel = groupLabels(k);
                sgData = cell2mat(squeeze(SG(ch,j,:)));
                % Average across channels and trials
                sgMean = mean(sgData,1,"omitmissing");
                % sgMean = mean(sgMean,2,"omitmissing");
                % Standard deviation across channels and trials
                std1 = std(sgData,1,1,"omitmissing");
                sgSem = std1 / sqrt(size(sgData,1));                             
                % compile
                specMean = [specMean, sgMean];
                specSem = [specSem, sgSem];
            end
            % PLOT BARS
            b = bar(categorical(groupLabels),specMean);
            b.FaceColor = strcat("#",regColor);
            hold on;    
            er = errorbar(categorical(groupLabels),specMean,specSem);
            er.Color = [0 0 0];
            er.LineStyle = 'none';
            hold off;
            title(sprintf("%s",strrep(specParam,"_","-")));
        end
        figTitle = sprintf("ch%d--%s.png",i,reg);
        set(gcf,"Position",[14,1242,3796,540]);
        drawnow;
        saveas(gcf,figTitle);
        % close(gcf);
    end
    % plot bars together
end