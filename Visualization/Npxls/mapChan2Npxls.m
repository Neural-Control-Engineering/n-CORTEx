function [NT, NT_color] = mapChan2Npxls(regMap, dataStream)
    % bin 384 channel datastream into npxls style heatmap
    % return a neuropixels tensor (NT) for video gen
    NT = zeros(96,4,size(dataStream,2));
    NT_color = zeros(96,4);
    colors = string(unique(regMap.color));    
    for i = 1:height(regMap)
        npxChan = regMap(i,:);
        channelNum = npxChan.channel{1};
        X = npxChan.X{1};
        Y = npxChan.Y{1};
        X_shift = (X-11)/16+1;
        Y_shift = floor((Y-240) / 40)+1;
        NT(Y_shift,X_shift,:) = dataStream(i,:);
        % NT_color(Y_shift,X_shift,:) = hex2dec(npxChan.color{1});
        % NT_color(Y_shift,X_shift) = hex2dec((npxChan.color{1}));
        NT_color(Y_shift,X_shift) = find(contains(colors,(npxChan.color{1})));
    end

    NT = flip(NT,1);
    NT_color = flip(NT_color,1);

    % NT_color = NT_color(:,:,1);
    colors = string(unique(regMap.color));    
    colors = strcat("#",colors)
    
    cMap = validatecolor(colors,'multiple')
    fh = figure
    % imagesc(NT_color)      
    h = heatmap(NT_color)
    % h.CellLabelFormat = '%.2f';
    % cRange = [hex2dec(strrep(rgb2hex(cMap(1,:)),'#','')), hex2dec(strrep(rgb2hex(cMap(end,:)),'#',''))];
    colormap(cMap)
    h.CellLabelColor='none'
    h.ColorbarVisible='off'
    % daspect([18,14,1]);
    set(gcf,'Position',[320,116,120,1602]);
    set(gcf,'Color',[1,1,1])
    % set(gcf,'InnerPosition', [320,116,120,1602]);     
    % set(gcf,'GridColor',[0,0,0])
    caxis([1,8])

    

end