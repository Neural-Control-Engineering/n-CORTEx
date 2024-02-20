function sfxFtrs = suffixFeatures(features, suffix)
    % concatenate the prefix to each of the listed feature labels for each
    % prefix and for each label
    sfxFtrs = {};
    for i = 1:length(suffix)
        sfx = suffix{i};
        for j = 1:length(features)
            ftr = features{j};
            sfxFtrs = [sfxFtrs, {sprintf("%s_%s", ftr, sfx)}];            
        end
    end
end