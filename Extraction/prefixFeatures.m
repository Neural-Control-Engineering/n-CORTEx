function pfxFtrs = prefixFeatures(features, prefix)
    % concatenate the prefix to each of the listed feature labels for each
    % prefix and for each label
    pfxFtrs = {};
    for i = 1:length(prefix)
        pfx = prefix{i};
        for j = 1:length(features)
            ftr = features{j};
            pfxFtrs = [pfxFtrs, {sprintf("%s_%s", pfx, ftr)}];            
        end
    end
end