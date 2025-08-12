function embedUMAP(DF, args)

    % CFG HEADER
    n_components = args.n_components; % default = 3
    n_neighbors = args.n_neighbors; % default = 10
    min_dist = args.min_dist; % default = 0.1
    r_decimation = args.r_decimation; % default = 0.1

    dataPath = args.args.dataPath;    
    
    if isempty(DF) % compute from written dataset
        % system call to python
    else
    end
end