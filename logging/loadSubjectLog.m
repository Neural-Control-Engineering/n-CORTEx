function subjNameTable = loadSubjectLog(path)
    path = fullfile(path,"subjectLog.csv");
    if exist(path,"file")        
        subjNameTable = readtable(path,"Delimiter",",");        
    else
        subjNameTable = [];
    end
end