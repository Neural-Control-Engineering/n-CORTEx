function Tnsr2Movie(params, tnsr)
    % convert 3D tensor into gif cycling through each matrix slide
    % for tnsr struct objects create a subplot for each sub tnsr 
    % tnsr struct handling assumes each tensor has the same size along the
    % 3rd dimension (i.e. same number of frames in time)
    state = isstruct(tnsr);
    % make a local folder to store movie
    movieDir = uigetdir();
    if ~isfolder(fullfile(movieDir,"Movies"))
        mkdir(fullfile(movieDir,"Movies"));        
    end
    movieDir = fullfile(movieDir, "Movies");
    switch state
        case 1
            tnsrs = fieldnames(tnsr);
            numTnsrs = length(tnsrs); 
            timeLen = size(tnsr.(tnsrs{1}),3);
            for t = 1:timeLen
                
                fig = figure;
                % Set the desired aspect ratio
                aspectRatio = [12, 4]; % Width-to-height ratio

                % Set the desired figure size
                figureWidth = 3600; % in pixels
                figureHeight = figureWidth * aspectRatio(2) / aspectRatio(1); % Calculate height based on aspect ratio
                
                % Set the figure size and position
                set(gcf, 'Position', [100, 100, figureWidth, figureHeight]);

                for i = 1:numTnsrs
                    tnsrName = tnsrs{i};
                    T = tnsr.(tnsrName);
                    subplot(1,numTnsrs,i);                    
                    imagesc(T(:,:,t));
                    xlabel(tnsrName);
                end
                % save frame
                drawnow
                pause(2)
                figName = sprintf('frame%d.png',t);
                figName = fullfile(movieDir,figName);
                exportgraphics(fig,figName);
                close(fig);
            end

            % convert to gif
            filename = 'TnsrMovie';
            for t = 1:timeLen
                if i == 1
                    img = imread(fullfile(movieDir,sprintf("frame%d.png",t)));
    %             pause(1.5);
                    [A, map] = rgb2ind(img, 256);
                    imwrite(A, map, filename, 'gif', 'LoopCount', Inf, 'DelayTime', params.gifCfg.frameDelay);
                else
                    img = imread(fullfile(movieDir,sprintf("frame%d.png",t)));
    %             pause(1.5);
                    [A, map] = rgb2ind(img, 256);
                    imwrite(A, map, filename, 'gif', 'WriteMode', 'append', 'DelayTime', params.gifCfg.frameDelay);
                end
            end

        otherwise 
    end
end