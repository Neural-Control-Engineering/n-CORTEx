function readAPBinaryData(binFldr, fileName, chan_imec)
    
    fid = fopen(fullfile(binFldr,fileName), 'r');
    
    % Define parameters
    n_channels = 384;      % Depends on your probe/config
    data_type = 'int16';   % SpikeGLX usually stores as 16-bit signed integers
    
    % Read data
    raw_data = fread(fid, [n_channels, Inf], data_type);
    fclose(fid);
    
    % Each column is a sample across all channels
end