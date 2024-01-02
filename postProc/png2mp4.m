function png2mp4(png, fileType, frameRate, label, debayer)   
    switch fileType
        case "dir"
            % Check if the specified folder exists
            if ~isfolder(png)
                error('Folder does not exist: %s', png);
            end
            
            % Define the output video file name in the same folder
            % [~, folderName, ~] = fileparts(png);
            outputVideoFile = fullfile(png, strcat(label));
            
            % Create a VideoWriter object
            outputVideo = VideoWriter(outputVideoFile);
            outputVideo.FrameRate = frameRate; % Set the frame rate (adjust as needed)
            open(outputVideo);
            
            % List all the PNG files in the folder
            pngFiles = dir(fullfile(png, '*.png'));
            
            % Loop through the PNG files and write them to the video
            for i = 1:length(pngFiles)
                % get png name
                pngName=sprintf("frame_%d.png",i-1);
                % disp(pngName);
                % Read the PNG image
                img = imread(fullfile(png, pngName));

                if debayer
                    img = demosaic(img,'rggb');
                end
                
                % Write the image to the video
                writeVideo(outputVideo, img);
            end
            
            % Close the video file
            close(outputVideo);
            
            disp(['Video created: ', outputVideoFile]);
            
            % Delete the PNG files
            for i = 1:length(pngFiles)
                delete(fullfile(png, pngFiles(i).name));
            end
        otherwise
            disp("Warning: Invalid fileType. Use 'dir' to specify a directory.")
    end
end