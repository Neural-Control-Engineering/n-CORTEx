function plotNpxlsStream(data)
    x = 1:size(data,1);
    y = size(data,2);
    div = 40;
    % y = mat(:,1);
    figure; t = tiledlayout(ceil(y/div),1);
    for i = 1:div:y
        nexttile(t);
        plot(x,data(:,i));
    end
    set(gcf,"Position",[320,188,560,1530])
    % figure(1);
    % set(gcf, 'doublebuffer', 'on');
    figure; plot(x, data(:,769));
    set(p, 'XData', x, 'YData', y);
    drawnow;
end