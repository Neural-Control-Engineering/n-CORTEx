classdef nexObj_channelGram < handle
    properties
        dataFrame % This will hold any type of data, such as a struct     
        frameNum
        entryPanel
        dfID % DTS df identifier (trial-wise)
        f % frequency axis
        t % time axis
        freqResponse
        chgFigure % figure handle
        psdCfg % spectral computing configuration DEPRECATED
        opCfg
        visCfg
        UserData
        bPool
        isAnimated
        rtSpec
        pltTimer
        isPlay
        frameBuffer
    end
    
    methods
        % Constructor
        function obj = nexObj_channelGram(nexon, shank, dataFrame, dfID, opFcn, visFcn, freqResponse)
            obj.dataFrame=dataFrame;             
            obj.dfID = dfID; % dataframe column identifier
            obj.f = []; % frequency axis
            obj.t = []; % time axis            
            obj.frameNum = 1; % time-wise frame (for animating or plotting)
            obj.frameBuffer.frames=[];
            obj.frameBuffer.frameIds=[];
            obj.freqResponse = freqResponse; % choose phase or magnitude
            obj.UserData = struct;
            obj.UserData.chanSel = 1;
            obj.psdCfg = configurePsd();
            obj.psdCfg.method="pmtm";
            % signal process configuration
            obj.opCfg.opFcn = opFcn;
            obj.opCfg.entryParams = extractMethodCfg(rmExtension(opFcn));            
            obj.psdCfg.chanRange=[1:384];
            obj.isAnimated=1;
            % modelPath = "/home/user/Code_Repo/n-CORTEx/utils/RTSpec/Models/biLSTM50.pth";
            try
                % obj.rtSpec = initRTSpec(nexon.console.BASE.params, []);
                obj.rtSpec = [];
            catch e
                disp(getReport(e));
                obj.rtSpec = [];
            end
            obj.pltTimer=timer("ExecutionMode","fixedRate","BusyMode","drop","Period",0.1,"TimerFcn",@(~,~)animate(obj, nexon, shank));
            obj.isPlay=0;
            obj = nexPlot_npxls_channelGram(nexon, shank, obj);                       
            % if obj.isAnimated           
            %     % obj.animate(nexon, shank);                                  
            %     start(obj.pltTimer);
            % end
            % dfToPool = dataFrame(obj.UserData.chanSel,:,:);
            % [poolDf, b] = poolBands(nexon.console.BASE.params.bands, obj.f, dfToPool);            
            % obj.bPool = nexObj_bandPool(nexon, obj, b, t, [], poolDf, []);
        end

        function updateScope(obj, nexon, shank)
            % save previous buffer
            disp(obj.dfID);
            frameBufferID = sprintf("frameBuffer_chg_%s",obj.dfID);
            writeDf(nexon,frameBufferID, obj.frameBuffer,[]);
            % writeDf(nexon,obj.dfID,dataFrame); % write new data entry to given dfID column
            % grab next dataframe
            obj.dataFrame = grabDataFrame(nexon, obj.dfID,[]);            
            try
                % obj.frameBuffer = grabDataFrame(nexon, "frameBuffer_chg");
                obj.frameBuffer = grabDataFrame(nexon, frameBufferID,[]);
                if isempty(obj.frameBuffer)
                    disp("save buffer could not be recovered");
                    obj.frameBuffer=struct;
                    obj.frameBuffer.frameIds=[];
                    obj.frameBuffer.frames=[];
                end
            catch e
                disp(e)
                obj.frameBuffer=struct;
                obj.frameBuffer.frameIds=[];
                obj.frameBuffer.frames=[];
            end
        end

        function animate(obj, nexon, shank)
            % while(obj.isAnimated)
            % stride through lfp dataframe, compute PSD, and apply fit
            % (plot PSD)
            frameNum = obj.frameNum; 
            if any(obj.frameBuffer.frameIds == frameNum)
                % f =                 
                sChans = nexDeBufferFrame(obj.frameBuffer, frameNum);
                % fCond = f(f>obj.psdCfg.fRange(1) & f<obj.psdCfg.fRange(2));
                % sChans = obj.frameBuffer.frame(frameNum); % retrieve already processed frame
            else
                chanRange = obj.psdCfg.chanRange;
                lfp_frame = obj.dataFrame(chanRange,frameNum:frameNum+obj.psdCfg.windowLen)';
                switch obj.psdCfg.method
                    case "fft"
                        SFT = extractRT_FFT(obj.psdCfg, lfp_frame);
                    case "pmtm"
                       SF = extractRT_PMTM(obj.psdCfg, lfp_frame);
                       sChans = [SF{1,1}{:}]';
                       f = SF{1,2}{1};
                    case "stft"
                        SFT = extractRT_STFT(obj.psdCfg, lfp_frame);
                        f = SFT{1,2}{1};
                        t = SFT{1,3}{1};
                        S = SFT{1,1};
                        sAvg = cellfun(@(x) mean(10*log10(abs(x)),2),S,"UniformOutput",false);
                        sChans = [sAvg{:}]';
                        % stftIdx = streamCfg.chanViewSel;   
                        
                end 
                fCond = f(f>obj.psdCfg.fRange(1) & f<obj.psdCfg.fRange(2));                
                sChans = sChans(:,fCond);            
                obj.chgFigure.panel1.tiles.Axes.channelGram.XData = gather(f(fCond)); % should be consistent
            end
            t_frame = frameNum / obj.psdCfg.Fs - 3.5;
            obj.chgFigure.panel1.tiles.Axes.channelGram.Parent.Parent.Title.String=(sprintf("%0f (s)",t_frame));
            obj.chgFigure.panel1.tiles.Axes.channelGram.YData = gather([1:size(sChans,1)]);            
            obj.chgFigure.panel1.tiles.Axes.channelGram.ZData = gather(sChans);
            obj.chgFigure.panel1.tiles.Axes.channelGram.CData = gather(sChans);
            % Buffer frames (for faster plotting on next go-around)
            obj.frameBuffer = nexBufferFrame(obj.frameBuffer,frameNum, sChans);
            % obj.chgFigure.panel1.ph.Children.Children.CLim=[-12.2,-10.7];
            obj.chgFigure.panel1.ph.Children.Children.CLim=[-11.5,-9.5];
            % obj.chgFigure.Ax.Parent.CLim=[-11.2,-3.5];
            % fooof contours
            %% RTSPEC
            % fooofPredictions = extractRT_fooof(obj.rtSpec,sChans);                
            % f_psd = resampleDataFrame(f(fCond),195);
            % contours = composeFooofPreds(fooofPredictions, f_psd, 8, 195);                    
            % obj.chgFigure.panel1.tiles.Axes.fooof.Children.YData = gather([1:size(contours,1)]);
            % obj.chgFigure.panel1.tiles.Axes.fooof.Children.XData = gather(f_psd);
            % obj.chgFigure.panel1.tiles.Axes.fooof.Children.ZData = (contours);
            % obj.chgFigure.panel1.tiles.Axes.fooof.Children.CData = (contours);
            % % pause(0.1);
            drawnow;
            % step to next frame
            obj.frameNum = mod(obj.frameNum+20,size(obj.dataFrame,2)-obj.psdCfg.windowLen);
            if obj.frameNum == 0
                obj.frameNum=1;
            end        
        end
        
        % Example method to set UserData
        function setUserData(obj, data)
            obj.UserData = data;
        end
        
        % Example method to retrieve UserData
        function data = getUserData(obj)
            data = obj.UserData;
        end
    end
end