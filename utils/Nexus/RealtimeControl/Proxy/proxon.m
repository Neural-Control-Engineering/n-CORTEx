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

        function p = primaryProxy(proxon, proxyID)
            % Fetch a type-1 (primary) proxy by its proxyID (e.g. "slrt", "nexus").
            % Returns [] if not present. Lets a target proxy reach an orchestrator
            % proxy — e.g. npxls handing a streamed feature to slrt for TX.
            p = [];
            fns = fieldnames(proxon.index_type1);
            for i = 1:numel(fns)
                cand = proxon.index_type1.(fns{i});
                if strcmp(cand.proxyID, proxyID), p = cand; return; end
            end
        end

        function proxObjID = generateProxyID(proxon, proxObj)
            type = proxObj.type;
            indexTypeID = sprintf("index_type%d",type);            
            proxyFieldNames = convertCharsToStrings(fieldnames(proxon.(indexTypeID)));
            proxyNumber_class = size(proxyFieldNames,1)+1; 
            % proxyIDMatches = proxyFieldNames(ismember(proxyFieldNames,proxyClassCount));
            % proxObjID = sprintf("%s_%d",proxObj.proxyID,proxyNumber_class);
            proxObjID = sprintf("%s",proxObj.proxyID);
        end
    
    end

end