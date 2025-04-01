classdef nexObj_embedding < handle
    properties
        classID
        nexon
        Parent
        Partners 
        Children % hold sub-Objs (e.g. spectrogram)
        Origins
        DF % df pre operation function (behavior depends on online or offline status); struct containing df and ax 
        DF_postOp % df post operation function (behavior depends on online or offline status); struct containint df and ax (and opCfg!?)
        labelSelection
        visSelection
        entryPanel
        dfID % DTS df identifier (trial-wise)
        preBufferLen
        Fs
        Figure % figure handle       
        compCfg
        exportCfg
        opCfg
        visCfg        
        UserData        
        isOnline
        isStatic        
        keyListener
    end

    methods
        % constructor
        function obj = nexObj_embedding(nexon, Parent, opFcn, dfID)
            obj.nexon = nexon;
            obj.dfID = dfID;
            if isempty(opFcn)
                obj.opCfg.opFcn=str2func("embedUMAP");
                obj.opCfg.entryParams = extractMethodCfg('embedUMAP');            
            else
                obj.opCfg.opFcn=opFcn;
                obj.opCfg.entryParams = extractMethodCfg(func2str(opFcn));            
            end            
            % load embedding data (if exists)
            try obj.loadEmbedding("Y"); catch; end                
            try obj.loadEmbedding("DF_postOp"); catch; end      
            % build label and dim selections
            % LABEL SELECTION
            try
                for i = 1:size(obj.DF.Y,2)
                    key = obj.DF.Y.Properties.VariableNames{i};
                    values = table2array(unique(obj.DF.Y(:,i)));
                    if i==1
                        obj.labelSelection = nexObj_selectionBus(obj, key, values);
                    else
                        obj.labelSelection.addKey(key, values);
                    end
                end
            catch e
                disp(getReport(e));
            end
            % DIM SELECTION
            try
                key = "dimensions";
                values = [1:size(obj.DF_postOp.df,2)];
                obj.visSelection = nexObj_selectionBus(obj, key, values);
                key = "label";
                values = convertCharsToStrings(obj.DF.Y.Properties.VariableNames');
                obj.visSelection.addKey(key, values);
            catch e
                disp(getReport(e));
            end
            nexFigure_embedding(obj);
        end

        % update method
        function updateScope(obj, nexon)
            % update DF_postOp if cfg changes
            % update visualization
            visArgs = [];
            nexVisualization_embedding(nexon,obj,visArgs);
        end

        function loadEmbedding(obj, key)
            ftrPath = "/media/user/Expansion/nCORTEx_local/Project_Neuromodulation-For-Pain/Experiments/JOLT/Data/FTR/TRAIN"; % currently hard-coded            
            dataPath = fullfile(ftrPath,obj.dfID);
            switch key
                case "labelKeys"                  
                    labelKeysFile = fullfile(dataPath,"labelKeys.json");                    
                    labelKeysJson = fileread(labelKeysFile); % Read JSON file as a string
                    obj.DF.labelKeys = jsondecode(labelKeysJson); % Decode JSON                    
                case "Y" % load labels only
                    YFile = fullfile(dataPath,"Y.csv");
                    labelKeysFile = fullfile(dataPath,"labelKeys.json");
                    obj.DF.Y = readtable(YFile);
                    labelKeysJson = fileread(labelKeysFile); % Read JSON file as a string
                    obj.DF.labelKeys = jsondecode(labelKeysJson); % Decode JSON                    
                case "X"
                case "DF_postOp"      
                    opArgsLabel = nex_generateArgsLabel(obj.opCfg.entryParams);
                    embedResultLabel = sprintf("%s%s",func2str(obj.opCfg.opFcn),opArgsLabel);
                    embedDataPath = fullfile(dataPath,embedResultLabel);
                    dfEmbedFile = fullfile(embedDataPath,"df.csv");
                    YEmbedFile = fullfile(embedDataPath,"Y.csv");
                    obj.DF_postOp.df = readmatrix(dfEmbedFile);
                    obj.DF_postOp.Y = readtable(YEmbedFile);
            end
        end

    end
end