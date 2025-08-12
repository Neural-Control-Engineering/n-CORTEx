classdef targetKey < Simulink.IntEnumType
    enumeration        
        npxls  (1)
        photon (2)
        photom (3)        
    end

    methods (Static)

        function code = getCode(targetID)
            switch targetID
                case "all"
                    code = targetKey.all;
                case "npxls"
                    code = targetKey.npxls;
                case "photon"
                    code = targetKey.photon;
                case "photom"
                    code = targetKey.photom;
                otherwise
                    code = targetKey(-1); % Or handle error as needed
            end
        end

        function targetID = getTargetID(code)
            switch code
                case targetKey.all
                    targetID = "all";
                case targetKey.npxls
                    targetID = "npxls";
                case targetKey.photon
                    targetID = "photon";
                case targetKey.photom
                    targetID = "photom";
                otherwise
                    targetID = "UNKNOWN"; % Or use "" or raise error
            end
        end

    end
end
