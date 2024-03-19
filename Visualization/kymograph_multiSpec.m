function kymograph_multiSpec(datastream, f, t, f_range)
    % columns = [40:120]; % change this
    % deltaCol = find((f>1&f<4));
    % thetaCol = find((f>4&f<10));
    % alphaCol = find((f>10&f<15));
    % betaCol = find((f>15&f<30));
    % gammaCol = find((f>30&f<60));
    % highCol = find(f>60);
    
    % columns = gammaCol;
    columns = find(f>f_range(1)&f<f_range(2));
    % j=7;
    % eval(sprintf('datahere = mask.*data.%s;',colnamesH{j-3}));  
    
    figure
    subplot(121)
    imagesc(f,[1:384],squeeze(mean(datastream(:,:,100:140),3)));
    xlabel('frequency, (Hz)')
    ylabel('channels');
    % title(colnamesH{j-3})
    hold on
    xline(f_range(1),'color','y'); 
    xline(f_range(2),'color','y');
    
    caxis([-40,-30]); % SINGLE
    colormap cool
    subplot(122)
    % imagesc([1:ss(3)]/(m.framerate/m.nLEDs), [1:ss(1)],squeeze(mean(data.gcamp(:,columns,:),2)))
    imagesc(t,[1:384],squeeze(mean(datastream(:,columns,:),2)))
    caxis([-40,-30]); % SINGLE
    xline(0,'color','y')
    xlabel('time (s)');
    ylabel('channels')
    title('kymograph')
end
