classdef rtStream < handle
    properties
        tcpServer
        modServer
        buffer        
        plotHandle
        plotFcn
        operationFcn
        timerObj        
    end
    methods
        function obj = rtStream(Ax, tcpServer, modServer, operationFcn, plotFcn)
            % Initialize
            obj.plotHandle = Ax;
            obj.tcpServer = tcpServer;
            obj.modServer = modServer;
            obj.operationFcn = operationFcn;
            obj.plotFcn = plotFcn;
            obj.timerObj = timer("ExecutionMode","fixedRate","Period",0.1,"TimerFcn",@(~,~)obj.cascade);                        
            % obj.timerObj = timer("ExecutionMode","singleShot","TimerFcn",@(~,~)obj.cascade);                        
        end

        function cascade(obj)
            % read data onto buffer
            obj.buffer = readDataMod(obj.modServer, 2500);            
            % perform realtime operation on buffer (this operation is expected to            
            % place the buffer onto a gpuArray)
            obj.buffer = obj.operationFcn(obj.buffer);                   
            % plot operation output     
            S = obj.buffer{1,1};
            S = 10*log10(abs(S));
            % obj.plotHandle.CData = S;
            set(obj.plotHandle,"CData",gather(S))
            drawnow;
            % @(~,~)plotFcn(obj.plotHandle,obj.buffer);
            % transmit over TCP
            % write(sgSrv,uint8(obj.buffer));

        end

        function open(obj)
            % start rtStream
            start(obj.timerObj);
        end

        function close(obj)
            stop(obj.timerObj);
        end
    end
end
