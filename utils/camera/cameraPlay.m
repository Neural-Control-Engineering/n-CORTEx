function cameraPlay(params, camera, filePath, fileName, cue)
    % wrap spinnaker parameters and initiate cameras (using spinTEX)
    cameras = fieldnames(camera);
    % Use parfeval to run the Python scripts concurrently
    % % app.params.spinParams.camSelect=app.params.spinParams.pupilSN;
    % % spinParams0 = struct2dict(app, app.params.spinParams);
    % % app.params.spinParams.camSelect=app.params.spinParams.whiskSN;
    % % spinParams1 = struct2dict(app, app.params.spinParams);
    % % spinParamsJSON0 = jsonencode(spinParams0);
    % % spinParamsJSON1 = jsonencode(spinParams1);    
    
    % build system command 
    % cmd = "parallel './callSpinTEx.sh' ::: ";
    cmd = sprintf("parallel '%s' ::: ",params.paths.nCORTEx_repo);
    JSON = struct;
    for i = 1:length(cameras)
        camParams = struct;
        cam = cameras{i};
        % camera.(cam).spinParams.saveDir = filePath;
        camParams.spinParams = camera.(cam).spinParams;
        camParams.SN = camera.(cam).SN;
        cameraDir = sprintf("S%s",camera.(cam).SN);
        camParams.saveDir= fullfile(filePath, 'CAMERA', cameraDir, fileName);
        buildPath(camParams.saveDir);
        % camParams.sessionLabel = fileName;
        camParams.execStatus = cue;
        % camParams.camSelect = ca;
        % JN = sprintf("J%d",i);
        camParams = structToDict(camParams);
        JSON = jsonencode(camParams);
        cmd = sprintf("%s %s", cmd, JSON);
    end
    % cmd = sprintf("%s %s", cmd);
    cmd = sprintf("%s %s", cmd, ' &');
    % cmd = sprintf("%s %s", cmd, '');
    system(cmd);
    % pause(5)
end