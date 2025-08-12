function camTable = compileCamParams(camStruct)
    camList = fieldnames(camStruct);
    camTable = [];
    for i = 1:length(camList)
        cam = camList{i};
        row = (camStruct.(cam));
        if isempty(camTable)
            camTable = row;
        else
            camTable = [camTable; row];
        end        
    end
    camTable = struct2table(camTable);
    camTable.target = convertCharsToStrings(camTable.target);
end