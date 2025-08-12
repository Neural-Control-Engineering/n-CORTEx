function cameraCtrl_convertBinaryFrames2Avi(frameDir)
    % Define directory with .bin files
    % frameDir = 'frames';
    
    % List all .bin files and sort by name
    frames = dir(fullfile(frameDir,'*.bin'));
    [~,idx] = sort({frames.name}); 
    frames = frames(idx);  
    
    % Prepare video (fps might be hardcoded or determined separately)
    fps = 30;
    output_file = 'output_video.avi';
    v = VideoWriter(output_file);
    v.FrameRate = fps;
    open(v)
    
    % Loop through files
    for i = 1:length(frames)
        fname = fullfile(frameDir,frames(i).name);
        fid = fopen(fname,'r');    
        
        % 1. First 4 bytes = width (uint32)
        width = fread(fid,1,'uint32'); 
        % 2. Next 4 bytes = height (uint32)
        height = fread(fid,1,'uint32'); 
        % 3. Next 4 bytes = channels (uint32)
        channels = fread(fid,1,'uint32');  
    
        % 4. The rest is pixel data
        raw = fread(fid,'uint8'); 
        fclose(fid);
        
        % Reshape based on dimensions
        if channels == 1
            img = reshape(raw, [width, height]);
            img = img';
        else
            img = reshape(raw, [width, height, channels]);
            img = permute(img, [2 1 3]);
        end
        
        writeVideo(v, img);
    end
    
    close(v);
end