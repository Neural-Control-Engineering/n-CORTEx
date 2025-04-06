classdef ctrlKey < Simulink.IntEnumType
    enumeration        
        startDataStream (1)
        stopDataStream (2)
        startCapture (3)
        stopCapture (4)
        endOfTrial (5)
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

% classdef CommandEnum < Simulink.IntEnumType
%     enumeration
%         startCapture_npxls (1)
%         stopCapture_npxls  (2)
%         resetDevice        (3)
%     end
% 
%     methods (Static)
%         function str = getStringFromCode(code)
%             switch code
%                 case CommandEnum.startCapture_npxls
%                     str = "startCapture_npxls";
%                 case CommandEnum.stopCapture_npxls
%                     str = "stopCapture_npxls";
%                 case CommandEnum.resetDevice
%                     str = "resetDevice";
%                 otherwise
%                     str = "UNKNOWN";
%             end
%         end
% 
%         function code = getCodeFromString(str)
%             switch str
%                 case "startCapture_npxls"
%                     code = CommandEnum.startCapture_npxls;
%                 case "stopCapture_npxls"
%                     code = CommandEnum.stopCapture_npxls;
%                 case "resetDevice"
%                     code = CommandEnum.resetDevice;
%                 otherwise
%                     code = CommandEnum(-1); % Or handle error differently
%             end
%         end
%     end
% end
