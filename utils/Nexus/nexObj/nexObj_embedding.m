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
    end

    methods
        % constructor
        function obj = nexObj_embedding(nexon, Parent, compFcn, dfID)
            obj.dfID = dfID;
            obj.opCfg.opFcn=str2func("embedUMAP");
            obj.opCfg.entryParams = extractMethodCfg('embedUMAP');            
            % load embedding data (if exists)
            try obj.loadEmbedding("labels"); catch; end                
            try obj.loadEmbedding("DF_postOp"); catch; end            
            obj.Figure = nexFigure_embedding(obj);
        end

        % update method
        function updateScope(obj, nexon)
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