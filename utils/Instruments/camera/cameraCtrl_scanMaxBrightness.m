function maxIntensity = cameraCtrl_scanMaxBrightness(frameDir)
%SCANMAXBRIGHTNESS Scans .bin image files to find global maximum intensity
%
%   maxIntensity = scanMaxBrightness(frameDir)
%
%   This function reads each .bin image file in the specified folder,
%   extracts the pixel data, and returns the maximum intensity value
%   found across all frames.

    files = dir(fullfile(frameDir, '*.bin'));
    if isempty(files)
        error('No .bin files found in the directory: %s', frameDir);
    end

    maxIntensity = -inf;

    for i = 1:numel(files)
        fname = fullfile(frameDir, files(i).name);
        fid = fopen(fname, 'r');
        if fid == -1
            warning('Could not open file: %s', fname);
            continue;
        end

        % Read image header
        width    = fread(fid, 1, 'uint32');
        height   = fread(fid, 1, 'uint32');
        channels = fread(fid, 1, 'uint32');

        % Read pixel data (assumed to be uint16 here)
        raw = fread(fid, 'uint16');
        fclose(fid);

        % Reshape according to header
        if channels == 1
            img = reshape(raw, [height, width])';
        else
            img = reshape(raw, [height, width, channels]);
            img = permute(img, [2 1 3]);
        end

        % Update max
        maxIntensity = max(maxIntensity, double(max(img(:))));
    end
end
