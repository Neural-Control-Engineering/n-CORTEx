function cameraCtrl_writeBinaryToMp4(framesFile, frameDim, outputFile, fps, pixelFormat)
    % Parameters
    numFrames = cameraCtrl_countFrames(framesFile, frameDim);
    chunkSize = 500;
    height = frameDim.height;
    width = frameDim.width;
    totalPixels = height * width;

    % Select FFmpeg pixel format and command
    switch pixelFormat
        case "BayerRG8"
            ffmpegPixFmt = 'rgb24';  % demosaiced to RGB
        case "Mono8"
            ffmpegPixFmt = 'gray';   % single channel
        otherwise
            error('Unsupported pixel format: %s', pixelFormat);
    end

    safe_ffmpeg_path = getenv('HOME');  % get home folder path
    safe_ffmpeg_path = fullfile(safe_ffmpeg_path, '.local', 'bin', 'safe_ffmpeg.sh');
    
    cmd = sprintf(['%s -y -f rawvideo -vcodec rawvideo ' ...
        '-pix_fmt %s -s %dx%d -r %d -i - ' ...
        '-an -c:v libx264 -pix_fmt yuv420p -preset fast -crf 23 %s'], ...
        safe_ffmpeg_path, ffmpegPixFmt, width, height, fps, outputFile);   

    % Launch ffmpeg subprocess
    ffmpeg = java.lang.Runtime.getRuntime().exec(cmd);
    stdin = ffmpeg.getOutputStream();
    % read stderr asynchronously:
    % Set up reader for FFmpeg stderr
    stderr = ffmpeg.getErrorStream();
    reader = java.io.InputStreamReader(stderr);
    buffered = java.io.BufferedReader(reader);
    cameraCtrl_ffmpegMonitor(stderr);

    % Open the binary frame file
    filename = fullfile(framesFile.folder, framesFile.name);
    fid = fopen(filename, 'rb');

    if fid < 0
        error('Could not open binary file: %s', filename);
    end
    % dummyFrame = uint8(repmat(reshape([255 0 0], 1, 1, 3), [1080, 1440, 1]));  % Red RGB frame
    % % flatBytes = reshape(permute(dummyFrame, [2,1,3]), 1, []);  % WxHx3
    % flatBytes = reshape(dummyFrame,1,[]);
    % frameBytes = typecast(flatBytes, 'int8');
    % 
    % for i = 1:100
    %     stdin.write(frameBytes, 0, numel(frameBytes));
    %     % stdin.write(dummyFrame);
    %     stdin.flush();
    % end
    % stdin.close()


    % Read and process frames in chunks
    for i = 1:chunkSize:numFrames
        batchEnd = min(i + chunkSize - 1, numFrames);
        framesInChunk = batchEnd - i + 1;

        switch pixelFormat
            case "BayerRG8"
                % Raw Bayer = 1 byte per pixel
                rawData = fread(fid, [width, height * framesInChunk], 'uint8');
                for j = 1:framesInChunk
                    % tic
                    idxStart = (j-1) * height + 1;
                    idxEnd = j * height;
                    % idxStart = (j-1) * width + 1;
                    % idxEnd = j * width;
                    rawFrame = uint8(rawData(:, idxStart:idxEnd)); % WxH
                    rawFrame = permute(rawFrame, [2,1]);    % -> HxW
                    
                    rgb = demosaic(rawFrame, 'rggb');       % HxWx3
                    
                    % rgb_perm = permute(rgb, [2,1,3]);            % -> WxHx3 for FFmpeg
                    rgb_perm = permute(rgb, [3, 2, 1]);            % -> WxHx3 for FFmpeg
                    flatBytes = reshape(rgb_perm, 1, []);    % Flatten to 1D array
                    % flatBytes(1:3)
                    % fwrite(stdin, rgb, 'uint8');
                    % Java needs an int8 array (which maps to uint8 for raw bytes)
                    % stdin.write(typecast(uint8(flatBytes), 'int8'));
                    stdin.write((flatBytes),0,numel(flatBytes));
                    stdin.flush();
                    % toc
                end

            case "Mono8"
                rawData = fread(fid, [width, height * framesInChunk], 'uint8');
                for j = 1:framesInChunk
                    idxStart = (j-1) * height + 1;
                    idxEnd = j * height;
                    grayFrame = rawData(:, idxStart:idxEnd);     % WxH
                    grayFrame = permute(grayFrame, [2,1]);       % → HxW
                    flatGray = reshape(grayFrame, 1, []);        % 1D
                    stdin.write(typecast(uint8(flatGray), 'int8'));
                end

        end
    end

    fclose(fid);
    stdin.close();            % Tell FFmpeg input is done
    exitCode = ffmpeg.waitFor();
    fprintf('FFmpeg exited with code %d\n', exitCode);
    
    % stderr = ffmpeg.getErrorStream();
    % reader = java.io.InputStreamReader(stderr);
    % buffered = java.io.BufferedReader(reader);
    
    % while true
    %     line = buffered.readLine();
    %     if isempty(line) || line == -1
    %         break;
    %     end
    %     disp(['FFmpeg: ', char(line)]);
    % end

end
