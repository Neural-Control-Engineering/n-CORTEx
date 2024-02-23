function extrctModules = buildExtrctModules(params, extrctItm)
    extrctModules = struct;
    extrctMods = categorize(fullfile(params.paths.stem,"Code_Repo","n-CORTEx","Extraction","Extraction-Modules"),"isDir");
    modalities = string(categorize(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","Raw-Data/"),"isDir"));
    for i = 1:length(extrctMods)
        extMod = string(extrctMods(i));
        if strcmp(extMod,params.extractCfg.experiment) | any(contains(modalities,extMod))
            extrctFuncs = string(categorize(fullfile(params.paths.stem,"Code_Repo","n-CORTEx","Extraction","Extraction-Modules",extMod),"extract"));
            extrctFuncs = strrep(extrctFuncs,".m","");
            for j = 1:length(extrctFuncs)
                extrctFunc = extrctFuncs(j);
                if contains(extrctFunc, extrctItm)
                    mod = split(extrctFunc,'_');
                    mod = mod(2);
                    % build extractionModule
                    extrctModules.(mod).q = parallel.pool.DataQueue;
                    extrctModules.(mod).pq = parallel.pool.PollableDataQueue;
                end
            end
        end
    end
end