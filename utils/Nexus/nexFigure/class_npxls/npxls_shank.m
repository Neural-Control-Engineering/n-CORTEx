classdef npxls_shank < handle
    properties
        regMap % This will hold any type of data, such as a struct        
        classID
        Parents
        Partners
        Children
        Origins
        DF
        scope        
        config
        UserData
    end
    
    methods
        % Constructor
        function obj = npxls_shank(nexon)
            obj.UserData = struct(); % Initialize as an empty struct
            obj.scope = struct();
            % configure Shank Mapping
            params = nexon.console.BASE.params;            
            regMapDir = fullfile(nexon.console.BASE.router.UserData.subjectDir,"npxls/trajectory/imec0","map_channel-region.mat");            
            load(regMapDir);
            obj.regMap = regMap;    
            % start user with one timeCourse
            dataFrame = grabDataFrame(nexon,"lfp",[]);
            obj.scope.timeCourse1 = nexObj_npxlsTimeCourse(nexon, obj, dataFrame, "lfp");
            % add STFT (PMTM method spectrogram)
            try
                df_lfp = grabDataFrame(nexon,"lfp",[]);
                % parfeval(@() nexObj_channelGram(nexon, obj, rtSpectrogram,"lfp","mag"),0);
                % obj.scope.channelgram1 = nexObj_channelGram(nexon, obj, rtSpectrogram, "lfp", "mag");
                opFcn = str2func("rtPMTM_magnitude");
                visFcn = str2func("nexVisualization_channelGram");
                aniFcn = str2func("nexAnimate_channelGram");
                obj.scope.channelGram1 = nexObj_channelGram(nexon, obj, df_lfp, "lfp", opFcn, visFcn, aniFcn);
            catch e
                disp(getReport(e));
            end
            try
                % spg1 = grabSpectrogram(nexon, "pmtm",[]);
                spg1.dataFrame=[];
                spg1.dfID = [];
                spg1.f = [];
                spg1.t = [];
                spg1.opFcn = [];
                spg1.visFcn = str2func("nexVisualization_spectroGram");
                spg1.isOnline = 1;
                obj.scope.channelGram1.Children.spectroGram1 = nexObj_spectroGram(nexon, obj.scope.channelGram1, spg1.dataFrame, spg1.dfID, spg1.f, spg1.t, spg1.opFcn, spg1.visFcn);
            catch e
                disp(getReport(e));
            end
            try
                opFcn = str2func("spectralParameterization");
                obj.scope.channelGram1.Children.spectroScope1 = nexObj_spectroScope(nexon, obj.scope.channelGram1, opFcn);
            catch  e
                disp(getReport(e))
            end
            % add CWT spectrogram (wavelet transform)
            % try
            %     spg2 = grabSpectrogram(nexon, "cwt",[]);
            %     obj.scope.spectrogram2 = nexObj_spectroGram(nexon, obj, spg2.dataFrame, spg2.dfID, spg2.f, spg2.t, "mag");
            % catch e
            %     disp(e);
            % end
            % obj.config = struct();
            % draw config Panel
            % obj.config = drawShankCfgPanel(nexon, obj);                          
        end       
    end
end