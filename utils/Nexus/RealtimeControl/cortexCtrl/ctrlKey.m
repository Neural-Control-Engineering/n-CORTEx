classdef ctrlKey < Simulink.IntEnumType
    enumeration        
        startDataStream (1)
        stopDataStream (2)
        startCapture (3)
        stopCapture (4)
        endOfTrial (5)
        zSeries (6)
        tSeries (7)
        state (8)
        % state_rtn (9)

    end

    methods (Static)        

        function code = getCode(cmd)
            switch cmd
                case "startDataStream"
                    code = ctrlKey.startDataStream;
                case "stopDataStream"
                    code = ctrlKey.stopDataStream;
                case "startCapture"
                    code = ctrlKey.startCapture;
                case "stopCapture"
                    code = ctrlKey.stopCapture;
            end
        end

        function cmd = getCmd(code)
            switch code                
                case ctrlKey.startDataStream
                    cmd = "startDataStream";
                case ctrlKey.stopDataStream
                    cmd = "stopDataStream";
                case ctrlKey.startCapture
                    cmd = "startCapture";
                case ctrlKey.stopCapture
                    cmd = "stopCapture";
            end
        end

        
    end

end

% ctrxControl("startDatastream","photon"); % return 1 if successful
% ctrxControl("startDatastream","npxls");
% 
% 
% PVrx 
% PVtx