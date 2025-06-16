classdef proxon < handle
    % proxy manager
    properties
        index_type1 % primary proxies (ncortex, slrt, etc.)
        index_type2 % target/instrument proxies (npxls, photon, camera, etc.)
        % proxy_ncortex
        nCORTEx
        nexon
    end

    methods
        % constructor
        function proxon = proxon(nCORTEx, nexon)
            proxon.index_type1=struct;
            proxon.index_type2=struct;
            proxon.nCORTEx = nCORTEx;
            proxon.nexon = nexon;
        end

        function addProxy(proxon, proxObj, partnerProxObj)
            proxObjID = proxon.generateProxyID(proxObj);
            switch proxObj.type
                case 1
                    % append to index
                    proxon.index_type1.(proxObjID) = proxObj;                    
                    % share targets
                    if ~isempty(partnerProxObj)
                        proxObj.addPartner(partnerProxObj)
                    end
                case 2
                    % append to index
                    proxon.index_type2.(proxObjID) = proxObj;                    
            end
            proxObj.proxon = proxon;
        end

        function proxObjID = generateProxyID(proxon, proxObj)
            type = proxObj.type;
            indexTypeID = sprintf("index_type%d",type);
            proxyID = proxObj.proxyID;
            proxyFieldNames = convertCharsToStrings(fieldnames(proxon.(indexTypeID)));
            proxyNumber_class = size(proxyFieldNames,1)+1; 
            % proxyIDMatches = proxyFieldNames(ismember(proxyFieldNames,proxyClassCount));
            proxObjID = sprintf("%s_%d",proxObj.proxyID,proxyNumber_class);
        end
    
    end

end