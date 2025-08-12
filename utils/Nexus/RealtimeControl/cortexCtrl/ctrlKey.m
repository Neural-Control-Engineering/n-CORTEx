classdef ctrlKey < Simulink.IntEnumType
    
    enumeration    
        % client-side
        startDataStream (1)
        stopDataStream (2)
        startCapture (3)
        stopCapture (4)
        transmitDataStream (5)
        endOfTrial (6)
        loadEnvironment (7)
        setSavePath (8)        
        setFileName (9)
        setFileIteration (10)
        loadTSeries (11)
        startTSeries (12)
        startZSeries (13)
        getState (14)
        setChannel (15)
        setDwellTime (16)
        setImageSize (17)
        setFeature (18)
        parameterSet (19)
        getLIneScan (20)
        state (21)
        
        % server-side      
    end

    methods (Static=true)   
        
        function retVal = addClassNameToEnumNames()
            retVal = true;
        end

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
                case "transmitDataStream"
                    code = ctrlKey.transmitDataStream;
                case "endOfTrial"
                    code = ctrlKey.endOfTrial;
                case "loadEnvironment"
                    code = ctrlKey.loadEnvironment;
                case "setSavePath"
                    code = ctrlKey.setSavePath;
                case "setFileIteration"
                    code = ctrlKey.setFileIteration;
                case "setFileName"
                    code = ctrlKey.setFileName;
                case "loadTSeries"
                    code = ctrlKey.loadTSeries;
                case "startTSeries"
                    code = ctrlKey.startTSeries;
                case "startZSeries"
                    code = ctrlKey.startZSeries;
                case "getState"
                    code = ctrlKey.getState;
                case "setChannel"
                    code = ctrlKey.setChannel;
                case "setDwellTime"
                    code = ctrlKey.setDwellTime;
                case "setImageSize"
                    code = ctrlKey.setImageSize;
                case "setFeature"
                    code = ctrlKey.setFeature;
                case "parameterSet"
                    code = ctrlKey.parameterSet;
                case "getLIneScan"
                    code = ctrlKey.getLIneScan;
                case "state"
                    code = ctrlKey.state;
                otherwise
                    error('Unknown command: %s', cmd)
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
                case ctrlKey.transmitDataStream
                    cmd = "transmitDataStream";
                case ctrlKey.endOfTrial
                    cmd = "endOfTrial";
                case ctrlKey.loadEnvironment
                    cmd = "loadEnvironment";
                case ctrlKey.setSavePath
                    cmd = "setSavePath";
                case ctrlKey.setFileIteration
                    cmd = "setFileIteration";
                case ctrlKey.setFileName
                    cmd = "setFileName";
                case ctrlKey.loadTSeries
                    cmd = "loadTSeries";
                case ctrlKey.startTSeries
                    cmd = "startTSeries";
                case ctrlKey.startZSeries
                    cmd = "startZSeries";
                case ctrlKey.getState
                    cmd = "getState";
                case ctrlKey.setChannel
                    cmd = "setChannel";
                case ctrlKey.setDwellTime
                    cmd = "setDwellTime";
                case ctrlKey.setImageSize
                    cmd = "setImageSize";
                case ctrlKey.setFeature
                    cmd = "setFeature";
                case ctrlKey.parameterSet
                    cmd = "parameterSet";
                case ctrlKey.getLIneScan
                    cmd = "getLIneScan";
                case ctrlKey.state
                    cmd = "state";
                otherwise
                    error('Unknown code: %d', code)
            end
        end        
    end
end
