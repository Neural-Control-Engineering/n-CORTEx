function tc = roiTimecourse(datastream, f, t, bands)
    figure
    % set(gcf,'Position',[0.0050    0.4650    1.3455    0.3050]*1000);
    subplot(1,2,1)
    % eval(sprintf('datahere = mask.*data.%s;',colnames{j}));
    % eval(sprintf('bg = mean(data.%s(:,:,50:100),3);',colnames{j}));
    imagesc(f,[1:384],squeeze(datastream(:,:,100)));
    axis image
    caxis([-40,-30]); % SINGLE
    colormap cool
    title('Use cursor to select a region of interest');
    [x, y] = ginput(2);
    f_bounds = find(f>min(x) & f<max(x));
    % x=round(x);
    y = round(y);
    hold on
    plot([min(x) min(x) max(x) max(x) min(x)],[min(y) max(y) max(y) min(y) min(y)],'--y');
    % plot([f_bounds(1) f_bounds(1) f_bounds(end) f_bounds(end) f_bounds(1)],[min(y) max(y) max(y) min(y) min(y)],'--y');
    subplot(1,2,2)
    % for j=1:4;
    % eval(sprintf('datahere = mask.*data.%s;',colnamesH{j}));
    % eval(sprintf('bg = mean(data.%s(:,:,50:100),3);',colnamesH{j}));
    tc = squeeze(mean(mean(datastream(min(y):max(y),f_bounds(1):f_bounds(end),:),2),1));
    plot(t,tc);
    xline(0);
    xlabel("time (s)");
    ylabel("spectral power")

    if ~isempty(bands)
        figure;
        bandFields = fieldnames(bands);       
        for i = 1:length(bandFields)
            band = bandFields{i};
            disp(band)
            f_bounds = bands.(band);            
            tc = squeeze(mean(mean(datastream(min(y):max(y),f_bounds(1):f_bounds(end),:),2),1));
            plot(t,tc);            
            hold on
        end
        legend(bandFields)
        xline(0);
    end
    % if j<4
    %     plot([0:size(tc,2)-1]./(m.framerate/m.nLEDs),(tc(j,:)),'color',cols{j});
    % else
    %     plot([0:size(tc,2)-1]./(m.framerate/m.nLEDs),100*(tc(j,:)*1e-5),'color',cols{j});
    % end
    % hold on
end
