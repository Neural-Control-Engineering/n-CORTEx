function [S, P, msk] = binFooofParams(bands, fooofparams)
    % S : channel wise readout of fooof params
    % P : column labeling of fooof params
    % msk : center frequency binary mask 
    F = struct2table(fooofparams);
    oscillatory = F.peak_params;
    fractal = F.aperiodic_params;
    bandNames = fieldnames(bands);
    try
        fRange = [1:bands.gamma(2)];
    catch
        fRange = 50;
    end

    S = [];
    msk = zeros(size(F,1),size(fRange,2));
    for i = 1:height(F)
        % disp(i);
        specs = F.peak_params{i};
        specParams = [];
        for j = 1:length(bandNames)
            % disp(j);
            bandName = bandNames{j}; 
            band = struct;
            band.name = bandName;
            band.range = bands.(bandName);
            spcs = struct2table(allocateSpecs(band, specs));
            % isAllNan = all(cell2mat((isnan(table2array(spcs(:,1))))));
            isAllNan = all(((isnan(cell2mat(table2array(spcs(:,1)))))));
            % DROP EMPTY 'NON-FIRST' ROWS
            if ~isAllNan
                % spcs = spcs(cell2mat(~isnan(table2array(spcs(:,1)))),:);
                spcs = spcs((~isnan(cell2mat(table2array(spcs(:,1))))),:);
            else
                spcs = spcs(1,:);
            end
            if height(spcs) > 1
                % SELECT CF WITH HIGHER POWER IF MULTIPLE
                highestCF = (max(cell2mat((table2array(spcs(:,1))))));
                highestCFidx = find(table2mat(spcs(:,1))==highestCF);
                spcs = spcs(highestCFidx,:);
            end
            specParams = [specParams, spcs];
            mskIdx = floor(table2mat(spcs(1,1)));
            mskBW = floor(table2mat(spcs(1,3))/2);
            if ~isnan(mskIdx)                
                bwIdx = [mskIdx-mskBW:1:mskIdx+mskBW];
                % drop zero-indices
                bwIdx = bwIdx(bwIdx>0 & bwIdx<size(msk,2));                
                msk(i,bwIdx) = 1;
                msk(i,mskIdx) = 2;
            end
            % specParams = flattenSpecs(specParams);
        end
        specParams.AP = fractal(i,2);
        specParams.Bias = fractal(i,1);
        S = [S; specParams];        
    end        
    P = S.Properties.VariableNames;
end