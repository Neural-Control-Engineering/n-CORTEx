function gifOverAxis(gifCfg, Data)    
    % loop over dim-specified axis, plotting time indexed figure dictated
    % by data.view format; data.dataStream is a cell array containing each
    % tensor to be included in the figure (must all be same size along
    % 'dim'); if there are multiple tensors in the cell, the figure will
    % display all tensors tile-wise

    % data is a cell array containing data objects for plotting

    % data.view         = change figure format; supports 'iso' - include
    % isometric, 'mesh' - TBD 

    % preVars
    dataBuffer = [];    

    ax = Data{1}.axs.(Data{1}.axs.sweepAx);
    for i = 1 : length(ax)      
        % Tile = tiledlayout(1,length(Data));                   
        % update axis value
        tick = ax(i);      
        
        % Tile = tiledlayout(size(Data,1),size(Data,2));
        
        % Plot figure (for each tensor)
        
        for j = 1 : length(Data) 
            fh(j) = figure('visible','off');     
            % fh(j) = figure;
            ph(j) = uipanel(fh(j));
            % nexttile(Tile);            
            % subAx = subplot(size(Data,1),size(Data,1),j);
            data = Data{j};
            tnsr = data.dataStream;
            label = sprintf("%s %s",num2str(tick),data.label);
            dataFrame = sliceTnsr(tnsr,data.sweepDim,i);
            % plot formatted dataframe
            if isfield(data,'bufferDim')   
                dataBuffer = cat(data.bufferDim, dataBuffer, dataFrame);                          
                dataFrame = dataBuffer;
            end     
            cmd = sprintf("ph(j) = df2Fig_%s(ph(j), data, dataFrame, label);",data.plot);
            eval(cmd);                 
        end
        % Create combined figure
        fh_main = figure('visible','off');
        % fh_main.Visible='off';
        npanels = numel(ph);
        ph_sub = nan(1,npanels);
        % Copy over the panels
        for idx = 1:npanels
            ph_sub(idx) = copyobj(ph(idx),fh_main);
            set(ph_sub(idx),'Position',[(idx-1)/npanels,0,(1)/npanels,1]);
        end
        if strcmp(data.plot,'NT')
            set(gcf,'Position', [769,98,200,1847]);     
            colormap(data.colorMap);
            caxis([-36,-32]);
        else
            set(gcf, 'Position', [100, 100, 1250, 900]);             
            colormap cool
            caxis([-40,-30]);
        end
        
        % caxis([-5,15]);
        
        title(label)
        %% WRITE TO GIF
        frame = getframe(fh_main);
        img = frame2im(frame);
        [A, map] = rgb2ind(img, 256);
        pause(0.05);
        if i == 1                    
            imwrite(A, map, gifCfg.filename, 'gif', 'LoopCount', Inf, 'DelayTime', gifCfg.frameDelay);
        else                    
            imwrite(A, map, gifCfg.filename, 'gif', 'WriteMode', 'append', 'DelayTime', gifCfg.frameDelay);
        end
        close(fh);
        close(fh_main);
    end    
end