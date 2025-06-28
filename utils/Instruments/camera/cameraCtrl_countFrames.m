function numFrames = cameraCtrl_countFrames(framesFile, frameDim)
    width = frameDim.width;
    height = frameDim.height;
    channels = frameDim.channels;
    byteDepth = frameDim.byteDepth;
    fileSize = framesFile.bytes; 
    numFrames = round(fileSize/ (width*height*channels*byteDepth));
    % filename = fullfile(framesFile.folder,framesFile.name);
    % fid = fopen(filename, 'rb');
    % % data = fread(fid, [width * height * channels, numFrames], dtype);
    % data = fread(fid, [width * height * channels, numFrames], "uint8");
    % fclose(fid);
end