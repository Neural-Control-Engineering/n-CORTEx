function cameraCtrl_convertBinaryFrames2mp4(frameDir, frameDim, outputFile, fps, pixelFormat)
    % Default arguments
    if nargin < 2
        outputFile = 'output_video.mp4';
    end
    if nargin < 3
        fps = 50;
    end

    maxScaler = 2^6;
    intensityScaler=1;
    chunkSize = 100; % number of frames to load into memory at once

    % Create a temporary directory to store images
    % tempImgDir = fullfile(frameDir, 'temp_frames');
    % outputFolder = strrep(outputFile,".mp4","");
    % if ~exist(outputFolder, 'dir')
    %     mkdir(outputFolder);
    % end

    % Get sorted .bin files
    frames = dir(fullfile(frameDir, '*.bin'));
    [~, idx] = sort({frames.name});
    frames = frames(idx);

    % brightness scaling
    % maxIntensity = cameraCtrl_scanMaxBrightness(frameDir)

    fprintf('Converting %d frames to images...\n', numel(frames));        
    % Loop and save as PNGs
    % ax_img = imagesc();
    
    tic
    cameraCtrl_writeBinaryToMp4(frames, frameDim, outputFile, fps, pixelFormat);
    toc
    
    % parfor i = 1:numel(frames)
    % % for i = 1:numel(frames)
    %     fname = fullfile(frameDir, frames(i).name);
    %     fid = fopen(fname, 'r');
    % 
    %     width = fread(fid, 1, 'uint32');
    %     height = fread(fid, 1, 'uint32');
    %     channels = fread(fid, 1, 'uint32');
    %     raw = fread(fid, 'uint8');
    %     fclose(fid);
    % 
    % 
    %     % Convert to image
    %     if channels == 1
    %         % img = reshape(raw, [width, height])';
    %         img = reshape(raw, [height, width])';
    %     else
    %         % img = reshape(raw, [width, height, channels]);
    %         img = reshape(raw, [height, width, channels]);
    %         img = permute(img, [2 1 3]);
    %     end
    % 
    %     % pixel format control
    %     switch pixelFormat
    %         case "BayerRG8"
    %             % img_gpu=gpuArray(img);
    %             img_format = demosaic(uint8(img),"rggb");
    %         case "Mono"
    %             img_format = img;
    %     end
    % 
    %     % imagesc(img)
    %     % ax_img.CData = img;
    %     % drawnow()
    % 
    %     % Write image to disk (zero-padded numbering for ffmpeg)
    %     % img_scaled = uint16(double(img) / double(max(img(:))) * 65535);
    %     img_scaled = uint8(((img_format*intensityScaler)));
    %     % img_scaled = img_format;
    %     imwrite(img_scaled, fullfile(outputFolder, sprintf('%010d.png', i)), 'png', 'BitDepth', 8);
    % 
    %     % imwrite(uint16(img), fullfile(outputFolder, sprintf('%010d.png', i)),"png","BitDepth",16);
    % 
    % 
    % end

    % Use ffmpeg to encode images into mp4
    % ffmpegCmd = sprintf('ffmpeg -y -framerate %d -i "%s/frame_%%05d.png" -c:v libx264 -pix_fmt yuv420p "%s"', ...
    %     fps, tempImgDir, outputFile);
    % fprintf('Running ffmpeg to create mp4...\n');
    % status = system(ffmpegCmd);
    % 
    % if status == 0
    %     fprintf('Successfully created %s\n', outputFile);
    % else
    %     error('ffmpeg failed. Please ensure it is installed and on your system path.');
    % end

    % png2mp4Path = fullfile(params.paths.nCORTEx_repo,"postProc","png2mp4.sh");                                
    % ffmCmd = sprintf("%s %d %s", png2mp4Path, camFS, localPath);              
    % ffmCmd = sprintf("png2mp4.sh %d %s", fps, outputFolder);              
    % setenv('LD_PRELOAD', '/usr/lib/x86_64-linux-gnu/libstdc++.so.6');
    % system(ffmCmd);   
    % if conversion successful, remove pngs
    % if isfile(sprintf("%s.mp4",localPath))
    % if isfile(outputFile)
    %     % rmdir(localPath,"s") % cleanup
    %     rmdir(outputFolder,"s"); % remove pngs
    %     delete(fullfile(frameDir, '*.bin')); % remove binaries   
    %     % error("png to mp4 conversion for session: %s failed",sessionLabel)
    % end

    % Optional: Clean up temp images
    % rmdir(tempImgDir, 's');
end
