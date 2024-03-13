function computeKilosortDataset()
    % Neuropixel.runKilosort3(imec, params.paths, exp_template, 'workingdir',convertStringsToChars(params.paths.neuropixel.workingdir));
    % Save Kilosort Object and compute metrics
    % ks = Neuropixel.KilosortDataset(((fullfile(params.paths.ksortNpxlsPath,strcat(exp_template,trigPattern)))));
    imec = Neuropixel.ImecDataset(fullfile(data_dir,strcat(exp_template,trigPattern)));
    ks = Neuropixel.KilosortDataset(fullfile(data_dir,"kilosort4"),'imecDataset',imec);
    ks.path = strcat('\\?\',ks.path);
    ks.kilosort_version=3;
    ks.load('loadFeatures',false);
    stats = ks.computeBasicStats();
    ks.printBasicStats();
    metrics = ks.computeMetrics();    
end