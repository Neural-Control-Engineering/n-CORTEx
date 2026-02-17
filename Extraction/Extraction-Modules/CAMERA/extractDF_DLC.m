function DF_dlc = extractDF_DLC(params, session)
    % recover session-related dlc output acting body part coordinates for each frame and
    % storing in a DF for further processing

    %% load output table
    path_camera_cloud = params.paths.Data.RAW.CAMERA.cloud;
    file_dlcOutput = sprintf("%s.csv", session);
    path_dlcOutput = fullfile(path_camera_cloud, file_dlcOutput);
    %% read dlc output
    [T_dlc, H_dlc] = readtable_dlc(path_dlcOutput);
    h_coords = H_dlc.coords(2:end); % drop initial 'coords' element 
    h_bodyParts = H_dlc.bodyParts(2:end);
    %% prepare DF
    df = table2array(T_dlc(:,2:end));
    idx_likelihood = (strcmp(h_coords,"likelihood"));
    ax_coords = unique(convertCharsToStrings(h_coords(~idx_likelihood)));
    ax_bodyParts = (convertCharsToStrings(h_bodyParts(idx_likelihood)));
    df_likelihood = df(:,idx_likelihood);
    df_coords = df(:,~idx_likelihood);
    df_coords_reshape = reshape(df_coords, [size(df_coords,1), length(ax_coords), size(df_coords,2)/length(ax_coords)]);
    ax_frame = table2array(T_dlc(:,1));
    ax_bodyParts = unique(convertCharsToStrings(h_bodyParts));
    % assignment
    DF_dlc.df = df_coords_reshape;
    DF_dlc.ax.frame = ax_frame;
    DF_dlc.ax.bodyParts = ax_bodyParts;
    DF_dlc.ax.coords = ax_coords;
    DF_dlc.likelihood = df_likelihood;
end