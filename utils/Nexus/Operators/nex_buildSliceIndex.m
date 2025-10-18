function idx = nex_buildSliceIndex(df, ptr, axSel, sliceType)
    ptrFields = fieldnames(ptr);
    idx = repmat({':'},1,ndims(ptrFields));
    switch sliceType
        case "single"
            % slice a single pointer using selected axis, leave
            % non-selected axis untouched
            for i = 1:length(ptrFields)
                ptrField = ptrFields{i};
                ptrDim = ptr.(ptrField).dim;
                ptrVal = ptr.(ptrField).value;
                if (ismember(ptrField,axSel))
                    idx{ptrDim} = ptrVal;
                end        
            end
        case "range"
            % use selected axis to slice a range of values, every
            % non-selected axis is used as a single pointer
            for i = 1:length(ptrFields)
                ptrField = ptrFields{i};
                ptrDim = ptr.(ptrField).dim;
                ptrVal = ptr.(ptrField).value;
                if ~(ismember(ptrField,axSel))
                    idx{ptrDim} = ptrVal;
                end        
            end
    end
end