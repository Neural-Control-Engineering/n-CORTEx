function extrctModules = buildExtrctModules(params, extrctModFcnPath, extrctModFldrPath, extrctItm)
    extrctModules = struct;
    % extrctMods = categorize(fullfile(params.paths.stem,"Code_Repo","n-CORTEx","Extraction","Extraction-Modules"),"isDir");
    extrctMods = categorize(extrctModFcnPath,"isDir");
    % modalities = string(categorize(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data",extrctItm),"isDir"));
    modalities = string(categorize(extrctModFldrPath,"isDir"));
    for i = 1:length(extrctMods)
        extMod = string(extrctMods(i));
        % if strcmp(extMod,params.extractCfg.experiment) | any(contains(modalities,extMod))        
        if any(contains(modalities,extMod))                       
            % extrctFuncs = string(categorize(fullfile(params.paths.stem,"Code_Repo","n-CORTEx","Extraction","Extraction-Modules",extMod),"extract"));
            extrctFuncs = string(categorize(fullfile(extrctModFcnPath,extMod),"extract"));
            extrctFuncs = strrep(extrctFuncs,".m","");
            for j = 1:length(extrctFuncs)
                extrctFunc = extrctFuncs(j);
                mod = split(extrctFunc,'_');
                mod = mod(2);
                if contains(extrctFunc, extrctItm)                    
                    % build extractionModule
                    extrctModules.(mod).Q.q = parallel.pool.DataQueue;
                    extrctModules.(mod).Q.pq = parallel.pool.PollableDataQueue;
                    extrctModules.(mod).extrctModules = buildExtrctModules(params, fullfile(extrctModFcnPath,extMod), fullfile(extrctModFldrPath, extMod), extrctItm);                
                end
            end    
        end
    end
end