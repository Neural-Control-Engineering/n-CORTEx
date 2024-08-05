function buildExperimentDirectory(expPath, modalityList_RAW, extLayers, opStat)
    disp(expPath);
    mkdir(expPath);
    % Experiment Layer
    mkdir(fullfile(expPath,"Data"));
    mkdir(fullfile(expPath,"Subjects"));
    mkdir(fullfile(expPath,"Instruments"));
    mkdir(fullfile(expPath,"Extraction-Logs"));
    % Extraction Logs
    % dataLayers = ["RAW","EXT","DTS","FTR"];
    buildExtractionLogs(fullfile(expPath,"Extraction-Logs"),extLayers);
    % Data Layers
    dataPath = fullfile(expPath,"Data");
    for i = 1:length(extLayers)
        extLayer = extLayers(i);
        mkdir(fullfile(dataPath,extLayer));
    end   
    if strcmp(opStat,"merge")
        selMods = modalityList_RAW;
        tf = ones(size(modalityList_RAW));
    else
        % Data Mod Selection    
        [sel, tf] = listdlg("Name","Modality Selection","PromptString",[{sprintf("Select your data modalities")},{''},{''}], "ListString", [modalityList_RAW';{''};{''};{''}]);
        selMods = modalityList_RAW(sel);
    end
    % modGen
    rawDataPath = fullfile(dataPath,"RAW");
    localDataPath = strrep(rawDataPath,"nCORTEx_cloud","nCORTEx_local");
    if tf == 1     
      for i = 1:length(selMods)      
          selMod = upper(selMods(i));
          mkdir(fullfile(rawDataPath,selMod));
          mkdir(fullfile(localDataPath, selMod));
      end    
    end
    

end