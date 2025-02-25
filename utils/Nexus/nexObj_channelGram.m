classdef nexObj_channelGram < handle
    properties
        classID
        nexon
        Parent
        Partners 
        Children % hold sub-Objs (e.g. spectrogram)
        DF % df pre operation function (behavior depends on online or offline status); struct containing df and ax 
        DF_postOp % df post operation function (behavior depends on online or offline status); struct containint df and ax (and opCfg!?)
        dataFrame % This will hold any type of data, such as a struct     
        frameNum
        entryPanel
        dfID % DTS df identifier (trial-wise)
        f % frequency axis
        t % time axis        
        preBufferLen
        chgFigure % figure handle        
        opCfg
        visCfg
        aniCfg
        UserData
        bPool        
        rtSpec
        isOnline
        isStatic
        pltTimer
        isPlay
        frameBuffer
    end
    
    methods
        % Constructor
        function obj = nexObj_channelGram(nexon, shank, dataFrame, dfID, opFcn, visFcn, aniFcn)
            obj.classID = "chg";
            obj.nexon = nexon;
            obj.Parent = shank;
            obj.Partners = struct;
            obj.Children = struct;            
            obj.DF = struct;
            obj.DF_postOp = struct;
            obj.dataFrame=dataFrame;    
            obj.DF.df = dataFrame;
            obj.dfID = dfID; % dataframe column identifier
            obj.f = []; % frequency axis
            obj.t = []; % time axis            
            obj.preBufferLen = 3.5;
            obj.frameNum = 1; % time-wise frame (for animating or plotting)
            obj.frameBuffer.frames=[];
            obj.frameBuffer.frameIds=[];            
            obj.UserData = struct;
            obj.UserData.chanSel = 1;         
            % operation function
            obj.opCfg.opFcn = opFcn;
            obj.opCfg.entryParams = extractMethodCfg(rmExtension(func2str(opFcn)));              
            obj.frameBuffer.opArgs = obj.opCfg.entryParams;
            % visualization function
            obj.visCfg.visFcn = visFcn;
            obj.visCfg.entryParams = extractMethodCfg(rmExtension(func2str(visFcn)));
            % animation function
            obj.aniCfg.aniFcn = aniFcn;
            obj.aniCfg.entryParams = extractMethodCfg(rmExtension(func2str(aniFcn)));      
            obj.frameBuffer.aniArgs = obj.aniCfg.entryParams;
            % state cfgs
            obj.isOnline = 1;
            obj.isStatic = 0;
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
            obj = nexPlot_channelGram(nexon, shank, obj);                                
        end

        function updateScope(obj, nexon)            
            % grab next dataframe
            % frameBufferID = sprintf("frameBuffer_chg--%s",obj.dfID);
            obj.dataFrame = grabDataFrame(nexon, obj.dfID,[]);            
            obj.DF.df = grabDataFrame(nexon, obj.dfID,[]);
            aniArgs = obj.aniCfg.entryParams;
            opArgs = obj.opCfg.entryParams;
            opArgs.frameNum = obj.frameNum; % custom arg for operation sequence
            try                
                % obj.frameBuffer = grabDataFrame(nexon, frameBufferID,[]); % % TESTING
                obj.frameBuffer = retrieveFrameBuffer(obj);
                % if df recovery possible but missing necessary entries
                if isempty(obj.frameBuffer) || ~isfield(obj.frameBuffer,"ax") || ~isfield(obj.frameBuffer,"opArgs") || ~isfield(obj.frameBuffer,"aniArgs")
                    disp("save buffer could not be recovered");
                    obj.frameBuffer=struct;
                    obj.frameBuffer.frameIds=channelGram.frameNum;                    
                    obj.frameBuffer.opArgs=struct;
                    obj.frameBuffer.aniArgs=struct;
                    % OPERATE (online/offline dependent)
                    df_slice = obj.DF.df(:,obj.frameNum:obj.frameNum+obj.aniCfg.entryParams.windowLen);
                    % opArgs = obj.opCfg.entryParams;                    
                    opFcn_out = obj.opCfg.opFcn(df_slice, opArgs);
                    df_out = opFcn_out.df;
                    obj.frameBuffer.ax = opFcn_out.ax;
                    obj.frameBuffer.frames = opFcn_out.df;
                else
                    try                        
                        obj.frameNum = obj.frameBuffer.currentFrame;
                    catch
                        obj.frameNum = min(obj.frameBuffer.frameIds);
                    end
                    [df_out, ax] = nexDeBufferFrame(obj.frameBuffer, obj.frameNum);
                end
            catch e % if df recovery fails
                disp(getReport(e));
                obj.frameBuffer=struct;
                obj.frameBuffer.frameIds=obj.frameNum;                                    
                obj.frameBuffer.opArgs=struct;
                obj.frameBuffer.aniArgs=struct;
                % OPERATE (online/offline dependent)
                df_slice = obj.DF.df(:,obj.frameNum:obj.frameNum+obj.aniCfg.entryParams.windowLen);
                % opArgs = obj.opCfg.entryParams;                
                opFcn_out = obj.opCfg.opFcn(df_slice, opArgs);
                df_out = opFcn_out.df;
                obj.frameBuffer.ax = opFcn_out.ax;
                obj.frameBuffer.frames = opFcn_out.df;
            end
            % Recover DF_postOp (for updating subObjs)
            obj.DF_postOp.df = obj.frameBuffer.frames;
            obj.DF_postOp.ax = obj.frameBuffer.ax;
            % df_out = obj.frameBuffer.frames(:,:,floor(obj.frameNum/aniArgs.stride)); % approximate, but good for now
            % ax = obj.DF_postOp.ax;
            
            % VISUALIZE
            % shank = obj.Parent;
            visArgs = obj.visCfg.entryParams;
            obj.visCfg.visFcn(nexon, obj, visArgs);
            % obj.visCfg.visFcn(nexon, shank, obj, df_out, ax, visArgs);
            % update children objs
            nex_updateChildren(nexon, obj);
        end

        function animate(obj, nexon, shank)
            args = obj.aniCfg.entryParams;
            nexAnimate_channelGram(nexon, shank, obj, args);
        end       
    end
end