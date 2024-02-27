function [dataDirs, loc] = scopeRawData(params, exp_template, refs)
    dataDirs = struct;
    loc = struct;
    for i = 1:length(refs)
        ref = refs(i);
        % dataDir.(ref) = refs(i);
        % CHECK LOCAL FIRST, CLOUD SECOND
        localDir = dir(fullfile(params.paths.rawData.(params.extractCfg.modality).local, strcat(exp_template, '*'), strcat(exp_template,sprintf('*%s*',ref))));
        % nidq_dir_local = dir(fullfile(params.paths.rawData.(params.extractCfg.modality).local, strcat(exp_template,'*'), strcat(exp_template,'*nidq*')));
        cloudDir = dir(fullfile(params.paths.rawData.(params.extractCfg.modality).cloud, strcat(exp_template, '*'), strcat(exp_template,sprintf('*%s*',ref))));
        % nidq_dir_cloud = dir(fullfile(params.paths.rawData.(params.extractCfg.modality).cloud, strcat(exp_template, '*'), strcat(exp_template,'*nidq*')));
        if isempty(cloudDir)
            dataDirs.(ref) = localDir;
            loc.(ref) = 1;
        else
            dataDirs.(ref) = cloudDir;
            loc.(ref) = 0;
        end        
    end
end