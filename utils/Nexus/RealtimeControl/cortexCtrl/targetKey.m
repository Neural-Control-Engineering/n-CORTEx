classdef targetKey < Simulink.IntEnumType
    enumeration
        all (0)
        npxls  (1)
        photon (2)
        photom (3)        
    end

    methods (Static)

        function code = getCode(cmd)
            switch cmd
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

        function cmd = getCmd(code)
            switch code
                case targetKey.all
                    cmd = "all";
                case targetKey.npxls
                    cmd = "npxls";
                case targetKey.photon
                    cmd = "photon";
                case targetKey.photom
                    cmd = "photom";
                otherwise
                    cmd = "UNKNOWN"; % Or use "" or raise error
            end
        end

    end
end
