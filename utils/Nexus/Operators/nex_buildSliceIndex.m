function idx = nex_buildSliceIndex(df, ptr, axSel, sliceType)
    ptrFields = fieldnames(ptr);
    % idx = repmat({':'},1,ndims(ptrFields));
    idx = repmat({':'},1,length(ptrFields));
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
            % selected axes: use ptr.range if set, else full ':'
            % non-selected axes: slice to ptr.value
            for i = 1:length(ptrFields)
                ptrField = ptrFields{i};
                if isfield(ptr.(ptrField),'dim')
                    ptrDim   = ptr.(ptrField).dim;
                else
                    continue
                end
                if ismember(ptrField, axSel)
                    if isfield(ptr.(ptrField), 'range') && ~isempty(ptr.(ptrField).range)
                        idx{ptrDim} = ptr.(ptrField).range(1):ptr.(ptrField).range(2);
                    end
                else
                    idx{ptrDim} = ptr.(ptrField).value;
                end
            end
    end
end