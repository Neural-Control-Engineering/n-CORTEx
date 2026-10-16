function kArgs = spcpmIO_apPe2kernel(apRow, peMat)
% Merge one (chan,t) slice's AP row + PE matrix into a kernel_args struct
% for kernel_specparam_segmented_multiexp — same field convention as
% spcpmIO_specs2kernel, just built from the separately-shaped AP/PE patch
% rows nexObj_fitScope reads (nexFit_specParam's own DF_ap/DF_pe
% convention), instead of one combined spec vector.
%
%   apRow : 1x7 [OFF, EXP1, EXP2, EXP3, FC1, FC2, FC3]
%   peMat : Nx3 [CF, PW, BW] rows, NaN-padded — NaN rows are dropped, not
%           included as peaks
%
%   kArgs : struct with fields OFF, EXP1-3, FC1-3, CF1/PW1/BW1,
%           CF2/PW2/BW2, ... (one triplet per non-NaN peMat row)
    apRow = double(apRow(:))';
    kArgs.OFF  = apRow(1);
    kArgs.EXP1 = apRow(2);
    kArgs.EXP2 = apRow(3);
    kArgs.EXP3 = apRow(4);
    kArgs.FC1  = apRow(5);
    kArgs.FC2  = apRow(6);
    kArgs.FC3  = apRow(7);

    if isempty(peMat), return; end
    keep  = ~isnan(peMat(:, 1));
    peMat = peMat(keep, :);
    for i = 1:size(peMat, 1)
        kArgs.(sprintf("CF%d", i)) = peMat(i, 1);
        kArgs.(sprintf("PW%d", i)) = peMat(i, 2);
        kArgs.(sprintf("BW%d", i)) = peMat(i, 3);
    end
end
