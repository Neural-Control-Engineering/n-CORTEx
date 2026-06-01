function [idx, ax_idx] = nexOp_buildSliceIndex(ax, ptr, axSels, axVals)
    ptrFields = fieldnames(ptr);
    idx = repmat({':'},1,numel(ptrFields));
    ax_idx=ax;
    % ax_df = [];
    for i = 1:length(axSels)
        axSel = axSels(i);
        sliceRange = axVals{i};
        sliceAx = ax.(axSel);
        sliceCond = find(ismember(sliceAx, sliceRange));
        ptrDim = ptr.(axSel).dim(1); % take only first element (case of axes with same lengths - DEBUG)
        idx{ptrDim} = sliceCond;
        % try
        %     idx{ptrDim} = sliceCond;
        % catch
        %     keyboard
        % end
        ax_idx.(axSel) = sliceAx(sliceCond);
        % ax_df = cat(i, sliceAx(sliceCond), ax_df);
        
    end
end