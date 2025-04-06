classdef proxy_npxls < handle
    properties
        proxyID = "npxls";                        
        Server      
        compCfg
        nexFigures % handles to interactive figures
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_npxls()
            proxObj.Server = SpikeGL; % spikeGL            
        end

        % Fetch data
        function df = getData(proxObj)
            df = FetchLatest(proxObj.Server, 2, 0, windowLen);          
            % computation during fetching
            % visualize during fetching
            % return template data if server does not exist
        end

        function sessionLabelChanged(proxObj)
        end
    end

end