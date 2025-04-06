classdef proxy_photon < handle
    properties
        proxyID = "photon";                        
        Server
        compCfg
        nexFigures % handles to interactive figures
    end
    
    methods
        % CONSTRUCTOR
        function proxObj = proxy_photon(Server)
            proxObj.Server = Server; % prairielink            
        end

        % FETCH DATA
        function readData(proxObj)
        end

        function writeData(proxObj)
        end

        % Z-Stack
        function zStack(proxObj)
        end

        % T-series
        function tSeries(proxObj)
        end

        % Open shuter
        function openShutter(proxObj)
        end

        % close shutter
        function closeShutter(proxObj)
        end

        function sessionLabelChanged(proxObj)
        end

    end

end