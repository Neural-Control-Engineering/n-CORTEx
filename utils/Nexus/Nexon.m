classdef Nexon < handle
    properties
        classID="nexon"
        console % This will hold any type of data, such as a struct
        Children
        UserData
        settings
    end
    
    methods
        % Constructor
        function obj = Nexon(nexon)
            obj.console=struct();
            obj.UserData = struct(); % Initialize as an empty struct      
            settings=struct();
        end
        
        % Example method to set UserData
        function setUserData(obj, data)
            obj.UserData = data;
        end
        
        % Example method to retrieve UserData
        function data = getUserData(obj)
            data = obj.UserData;
        end

        function saveRegistry(nexon)
            registry = nexon.console.BASE.registry; %#ok<NASGU>
            save(nexon.nexCachePath('registry'), 'registry');
        end

        function loadRegistry(nexon)
            p = nexon.nexCachePath('registry');
            if ~isfile(p)
                warning('Nexon:loadRegistry', 'No registry cache found at %s', p);
                return;
            end
            S = load(p, 'registry');
            nexon.console.BASE.registry = S.registry;
        end

        function p = nexCachePath(nexon, cacheKey)
            % Returns experiment-scoped cache path: Startup/Cache/<key>_<experiment>.mat
            try
                expt = char(nexon.console.BASE.params.experiment);
            catch
                try
                    expt = char(nexon.console.BASE.params.extractCfg.experiment);
                catch
                    expt = 'default';
                end
            end
            expt = matlab.lang.makeValidName(expt);
            p = fullfile(fileparts(which('Nexon')), 'Startup', 'Cache', ...
                         sprintf('%s_%s.mat', cacheKey, expt));
        end

        function appendToDTS(nexon, DTS)
            DTS_base = nexon.console.BASE.DTS;
            if isempty(DTS_base)
                DTS_full=DTS;
                nexon.console.BASE.DTS=DTS_full;
                % initialize control panel and subpanels
                nex_panelStartup(nexon);
            else
                DTS_full = mergeT_vertical(DTS_base, DTS);
                % sort by sessionLabel
                DTS_sort = sortrows(DTS_full,["sessionLabel","trialNumber"],"ascend");
                nexon.console.BASE.DTS=DTS_sort;
                % update router selection
                routerCfgParams = initializeRouterCfg(nexon.console.BASE.DTS);
                panelObj = nexon.console.BASE.controlPanel.Figure.panel1;
                updateEntryDropDownFields(panelObj, routerCfgParams);

            end


        end
    end
end