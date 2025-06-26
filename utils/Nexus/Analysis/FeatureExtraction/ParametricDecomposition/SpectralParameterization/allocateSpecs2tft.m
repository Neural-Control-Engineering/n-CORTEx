function M = allocateSpecs2tft(M, specVals, allocType, t)
    % place specVal into tensor 
    % (if not given f=frequency, place on all frequencies)
    % (if not given t=time, place on all timesteps)
    % M_alloc = {};
    M_alloc = cell(size(M,1),1);
    % M_alloc(:,f,t) = specVals;
    parfor i = 1:size(M,1) % for each channel
        specVal_chan = specVals(i);
        switch allocType
            case 'scalar'
                % M_alloc(i,:,t) = repelem(specVal_chan,size(M_alloc,2)); % f is 2nd dim        
                M_alloc{i} = repelem(specVal_chan,size(M,2)); % f is 2nd dim        
            case 'vector'
                % idx_f = f(i);
                % M_alloc(i,idx_f,t) = specVal_chan;
                % col_specVal = zeros(size(M,2));
                % col_specVal(idx_f) = specVal_chan;
                % M_alloc = [M_alloc; specVal_chan];
                M_alloc{i} = specVals{i};
        end
    end
    M_alloc=cat(1,M_alloc{:});
    % M_alloc=M_alloc{1,1};
    M(:,:,t)=M_alloc;
end