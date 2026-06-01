classdef nexObj_fitScope < handle
    properties
        classID="fitScp"
        nexon        
        DF
        DF_postOp        
        fitCfg                
        mlCfg % 
        Figure
        Parent
        UserData
        ModelObj
    end
    methods
        function nexObj = nexObj_fitScope(Parent, DF, fitFcn)
            nexObj.Parent = Parent;
            nexObj.nexon = Parent.nexon;
            % nexObj.DF = DF;
            nexObj.DF = nex_initAxisPointer(DF);
            % nexObj.DF_postOp = DF;
            % fit method configuration
            nexObj.fitCfg.kernel=str2func(fitFcn);
            nexObj.fitCfg.entryParams=extractMethodCfg(fitFcn);
            psd = slicePSD(nexObj.DF.df, nexObj.DF.ptr);
            nexObj.DF_postOp.cf = psdIO_readCornerFrequencies(nexObj.DF.ax.f, psd);
            nexObj.DF_postOp.df_fit = nexObj.fitCfg.kernel(nexObj.DF.ax, nexObj.fitCfg.entryParams);
            nexObj.DF_postOp.Y=struct; % empty struct, currently unused
            % machine learning configuration (optional)
            nexObj.mlCfg.DSCfg.numFolds = 5;            
            % nexObj.Figure =            
            nexFigure_fitScope(nexObj);
        end

        function updateScope(nexObj)
            % reassign DF from parent
            ptr = nexObj.DF.ptr;
            nexObj.DF = nexObj.Parent.DF_postOp;
            nexObj.DF.ptr=ptr;
            % re-compute df_fit with given parameters
            nexObj.DF_postOp.df = nexObj.DF.df(nexObj.DF.ptr.chans,:,nexObj.DF.ptr.t);         
            nexObj.DF_postOp.df_fit = nexObj.fitCfg.kernel(nexObj.DF.ax, nexObj.fitCfg.entryParams);
            psd = slicePSD(nexObj.DF.df, nexObj.DF.ptr);
            nexObj.DF_postOp.cf = psdIO_readCornerFrequencies(nexObj.DF.ax.f, psd);
            nexObj.DF_postOp.fitParams = nexObj.fitCfg.entryParams;
            % nexObj.DF.df = [];
            nexObj.visualize();
            %%  align sample address (optional)
            sessionLabel = grabDataFrame(nexObj.nexon,"sessionLabel",[]);
            trialNum = grabDataFrame(nexObj.nexon,"trialNumber",[]);
            nexObj.UserData.sampleAddress.sessionLabel = sessionLabel;
            nexObj.UserData.sampleAddress.trialNum = trialNum;
            nexObj.UserData.sampleAddress.t=nexObj.DF.ptr.t;
            nexObj.UserData.sampleAddress.chans=nexObj.DF.ptr.chans;
        end

        function visualize(nexObj)
            % visArgs = nexObj.fitCfg.entryParams;
            visArgs = struct;
            nexVisualization_fitScope(nexObj, visArgs);
        end

        function saveFit(nexObj, src, event)       
            % locate dataset
            ID_DS = sprintf("DS--rtspec_%s",nexObj.Parent.dfID_target);
            params = nexObj.nexon.console.BASE.params;
            path_FTR = params.paths.Data.FTR.local;
            path_DS = fullfile(path_FTR, ID_DS);
            % build directory if doesnt exist AND save config
            if ~isfolder(path_DS)
                [FID.conn_index, FID.file_index, FID.fld_DS]=MLIO_buildDSDirectory(path_DS, DSCfg);    
                nexObj.UserData.FID = FID;
            else
                FID = nexObj.UserData.FID;
            end
            % signal save to dataset
            % nexObj.UserData.isSave=1;
            % uiresume(nexObj.Figure.fh);
            DF_smp = nexObj.DF_postOp;
            % re-order fit parameters along frequency axis (sort by CF)            
            DF_smp.fitParams = spcpmIO_sortFitParams(DF_smp.fitParams);
            nexObj.DF_postOp=DF_smp; % assign back as sorted
            % args.sampleAddress.sessionLabel = sessionLabel;
            % args.sampleAddress.trialNum = trialNum;
            args.sampleAddress = nexObj.UserData.sampleAddress;
            % FID = nexObj.UserData.FID;
            args.DSCfg = nexObj.mlCfg.DSCfg;
            args.DFID_smp=nexObj.Parent.dfID_target;            
            %% WRITE SAMPLE
            MLIO_writeDS_rtspec(nexObj.nexon.console.BASE.params, DF_smp, FID, args);                       
            nexObj.fitCfg.entryParams=nexObj.DF_postOp.fitParams;
            nexObj.alignEntryParams();
        end

        function setAxisPointer(nexObj, src, event, axSel)
            axVal = src.Value;
            nexObj.DF = nex_setAxisPointer(nexObj.DF,axSel, axVal);
            nexObj.updateScope();
        end

        function connectDB(nexObj, src, event)
            params = nexObj.nexon.console.BASE.params;
            fld_DB = uigetdir(params.paths.Data.FTR.local);
            % connect to db if exists
            file_db = fullfile(fld_DB,"index_ds.db");
            if isfile(file_db)
                conn_index = sqlite(file_db,"connect"); 
            else
                conn_index = [];
            end
            fld_DS = fullfile(fld_DB,"DS");
            nexObj.UserData.FID.conn_index=conn_index;
            nexObj.UserData.FID.fld_DS=fld_DS;
            nexObj.UserData.FID.fld_DB=fld_DB;
            nexObj.UserData.FID.file_index=file_db;
        end

        function nullifyPeaks(nexObj, src, event)
            % revisualize with or without peaks to scope aperiodic
            % parameters 
            figHandle = ancestor(src, 'figure');
            clickType = get(figHandle, 'SelectionType');
            if ~isfield(nexObj.UserData,"toggle")
                nexObj.UserData.toggle.nullifyPeaks=0;
            end
            toggle_nullifyPeaks = nexObj.UserData.toggle.nullifyPeaks;
            switch toggle_nullifyPeaks
                case 0
                    switch clickType
                        case 'normal'
                            nexObj.UserData.fitParams_save_nullifyPeaks=nexObj.fitCfg.entryParams; % save before ease
                            % nexObj.DF_postOp.fitParams=spcpmIO_nullifyPeaks(nexObj.DF_postOp.fitParams);
                            nexObj.fitCfg.entryParams=spcpmIO_nullifyPeaks(nexObj.fitCfg.entryParams);
                            nexObj.UserData.toggle.nullifyPeaks=1;
                            nexObj.Figure.nullPeaksButton.BackgroundColor=nexObj.nexon.settings.Colors.disableGrey;
                        case 'alt' % don't nullify peaks
                            % nexObj.UserData.fitParams_save_nullifyPeaks=nexObj.fitCfg.entryParams; % save before ease
                            % % nexObj.DF_postOp.fitParams=spcpmIO_nullifyPeaks(nexObj.DF_postOp.fitParams);
                            % nexObj.fitCfg.entryParams=spcpmIO_nullifyPeaks(nexObj.fitCfg.entryParams);
                            nexObj.UserData.toggle.nullifyPeaks=1;
                            nexObj.Figure.nullPeaksButton.BackgroundColor=nexObj.nexon.settings.Colors.disableGrey;
                    end
                case 1
                    switch clickType
                        case 'normal'
                            % recover from save
                            % nexObj.DF_postOp.fitParams=nexObj.UserData.fitParams_save_nullifyPeaks;
                            nexObj.fitCfg.entryParams=nexObj.UserData.fitParams_save_nullifyPeaks;
                            nexObj.UserData.toggle.nullifyPeaks=0;
                            nexObj.Figure.nullPeaksButton.BackgroundColor=nexObj.nexon.settings.Colors.activeGrey;
                        case 'alt' % don't recover save
                            nexObj.UserData.toggle.nullifyPeaks=0;
                            nexObj.Figure.nullPeaksButton.BackgroundColor=nexObj.nexon.settings.Colors.activeGrey;
                    end
            end
            % update ui
            nexObj.alignEntryParams();
            nexObj.updateScope();
        end

        function alignEntryParams(nexObj)
            panFields = fieldnames(nexObj.Figure.panel2.editFields);
            for i = 1:length(panFields)
                panField = panFields{i};

                fieldVal = nexObj.fitCfg.entryParams.(panField);
                nexObj.Figure.panel2.editFields.(panField).uiField.Value = fieldVal;

                % fieldVal = nexObj.Figure.panel2.editFields.(panField).uiField.Value;
                % nexObj.fitCfg.entryParams.(panField) = fieldVal;
            end
            
        end
    end
end