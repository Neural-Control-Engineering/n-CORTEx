function data_ft = raw2ft(params, data_raw, fsample)    
    data_ft.trial = data_raw;
    data_ft.fsample = fsample;
    

    time = timeAxis(data_raw{1}, fsample);
    timeCell = cell(size(data_raw));
    time = cellfun(@(~) time, timeCell, 'UniformOutput', false);
    data_ft.time = time';
    
    data_ft.label = cellstr(string(num2str([1:1:size(data_raw{1},1)]')));
    
end